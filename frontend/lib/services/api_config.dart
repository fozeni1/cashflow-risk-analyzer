
class ApiConfig {
  static const String _apiBasePath = '/api/v1';
  static const String _baseUrlFromEnv = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
  if (_baseUrlFromEnv.isEmpty) {
    throw Exception('API_BASE_URL is not set');
  }

  final normalized = _baseUrlFromEnv.endsWith('/')
      ? _baseUrlFromEnv.substring(0, _baseUrlFromEnv.length - 1)
      : _baseUrlFromEnv;

  return '$normalized$_apiBasePath';
}
}