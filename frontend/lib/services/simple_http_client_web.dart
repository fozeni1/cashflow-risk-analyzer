// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

import 'simple_http_client_base.dart';

class WebSimpleHttpClient implements SimpleHttpClient {
  @override
  Future<SimpleHttpResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final response = await html.HttpRequest.request(
      url,
      method: 'GET',
      requestHeaders: headers,
    );

    return SimpleHttpResponse(
      statusCode: response.status ?? 0,
      body: response.responseText ?? '',
    );
  }

  @override
  Future<SimpleHttpResponse> post(
    String url, {
    Map<String, String>? headers,
    String? body,
  }) async {
    final response = await html.HttpRequest.request(
      url,
      method: 'POST',
      requestHeaders: headers,
      sendData: body,
    );

    return SimpleHttpResponse(
      statusCode: response.status ?? 0,
      body: response.responseText ?? '',
    );
  }
}

SimpleHttpClient createClient() => WebSimpleHttpClient();
