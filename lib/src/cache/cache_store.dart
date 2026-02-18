export 'cache_store_base.dart';

import 'cache_store_stub.dart'
    if (dart.library.io) 'cache_store_io.dart'
    if (dart.library.html) 'cache_store_web.dart';

import 'cache_store_base.dart';

ReRuneCacheStore reRuneCreateDefaultCacheStore() => createCacheStore();
