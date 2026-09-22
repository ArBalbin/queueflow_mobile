import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/student_models.dart';
import 'api_config.dart';
import 'queue_api.dart';

/// Thrown by studentGoogleAuth() when the backend needs a school_id because
/// this Google account has never signed in before (first-time sign-up).
class SchoolIdRequiredException implements Exception {
  const SchoolIdRequiredException();
}

class StudentApiClient {
  final http.Client _client;
  final String baseUrl;

  StudentApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = _normalizeBaseUrl(baseUrl ?? ApiConfig.baseUrl);

  Future<StudentSession> googleAuth({
    required String idToken,
    String? schoolId,
  }) async {
    final response = await _postJson('/api/students/auth/google', {
      'id_token': idToken,
      if (schoolId != null && schoolId.trim().isNotEmpty)
        'school_id': schoolId.trim(),
    });
    return StudentSession.fromJson(response);
  }

  Future<StudentSession> faceLogin(File photo) async {
    final response = await _postMultipart(
      '/api/students/auth/face',
      fileField: 'photo',
      files: [photo],
    );
    return StudentSession.fromJson(response);
  }

  Future<Map<String, dynamic>> registerFace(
    List<File> photos,
    String sessionToken,
  ) {
    return _postMultipart(
      '/api/students/me/face',
      fileField: 'photos',
      files: photos,
      sessionToken: sessionToken,
    );
  }

  /// Tells the backend this student actually wants a queue number, so the
  /// camera may issue one when it recognizes them. Without this, being seen
  /// by the camera does nothing — recognition alone is not a request to join.
  Future<void> joinQueue(String sessionToken) async {
    await _postJson('/api/students/me/join', const {}, sessionToken: sessionToken);
  }

  /// Withdraws that request. Walking past the camera then issues nothing.
  Future<void> cancelJoinQueue(String sessionToken) async {
    await _deleteJson('/api/students/me/join', sessionToken: sessionToken);
  }

  Future<MyQueueEntry> getMyQueueEntry(String sessionToken) async {
    final response = await _getJson('/api/students/me/queue', sessionToken: sessionToken);
    return MyQueueEntry.fromJson(response);
  }

  Future<StudentProfile> getMe(String sessionToken) async {
    final response = await _getJson('/api/students/me', sessionToken: sessionToken);
    final student = response['student'];
    if (student is! Map) {
      throw const QueueApiException('Unexpected response from server.');
    }
    return StudentProfile.fromJson(Map<String, dynamic>.from(student));
  }

  Future<void> logout(String sessionToken) async {
    await _postJson('/api/students/logout', const {}, sessionToken: sessionToken);
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    String? sessionToken,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final response = await _client
          .get(uri, headers: _headers(sessionToken))
          .timeout(kApiTimeout);
      return _decode(response);
    } on QueueApiException {
      rethrow;
    } on SchoolIdRequiredException {
      rethrow;
    } catch (e, st) {
      debugPrint('[QueuEx DEBUG] GET $uri failed: ${e.runtimeType}: $e');
      debugPrint('[QueuEx DEBUG] stack: $st');
      throw QueueApiException('Cannot reach QueuEx API at $baseUrl.');
    }
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body, {
    String? sessionToken,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              ..._headers(sessionToken),
            },
            body: jsonEncode(body),
          )
          .timeout(kApiTimeout);
      return _decode(response);
    } on QueueApiException {
      rethrow;
    } on SchoolIdRequiredException {
      rethrow;
    } catch (e, st) {
      debugPrint('[QueuEx DEBUG] POST $uri failed: ${e.runtimeType}: $e');
      debugPrint('[QueuEx DEBUG] stack: $st');
      throw QueueApiException('Cannot reach QueuEx API at $baseUrl.');
    }
  }

  Future<Map<String, dynamic>> _deleteJson(
    String path, {
    String? sessionToken,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final response = await _client
          .delete(uri, headers: _headers(sessionToken))
          .timeout(kApiTimeout);
      return _decode(response);
    } on QueueApiException {
      rethrow;
    } on SchoolIdRequiredException {
      rethrow;
    } catch (e, st) {
      debugPrint('[QueuEx DEBUG] DELETE $uri failed: ${e.runtimeType}: $e');
      debugPrint('[QueuEx DEBUG] stack: $st');
      throw QueueApiException('Cannot reach QueuEx API at $baseUrl.');
    }
  }

  Future<Map<String, dynamic>> _postMultipart(
    String path, {
    required String fileField,
    required List<File> files,
    String? sessionToken,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_headers(sessionToken));
      for (final file in files) {
        request.files.add(
          await http.MultipartFile.fromPath(fileField, file.path),
        );
      }
      final streamed = await request.send().timeout(kUploadTimeout);
      final response = await http.Response.fromStream(streamed);
      return _decode(response);
    } on QueueApiException {
      rethrow;
    } on SchoolIdRequiredException {
      rethrow;
    } catch (e, st) {
      debugPrint('[QueuEx DEBUG] MULTIPART $uri failed: ${e.runtimeType}: $e');
      debugPrint('[QueuEx DEBUG] stack: $st');
      throw QueueApiException('Cannot reach QueuEx API at $baseUrl.');
    }
  }

  Map<String, String> _headers(String? sessionToken) {
    if (sessionToken == null || sessionToken.isEmpty) return const {};
    return {'Authorization': 'Bearer $sessionToken'};
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    final json = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};

    if (response.statusCode >= 400) {
      // The backend's global error handler rewrites every /api/* error into
      // {"error": ..., "message": exc.detail} — there is no top-level
      // "detail" key in the actual response, even though FastAPI's default
      // (unwrapped) shape would have one. Check both so this works either way.
      final detail = json['detail'] ?? json['message'];
      if (detail == 'school_id_required') {
        throw const SchoolIdRequiredException();
      }
      final message = detail ?? 'Request failed.';
      throw QueueApiException(
        message.toString(),
        statusCode: response.statusCode,
      );
    }
    return json;
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }
}
