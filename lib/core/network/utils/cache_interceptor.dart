// import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
// import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
// import 'package:path_provider/path_provider.dart';

// class CacheInterceptor {
//   static Future<DioCacheInterceptor> buildCache() async {
//     final dir = await getTemporaryDirectory();
//     final store = HiveCacheStore(dir.path);

//     final options = CacheOptions(
//       store: store,
//       policy: CachePolicy.request, // Try cache first, then network
//       hitCacheOnErrorExcept: [401, 403],
//       maxStale: const Duration(days: 7),
//       priority: CachePriority.normal,
//       keyBuilder: (request) => request.uri.toString(),
//     );

//     return DioCacheInterceptor(options: options);
//   }
// }
