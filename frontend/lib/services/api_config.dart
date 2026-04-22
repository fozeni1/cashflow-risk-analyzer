import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _apiBasePath = '/api/v1';
  static const String _baseUrlFromEnv = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    final rawBaseUrl = _baseUrlFromEnv.isNotEmpty
        ? _baseUrlFromEnv
        : switch (defaultTargetPlatform) {
            TargetPlatform.android => 'http://10.0.2.2:8000',
            _ when kIsWeb => 'http://localhost:8000',
            _ => 'http://127.0.0.1:8000',
          };

    final normalized = rawBaseUrl.endsWith('/')
        ? rawBaseUrl.substring(0, rawBaseUrl.length - 1)
        : rawBaseUrl;

    return '$normalized$_apiBasePath';
  }
}
