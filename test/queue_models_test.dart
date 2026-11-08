import 'package:flutter_test/flutter_test.dart';
import 'package:queueflow_mobile/models/queue_models.dart';

Map<String, dynamic> statusJson(Map<String, dynamic> prediction) => {
      'queue_number': 5003,
      'status': 'waiting',
      'position_in_line': 11,
      'prediction': prediction,
    };

void main() {
  test('the wait is shown with its usual range', () {
    final status = QueueStatus.fromJson(statusJson({
      'position': 11,
      'estimated_wait_time_minutes': 2.6,
      'estimated_wait_time_label': '3 mins',
      'estimated_wait_range_label': 'usually 0–10 mins',
    }));

    expect(status.estimatedWaitWithRange, '3 mins · usually 0–10 mins');
  });

  test('a server that sends no range shows the estimate alone', () {
    final status = QueueStatus.fromJson(statusJson({
      'position': 11,
      'estimated_wait_time_minutes': 2.6,
      'estimated_wait_time_label': '3 mins',
    }));

    expect(status.estimatedWaitWithRange, '3 mins');
  });
}
