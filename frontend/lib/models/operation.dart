class OperationModel {
  const OperationModel({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.createdAt,
    this.category,
    this.subcategory,
  });

  final int id;
  final int walletId;
  final String type;
  final double amount;
  final String currency;
  final DateTime createdAt;
  final String? category;
  final String? subcategory;

  bool get isExpense => type.toLowerCase() == 'expense';

  String get title {
    final trimmedCategory = category?.trim();
    if (trimmedCategory != null && trimmedCategory.isNotEmpty) {
      return trimmedCategory;
    }
    return isExpense ? 'Expense' : 'Income';
  }

  String get subtitle {
    final trimmedSubcategory = subcategory?.trim();
    if (trimmedSubcategory != null && trimmedSubcategory.isNotEmpty) {
      return trimmedSubcategory;
    }
    return 'Wallet #$walletId';
  }

  factory OperationModel.fromJson(Map<String, dynamic> json) {
    return OperationModel(
      id: json['id'] as int,
      walletId: json['wallet_id'] as int,
      type: (json['type'] ?? '').toString(),
      amount: _parseDouble(json['amount']),
      currency: (json['currency'] ?? 'rub').toString().toUpperCase(),
      category: json['category']?.toString(),
      subcategory: json['subcategory']?.toString(),
      createdAt: DateTime.parse(json['created_at'].toString()).toLocal(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString()) ?? 0;
  }
}
