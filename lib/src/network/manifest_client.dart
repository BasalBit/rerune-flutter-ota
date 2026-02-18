import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../model/manifest.dart';

class ManifestFetchResult {
  const ManifestFetchResult({
    this.manifest,
    this.etag,
    required this.notModified,
  });

  final ReRuneManifest? manifest;
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
      if (kDebugMode) {
        debugPrint('OtaLocalization: GET $url (manifest)');
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
          'OtaLocalization: manifest request headers ${_sanitizeHeaders(requestHeaders)}',
        );
      }
      final response = await client.get(url, headers: requestHeaders);
      if (kDebugMode) {
        debugPrint('OtaLocalization: manifest response ${response.statusCode}');
        debugPrint('OtaLocalization: manifest body start');
        debugPrint(response.body);
        debugPrint('OtaLocalization: manifest body end');
        if (response.headers.isNotEmpty) {
          debugPrint('OtaLocalization: manifest headers ${response.headers}');
        }
      }
      if (response.statusCode == 304) {
        return const ManifestFetchResult(notModified: true);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw http.ClientException(
          'ReRuneManifest request failed (${response.statusCode}).',
          url,
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('ReRuneManifest JSON must be an object.');
      }
      return ManifestFetchResult(
        manifest: ReRuneManifest.fromJson(decoded),
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
  if (sanitized.containsKey('X-OTA-Publish-Id')) {
    final value = sanitized['X-OTA-Publish-Id'];
    if (value != null && value.length > 6) {
      sanitized['X-OTA-Publish-Id'] =
          '${value.substring(0, 3)}***${value.substring(value.length - 3)}';
    } else {
      sanitized['X-OTA-Publish-Id'] = '***';
    }
  }
  return sanitized;
}
