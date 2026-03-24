abstract class SimpleHttpClient {
  Future<SimpleHttpResponse> get(
    String url, {
    Map<String, String>? headers,
  });

  Future<SimpleHttpResponse> post(
    String url, {
    Map<String, String>? headers,
    String? body,
  });
}

class SimpleHttpResponse {
  final int statusCode;
  final String body;

  const SimpleHttpResponse({
    required this.statusCode,
    required this.body,
  });
}
