import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:queueflow_mobile/services/queue_api.dart';
import 'package:queueflow_mobile/services/student_session_store.dart';
import 'package:queueflow_mobile/services/turn_notice.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fixes made after the user acceptance test of 16 Nov 2026.
void main() {
  group('"Your turn is near" heads-up', () {
    test('comes at five minutes or less, once per ticket', () {
      expect(TurnSoonNotice.shouldShow(5001, 12, 6), isFalse);
      expect(TurnSoonNotice.shouldShow(5001, 5, 3), isTrue);
      TurnSoonNotice.markShown(5001);
      expect(TurnSoonNotice.shouldShow(5001, 3, 2), isFalse, reason: 'once only');
      expect(TurnSoonNotice.shouldShow(5002, 4.5, 2), isTrue, reason: 'a new ticket');
    });

    test('waits for an estimate, and leaves first in line to "You\'re next"', () {
      expect(TurnSoonNotice.shouldShow(5010, null, 3), isFalse);
      expect(TurnSoonNotice.shouldShow(5011, 2, 1), isFalse);
    });
  });

  group('Network errors a student can act on', () {
    test('a timeout says the server is slow or busy', () {
      expect(networkErrorMessage(TimeoutException('x')), kServerSlowMessage);
    });

    test('anything else says the server cannot be reached', () {
      final message = networkErrorMessage(Exception('socket'));
      expect(message, kServerUnreachableMessage);
      expect(message, isNot(contains('http')), reason: 'no server address');
    });
  });

  group('Face sign-in opens only the account last used on the phone', () {
    test('with no account used on this phone, it asks for Gbox', () async {
      SharedPreferences.setMockInitialValues({});
      final account = await StudentSessionStore.faceSignInAccount();
      expect(account.studentId, isNull);
      expect(account.reason, StudentSessionStore.faceSignInNeedsAccountMessage);
    });

    test('an account without a registered face is told so', () async {
      SharedPreferences.setMockInitialValues({
        'last_student_id': 24,
        'last_student_has_face': false,
      });
      final account = await StudentSessionStore.faceSignInAccount();
      expect(account.studentId, isNull);
      expect(account.reason, StudentSessionStore.faceNotRegisteredMessage);
    });

    test('the remembered account with a face is the one offered', () async {
      SharedPreferences.setMockInitialValues({
        'last_student_id': 22,
        'last_student_has_face': true,
      });
      final account = await StudentSessionStore.faceSignInAccount();
      expect(account.studentId, 22);
    });
  });
}
