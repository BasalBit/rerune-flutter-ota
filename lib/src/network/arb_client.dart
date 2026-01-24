import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ArbFetchResult {
  const ArbFetchResult({this.data, this.etag, required this.notModified});

  final String? data;
  final String? etag;
  final bool notModified;
}

class ArbClient {
  const ArbClient({http.Client? httpClient}) : _httpClient = httpClient;

  final http.Client? _httpClient;

  Future<ArbFetchResult> fetch(
    Uri url, {
    String? etag,
    Map<String, String>? headers,
  }) async {
    final client = _httpClient ?? http.Client();
    try {
      if (kDebugMode) {
        debugPrint('OtaLocalization: GET $url (arb)');
      }
      final requestHeaders = <String, String>{
        if (etag != null) 'If-None-Match': etag,
        'Accept': 'application/json',
      };
      if (headers != null) {
        requestHeaders.addAll(headers);
      }
      if (kDebugMode) {
        debugPrint(
          'OtaLocalization: arb request headers ${_sanitizeHeaders(requestHeaders)}',
        );
      }
      final response = await client.get(url, headers: requestHeaders);
      if (kDebugMode) {
        debugPrint('OtaLocalization: arb response ${response.statusCode}');
        debugPrint('OtaLocalization: arb body start');
        debugPrint(response.body);
        debugPrint('OtaLocalization: arb body end');
        if (response.headers.isNotEmpty) {
          debugPrint('OtaLocalization: arb headers ${response.headers}');
        }
      }
      if (response.statusCode == 304) {
        return const ArbFetchResult(notModified: true);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw http.ClientException(
          'ARB request failed (${response.statusCode}).',
          url,
        );
      }
      return ArbFetchResult(
        data: response.body,
        etag: response.headers['etag'],
        notModified: false,
      );
    } finally {
      if (_httpClient == null) {
        client.close();
      }
    }
  }
}

Map<String, String> _sanitizeHeaders(Map<String, String> headers) {
  final sanitized = Map<String, String>.from(headers);
  if (sanitized.containsKey('X-API-Key')) {
    final value = sanitized['X-API-Key'];
    if (value != null && value.length > 6) {
      sanitized['X-API-Key'] =
          '${value.substring(0, 3)}***${value.substring(value.length - 3)}';
    } else {
      sanitized['X-API-Key'] = '***';
    }
  }
  return sanitized;
}
