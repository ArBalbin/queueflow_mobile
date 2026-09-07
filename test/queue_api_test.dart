import 'package:flutter_test/flutter_test.dart';
import 'package:queueflow_mobile/services/queue_api.dart';

void main() {
  group('QueueApiClient.parseTicketQr', () {
    final api = QueueApiClient(baseUrl: 'http://fallback.local:5000');

    test('keeps the API host from a ticket status URL', () {
      final credentials = api.parseTicketQr(
        'http://192.168.43.236:5000/api/queue/status?q=4&token=ABCD-EFGH',
      );

      expect(credentials.queueNumber, 4);
      expect(credentials.accessToken, 'ABCD-EFGH');
      expect(credentials.apiBaseUrl, 'http://192.168.43.236:5000');
    });

    test('normalizes compact tokens from scanned text', () {
      final credentials = api.parseTicketQr('Q004 token=ABCDEFGH');

      expect(credentials.queueNumber, 4);
      expect(credentials.accessToken, 'ABCD-EFGH');
      expect(credentials.apiBaseUrl, isNull);
    });
  });
}
