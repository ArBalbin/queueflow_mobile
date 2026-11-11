import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queueflow_mobile/models/payment_models.dart';
import 'package:queueflow_mobile/models/queue_models.dart';
import 'package:queueflow_mobile/widgets/join_payment_sheet.dart';

/// Opens the form from a button and records what it returns.
Future<List<JoinPayment?>> _openForm(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  final results = <JoinPayment?>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(
              await showJoinPaymentSheet(context, PaymentOptions.fallback),
            ),
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

Future<void> _pick(WidgetTester tester, String line) async {
  await tester.tap(find.text(line));
  await tester.pumpAndSettle();
}

Future<void> _submit(WidgetTester tester) async {
  await tester.tap(find.text('Request Number'));
  await tester.pumpAndSettle();
}

void main() {
  group('payment options', () {
    test('the slip lines come from the server, with the slip as a fallback', () {
      final options = PaymentOptions.fromJson({
        'items': [
          {'name': 'Tuition', 'detail_prompt': null},
          {'name': 'Special Exam', 'detail_prompt': 'Subject'},
        ],
        'amount_max': 50000,
      });
      expect(options.lines.map((l) => l.name), ['Tuition', 'Special Exam']);
      expect(options.lines.last.detailPrompt, 'Subject');
      expect(options.amountMax, 50000);
      expect(
        PaymentOptions.fromJson({}).lines.map((l) => l.name),
        ['Tuition', 'Books', 'Special Exam', 'Others'],
      );
    });

    test('an older server with one list still works', () {
      final options = PaymentOptions.fromJson({
        'payment_types': ['Tuition fee', 'Other fees'],
        'other_type': 'Other fees',
      });
      expect(options.lines.last.detailPrompt, 'Please specify');
      expect(options.lines.first.detailPrompt, isNull);
    });

    test('the join request carries every line and its own amount', () {
      const payment = JoinPayment([
        JoinPaymentItem(type: 'Tuition', amount: 5000),
        JoinPaymentItem(type: 'Others', amount: 150.5, detail: ' ID '),
      ]);
      expect(payment.total, 5150.5);
      expect(payment.toJson(), {
        'payment_items': [
          {'type': 'Tuition', 'amount': 5000.0},
          {'type': 'Others', 'amount': 150.5, 'detail': 'ID'},
        ],
      });
    });

    test('pesos are written the Philippine way', () {
      expect(formatPeso(5000), '₱5,000.00');
      expect(formatPeso(1234567.5), '₱1,234,567.50');
      expect(formatPeso(350), '₱350.00');
    });

    test('the queue status carries what the student is paying', () {
      final status = QueueStatus.fromJson({
        'queue_number': 5001,
        'payment_type': 'Tuition, Books',
        'payment_amount': 5800,
      });
      expect(status.paymentType, 'Tuition, Books');
      expect(status.paymentAmount, 5800.0);
      expect(status.paymentNote, isNull);
    });
  });

  group('the join form, laid out like the payment slip', () {
    testWidgets('needs at least one line, and an amount for each', (tester) async {
      final results = await _openForm(tester);
      await _submit(tester);
      expect(find.text('Choose at least one thing you are paying for.'), findsOneWidget);

      await _pick(tester, 'Tuition');
      await _submit(tester);
      expect(find.text('Enter the amount.'), findsOneWidget);
      expect(results, isEmpty, reason: 'nothing is sent until the form is valid');
    });

    testWidgets('adds the lines into the TOTAL', (tester) async {
      final results = await _openForm(tester);
      await _pick(tester, 'Tuition');
      await tester.enterText(find.byKey(const Key('payment-amount-Tuition')), '5,000');
      await _pick(tester, 'Books');
      await tester.enterText(find.byKey(const Key('payment-amount-Books')), '800');
      await tester.pump();
      expect(find.text('₱5,800.00'), findsOneWidget);

      await _submit(tester);
      final payment = results.single!;
      expect(payment.items.map((i) => i.type), ['Tuition', 'Books']);
      expect(payment.total, 5800);
    });

    testWidgets('special exam asks for the subject and others what they are', (tester) async {
      final results = await _openForm(tester);
      expect(find.byKey(const Key('payment-detail-Special Exam')), findsNothing);
      await _pick(tester, 'Special Exam');
      expect(find.byKey(const Key('payment-detail-Special Exam')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('payment-amount-Special Exam')), '300');
      await _submit(tester);
      expect(find.text('Fill in the subject.'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('payment-detail-Special Exam')), 'Math 101');
      await _submit(tester);
      expect(results.single!.items.single.detail, 'Math 101');
    });

    testWidgets('tapping a picked line again leaves it out', (tester) async {
      final results = await _openForm(tester);
      await _pick(tester, 'Books');
      await _pick(tester, 'Books');
      expect(find.byKey(const Key('payment-amount-Books')), findsNothing);
      await _pick(tester, 'Tuition');
      await tester.enterText(find.byKey(const Key('payment-amount-Tuition')), '100');
      await _submit(tester);
      expect(results.single!.items.map((i) => i.type), ['Tuition']);
    });

    testWidgets('cancel requests nothing', (tester) async {
      final results = await _openForm(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(results.single, isNull);
    });
  });
}
