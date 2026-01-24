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
      final requestHeaders = <String, String>{
        if (etag != null) 'If-None-Match': etag,
        'Accept': 'application/json',
      };
      if (headers != null) {
        requestHeaders.addAll(headers);
      }
      final response = await client.get(url, headers: requestHeaders);
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
