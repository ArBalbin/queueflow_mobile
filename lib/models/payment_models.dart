/// What a student can say they are paying for when they join, from the
/// server so the cashier office can change the list without a new app.
class PaymentOptions {
  final List<String> types;

  /// The type that asks the student to write which fees they are paying.
  final String otherType;
  final double amountMax;
  final int noteMaxChars;

  const PaymentOptions({
    required this.types,
    required this.otherType,
    required this.amountMax,
    required this.noteMaxChars,
  });

  /// Used when the list cannot be loaded; matches the server's default.
  static const fallback = PaymentOptions(
    types: ['Tuition fee', 'Enrollment fee', 'Balance', 'Other fees'],
    otherType: 'Other fees',
    amountMax: 1000000,
    noteMaxChars: 120,
  );

  factory PaymentOptions.fromJson(Map<String, dynamic> json) {
    final raw = json['payment_types'];
    final types = raw is List
        ? raw
              .map((t) => t.toString().trim())
              .where((t) => t.isNotEmpty)
              .toList()
        : <String>[];
    if (types.isEmpty) return fallback;
    final amountMax = json['amount_max'];
    final noteMax = json['note_max_chars'];
    return PaymentOptions(
      types: types,
      otherType: (json['other_type'] ?? fallback.otherType).toString(),
      amountMax: amountMax is num ? amountMax.toDouble() : fallback.amountMax,
      noteMaxChars: noteMax is num ? noteMax.toInt() : fallback.noteMaxChars,
    );
  }

  bool isOther(String? type) =>
      type != null && type.toLowerCase() == otherType.toLowerCase();
}

/// What the student filled in on the join form.
class JoinPayment {
  final String type;
  final double amount;

  /// Which fees, for the "other fees" type.
  final String? note;

  const JoinPayment({required this.type, required this.amount, this.note});

  Map<String, dynamic> toJson() => {
    'payment_type': type,
    'payment_amount': amount,
    if (note != null && note!.trim().isNotEmpty) 'payment_note': note!.trim(),
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
