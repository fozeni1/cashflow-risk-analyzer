import 'dart:convert';

import '../models/dashboard_data.dart';
import '../models/operation.dart';
import '../models/wallet.dart';
import 'simple_http_client.dart';

class ApiService {
  ApiService({
    required String baseUrl,
  }) : _baseUrl = _normalizeBaseUrl(baseUrl);

  final String _baseUrl;
  final SimpleHttpClient _client = createSimpleHttpClient();

  Future<void> login(String login) async {
    await _get(
      '/users/me',
      login: login,
    );
  }

  Future<void> createUser(String login) async {
    await _post(
      '/users',
      body: {'login': login},
    );
  }

  Future<double> fetchBalance(String login) async {
    final response = await _get('/balance', login: login);
    return _toDouble(response['total_balance']);
  }

  Future<List<Wallet>> fetchWallets(String login) async {
    final response = await _get('/wallets', login: login) as List<dynamic>;
    return response
        .map((item) => Wallet.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Operation>> fetchOperations(String login) async {
    final response = await _get('/operations', login: login) as List<dynamic>;
    final operations = response
        .map((item) => Operation.fromJson(item as Map<String, dynamic>))
        .toList();
    operations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return operations;
  }

  Future<DashboardData> fetchDashboard(String login) async {
    final results = await Future.wait([
      fetchBalance(login),
      fetchWallets(login),
      fetchOperations(login),
    ]);

    return DashboardData(
      totalBalance: results[0] as double,
      wallets: results[1] as List<Wallet>,
      operations: results[2] as List<Operation>,
    );
  }

  Future<void> createWallet({
    required String login,
    required String name,
    required String currency,
    required String initialBalance,
  }) async {
    await _post(
      '/wallets',
      login: login,
      body: {
        'name': name,
        'initial_balance': initialBalance,
        'currency': currency,
      },
    );
  }

  Future<void> createOperation({
    required String login,
    required String walletName,
    required String type,
    required String amount,
    required String description,
  }) async {
    final normalizedType = type.toLowerCase();
    final path = normalizedType == 'expense'
        ? '/operations/expense'
        : '/operations/income';

    await _post(
      path,
      login: login,
      body: {
        'wallet_name': walletName,
        'amount': amount,
        'description': description.isEmpty ? null : description,
      },
    );
  }

  Future<dynamic> _get(
    String path, {
    String? login,
  }) async {
    final response = await _client.get(
      '$_baseUrl$path',
      headers: _headers(login),
    );
    return _decodeResponse(response);
  }

  Future<dynamic> _post(
    String path, {
    String? login,
    required Map<String, dynamic> body,
  }) async {
    final response = await _client.post(
      '$_baseUrl$path',
      headers: _headers(login),
      body: jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  Map<String, String> _headers(String? login) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (login != null && login.isNotEmpty) {
      headers['Authorization'] = 'Bearer $login';
    }

    return headers;
  }

  dynamic _decodeResponse(SimpleHttpResponse response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }

      return jsonDecode(response.body);
    }

    String message = 'Request failed with status ${response.statusCode}';
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
          message = decoded['detail'].toString();
        }
      } catch (_) {
        message = response.body;
      }
    }

    throw ApiException(message);
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim().replaceAll(RegExp(r'/+$'), '');
    if (trimmed.endsWith('/api/v1')) {
      return trimmed;
    }

    return '$trimmed/api/v1';
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }
}

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}
