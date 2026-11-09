import 'package:flutter_test/flutter_test.dart';
import 'package:queueflow_mobile/models/queue_models.dart';
import 'package:queueflow_mobile/services/queue_navigation.dart';
import 'package:queueflow_mobile/services/queue_session_store.dart';

void main() {
  tearDown(QueueSessionStore.clear);

  test('My Queue nav opens ticket lookup only when no ticket session exists', () {
    QueueSessionStore.clear();

    expect(routeForBottomNavIndex(0), '/ticket/lookup');
  });

  test('My Queue nav returns to queue page when credentials exist', () {
    QueueSessionStore.credentials = const QueueCredentials(
      queueNumber: 1,
      accessToken: 'ABCD-EFGH',
    );

    expect(routeForBottomNavIndex(0), '/queue/waiting');
  });

  group('the screen for a ticket follows its status', () {
    QueueSnapshot snapshot(String status, {int position = 0, int? counter}) => QueueSnapshot(
          credentials: const QueueCredentials(queueNumber: 7, accessToken: 'ABCD-EFGH'),
          status: QueueStatus.fromJson({
            'queue_number': 7,
            'status': status,
            'position_in_line': position,
            'counter_number': counter,
          }),
          prediction: QueuePrediction.fromJson(const {}),
        );

    test('a skipped ticket explains itself instead of staying on the waiting screen', () {
      expect(routeForQueueSnapshot(snapshot('no_show')), '/queue/skipped');
    });

    test('a served ticket still goes to the exit screen', () {
      expect(routeForQueueSnapshot(snapshot('done_pending')), '/queue/exit');
      expect(routeForQueueSnapshot(snapshot('served')), '/queue/exit');
    });

    test("a ticket called to a window shows It's your turn, at any position", () {
      expect(routeForQueueSnapshot(snapshot('waiting', position: 1, counter: 1)), '/queue/serving');
      expect(routeForQueueSnapshot(snapshot('waiting', position: 3, counter: 3)), '/queue/serving',
          reason: 'with three windows, the third in line is being served too');
    });

    test('finishing or skipping at a window leaves the serving screen', () {
      expect(routeForQueueSnapshot(snapshot('done_pending', counter: 2)), '/queue/exit');
      expect(routeForQueueSnapshot(snapshot('no_show', counter: 2)), '/queue/skipped');
    });

    test('a waiting ticket is next at position 1, otherwise waiting', () {
      expect(routeForQueueSnapshot(snapshot('waiting', position: 1)), '/queue/next');
      expect(routeForQueueSnapshot(snapshot('waiting', position: 4)), '/queue/waiting');
    });
  });

  test('Other bottom nav routes stay fixed', () {
    expect(routeForBottomNavIndex(1), '/history');
    expect(routeForBottomNavIndex(2), '/profile');
    expect(routeForBottomNavIndex(3), '/help');
  });
}
