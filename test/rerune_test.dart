import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rerune/rerune.dart';
import 'package:rerune/src/network/arb_client.dart';
import 'package:rerune/src/network/manifest_client.dart';

void main() {
  test('manifest parses locales', () {
    final manifest = ReRuneManifest.fromJson({
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
    const policy = ReRuneUpdatePolicy();
    expect(policy.checkOnStart, isTrue);
    expect(policy.periodicInterval, isNull);
  });

  test('controller returns empty bundle when cache is empty', () {
    final controller = ReRuneLocalizationController(
      supportedLocales: const [Locale('en')],
    );

    final bundle = controller.bundleForLocale(const Locale('en'));
    expect(bundle, isEmpty);
  });

  test('controller falls back to bundled string when OTA is unavailable', () {
    final controller = ReRuneLocalizationController(
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
    final controller = ReRuneLocalizationController(
      supportedLocales: const [Locale('en')],
    );

    await expectLater(controller.checkForUpdates(), throwsA(isA<StateError>()));
  });

  test('controller falls back when manifest request fails', () async {
    final controller = ReRuneLocalizationController(
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

  test('fetched-only revision and event emit on applied update', () async {
    final controller = ReRuneLocalizationController(
      supportedLocales: const [Locale('en')],
      projectId: 'project',
      apiKey: 'key',
      cacheStore: _MemoryCacheStore(),
      manifestClient: _StubManifestClient(
        result: ManifestFetchResult(
          manifest: ReRuneManifest.fromJson({
            'version': 1,
            'locales': {
              'en': {'version': 1},
            },
          }),
          etag: 'manifest-v1',
          notModified: false,
        ),
      ),
      arbClient: _StubArbClient(
        result: const ArbFetchResult(
          data: '{"title":"Hello OTA"}',
          etag: 'arb-v1',
          notModified: false,
        ),
      ),
    );

    var fetchedRevisionChanges = 0;
    controller.reRuneFetchedRevisionListenable.addListener(() {
      fetchedRevisionChanges += 1;
    });
    final eventFuture = controller.onReRuneFetchedTextsApplied.first;

    final result = await controller.checkForUpdates();
    final event = await eventFuture;

    expect(result.hasUpdates, isTrue);
    expect(result.updatedLocales, const [Locale('en')]);
    expect(controller.revision, 1);
    expect(controller.reRuneFetchedRevision, 1);
    expect(fetchedRevisionChanges, 1);
    expect(event.revision, 1);
    expect(event.updatedLocales, const [Locale('en')]);
  });

  test(
    'fetched-only signal does not emit when manifest is unchanged',
    () async {
      final cacheStore = _MemoryCacheStore(
        manifest: ReRuneCachedManifest(
          manifest: ReRuneManifest.fromJson({
            'version': 1,
            'locales': {
              'en': {'version': 1},
            },
          }),
          etag: 'manifest-v1',
        ),
        arbs: {
          'en': const ReRuneCachedArb(
            data: '{"title":"Cached"}',
            etag: 'arb-v1',
          ),
        },
      );
      final controller = ReRuneLocalizationController(
        supportedLocales: const [Locale('en')],
        projectId: 'project',
        apiKey: 'key',
        cacheStore: cacheStore,
        manifestClient: _StubManifestClient(
          result: const ManifestFetchResult(notModified: true),
        ),
        arbClient: _StubArbClient(
          result: const ArbFetchResult(notModified: true),
        ),
      );

      var emitted = false;
      final sub = controller.onReRuneFetchedTextsApplied.listen((_) {
        emitted = true;
      });

      final result = await controller.checkForUpdates();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(result.hasUpdates, isFalse);
      expect(controller.reRuneFetchedRevision, 0);
      expect(emitted, isFalse);
    },
  );

  test('fetched-only signal does not emit on fetch errors', () async {
    final controller = ReRuneLocalizationController(
      supportedLocales: const [Locale('en')],
      projectId: 'project',
      apiKey: 'key',
      cacheStore: _MemoryCacheStore(),
      manifestClient: const _ThrowingManifestClient(),
    );

    var emitted = false;
    final sub = controller.onReRuneFetchedTextsApplied.listen((_) {
      emitted = true;
    });

    final result = await controller.checkForUpdates();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(result.hasErrors, isTrue);
    expect(result.hasUpdates, isFalse);
    expect(controller.reRuneFetchedRevision, 0);
    expect(emitted, isFalse);
  });

  test('initialize cache load does not change fetched-only revision', () async {
    final controller = ReRuneLocalizationController(
      supportedLocales: const [Locale('en')],
      projectId: 'project',
      apiKey: 'key',
      cacheStore: _MemoryCacheStore(
        arbs: {
          'en': const ReRuneCachedArb(
            data: '{"title":"Cached"}',
            etag: 'arb-v1',
          ),
        },
      ),
      updatePolicy: const ReRuneUpdatePolicy(checkOnStart: false),
    );

    var fetchedRevisionChanges = 0;
    controller.reRuneFetchedRevisionListenable.addListener(() {
      fetchedRevisionChanges += 1;
    });

    await controller.initialize();

    expect(controller.revision, 1);
    expect(controller.reRuneFetchedRevision, 0);
    expect(fetchedRevisionChanges, 0);
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

class _StubManifestClient extends ManifestClient {
  _StubManifestClient({this.result, this.error});

  final ManifestFetchResult? result;
  final Object? error;

  @override
  Future<ManifestFetchResult> fetch(
    Uri url, {
    String? etag,
    Map<String, String>? headers,
  }) async {
    if (error != null) {
      throw error!;
    }
    return result!;
  }
}

class _StubArbClient extends ArbClient {
  _StubArbClient({this.result, this.error});

  final ArbFetchResult? result;
  final Object? error;

  @override
  Future<ArbFetchResult> fetch(
    Uri url, {
    String? etag,
    Map<String, String>? headers,
  }) async {
    if (error != null) {
      throw error!;
    }
    return result!;
  }
}

class _MemoryCacheStore extends ReRuneCacheStore {
  _MemoryCacheStore({
    ReRuneCachedManifest? manifest,
    Map<String, ReRuneCachedArb>? arbs,
  }) : _manifest = manifest,
       _arbs = Map<String, ReRuneCachedArb>.from(arbs ?? const {});

  ReRuneCachedManifest? _manifest;
  final Map<String, ReRuneCachedArb> _arbs;

  @override
  Future<ReRuneCachedManifest?> readManifest() async => _manifest;

  @override
  Future<void> writeManifest(ReRuneCachedManifest manifest) async {
    _manifest = manifest;
  }

  @override
  Future<ReRuneCachedArb?> readArb(String localeKey) async => _arbs[localeKey];

  @override
  Future<void> writeArb(String localeKey, ReRuneCachedArb arb) async {
    _arbs[localeKey] = arb;
  }
}
