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

  test('Other bottom nav routes stay fixed', () {
    expect(routeForBottomNavIndex(1), '/history');
    expect(routeForBottomNavIndex(2), '/profile');
    expect(routeForBottomNavIndex(3), '/help');
  });
}
