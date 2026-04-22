import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/operation.dart';
import '../models/wallet.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'auth_service.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<double> getBalance() async {
    final response = await http.get(
      Uri.parse('$baseUrl/balance'),
      headers: await _headers(),
    );

    final data = _decodeResponse(response) as Map<String, dynamic>;
    return _parseDouble(data['total_balance']);
  }

  static Future<List<OperationModel>> getOperations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/operations'),
      headers: await _headers(),
    );

    final data = _decodeResponse(response) as List<dynamic>;
    return data
        .map((item) => OperationModel.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<List<WalletModel>> getWallets() async {
    final response = await http.get(
      Uri.parse('$baseUrl/wallets'),
      headers: await _headers(),
    );

    final data = _decodeResponse(response) as List<dynamic>;
    return data
        .map((item) => WalletModel.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  static Future<WalletModel> createWallet({
    required String name,
    double initialBalance = 0,
    String currency = 'rub',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wallets'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name.trim(),
        'initial_balance': initialBalance,
        'currency': currency.toLowerCase(),
      }),
    );

    final data = _decodeResponse(response) as Map<String, dynamic>;
    return WalletModel.fromJson(data);
  }

  static Future<OperationModel> addExpense({
    required String walletName,
    required double amount,
    String? description,
  }) {
    return _createOperation(
      type: 'expense',
      walletName: walletName,
      amount: amount,
      description: description,
    );
  }

  static Future<OperationModel> addIncome({
    required String walletName,
    required double amount,
    String? description,
  }) {
    return _createOperation(
      type: 'income',
      walletName: walletName,
      amount: amount,
      description: description,
    );
  }

  static Future<Map<String, double>?> getPrediction() async {
    final response = await http.get(
      Uri.parse('$baseUrl/predict'),
      headers: await _headers(),
    );

    if (response.statusCode == 503) {
      return null;
    }

    final data = _decodeResponse(response) as Map<String, dynamic>;
    return {
      'predicted_expense': _parseDouble(data['predicted_expense']),
      'predicted_balance': _parseDouble(data['predicted_balance']),
    };
  }

  static Future<OperationModel> _createOperation({
    required String type,
    required String walletName,
    required double amount,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/operations/$type'),
      headers: await _headers(),
      body: jsonEncode({
        'wallet_name': walletName.trim(),
        'amount': amount,
        'description':
            description?.trim().isEmpty ?? true ? null : description?.trim(),
      }),
    );

    final data = _decodeResponse(response) as Map<String, dynamic>;
    return OperationModel.fromJson(data);
  }

  static dynamic _decodeResponse(http.Response response) {
    final body = response.body.trim();
    final decoded = body.isEmpty ? null : jsonDecode(body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw ApiException(
      _extractErrorMessage(decoded) ??
          'Request failed with ${response.statusCode}',
      statusCode: response.statusCode,
    );
  }

  static String? _extractErrorMessage(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final detail = decoded['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
      if (detail is List) {
        return detail
            .map((item) => item is Map<String, dynamic>
                ? item['msg']?.toString() ?? item.toString()
                : item.toString())
            .join('\n');
      }
    }

    if (decoded is String && decoded.isNotEmpty) {
      return decoded;
    }

    return null;
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString()) ?? 0;
  }
}
