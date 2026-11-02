import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:queueflow_mobile/screens/consent_screen.dart';
import 'package:queueflow_mobile/services/privacy_notice.dart';

void main() {
  Future<bool?> openConsent(WidgetTester tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const ConsentScreen()),
            );
          },
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('shows every part of the privacy notice', (tester) async {
    await openConsent(tester);
    expect(find.text('Data Privacy Notice and Consent'), findsOneWidget);
    for (final section in kNoticeSections) {
      expect(find.text(section.heading), findsOneWidget);
    }
  });

  testWidgets('cannot agree until the box is ticked', (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const ConsentScreen()),
            );
          },
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('I agree'));
    await tester.pumpAndSettle();
    expect(find.byType(ConsentScreen), findsOneWidget, reason: 'still open');
    expect(result, isNull);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('I agree'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('declining returns false', (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const ConsentScreen()),
            );
          },
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}
