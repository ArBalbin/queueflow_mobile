import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/queue_models.dart';
import 'api_config.dart';

class QueueApiException implements Exception {
  final String message;
  final int? statusCode;

  const QueueApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class QueueApiClient {
  final http.Client _client;
  final String baseUrl;

  QueueApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = _normalizeBaseUrl(baseUrl ?? ApiConfig.baseUrl);

  int parseQueueNumber(String input) {
    final match = RegExp(r'\d+').firstMatch(input.trim());
    if (match == null) {
      throw const FormatException('Enter a valid queue number like Q004.');
    }
    return int.parse(match.group(0)!);
  }

  String normalizeToken(String input) {
    final token = input.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
    if (!token.contains('-') && token.length == 8) {
      return '${token.substring(0, 4)}-${token.substring(4)}';
    }
    return token;
  }

  QueueCredentials parseTicketQr(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      throw const FormatException('The scanned QR code was empty.');
    }

    String? queueInput;
    String? tokenInput;
    final uri = Uri.tryParse(value);
    final query = uri?.queryParameters ?? const <String, String>{};

    queueInput = query['q'] ?? query['queue'] ?? query['queue_number'];
    tokenInput = query['token'] ?? query['access_token'] ?? query['code'];

    queueInput ??= RegExp(
      r'(?:^|[?&\s])(?:q|queue|queue_number)=?(Q?\d+)',
      caseSensitive: false,
    ).firstMatch(value)?.group(1);

    tokenInput ??= RegExp(
      r'(?:^|[?&\s])(?:token|access_token|code)=?([A-Z0-9]{4}-?[A-Z0-9]{4})',
      caseSensitive: false,
    ).firstMatch(value)?.group(1);

    queueInput ??= RegExp(
      r'\bQ\s*(\d{1,5})\b',
      caseSensitive: false,
    ).firstMatch(value)?.group(0);

    tokenInput ??= RegExp(
      r'\b[A-Z0-9]{4}-?[A-Z0-9]{4}\b',
      caseSensitive: false,
    ).firstMatch(value)?.group(0);

    if (queueInput == null || tokenInput == null) {
      throw const FormatException(
        'This QR code does not contain a QueuEx ticket.',
      );
    }

    return QueueCredentials(
      queueNumber: parseQueueNumber(queueInput),
      accessToken: normalizeToken(tokenInput),
      // Prefer the host embedded in the scanned ticket URL (so a ticket
      // printed by a different backend instance still resolves correctly);
      // null falls back to this client's configured baseUrl at request time.
      apiBaseUrl: _baseUrlFromTicketUri(uri),
    );
  }

  Future<QueueSnapshot> fetchQueueSnapshot(QueueCredentials credentials) async {
    final status = await fetchQueueStatus(credentials);
    QueuePrediction prediction;

    try {
      prediction = await fetchQueuePrediction(
        baseUrlOverride: credentials.apiBaseUrl,
      );
    } on QueueApiException {
      prediction = QueuePrediction.empty();
    }

    return QueueSnapshot(
      credentials: credentials,
      status: status,
      prediction: prediction,
    );
  }

  Future<QueueStatus> fetchQueueStatus(QueueCredentials credentials) async {
    final uri = _uri(
      '/api/queue/status',
      queryParameters: {
        'q': credentials.queueNumber.toString(),
        'token': credentials.accessToken,
      },
      baseUrlOverride: credentials.apiBaseUrl,
    );
    final json = await _getJson(uri);
    return QueueStatus.fromJson(json);
  }

  Future<QueuePrediction> fetchQueuePrediction({
    String? baseUrlOverride,
  }) async {
    final json = await _getJson(
      _uri('/api/queue/prediction', baseUrlOverride: baseUrlOverride),
    );
    return QueuePrediction.fromJson(json);
  }

  Future<Map<String, dynamic>> notifyOnTheWay(
    QueueCredentials credentials,
  ) async {
    final uri = _uri(
      '/api/queue/on_way',
      baseUrlOverride: credentials.apiBaseUrl,
    );
    return _postJson(uri, {
      'queue_number': credentials.queueNumber,
      'token': credentials.accessToken,
    });
  }

  Uri _uri(
    String path, {
    Map<String, String>? queryParameters,
    String? baseUrlOverride,
  }) {
    final effectiveBaseUrl = _normalizeBaseUrl(baseUrlOverride ?? baseUrl);
    return Uri.parse(
      '$effectiveBaseUrl$path',
    ).replace(queryParameters: queryParameters);
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final requestBaseUrl = _baseUrlFromUri(uri) ?? baseUrl;
    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 15));
      return _decodeResponse(response);
    } on QueueApiException {
      rethrow;
    } on TimeoutException {
      throw QueueApiException(
        'QueuEx API timed out. Make sure the backend is running at $requestBaseUrl.',
      );
    } on http.ClientException {
      throw QueueApiException(
        'Cannot connect to QueuEx API at $requestBaseUrl.',
      );
    } catch (e, st) {
      debugPrint('[QueuEx DEBUG] $uri failed: ${e.runtimeType}: $e');
      debugPrint('[QueuEx DEBUG] stack: $st');
      throw QueueApiException(
        'Cannot reach QueuEx API. Check your backend server and network.',
      );
    }
  }

  Future<Map<String, dynamic>> _postJson(
    Uri uri,
    Map<String, dynamic> body,
  ) async {
    final requestBaseUrl = _baseUrlFromUri(uri) ?? baseUrl;
    try {
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _decodeResponse(response);
    } on QueueApiException {
      rethrow;
    } on TimeoutException {
      throw QueueApiException(
        'QueuEx API timed out. Make sure the backend is running at $requestBaseUrl.',
      );
    } on http.ClientException {
      throw QueueApiException(
        'Cannot connect to QueuEx API at $requestBaseUrl.',
      );
    } catch (e, st) {
      debugPrint('[QueuEx DEBUG] $uri failed: ${e.runtimeType}: $e');
      debugPrint('[QueuEx DEBUG] stack: $st');
      throw QueueApiException(
        'Cannot reach QueuEx API. Check your backend server and network.',
      );
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);

    final json = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};

    if (response.statusCode >= 400) {
      throw QueueApiException(
        _errorMessage(json),
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map) {
      throw const QueueApiException(
        'QueuEx API returned an unexpected response.',
      );
    }

    return json;
  }

  String _errorMessage(Map<String, dynamic> json) {
    final message = json['message'] ?? json['detail'] ?? json['error'];
    if (message != null && message.toString().trim().isNotEmpty) {
      return message.toString();
    }
    return 'QueuEx API request failed.';
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  static String? _baseUrlFromTicketUri(Uri? uri) {
    if (uri == null) return null;
    if (uri.path.isNotEmpty && !uri.path.endsWith('/api/queue/status')) {
      return null;
    }
    return _baseUrlFromUri(uri);
  }

  static String? _baseUrlFromUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if ((scheme != 'http' && scheme != 'https') || uri.host.isEmpty) {
      return null;
    }
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '$scheme://${uri.host}$port';
  }
}
