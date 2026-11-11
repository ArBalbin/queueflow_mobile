/// A line of the cashier's Payment Slip (NCF-F-CSH-09), e.g. "Tuition" or
/// "Special Exam", and the detail it asks for, if any ("Subject").
class PaymentLine {
  final String name;
  final String? detailPrompt;

  const PaymentLine(this.name, [this.detailPrompt]);
}

/// The slip's lines, from the server so the cashier office can change them
/// without a new app.
class PaymentOptions {
  final List<PaymentLine> lines;
  final double amountMax;
  final int detailMaxChars;

  const PaymentOptions({
    required this.lines,
    required this.amountMax,
    required this.detailMaxChars,
  });

  /// Used when the list cannot be loaded; the paper slip's own lines.
  static const fallback = PaymentOptions(
    lines: [
      PaymentLine('Tuition'),
      PaymentLine('Books'),
      PaymentLine('Special Exam', 'Subject'),
      PaymentLine('Others', 'Please specify'),
    ],
    amountMax: 1000000,
    detailMaxChars: 40,
  );

  factory PaymentOptions.fromJson(Map<String, dynamic> json) {
    final lines = <PaymentLine>[];
    final items = json['items'];
    if (items is List) {
      for (final item in items.whereType<Map>()) {
        final name = item['name']?.toString().trim() ?? '';
        if (name.isEmpty) continue;
        final prompt = item['detail_prompt']?.toString().trim();
        lines.add(PaymentLine(name, prompt == null || prompt.isEmpty ? null : prompt));
      }
    } else if (json['payment_types'] is List) {
      // A server from before the slip lines: one "other" type asks for detail.
      final other = json['other_type']?.toString().toLowerCase();
      for (final t in json['payment_types'] as List) {
        final name = t.toString().trim();
        if (name.isEmpty) continue;
        lines.add(PaymentLine(name, name.toLowerCase() == other ? 'Please specify' : null));
      }
    }
    if (lines.isEmpty) return fallback;
    final amountMax = json['amount_max'];
    final detailMax = json['detail_max_chars'];
    return PaymentOptions(
      lines: lines,
      amountMax: amountMax is num ? amountMax.toDouble() : fallback.amountMax,
      detailMaxChars: detailMax is num ? detailMax.toInt() : fallback.detailMaxChars,
    );
  }
}

/// One filled-in line of the slip.
class JoinPaymentItem {
  final String type;
  final double amount;
  final String? detail;

  const JoinPaymentItem({required this.type, required this.amount, this.detail});

  Map<String, dynamic> toJson() => {
    'type': type,
    'amount': amount,
    if (detail != null && detail!.trim().isNotEmpty) 'detail': detail!.trim(),
  };
}

/// What the student filled in on the join form: the slip's lines they pay.
class JoinPayment {
  final List<JoinPaymentItem> items;

  const JoinPayment(this.items);

  double get total => items.fold(0, (sum, item) => sum + item.amount);

  Map<String, dynamic> toJson() => {
    'payment_items': [for (final item in items) item.toJson()],
  };
}

/// "₱5,000.00"
String formatPeso(double amount) {
  final fixed = amount.toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '₱$whole.${parts[1]}';
}
