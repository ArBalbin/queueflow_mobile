import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/student_models.dart';
import 'queue_navigation.dart';
import 'queue_session_store.dart';
import 'student_session_store.dart';

/// Signs a student out after the app has gone unused for [idleLimit].
///
/// A saved session used to last 30 days, so anyone who picked up the phone
/// later — a shared or borrowed phone is common on campus — opened straight
/// into the student's account. Time spent with the app in the background or
/// closed now counts as idle, and on return the student is sent to the login
/// screen once the limit has passed.
///
/// A student who is in the queue is never signed out this way: they may wait
/// a long time with the phone in their pocket, and their number is what they
/// came back to see.
class IdleLogout with WidgetsBindingObserver {
  static const Duration idleLimit = Duration(minutes: 30);
  static const String _lastActiveKey = 'student_last_active_ms';

  final GlobalKey<NavigatorState> navigatorKey;
  bool _checking = false;

  IdleLogout(this.navigatorKey);

  void start() => WidgetsBinding.instance.addObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        markActive();
      case AppLifecycleState.resumed:
        _checkOnResume();
      case AppLifecycleState.inactive:
        break;
    }
  }

  /// Records that the app was in use just now.
  static Future<void> markActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastActiveKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      // Storage unavailable: the next check simply finds no timestamp.
    }
  }

  /// Whether the app has gone unused past [idleLimit]. No record (the first
  /// run after this was added) counts as recent use.
  static bool idleTooLong(int? lastActiveMs, DateTime now) {
    if (lastActiveMs == null) return false;
    final idle = now.difference(DateTime.fromMillisecondsSinceEpoch(lastActiveMs));
    return idle >= idleLimit;
  }

  /// A student who asked to be queued, or holds a number, stays signed in.
  static bool inQueue(MyQueueEntry entry) =>
      entry.joined || entry.hasActiveEntry || entry.pendingLink;

  /// Whether the signed-in student's session should end now: the app has
  /// been unused past [idleLimit] and the student is not in the queue.
  static Future<bool> shouldSignOut() async {
    final token = StudentSessionStore.sessionToken;
    if (token == null) return false;

    final prefs = await SharedPreferences.getInstance();
    if (!idleTooLong(prefs.getInt(_lastActiveKey), DateTime.now())) return false;

    try {
      final entry = await StudentSessionStore.api.getMyQueueEntry(token);
      if (inQueue(entry)) return false;
    } catch (_) {
      // Cannot confirm a queue entry: sign out. A queue number is kept on the
      // server, so signing back in shows it again.
    }
    return true;
  }

  /// Ends the session and clears the ticket being tracked on this phone.
  static Future<void> signOut() async {
    QueueSessionStore.clear();
    await StudentSessionStore.logout();
  }

  Future<void> _checkOnResume() async {
    if (_checking) return;
    _checking = true;
    try {
      if (await shouldSignOut()) {
        await signOut();
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/student/login',
          (_) => false,
          arguments: loginIdleArgument,
        );
      } else {
        await markActive();
      }
    } finally {
      _checking = false;
    }
  }
}
