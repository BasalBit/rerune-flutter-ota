import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../cache/cache_store.dart';
import '../delegate/ota_localizations_delegate.dart';
import '../model/manifest.dart';
import '../model/ota_error.dart';
import '../model/update_result.dart';
import '../network/arb_client.dart';
import '../network/manifest_client.dart';
import '../policy/update_policy.dart';
import '../utils/arb_utils.dart';
import '../utils/locale_utils.dart';

class OtaLocalizationController extends ChangeNotifier {
  OtaLocalizationController({
    Uri? manifestUrl,
    required this.baseUrl,
    required this.supportedLocales,
    CacheStore? cacheStore,
    OtaUpdatePolicy? updatePolicy,
    ManifestClient? manifestClient,
    ArbClient? arbClient,
    String? apiKey,
    String? projectId,
    String? platform,
    Map<Locale, Map<String, String>>? seedBundles,
  }) : _cacheStore = cacheStore ?? createDefaultCacheStore(),
       _updatePolicy = updatePolicy ?? const OtaUpdatePolicy(),
       _manifestClient = manifestClient ?? const ManifestClient(),
       _arbClient = arbClient ?? const ArbClient(),
       _apiKeyOverride = apiKey,
       _projectIdOverride = projectId,
       _platformOverride = platform,
       _manifestUrlOverride = manifestUrl,
       _seedBundles = seedBundles == null
           ? <Locale, Map<String, String>>{}
           : Map<Locale, Map<String, String>>.from(seedBundles);

  final Uri? baseUrl;
  final List<Locale> supportedLocales;

  final CacheStore _cacheStore;
  final OtaUpdatePolicy _updatePolicy;
  final ManifestClient _manifestClient;
  final ArbClient _arbClient;
  final String? _apiKeyOverride;
  final String? _projectIdOverride;
  final String? _platformOverride;
  final Uri? _manifestUrlOverride;
  final Map<Locale, Map<String, String>> _seedBundles;

  final Map<String, Map<String, String>> _bundles = {};
  CachedManifest? _cachedManifest;
  Timer? _timer;
  int _revision = 0;
  bool _configResolved = false;
  String? _apiKey;
  String? _projectId;
  String _platform = 'flutter';
  Uri? _manifestUrl;

  int get revision => _revision;

  Future<void> initialize() async {
    await _resolveConfig();
    await _loadCachedBundles();
    if (_updatePolicy.checkOnStart) {
      await checkForUpdates();
    }
    final interval = _updatePolicy.periodicInterval;
    if (interval != null) {
      _timer?.cancel();
      _timer = Timer.periodic(interval, (_) {
        checkForUpdates();
      });
    }
  }

  OtaLocalizationsDelegate buildDelegate() {
    return OtaLocalizationsDelegate(controller: this, revision: _revision);
  }

  Map<String, String> bundleForLocale(Locale locale) {
    final key = localeKey(locale);
    final bundle = _bundles[key];
    if (bundle != null) {
      return bundle;
    }
    final languageBundle = _bundles[locale.languageCode];
    if (languageBundle != null) {
      return languageBundle;
    }
    final seeded = _seedBundleForLocale(locale);
    if (seeded != null) {
      return seeded;
    }
    return const {};
  }

