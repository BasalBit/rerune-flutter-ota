import '../model/manifest.dart';
import 'cache_store_base.dart';

class UnsupportedCacheStore extends CacheStore {
  const UnsupportedCacheStore();

  @override
  Future<CachedManifest?> readManifest() async => null;

  @override
  Future<void> writeManifest(CachedManifest manifest) async {
    throw UnsupportedError('No cache store available for this platform.');
  }

  @override
  Future<CachedArb?> readArb(String localeKey) async => null;

  @override
  Future<void> writeArb(String localeKey, CachedArb arb) async {
    throw UnsupportedError('No cache store available for this platform.');
  }
}

CacheStore createCacheStore() => const UnsupportedCacheStore();
