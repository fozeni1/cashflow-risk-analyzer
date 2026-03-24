import 'dart:convert';
import 'dart:io';

import 'simple_http_client_base.dart';

class IoSimpleHttpClient implements SimpleHttpClient {
  final HttpClient _client = HttpClient();

  @override
  Future<SimpleHttpResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final request = await _client.getUrl(Uri.parse(url));
    _setHeaders(request, headers);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    return SimpleHttpResponse(
      statusCode: response.statusCode,
      body: body,
    );
  }

  @override
  Future<SimpleHttpResponse> post(
    String url, {
    Map<String, String>? headers,
    String? body,
  }) async {
    final request = await _client.postUrl(Uri.parse(url));
    _setHeaders(request, headers);

    if (body != null) {
      request.add(utf8.encode(body));
    }

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    return SimpleHttpResponse(
      statusCode: response.statusCode,
      body: responseBody,
    );
  }

  void _setHeaders(
    HttpClientRequest request,
    Map<String, String>? headers,
  ) {
    if (headers == null) {
      return;
    }

    headers.forEach(request.headers.set);
  }
}

SimpleHttpClient createClient() => IoSimpleHttpClient();
