import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import 'api_config.dart';
import 'api_exception.dart';

class AuthService {
  static const String _tokenKey = 'token';

  static String get baseUrl => ApiConfig.baseUrl;

  static Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username.trim(),
        'password': password,
      }),
    );

    final data = _decodeResponse(response) as Map<String, dynamic>;
    final token = data['access_token']?.toString();
    if (token == null || token.isEmpty) {
      throw const ApiException('Backend did not return an access token');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    return true;
  }

  static Future<bool> register(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username.trim(),
        'password': password,
      }),
    );

    _decodeResponse(response);
    return true;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<UserProfile> getCurrentUser() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw const ApiException('You are not logged in');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = _decodeResponse(response) as Map<String, dynamic>;
    return UserProfile.fromJson(data);
  }

  static Future<bool> checkAuth() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      await getCurrentUser();
      return true;
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      return false;
    }
  }

  static Future<void> logout() async {
    final token = await getToken();

    if (token != null && token.isNotEmpty) {
      try {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
      } catch (_) {
        // Local token cleanup still logs the user out of the app.
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
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
}
