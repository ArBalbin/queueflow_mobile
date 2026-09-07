import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/queue_models.dart';
import 'queue_api.dart';

class QueueSessionStore {
  static const _kQueueNumber = 'ticket_queue_number';
  static const _kAccessToken = 'ticket_access_token';
  static const _kApiBaseUrl = 'ticket_api_base_url';

  static final QueueApiClient api = QueueApiClient();

  static QueueCredentials? credentials;
  static QueueSnapshot? latestSnapshot;

  static bool get hasSession => credentials != null;

  /// Restores a previously-tracked printed ticket after an app restart, so a
  /// guest (no student login) isn't dumped back to the lookup form every
  /// time they reopen the app. Returns true only if the saved ticket is
  /// still valid on the backend — a stale/served ticket is cleared instead.
  static Future<bool> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueNumber = prefs.getInt(_kQueueNumber);
      final accessToken = prefs.getString(_kAccessToken);
      if (queueNumber == null || accessToken == null) return false;

      await startSessionWithCredentials(
        QueueCredentials(
          queueNumber: queueNumber,
          accessToken: accessToken,
          apiBaseUrl: prefs.getString(_kApiBaseUrl),
        ),
        persist: false,
      );
      return true;
    } catch (_) {
      await _clearPersisted();
      return false;
    }
  }

  static Future<void> _persist(QueueCredentials credentials) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kQueueNumber, credentials.queueNumber);
      await prefs.setString(_kAccessToken, credentials.accessToken);
      final baseUrl = credentials.apiBaseUrl;
      if (baseUrl == null) {
        await prefs.remove(_kApiBaseUrl);
      } else {
        await prefs.setString(_kApiBaseUrl, baseUrl);
      }
    } catch (_) {
      // Persistence is a convenience — a failure here shouldn't break the
      // in-memory session the user is actively using.
    }
  }

  static Future<void> _clearPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kQueueNumber);
      await prefs.remove(_kAccessToken);
      await prefs.remove(_kApiBaseUrl);
    } catch (_) {}
  }

  static Future<QueueSnapshot> startSession({
    required String queueInput,
    required String tokenInput,
  }) async {
    final queueNumber = api.parseQueueNumber(queueInput);
    final token = api.normalizeToken(tokenInput);
    final nextCredentials = QueueCredentials(
      queueNumber: queueNumber,
      accessToken: token,
    );

    return startSessionWithCredentials(nextCredentials);
  }

  static Future<QueueSnapshot> startSessionFromQr(String rawValue) {
    return startSessionWithCredentials(api.parseTicketQr(rawValue));
  }

  static Future<QueueSnapshot> startSessionWithCredentials(
    QueueCredentials nextCredentials, {
    bool persist = true,
  }) async {
    final snapshot = await api.fetchQueueSnapshot(nextCredentials);
    credentials = nextCredentials;
    latestSnapshot = snapshot;
    if (persist) await _persist(nextCredentials);
    return snapshot;
  }

  static Future<QueueSnapshot> refresh() async {
    final currentCredentials = credentials;
    if (currentCredentials == null) {
      throw const QueueApiException('Enter your ticket details first.');
    }

    final snapshot = await api.fetchQueueSnapshot(currentCredentials);
    latestSnapshot = snapshot;
    return snapshot;
  }

  static Future<QueueSnapshot> notifyOnTheWay() async {
    final currentCredentials = credentials;
    if (currentCredentials == null) {
      throw const QueueApiException('Enter your ticket details first.');
    }

    await api.notifyOnTheWay(currentCredentials);

    try {
      return await refresh();
    } on QueueApiException {
      final currentSnapshot = latestSnapshot;
      if (currentSnapshot == null) {
        rethrow;
      }
      final updatedSnapshot = currentSnapshot.copyWith(
        status: currentSnapshot.status.copyWith(onTheWay: true),
        fetchedAt: DateTime.now(),
      );
      latestSnapshot = updatedSnapshot;
      return updatedSnapshot;
    }
  }

  static void clear() {
    credentials = null;
    latestSnapshot = null;
    unawaited(_clearPersisted());
  }
}
