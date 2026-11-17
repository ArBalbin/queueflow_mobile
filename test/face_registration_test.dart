import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:queueflow_mobile/services/queue_api.dart';
import 'package:queueflow_mobile/services/student_api.dart';
import 'package:queueflow_mobile/widgets/face_scan_widgets.dart';

/// Face registration after the UAT: progress while the photos upload, and a
/// send that gets no answer is reported as one that can simply be sent again.
void main() {
  late Directory dir;
  late List<File> photos;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('queuex_face_');
    photos = [
      for (var i = 0; i < 3; i++)
        File('${dir.path}/pose$i.jpg')..writeAsBytesSync(List.filled(40000, i)),
    ];
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('the upload reports its progress up to 100%', () async {
    final client = MockClient((request) async {
      return http.Response('{"student_id": 7, "samples_used": 3}', 200);
    });
    final api = StudentApiClient(client: client, baseUrl: 'https://example.test');
    final progress = <double>[];
    await api.registerFace(photos, 'token', onProgress: progress.add);
    expect(progress, isNotEmpty);
    expect(progress.last, closeTo(1.0, 1e-9));
    for (var i = 1; i < progress.length; i++) {
      expect(progress[i], greaterThanOrEqualTo(progress[i - 1]));
    }
  });

  test('no answer from the server can be sent again; an answer cannot', () async {
    final silent = StudentApiClient(
      client: MockClient((_) async => throw http.ClientException('connection reset')),
      baseUrl: 'https://example.test',
    );
    await expectLater(
      silent.registerFace(photos, 'token'),
      throwsA(isA<QueueApiException>().having((e) => e.statusCode, 'statusCode', isNull)),
    );

    final unclear = StudentApiClient(
      client: MockClient((_) async => http.Response(
            '{"message": "We could not see a face clearly."}', 422)),
      baseUrl: 'https://example.test',
    );
    await expectLater(
      unclear.registerFace(photos, 'token'),
      throwsA(isA<QueueApiException>().having((e) => e.statusCode, 'statusCode', 422)),
    );
  });

  testWidgets('the scan instruction is large and above the camera', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(children: [
          FaceScanPrompt(text: 'Now turn your head to the other side', step: 'STEP 3 OF 3'),
        ]),
      ),
    ));
    final text = tester.widget<Text>(find.text('Now turn your head to the other side'));
    expect(text.style!.fontSize, greaterThanOrEqualTo(20));
    expect(find.text('STEP 3 OF 3'), findsOneWidget);
  });
}
