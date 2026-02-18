import '../model/manifest.dart';

abstract class ReRuneCacheStore {
  const ReRuneCacheStore();

  Future<ReRuneCachedManifest?> readManifest();
  Future<void> writeManifest(ReRuneCachedManifest manifest);

  Future<ReRuneCachedArb?> readArb(String localeKey);
  Future<void> writeArb(String localeKey, ReRuneCachedArb arb);
}