  Future<OtaUpdateResult> checkForUpdates() async {
    await _resolveConfig();
    final updated = <Locale>[];
    final skipped = <Locale>[];
    final errors = <OtaError>[];

    CachedManifest? cachedManifest;
    try {
      cachedManifest = _cachedManifest ?? await _cacheStore.readManifest();
    } catch (error, stackTrace) {
      errors.add(
        OtaError(
          type: OtaErrorType.storage,
          message: 'Failed to read cached manifest.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }

    if (_manifestUrl == null) {
      errors.add(
        const OtaError(
          type: OtaErrorType.invalidManifest,
          message: 'Manifest URL is missing. Provide baseUrl/project_id.',
        ),
      );
      return OtaUpdateResult(
        updatedLocales: updated,
        skippedLocales: skipped,
        errors: errors,
      );
    }

    Manifest? manifest = cachedManifest?.manifest;
    try {
      if (kDebugMode) {
        debugPrint(
          'OtaLocalization: config apiKey=${_apiKey != null} projectId=$_projectId platform=$_platform',
        );
      }
      final result = await _manifestClient
          .fetch(
            _manifestUrl!,
            etag: cachedManifest?.etag,
            headers: _authHeaders(),
          )
          .timeout(const Duration(seconds: 15));
      if (!result.notModified && result.manifest != null) {
        manifest = result.manifest;
        _cachedManifest = CachedManifest(
          manifest: result.manifest!,
          etag: result.etag,
        );
        await _cacheStore.writeManifest(_cachedManifest!);
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('OtaLocalization: manifest fetch failed: $error');
        debugPrint('$stackTrace');
      }
      errors.add(
        OtaError(
          type: OtaErrorType.network,
          message: 'Failed to fetch manifest.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }

    if (manifest == null) {
      return OtaUpdateResult(
        updatedLocales: updated,
        skippedLocales: skipped,
        errors: errors,
      );
    }

    for (final locale in supportedLocales) {
      final key = localeKey(locale);
      final entry = manifest.locales[key];
      if (entry == null) {
        skipped.add(locale);
        continue;
      }

      final previousVersion = cachedManifest?.manifest.locales[key]?.version;
      CachedArb? cachedArb;
      try {
        cachedArb = await _cacheStore.readArb(key);
      } catch (error, stackTrace) {
        errors.add(
          OtaError(
            type: OtaErrorType.storage,
            message: 'Failed to read cached ARB for $key.',
            cause: error,
            stackTrace: stackTrace,
          ),
        );
      }

      final shouldFetch =
          cachedArb == null ||
          previousVersion == null ||
          entry.version > previousVersion;

      if (!shouldFetch) {
        try {
          _bundles[key] = parseArb(cachedArb.data);
        } catch (error, stackTrace) {
          errors.add(
            OtaError(
              type: OtaErrorType.parse,
              message: 'Failed to parse cached ARB for $key.',
              cause: error,
              stackTrace: stackTrace,
            ),
          );
        }
        skipped.add(locale);
        continue;
      }

      try {
        final arbUrl = _resolveArbUrl(entry, key);
        if (arbUrl == null) {
          errors.add(
            OtaError(
              type: OtaErrorType.invalidManifest,
              message:
                  'No ARB URL for $key. Provide url in manifest or project_id.',
            ),
          );
          skipped.add(locale);
          continue;
        }
        if (kDebugMode) {
          debugPrint('OtaLocalization: resolved ARB URL $arbUrl');
        }
        final response = await _arbClient
            .fetch(arbUrl, etag: cachedArb?.etag, headers: _authHeaders())
            .timeout(const Duration(seconds: 15));
        if (response.notModified && cachedArb != null) {
          _bundles[key] = parseArb(cachedArb.data);
          skipped.add(locale);
          continue;
        }
        final data = response.data;
        if (data == null) {
          skipped.add(locale);
          continue;
        }
        if (entry.sha256 != null && !_matchesChecksum(data, entry.sha256!)) {
          errors.add(
            OtaError(
              type: OtaErrorType.checksum,
              message: 'Checksum mismatch for $key.',
            ),
          );
          skipped.add(locale);
          continue;
        }
        final parsed = parseArb(data);
        _bundles[key] = parsed;
        await _cacheStore.writeArb(
          key,
          CachedArb(data: data, etag: response.etag),
        );
        updated.add(locale);
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('OtaLocalization: ARB fetch failed for $key: $error');
          debugPrint('$stackTrace');
        }
        errors.add(
          OtaError(
            type: OtaErrorType.network,
            message: 'Failed to fetch ARB for $key.',
            cause: error,
            stackTrace: stackTrace,
          ),
        );
        skipped.add(locale);
      }
    }

    if (updated.isNotEmpty) {
      _revision += 1;
      notifyListeners();
    }

    return OtaUpdateResult(
      updatedLocales: updated,
      skippedLocales: skipped,
      errors: errors,
    );
  }

  Future<void> _loadCachedBundles() async {
    var loadedAny = false;
    for (final locale in supportedLocales) {
      final key = localeKey(locale);
      try {
        final cachedArb = await _cacheStore.readArb(key);
        if (cachedArb != null) {
          _bundles[key] = parseArb(cachedArb.data);
          loadedAny = true;
        } else {
          final seeded = _seedBundleForLocale(locale);
          if (seeded != null) {
            _bundles[key] = Map<String, String>.from(seeded);
            loadedAny = true;
          }
        }
      } catch (_) {
        final seeded = _seedBundleForLocale(locale);
        if (seeded != null) {
          _bundles[key] = Map<String, String>.from(seeded);
          loadedAny = true;
        }
      }
    }
    if (loadedAny) {
      _revision += 1;
      notifyListeners();
    }
  }

  Map<String, String>? _seedBundleForLocale(Locale locale) {
    final exact = _seedBundles[locale];
    if (exact != null) {
      return exact;
    }
    for (final entry in _seedBundles.entries) {
      if (entry.key.languageCode == locale.languageCode) {
        return entry.value;
      }
    }
    return null;
  }

  bool _matchesChecksum(String data, String expected) {
    final digest = sha256.convert(utf8.encode(data)).toString();
    return digest == expected;
  }

  Future<void> _resolveConfig() async {
    if (_configResolved) {
      return;
    }
    _configResolved = true;
    final config = await _loadConfigFromAsset();
    final apiKey = config?['api_key'];
    final projectId = config?['project_id'];
    final platform = config?['platform'];

    final apiKeyOverride = _apiKeyOverride;
    if (apiKeyOverride != null && apiKeyOverride.isNotEmpty) {
      _apiKey = apiKeyOverride;
    } else if (apiKey is String && apiKey.isNotEmpty) {
      _apiKey = apiKey;
    }

    final projectIdOverride = _projectIdOverride;
    if (projectIdOverride != null && projectIdOverride.isNotEmpty) {
      _projectId = projectIdOverride;
    } else if (projectId is String && projectId.isNotEmpty) {
      _projectId = projectId;
    }

    final platformOverride = _platformOverride;
    if (platformOverride != null && platformOverride.isNotEmpty) {
      _platform = platformOverride;
    } else if (platform is String && platform.isNotEmpty) {
      _platform = platform;
    }

    _resolveManifestUrl();

    await _loadSeedBundlesFromConfig(config);
  }

  Map<String, String>? _authHeaders() {
    final apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }
    return {'X-API-Key': apiKey};
  }

  Uri? _resolveArbUrl(ManifestLocale entry, String localeKey) {
    final url = entry.url;
    if (url != null) {
      if (url.isAbsolute) {
        return url;
      }
      final base = _manifestUrl ?? baseUrl;
      if (base == null) {
        return null;
      }
      return base.resolveUri(url);
    }
    final projectId = _projectId;
    if (projectId == null || projectId.isEmpty) {
      return null;
    }
    final path = '/sdk/projects/$projectId/translations/$_platform/$localeKey';
    final base = _manifestUrl ?? baseUrl;
    if (base == null) {
      return null;
    }
    return base.replace(path: path, query: null, fragment: null);
  }

  void _resolveManifestUrl() {
    if (_manifestUrlOverride != null) {
      _manifestUrl = _manifestUrlOverride;
      return;
    }
    final projectId = _projectId;
    final base = baseUrl;
    if (projectId == null || projectId.isEmpty || base == null) {
      return;
    }
    _manifestUrl = base.replace(
      path: '/sdk/projects/$projectId/translations/manifest',
      queryParameters: {'platform': _platform},
    );
  }

  Future<Map<String, Object?>?> _loadConfigFromAsset() async {
    try {
      final jsonString = await rootBundle.loadString('rerune.json');
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, Object?>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, Object?>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _loadSeedBundlesFromConfig(Map<String, Object?>? config) async {
    if (_seedBundles.isNotEmpty) {
      return;
    }
    final translationsPath = config?['translations_path'];
    if (translationsPath is! String || translationsPath.isEmpty) {
      return;
    }

    final codes = _languageCodesFromConfig(config?['languages']);
    final localeCodes = codes.isNotEmpty
        ? codes
        : supportedLocales.map(localeKey).toList(growable: false);

    final normalizedPath = translationsPath.endsWith('/')
        ? translationsPath
        : '$translationsPath/';

    for (final code in localeCodes) {
      final assetPath = '${normalizedPath}app_$code.arb';
      try {
        final data = await rootBundle.loadString(assetPath);
        final parsed = parseArb(data);
        _seedBundles[_matchSupportedLocale(code)] = parsed;
      } catch (_) {}
    }
  }

  List<String> _languageCodesFromConfig(Object? languages) {
    if (languages is! List) {
      return const [];
    }
    final codes = <String>[];
    for (final entry in languages) {
      if (entry is Map) {
        final code = entry['code'];
        if (code is String && code.isNotEmpty) {
          codes.add(code);
        }
      }
    }
    return codes;
  }

  Locale _matchSupportedLocale(String code) {
    for (final locale in supportedLocales) {
      if (localeKey(locale) == code || locale.languageCode == code) {
        return locale;
      }
    }
    return _localeFromCode(code);
  }

  Locale _localeFromCode(String code) {
    final normalized = code.replaceAll('-', '_');
    final parts = normalized.split('_');
    if (parts.length > 1) {
      return Locale(parts[0], parts[1]);
    }
    return Locale(parts.first);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
