import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queueflow_mobile/models/payment_models.dart';
import 'package:queueflow_mobile/models/queue_models.dart';
import 'package:queueflow_mobile/widgets/join_payment_sheet.dart';

/// Opens the form from a button and records what it returns.
Future<List<JoinPayment?>> _openForm(WidgetTester tester) async {
  final results = <JoinPayment?>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                results.add(await showJoinPaymentSheet(context, PaymentOptions.fallback)),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return results;
}

Future<void> _choose(WidgetTester tester, String type) async {
  await tester.tap(find.byKey(const Key('payment-type')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(type).last);
  await tester.pumpAndSettle();
}

void main() {
  group('payment options', () {
    test('read from the server, with the default list as a fallback', () {
      final options = PaymentOptions.fromJson({
        'payment_types': ['Tuition fee', 'Other fees'],
        'other_type': 'Other fees',
        'amount_max': 50000,
      });
      expect(options.types, ['Tuition fee', 'Other fees']);
      expect(options.isOther('other fees'), isTrue);
      expect(options.amountMax, 50000);
      expect(PaymentOptions.fromJson({}).types, PaymentOptions.fallback.types);
    });

    test('the join request carries the form, the note only when given', () {
      expect(const JoinPayment(type: 'Balance', amount: 1200).toJson(), {
        'payment_type': 'Balance',
        'payment_amount': 1200.0,
      });
      expect(
        const JoinPayment(type: 'Other fees', amount: 300, note: ' ID ').toJson()['payment_note'],
        'ID',
      );
    });

    test('pesos are written the Philippine way', () {
      expect(formatPeso(5000), '₱5,000.00');
      expect(formatPeso(1234567.5), '₱1,234,567.50');
      expect(formatPeso(350), '₱350.00');
    });

    test('the queue status carries what the student is paying', () {
      final status = QueueStatus.fromJson({
        'queue_number': 5001,
        'payment_type': 'Tuition fee',
        'payment_amount': 5000,
      });
      expect(status.paymentType, 'Tuition fee');
      expect(status.paymentAmount, 5000.0);
      expect(status.paymentNote, isNull);
    });
  });

  group('the join form', () {
    testWidgets('asks for the type and a total before joining', (tester) async {
      final results = await _openForm(tester);
      await tester.tap(find.text('Join the Queue'));
      await tester.pumpAndSettle();
      expect(find.text('Choose what you are paying for.'), findsOneWidget);
      expect(find.text('Enter the total you will pay.'), findsOneWidget);
      expect(results, isEmpty, reason: 'nothing is sent until the form is valid');

      await _choose(tester, 'Tuition fee');
      await tester.enterText(find.byKey(const Key('payment-amount')), '5,000');
      await tester.tap(find.text('Join the Queue'));
      await tester.pumpAndSettle();
      expect(results.single?.type, 'Tuition fee');
      expect(results.single?.amount, 5000.0);
      expect(results.single?.note, isNull);
    });

    testWidgets('other fees ask which fees', (tester) async {
      final results = await _openForm(tester);
      expect(find.byKey(const Key('payment-note')), findsNothing);
      await _choose(tester, 'Other fees');
      expect(find.byKey(const Key('payment-note')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('payment-amount')), '350');
      await tester.tap(find.text('Join the Queue'));
      await tester.pumpAndSettle();
      expect(find.text('Write which fees you are paying.'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('payment-note')), 'ID replacement');
      await tester.tap(find.text('Join the Queue'));
      await tester.pumpAndSettle();
      expect(results.single?.note, 'ID replacement');
    });

    testWidgets('cancel joins nothing', (tester) async {
      final results = await _openForm(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(results.single, isNull);
    });
  });
}
