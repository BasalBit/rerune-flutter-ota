import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/manifest.dart';
import 'cache_store_base.dart';

class WebCacheStore extends ReRuneCacheStore {
  const WebCacheStore({this.prefix = 'ota_localizations'});

  final String prefix;

  String _manifestKey() => '${prefix}_manifest';
  String _arbKey(String localeKey) => '${prefix}_arb_$localeKey';
  String _etagKey(String localeKey) => '${prefix}_arb_etag_$localeKey';

  @override
  Future<ReRuneCachedManifest?> readManifest() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_manifestKey());
    if (value == null) {
      return null;
    }
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, Object?>) {
      return null;
    }
    return ReRuneCachedManifest.fromJson(decoded);
  }

  @override
  Future<void> writeManifest(ReRuneCachedManifest manifest) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_manifestKey(), jsonEncode(manifest.toJson()));
  }

  @override
  Future<ReRuneCachedArb?> readArb(String localeKey) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_arbKey(localeKey));
    if (data == null) {
      return null;
    }
    final etag = prefs.getString(_etagKey(localeKey));
    return ReRuneCachedArb(data: data, etag: etag);
  }

  @override
  Future<void> writeArb(String localeKey, ReRuneCachedArb arb) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_arbKey(localeKey), arb.data);
    if (arb.etag == null) {
      await prefs.remove(_etagKey(localeKey));
    } else {
      await prefs.setString(_etagKey(localeKey), arb.etag!);
    }
  }
}

ReRuneCacheStore createCacheStore() => const WebCacheStore();
