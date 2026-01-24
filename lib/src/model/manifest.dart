import 'dart:convert';

class Manifest {
  const Manifest({required this.version, required this.locales});

  final int version;
  final Map<String, ManifestLocale> locales;

  factory Manifest.fromJson(Map<String, Object?> json) {
    final version = json['version'];
    if (version is! int) {
      throw const FormatException('Manifest version is missing or invalid.');
    }
    final localesJson = json['locales'];
    if (localesJson is! Map) {
      throw const FormatException('Manifest locales are missing or invalid.');
    }
    final locales = <String, ManifestLocale>{};
    for (final entry in localesJson.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || value is! Map) {
        continue;
      }
      locales[key] = ManifestLocale.fromJson(Map<String, Object?>.from(value));
    }
    return Manifest(version: version, locales: locales);
  }

  Map<String, Object?> toJson() {
    return {
      'version': version,
      'locales': locales.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  static Manifest fromString(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Manifest JSON must be an object.');
    }
    return Manifest.fromJson(decoded);
  }
}

class ManifestLocale {
  const ManifestLocale({required this.version, this.url, this.sha256});

  final int version;
  final Uri? url;
  final String? sha256;

  factory ManifestLocale.fromJson(Map<String, Object?> json) {
    final version = json['version'];
    if (version is! int) {
      throw const FormatException('Manifest locale entry is invalid.');
    }
    final urlValue = json['url'];
    Uri? url;
    if (urlValue is String && urlValue.isNotEmpty) {
      url = Uri.parse(urlValue);
    }
    final sha256 = json['sha256'];
    return ManifestLocale(
      version: version,
      url: url,
      sha256: sha256 is String ? sha256 : null,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'version': version,
      if (url != null) 'url': url.toString(),
      if (sha256 != null) 'sha256': sha256,
    };
  }
}

class CachedManifest {
  const CachedManifest({required this.manifest, this.etag});

  final Manifest manifest;
  final String? etag;

  factory CachedManifest.fromJson(Map<String, Object?> json) {
    final manifestJson = json['manifest'];
    if (manifestJson is! Map<String, Object?>) {
      throw const FormatException('Cached manifest is invalid.');
    }
    return CachedManifest(
      manifest: Manifest.fromJson(manifestJson),
      etag: json['etag'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {'manifest': manifest.toJson(), if (etag != null) 'etag': etag};
  }
}

class CachedArb {
  const CachedArb({required this.data, this.etag});

  final String data;
  final String? etag;
}
