import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/message_format.dart';

import '../cache/cache_store.dart';
import '../model/manifest.dart';
import '../model/ota_error.dart';
import '../model/rerune_text_update_event.dart';
import '../model/update_result.dart';
import '../network/arb_client.dart';
import '../network/manifest_client.dart';
import '../policy/update_policy.dart';
import '../utils/arb_utils.dart';
import '../utils/locale_utils.dart';

class ReRuneLocalizationController extends ChangeNotifier {
  static final Uri _reruneApiBaseUrl = Uri.parse('https://rerune.io/api');

  ReRuneLocalizationController({
    Uri? manifestUrl,
    required this.supportedLocales,
    ReRuneCacheStore? cacheStore,
    ReRuneUpdatePolicy? updatePolicy,
    ManifestClient? manifestClient,
    ArbClient? arbClient,
    String? apiKey,
    String? projectId,
  }) : _cacheStore = cacheStore ?? reRuneCreateDefaultCacheStore(),
       _updatePolicy = updatePolicy ?? const ReRuneUpdatePolicy(),
       _manifestClient = manifestClient ?? const ManifestClient(),
       _arbClient = arbClient ?? const ArbClient(),
       _apiKeyOverride = apiKey,
       _projectIdOverride = projectId,
       _manifestUrlOverride = manifestUrl;

  final List<Locale> supportedLocales;

  final ReRuneCacheStore _cacheStore;
  final ReRuneUpdatePolicy _updatePolicy;
  final ManifestClient _manifestClient;
  final ArbClient _arbClient;
  final String? _apiKeyOverride;
  final String? _projectIdOverride;
  final Uri? _manifestUrlOverride;

  final Map<String, Map<String, String>> _bundles = {};
  ReRuneCachedManifest? _cachedManifest;
  Timer? _timer;
  int _revision = 0;
  int _fetchedRevision = 0;
  final ValueNotifier<int> _fetchedRevisionNotifier = ValueNotifier<int>(0);
  final StreamController<ReRuneTextUpdateEvent> _fetchedTextUpdates =
      StreamController<ReRuneTextUpdateEvent>.broadcast();
  bool _configResolved = false;
  String? _apiKey;
  String? _projectId;
  Uri? _manifestUrl;

  int get revision => _revision;
  int get reRuneFetchedRevision => _fetchedRevision;
  ValueListenable<int> get reRuneFetchedRevisionListenable =>
      _fetchedRevisionNotifier;
  Stream<ReRuneTextUpdateEvent> get onReRuneFetchedTextsApplied =>
      _fetchedTextUpdates.stream;

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

  Map<String, String> bundleForLocale(Locale locale) {
    for (final key in localeFallbackKeys(locale)) {
      final bundle = _bundles[key];
      if (bundle != null) {
        return bundle;
      }
    }
    return const {};
  }

  String? lookupRaw(Locale locale, String key) {
    final bundle = bundleForLocale(locale);
    return bundle[key];
  }

  String resolveText(
    Locale locale, {
    required String key,
    required String fallback,
    Map<String, Object?>? args,
  }) {
    final raw = lookupRaw(locale, key);
    if (raw == null) {
      return fallback;
    }
    if (args == null || args.isEmpty) {
      return raw;
    }
    try {
      final formatter = MessageFormat(raw, locale: locale.toString());
      return formatter.format(Map<String, Object>.from(args));
    } on FormatException {
      return fallback;
    }
  }

