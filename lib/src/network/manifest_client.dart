import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/manifest.dart';

class ManifestFetchResult {
  const ManifestFetchResult({
    this.manifest,
    this.etag,
    required this.notModified,
  });

  final Manifest? manifest;
  final String? etag;
  final bool notModified;
}

class ManifestClient {
  const ManifestClient({http.Client? httpClient}) : _httpClient = httpClient;

  final http.Client? _httpClient;

  Future<ManifestFetchResult> fetch(
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
        return const ManifestFetchResult(notModified: true);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw http.ClientException(
          'Manifest request failed (${response.statusCode}).',
          url,
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Manifest JSON must be an object.');
      }
      return ManifestFetchResult(
        manifest: Manifest.fromJson(decoded),
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
