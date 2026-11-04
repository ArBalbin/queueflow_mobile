import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:queueflow_mobile/models/student_models.dart';
import 'package:queueflow_mobile/services/idle_logout.dart';

void main() {
  final now = DateTime(2026, 11, 4, 12, 0);
  int minutesAgo(int m) => now.subtract(Duration(minutes: m)).millisecondsSinceEpoch;

  test('29 minutes away is not idle; 30 minutes is', () {
    expect(IdleLogout.idleTooLong(minutesAgo(29), now), isFalse);
    expect(IdleLogout.idleTooLong(minutesAgo(30), now), isTrue);
    expect(IdleLogout.idleTooLong(minutesAgo(600), now), isTrue);
  });

  test('no record of use yet does not sign anyone out', () {
    expect(IdleLogout.idleTooLong(null, now), isFalse);
  });

  test('a student in the queue keeps the session', () {
    const notQueued = MyQueueEntry(hasActiveEntry: false, pendingLink: false);
    const joined = MyQueueEntry(hasActiveEntry: false, pendingLink: false, joined: true);
    const holdingNumber = MyQueueEntry(hasActiveEntry: true, pendingLink: false, queueNumber: 5001);
    const beingIdentified = MyQueueEntry(hasActiveEntry: false, pendingLink: true);
    expect(IdleLogout.inQueue(notQueued), isFalse);
    expect(IdleLogout.inQueue(joined), isTrue);
    expect(IdleLogout.inQueue(holdingNumber), isTrue);
    expect(IdleLogout.inQueue(beingIdentified), isTrue);
  });

  test('nobody signed in means nothing to sign out', () async {
    SharedPreferences.setMockInitialValues({'student_last_active_ms': minutesAgo(600)});
    expect(await IdleLogout.shouldSignOut(), isFalse);
  });
}