  Future<ReRuneUpdateResult> checkForUpdates() async {
    await _resolveConfig();
    final updated = <Locale>[];
    final skipped = <Locale>[];
    final errors = <ReRuneError>[];

    ReRuneCachedManifest? cachedManifest;
    try {
      cachedManifest = _cachedManifest ?? await _cacheStore.readManifest();
    } catch (error, stackTrace) {
      errors.add(
        ReRuneError(
          type: ReRuneErrorType.storage,
          message: 'Failed to read cached manifest.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }

    if (_manifestUrl == null) {
      errors.add(
        const ReRuneError(
          type: ReRuneErrorType.invalidManifest,
          message:
              'ReRuneManifest URL is missing. Provide projectId/apiKey in constructor or add rerune.json to assets.',
        ),
      );
      return ReRuneUpdateResult(
        updatedLocales: updated,
        skippedLocales: skipped,
        errors: errors,
      );
    }

    ReRuneManifest? manifest = cachedManifest?.manifest;
    try {
      if (kDebugMode) {
        debugPrint(
          'OtaLocalization: config apiKey=${_apiKey != null} projectId=$_projectId platform=flutter',
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
        _cachedManifest = ReRuneCachedManifest(
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
        ReRuneError(
          type: ReRuneErrorType.network,
          message: 'Failed to fetch manifest.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }

    if (manifest == null) {
      return ReRuneUpdateResult(
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
      ReRuneCachedArb? cachedArb;
      try {
        cachedArb = await _cacheStore.readArb(key);
      } catch (error, stackTrace) {
        errors.add(
          ReRuneError(
            type: ReRuneErrorType.storage,
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
            ReRuneError(
              type: ReRuneErrorType.parse,
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
            ReRuneError(
              type: ReRuneErrorType.invalidManifest,
              message:
                  'No ARB URL for $key. Provide a locale url in manifest or project_id.',
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
            ReRuneError(
              type: ReRuneErrorType.checksum,
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
          ReRuneCachedArb(data: data, etag: response.etag),
        );
        updated.add(locale);
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('OtaLocalization: ARB fetch failed for $key: $error');
          debugPrint('$stackTrace');
        }
        errors.add(
          ReRuneError(
            type: ReRuneErrorType.network,
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
      _fetchedRevision += 1;
      _fetchedRevisionNotifier.value = _fetchedRevision;
      _fetchedTextUpdates.add(
        ReRuneTextUpdateEvent(
          revision: _fetchedRevision,
          updatedLocales: List<Locale>.unmodifiable(updated),
        ),
      );
      notifyListeners();
    }

    return ReRuneUpdateResult(
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
        }
      } catch (_) {}
    }
    if (loadedAny) {
      _revision += 1;
      notifyListeners();
    }
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
    final assetApiKey = _optionalValue(_configString(config, 'api_key'));
    final assetProjectId = _optionalValue(_configString(config, 'project_id'));

    final apiKeyOverride = _optionalValue(_apiKeyOverride);
    final projectIdOverride = _optionalValue(_projectIdOverride);

    _apiKey = assetApiKey ?? apiKeyOverride;
    _projectId = assetProjectId ?? projectIdOverride;

    _resolveManifestUrl();
    _assertRequiredConfig();
  }

  void _assertRequiredConfig() {
    if (_apiKey != null && _projectId != null) {
      return;
    }

    const message =
        'Missing Rerune configuration. Provide `projectId` and `apiKey` '
        'in ReRuneLocalizationController, or add `rerune.json` to Flutter assets '
        'with `project_id` and `api_key`.';
    if (kDebugMode) {
      debugPrint('OtaLocalization: $message');
    }
    throw StateError(message);
  }

  Map<String, String>? _authHeaders() {
    final apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }
    return {'X-API-Key': apiKey};
  }

  Uri? _resolveArbUrl(ReRuneManifestLocale entry, String localeKey) {
    final url = entry.url;
    if (url != null) {
      if (url.isAbsolute) {
        return url;
      }
      final base = _manifestUrl ?? _reruneApiBaseUrl;
      return base.resolveUri(url);
    }
    final projectId = _projectId;
    if (projectId == null || projectId.isEmpty) {
      return null;
    }
    final path = '/api/sdk/projects/$projectId/translations/flutter/$localeKey';
    final base = _manifestUrl ?? _reruneApiBaseUrl;
    return base.replace(path: path, query: null, fragment: null);
  }

  void _resolveManifestUrl() {
    if (_manifestUrlOverride != null) {
      _manifestUrl = _manifestUrlOverride;
      return;
    }
    final projectId = _projectId;
    final base = _reruneApiBaseUrl;
    if (projectId == null || projectId.isEmpty) {
      return;
    }
    _manifestUrl = base.replace(
      path: '/api/sdk/projects/$projectId/translations/manifest',
      queryParameters: {'platform': 'flutter'},
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

  String? _configString(Map<String, Object?>? config, String key) {
    final value = config?[key];
    if (value is! String || value.isEmpty) {
      return null;
    }
    return value;
  }

  String? _optionalValue(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fetchedRevisionNotifier.dispose();
    _fetchedTextUpdates.close();
    super.dispose();
  }
}
