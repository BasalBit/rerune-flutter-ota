import '../model/manifest.dart';

abstract class CacheStore {
  const CacheStore();

  Future<CachedManifest?> readManifest();
  Future<void> writeManifest(CachedManifest manifest);

  Future<CachedArb?> readArb(String localeKey);
  Future<void> writeArb(String localeKey, CachedArb arb);
}
