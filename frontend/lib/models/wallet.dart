class Wallet {
  final int id;
  final String name;
  final double balance;
  final String currency;

  Wallet({
    required this.id,
    required this.name,
    required this.balance,
    required this.currency,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as int,
      name: (json['name'] ?? '').toString(),
      balance: _toDouble(json['balance']),
      currency: (json['currency'] ?? '').toString(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }
}
