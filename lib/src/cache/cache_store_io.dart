import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../model/manifest.dart';
import 'cache_store_base.dart';

class IoCacheStore extends CacheStore {
  const IoCacheStore({this.directoryName = 'ota_localizations'});

  final String directoryName;

  Future<Directory> _rootDir() async {
    final baseDir = await getApplicationSupportDirectory();
    final dir = Directory('${baseDir.path}/$directoryName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _manifestPath(Directory dir) => '${dir.path}/manifest.json';
  String _arbPath(Directory dir, String localeKey) =>
      '${dir.path}/locale_$localeKey.arb';
  String _etagPath(Directory dir, String localeKey) =>
      '${dir.path}/locale_$localeKey.etag';

  @override
  Future<CachedManifest?> readManifest() async {
    final dir = await _rootDir();
    final file = File(_manifestPath(dir));
    if (!await file.exists()) {
      return null;
    }
    final content = await file.readAsString();
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, Object?>) {
      return null;
    }
    return CachedManifest.fromJson(decoded);
  }

  @override
  Future<void> writeManifest(CachedManifest manifest) async {
    final dir = await _rootDir();
    final file = File(_manifestPath(dir));
    await file.writeAsString(jsonEncode(manifest.toJson()));
  }

  @override
  Future<CachedArb?> readArb(String localeKey) async {
    final dir = await _rootDir();
    final arbFile = File(_arbPath(dir, localeKey));
    if (!await arbFile.exists()) {
      return null;
    }
    final data = await arbFile.readAsString();
    final etagFile = File(_etagPath(dir, localeKey));
    final etag = await etagFile.exists() ? await etagFile.readAsString() : null;
    return CachedArb(data: data, etag: etag?.isEmpty == true ? null : etag);
  }

  @override
  Future<void> writeArb(String localeKey, CachedArb arb) async {
    final dir = await _rootDir();
    final arbFile = File(_arbPath(dir, localeKey));
    await arbFile.writeAsString(arb.data);
    final etagFile = File(_etagPath(dir, localeKey));
    if (arb.etag == null) {
      if (await etagFile.exists()) {
        await etagFile.delete();
      }
      return;
    }
    await etagFile.writeAsString(arb.etag!);
  }
}

CacheStore createCacheStore() => const IoCacheStore();
