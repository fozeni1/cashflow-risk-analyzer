class WalletModel {
  const WalletModel({
    required this.id,
    required this.name,
    required this.balance,
    required this.currency,
  });

  final int id;
  final String name;
  final double balance;
  final String currency;

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as int,
      name: (json['name'] ?? '').toString(),
      balance: _parseDouble(json['balance']),
      currency: (json['currency'] ?? 'rub').toString().toUpperCase(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString()) ?? 0;
  }
}
