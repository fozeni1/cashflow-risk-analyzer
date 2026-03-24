class Operation {
  final int id;
  final double amount;
  final int walletId;
  final String type;
  final String currency;
  final String? category;
  final DateTime createdAt;

  Operation({
    required this.id,
    required this.amount,
    required this.walletId,
    required this.type,
    required this.currency,
    this.category,
    required this.createdAt,
  });

  bool get isIncome => type.toLowerCase() == 'income';

  factory Operation.fromJson(Map<String, dynamic> json) {
    return Operation(
      id: json['id'] as int,
      amount: _toDouble(json['amount']),
      walletId: json['wallet_id'] as int,
      type: (json['type'] ?? '').toString(),
      currency: (json['currency'] ?? '').toString(),
      category: json['category']?.toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }
}
