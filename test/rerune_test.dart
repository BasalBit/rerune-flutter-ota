import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rerune/rerune.dart';
import 'package:rerune/src/network/manifest_client.dart';

void main() {
  test('manifest parses locales', () {
    final manifest = Manifest.fromJson({
      'version': 1,
      'locales': {
        'en': {'version': 2, 'url': 'https://example.com/en.arb'},
        'fr': {'version': 1, 'url': 'https://example.com/fr.arb'},
      },
    });

    expect(manifest.version, 1);
    expect(manifest.locales['en']?.version, 2);
    expect(
      manifest.locales['fr']?.url,
      Uri.parse('https://example.com/fr.arb'),
    );
  });

  test('update policy defaults', () {
    const policy = OtaUpdatePolicy();
    expect(policy.checkOnStart, isTrue);
    expect(policy.periodicInterval, isNull);
  });

  test('controller returns empty bundle when cache is empty', () {
    final controller = OtaLocalizationController(
      supportedLocales: const [Locale('en')],
    );

    final bundle = controller.bundleForLocale(const Locale('en'));
    expect(bundle, isEmpty);
  });

  test('controller falls back to bundled string when OTA is unavailable', () {
    final controller = OtaLocalizationController(
      supportedLocales: const [Locale('en')],
    );

    final resolved = controller.resolveText(
      const Locale('en'),
      key: 'hello',
      fallback: 'Hello fallback',
    );

    expect(resolved, 'Hello fallback');
  });

  test('controller throws when credentials are missing', () async {
    final controller = OtaLocalizationController(
      supportedLocales: const [Locale('en')],
    );

    await expectLater(controller.checkForUpdates(), throwsA(isA<StateError>()));
  });

  test('controller falls back when manifest request fails', () async {
    final controller = OtaLocalizationController(
      supportedLocales: const [Locale('en')],
      projectId: 'project',
      apiKey: 'key',
      manifestClient: const _ThrowingManifestClient(),
    );

    final result = await controller.checkForUpdates();
    expect(result.errors, isNotEmpty);

    final resolved = controller.resolveText(
      const Locale('en'),
      key: 'hello',
      fallback: 'Hello fallback',
    );

    expect(resolved, 'Hello fallback');
  });
}

class _ThrowingManifestClient extends ManifestClient {
  const _ThrowingManifestClient();

  @override
  Future<ManifestFetchResult> fetch(
    Uri url, {
    String? etag,
    Map<String, String>? headers,
  }) async {
    throw Exception('Network failure');
  }
}
