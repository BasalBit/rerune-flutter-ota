import 'dart:convert';

class ReRuneManifest {
  const ReRuneManifest({required this.version, required this.locales});

  final int version;
  final Map<String, ReRuneManifestLocale> locales;

  factory ReRuneManifest.fromJson(Map<String, Object?> json) {
    final version = json['version'];
    if (version is! int) {
      throw const FormatException(
        'ReRuneManifest version is missing or invalid.',
      );
    }
    final localesJson = json['locales'];
    if (localesJson is! Map) {
      throw const FormatException(
        'ReRuneManifest locales are missing or invalid.',
      );
    }
    final locales = <String, ReRuneManifestLocale>{};
    for (final entry in localesJson.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || value is! Map) {
        continue;
      }
      locales[key] = ReRuneManifestLocale.fromJson(
        Map<String, Object?>.from(value),
      );
    }
    return ReRuneManifest(version: version, locales: locales);
  }

  Map<String, Object?> toJson() {
    return {
      'version': version,
      'locales': locales.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  static ReRuneManifest fromString(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('ReRuneManifest JSON must be an object.');
    }
    return ReRuneManifest.fromJson(decoded);
  }
}

class ReRuneManifestLocale {
  const ReRuneManifestLocale({required this.version, this.url, this.sha256});

  final int version;
  final Uri? url;
  final String? sha256;

  factory ReRuneManifestLocale.fromJson(Map<String, Object?> json) {
    final version = json['version'];
    if (version is! int) {
      throw const FormatException('ReRuneManifest locale entry is invalid.');
    }
    final urlValue = json['url'];
    Uri? url;
    if (urlValue is String && urlValue.isNotEmpty) {
      url = Uri.parse(urlValue);
    }
    final sha256 = json['sha256'];
    return ReRuneManifestLocale(
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

class ReRuneCachedManifest {
  const ReRuneCachedManifest({required this.manifest, this.etag});

  final ReRuneManifest manifest;
  final String? etag;

  factory ReRuneCachedManifest.fromJson(Map<String, Object?> json) {
    final manifestJson = json['manifest'];
    if (manifestJson is! Map<String, Object?>) {
      throw const FormatException('Cached manifest is invalid.');
    }
    return ReRuneCachedManifest(
      manifest: ReRuneManifest.fromJson(manifestJson),
      etag: json['etag'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {'manifest': manifest.toJson(), if (etag != null) 'etag': etag};
  }
}

class ReRuneCachedArb {
  const ReRuneCachedArb({required this.data, this.etag});

  final String data;
  final String? etag;
}
