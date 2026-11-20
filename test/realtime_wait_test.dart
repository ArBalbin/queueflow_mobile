import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queueflow_mobile/models/queue_models.dart';
import 'package:queueflow_mobile/widgets/live_wait.dart';

void main() {
  group('Times shown as a clock', () {
    test('minutes and seconds, and hours past an hour', () {
      expect(formatClock(0), '0:00');
      expect(formatClock(59), '0:59');
      expect(formatClock(185), '3:05');
      expect(formatClock(3725), '1:02:05');
      expect(formatClock(-4), '0:00');
    });
  });

  group('The real-time estimate from the server', () {
    test('carries seconds, the time of service and the average service time', () {
      final e = QueueEstimate.fromJson({
        'position': 3,
        'estimated_wait_time_minutes': 2.7,
        'estimated_wait_seconds': 164,
        'estimated_wait_time_label': '2 min 44 sec',
        'estimated_service_start_at': '2026-11-22T14:41:30+08:00',
        'estimated_service_start_label': '2:41:30 PM',
        'estimated_service_time_min': 1.95,
        'avg_service_seconds': 117,
        'avg_service_basis': 'last 4 services',
        'adjustment_note': 'Window 1 has been serving Q001 for 5 min 00 sec.',
      });
      expect(e.estimatedWaitSeconds, 164);
      expect(e.estimatedServiceStartLabel, '2:41:30 PM');
      expect(e.avgServiceSeconds, 117);
      expect(e.avgServiceBasis, 'last 4 services');
      expect(e.adjustmentNote, startsWith('Window 1'));
    });

    test('an older server that sends minutes only still gives seconds', () {
      final e = QueueEstimate.fromJson({
        'estimated_wait_time_minutes': 2.5,
        'estimated_service_time_min': 2.0,
      });
      expect(e.estimatedWaitSeconds, 150);
      expect(e.avgServiceSeconds, 120);
      expect(e.adjustmentNote, '');
    });

    test('the line says how long each window has been serving', () {
      final p = QueuePrediction.fromJson({
        'avg_service_seconds': 117,
        'new_arrival': {'estimated_wait_seconds': 245},
        'now_serving': [
          {
            'counter_number': 1,
            'queue_number': 1,
            'queue_label': 'Q001',
            'serving_seconds': 300,
            'running_long': true,
          },
        ],
      });
      expect(p.newArrivalWaitSeconds, 245);
      expect(p.avgServiceSeconds, 117);
      expect(p.nowServing.single.servingSeconds, 300);
      expect(p.nowServing.single.runningLong, isTrue);
    });

    test('a called ticket says how long ago and how long to reach the window', () {
      final s = QueueStatus.fromJson({
        'queue_number': 7,
        'counter_number': 2,
        'seconds_at_counter': 12,
        'arrive_within_seconds': 90,
      });
      expect(s.secondsAtCounter, 12);
      expect(s.arriveWithinSeconds, 90);
    });
  });

  testWidgets('the wait counts down on the phone between requests', (tester) async {
    final anchor = DateTime.now();
    await tester.pumpWidget(
      MaterialApp(
        home: LiveCountdown(seconds: 125, anchor: anchor),
      ),
    );
    expect(find.text('2:05'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the service time card shows the clock time, average and why it moved', (
    tester,
  ) async {
    const estimate = QueueEstimate(
      position: 2,
      estimatedWaitMinutes: 1.3,
      estimatedWaitLabel: '1 min 16 sec',
      estimatedServiceStartAt: null,
      estimatedServiceFinishAt: null,
      estimatedServiceTimeMinutes: 2.3,
      estimatedWaitSeconds: 76,
      estimatedServiceStartLabel: '2:41:30 PM',
      avgServiceSeconds: 140,
      avgServiceBasis: 'last 4 services',
      adjustmentNote: 'Window 1 has been serving Q001 for 5 min 00 sec, '
          'longer than the average of 2 min 20 sec, so your time moved later.',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ServiceTimeCard(estimate: estimate, anchor: DateTime.now()),
          ),
        ),
      ),
    );
    expect(find.text('Estimated time of service'), findsOneWidget);
    expect(find.text('2:41:30 PM'), findsOneWidget);
    expect(find.text('2:20'), findsOneWidget, reason: 'average service time');
    expect(find.textContaining('last 4 services'), findsOneWidget);
    expect(find.textContaining('so your time moved later'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });
}
