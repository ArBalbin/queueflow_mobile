import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/payment_models.dart';
import '../theme/app_theme.dart';
import 'shared_widgets.dart';

/// Asks what the student is paying for and the total before they join, so
/// the cashier can have the receipt ready. Returns null if they cancel.
Future<JoinPayment?> showJoinPaymentSheet(
  BuildContext context,
  PaymentOptions options,
) {
  return showModalBottomSheet<JoinPayment>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => JoinPaymentForm(options: options),
  );
}

class JoinPaymentForm extends StatefulWidget {
  final PaymentOptions options;

  const JoinPaymentForm({super.key, required this.options});

  @override
  State<JoinPaymentForm> createState() => _JoinPaymentFormState();
}

class _JoinPaymentFormState extends State<JoinPaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String? _type;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final other = widget.options.isOther(_type);
    Navigator.pop(
      context,
      JoinPayment(
        type: _type!,
        amount: double.parse(_amount.text.replaceAll(',', '').trim()),
        note: other ? _note.text.trim() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.options;
    final other = options.isOther(_type);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderMid,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'What are you paying?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'The cashier sees this before you reach the window, so your '
                'receipt can be ready.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                key: const Key('payment-type'),
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Payment for',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final type in options.types)
                    DropdownMenuItem(value: type, child: Text(type)),
                ],
                onChanged: (value) => setState(() => _type = value),
                validator: (value) =>
                    value == null ? 'Choose what you are paying for.' : null,
              ),
              if (other) ...[
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('payment-note'),
                  controller: _note,
                  maxLength: options.noteMaxChars,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Which fees?',
                    hintText: 'e.g. ID replacement, library fine',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Write which fees you are paying.'
                      : null,
                ),
              ],
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('payment-amount'),
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Total amount',
                  prefixText: '₱ ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final amount = double.tryParse(
                    (value ?? '').replaceAll(',', '').trim(),
                  );
                  if (amount == null || amount <= 0) {
                    return 'Enter the total you will pay.';
                  }
                  if (amount > options.amountMax) {
                    return 'That is more than ${formatPeso(options.amountMax)}.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Join the Queue',
                bg: AppColors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                fontSize: 14,
                onTap: _submit,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
