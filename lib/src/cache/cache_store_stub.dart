import '../model/manifest.dart';
import 'cache_store_base.dart';

class UnsupportedCacheStore extends ReRuneCacheStore {
  const UnsupportedCacheStore();

  @override
  Future<ReRuneCachedManifest?> readManifest() async => null;

  @override
  Future<void> writeManifest(ReRuneCachedManifest manifest) async {
    throw UnsupportedError('No cache store available for this platform.');
  }

  @override
  Future<ReRuneCachedArb?> readArb(String localeKey) async => null;

  @override
  Future<void> writeArb(String localeKey, ReRuneCachedArb arb) async {
    throw UnsupportedError('No cache store available for this platform.');
  }
}

ReRuneCacheStore createCacheStore() => const UnsupportedCacheStore();
