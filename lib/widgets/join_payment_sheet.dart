import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/payment_models.dart';
import '../theme/app_theme.dart';
import 'shared_widgets.dart';

/// The cashier's Payment Slip as a form: pick the lines you are paying, enter
/// each amount, and see the TOTAL. Returns null if the student cancels.
Future<JoinPayment?> showJoinPaymentSheet(
  BuildContext context,
  PaymentOptions options,
) {
  return showModalBottomSheet<JoinPayment>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
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

class _LineState {
  bool selected = false;
  final amount = TextEditingController();
  final detail = TextEditingController();

  double? get value => double.tryParse(amount.text.replaceAll(',', '').trim());

  void dispose() {
    amount.dispose();
    detail.dispose();
  }
}

class _JoinPaymentFormState extends State<JoinPaymentForm> {
  final _formKey = GlobalKey<FormState>();
  late final List<_LineState> _lines = [
    for (final _ in widget.options.lines) _LineState(),
  ];
  bool _triedWithNothing = false;

  @override
  void dispose() {
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  double get _total => [
    for (final line in _lines)
      if (line.selected) line.value ?? 0,
  ].fold(0.0, (sum, v) => sum + v);

  bool get _anySelected => _lines.any((l) => l.selected);

  void _toggle(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _lines[index].selected = !_lines[index].selected;
      _triedWithNothing = false;
    });
  }

  void _submit() {
    if (!_anySelected) {
      setState(() => _triedWithNothing = true);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final items = <JoinPaymentItem>[
      for (var i = 0; i < _lines.length; i++)
        if (_lines[i].selected)
          JoinPaymentItem(
            type: widget.options.lines[i].name,
            amount: _lines[i].value!,
            detail: widget.options.lines[i].detailPrompt == null
                ? null
                : _lines[i].detail.text.trim(),
          ),
    ];
    Navigator.pop(context, JoinPayment(items));
  }

  String? _amountError(String? value) {
    final amount = double.tryParse((value ?? '').replaceAll(',', '').trim());
    if (amount == null || amount <= 0) return 'Enter the amount.';
    if (amount > widget.options.amountMax) {
      return 'That is more than ${formatPeso(widget.options.amountMax)}.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.options;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.borderMid,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('What are you paying?', style: AppText.title),
                    const SizedBox(height: 4),
                    Text(
                      'Same as the cashier\'s payment slip. Pick what you are paying '
                      'and enter each amount; the cashier sees it before you arrive.',
                      style: AppText.bodyMuted,
                    ),
                    const SizedBox(height: 18),
                    for (var i = 0; i < options.lines.length; i++) ...[
                      _LineCard(
                        key: Key('payment-line-${options.lines[i].name}'),
                        line: options.lines[i],
                        state: _lines[i],
                        maxDetail: options.detailMaxChars,
                        onToggle: () => _toggle(i),
                        onChanged: () => setState(() {}),
                        amountError: _amountError,
                      ),
                      const SizedBox(height: 10),
                    ],
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _triedWithNothing
                          ? const Padding(
                              key: ValueKey('nothing'),
                              padding: EdgeInsets.only(top: 2),
                              child: Text(
                                'Choose at least one thing you are paying for.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.redDark,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
            // The TOTAL stays in view while the keyboard is open.
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text('TOTAL', style: AppText.label),
                      const Spacer(),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: Text(
                          formatPeso(_total),
                          key: ValueKey(_total),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Request Number',
                    bg: AppColors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    fontSize: 15,
                    onTap: _submit,
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One line of the slip: tap to include it, then fill in its amount (and
/// its subject or description when the slip asks for one).
class _LineCard extends StatelessWidget {
  final PaymentLine line;
  final _LineState state;
  final int maxDetail;
  final VoidCallback onToggle;
  final VoidCallback onChanged;
  final String? Function(String?) amountError;

  const _LineCard({
    super.key,
    required this.line,
    required this.state,
    required this.maxDetail,
    required this.onToggle,
    required this.onChanged,
    required this.amountError,
  });

  @override
  Widget build(BuildContext context) {
    final selected = state.selected;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? AppColors.greenLight : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppColors.green : AppColors.border,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.green : AppColors.white,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: selected ? AppColors.green : AppColors.borderMid,
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded, size: 16, color: AppColors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(line.name, style: AppText.heading)),
                  if (selected && state.value != null && state.value! > 0)
                    Text(
                      formatPeso(state.value!),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green,
                      ),
                    ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: selected
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                      children: [
                        if (line.detailPrompt != null) ...[
                          TextFormField(
                            key: Key('payment-detail-${line.name}'),
                            controller: state.detail,
                            maxLength: maxDetail,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: _field(line.detailPrompt!),
                            validator: (value) => (value == null || value.trim().isEmpty)
                                ? 'Fill in the ${line.detailPrompt!.toLowerCase()}.'
                                : null,
                          ),
                          const SizedBox(height: 6),
                        ],
                        TextFormField(
                          key: Key('payment-amount-${line.name}'),
                          controller: state.amount,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                          ],
                          decoration: _field('Amount', prefix: '₱ '),
                          onChanged: (_) => onChanged(),
                          validator: amountError,
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  InputDecoration _field(String label, {String? prefix}) => InputDecoration(
    labelText: label,
    prefixText: prefix,
    filled: true,
    fillColor: AppColors.white,
    counterText: '',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
  );
}
