import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queueflow_mobile/models/queue_models.dart';
import 'package:queueflow_mobile/services/long_wait.dart';
import 'package:queueflow_mobile/widgets/now_serving_card.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  group('the prediction carries who is at each window', () {
    test('windows are read in order and incomplete entries are skipped', () {
      final prediction = QueuePrediction.fromJson({
        'now_serving': [
          {'counter_number': 2, 'queue_number': 5001, 'queue_label': 'Q5001'},
          {'counter_number': 1, 'queue_number': 5000, 'queue_label': 'Q5000'},
          {'counter_number': null, 'queue_number': 5002},
        ],
        'new_arrival': {'estimated_wait_time_minutes': 18.4},
      });
      expect(prediction.nowServing.map((e) => e.counterNumber), [1, 2]);
      expect(prediction.nowServing.first.queueLabel, 'Q5000');
      expect(prediction.newArrivalWaitMinutes, 18.4);
      expect(prediction.countersClosedUntil, isNull);
    });

    test('an older backend without the field still parses', () {
      final prediction = QueuePrediction.fromJson({'queue_length': 3});
      expect(prediction.nowServing, isEmpty);
      expect(prediction.newArrivalWaitMinutes, 0);
    });

    test('a lunch closure is read as a time', () {
      final prediction = QueuePrediction.fromJson({
        'counters_closed_until': '2026-11-10T13:00:00+08:00',
      });
      expect(prediction.countersClosedUntil, DateTime.parse('2026-11-10T05:00:00Z').toLocal());
    });
  });

  group('long waits', () {
    test('fifteen minutes or more counts as long', () {
      expect(isLongWait(14.9), isFalse);
      expect(isLongWait(15), isTrue);
    });

    test('waits read naturally', () {
      expect(describeWait(18.4), 'about 18 min');
      expect(describeWait(60), 'about 1 hr');
      expect(describeWait(72), 'about 1 hr 12 min');
      expect(formatClockTime(DateTime(2026, 11, 10, 13, 0)), '1:00 PM');
      expect(formatClockTime(DateTime(2026, 11, 10, 0, 5)), '12:05 AM');
    });

    test('the long-wait message is shown once per ticket', () {
      expect(LongWaitNotice.shouldShow(9001, 20), isTrue);
      LongWaitNotice.markShown(9001);
      expect(LongWaitNotice.shouldShow(9001, 25), isFalse);
      expect(LongWaitNotice.shouldShow(9002, 20), isTrue, reason: 'a new ticket is warned again');
      expect(LongWaitNotice.shouldShow(9003, 5), isFalse, reason: 'short waits are not warned');
    });
  });

  group('the Now serving card', () {
    testWidgets('lists each window and marks the student\'s own number', (tester) async {
      final prediction = QueuePrediction.fromJson({
        'now_serving': [
          {'counter_number': 1, 'queue_number': 5000, 'queue_label': 'Q5000'},
          {'counter_number': 2, 'queue_number': 5001, 'queue_label': 'Q5001'},
        ],
      });
      await tester.pumpWidget(_wrap(NowServingCard(prediction: prediction, myQueueNumber: 5001)));
      expect(find.text('Window 1'), findsOneWidget);
      expect(find.text('Q5000'), findsOneWidget);
      expect(find.text('you'), findsOneWidget);
    });

    testWidgets('says when every window is closed', (tester) async {
      final reopen = DateTime.now().add(const Duration(minutes: 40));
      final prediction = QueuePrediction(
        queueLength: 4,
        activeCounters: 3,
        dataStatus: 'live',
        activeQueue: const [],
        countersClosedUntil: reopen,
      );
      await tester.pumpWidget(_wrap(NowServingCard(prediction: prediction)));
      expect(find.textContaining('All windows are closed until ${formatClockTime(reopen)}'), findsOneWidget);
    });

    testWidgets('says when no one is at a window', (tester) async {
      await tester.pumpWidget(_wrap(NowServingCard(prediction: QueuePrediction.empty())));
      expect(find.text('No one is at a window right now.'), findsOneWidget);
    });
  });
}
