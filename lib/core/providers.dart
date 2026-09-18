import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/core/network/api_client.dart';
import 'package:dukaapp/core/storage/secure_storage_service.dart';
import 'package:dukaapp/core/storage/local_storage_service.dart';
import 'package:dukaapp/core/cache/cache_manager.dart';
import 'package:dukaapp/core/utils/connectivity_service.dart';
import 'package:dukaapp/core/services/api_service.dart';
import 'package:dukaapp/core/database/local_database.dart';
import 'package:dukaapp/core/database/database_service.dart';
import 'package:dukaapp/core/services/local_cache_service.dart';
import 'package:dukaapp/core/models/shop_config.dart';
import 'package:dukaapp/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:dukaapp/features/auth/data/repositories/auth_repository.dart';

/// Async provider that returns the active shop name from secure storage.
/// Falls back to empty string if not yet loaded.
/// Invalidate this after a shop switch so reports pick up the new name.
final shopNameProvider = FutureProvider<String>((ref) async {
  final secure = ref.watch(secureStorageProvider);
  final shop = await secure.getActiveShop();
  return shop?['shop_name']?.toString() ?? shop?['shopname']?.toString() ?? '';
});

final localStorageProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final cacheManagerProvider = Provider<CacheManager>((ref) {
  return CacheManager(localStorage: ref.watch(localStorageProvider));
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(secureStorage: ref.watch(secureStorageProvider));
  return client;
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(apiClientProvider));
});

/// The singleton LocalDatabase instance.
/// Features never open/close this directly — use [dbSessionProvider] instead.
final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  return LocalDatabase.instance;
});

/// DatabaseService for the current session (role+shop).
/// This is what feature datasources inject.
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService(ref.watch(localDatabaseProvider));
});

final localCacheProvider = Provider<LocalCacheService>((ref) {
  return LocalCacheService(ref.watch(databaseServiceProvider));
});

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(apiClient: ref.watch(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    remoteDatasource: ref.watch(authRemoteDatasourceProvider),
    secureStorage: ref.watch(secureStorageProvider),
    cacheManager: ref.watch(cacheManagerProvider),
    localStorage: ref.watch(localStorageProvider),
  );
});

/// Shop configuration fetched from API and cached in SharedPreferences.
/// Use [shopConfigProvider] to read. Call [refreshShopConfig] after saving settings.
final shopConfigProvider = AsyncNotifierProvider<ShopConfigNotifier, ShopConfig>(
  ShopConfigNotifier.new,
);

class ShopConfigNotifier extends AsyncNotifier<ShopConfig> {
  static const _cacheKey = 'shop_config_v1';
  static const _cacheTtl = Duration(hours: 6);

  @override
  Future<ShopConfig> build() async {
    // Return cached value immediately, then refresh in background.
    final localStorage = ref.read(localStorageProvider);
    final cached = await localStorage.getCachedValue(_cacheKey, ttl: _cacheTtl);
    if (cached != null) {
      try {
        final config = ShopConfig.fromJson(cached);
        // Refresh in background so cache stays fresh.
        _fetchAndCache().ignore();
        return config;
      } catch (_) {}
    }
    return _fetchAndCache();
  }

  Future<ShopConfig> _fetchAndCache() async {
    final api = ref.read(apiServiceProvider);
    final localStorage = ref.read(localStorageProvider);
    try {
      final res = await api.getSessionShop();
      final raw = res.data;
      Map<String, dynamic>? map;
      if (raw is Map<String, dynamic>) {
        map = raw['data'] is Map ? raw['data'] as Map<String, dynamic> : raw;
      } else if (raw is List && raw.isNotEmpty) {
        map = raw.first as Map<String, dynamic>;
      }
      if (map != null) {
        final config = ShopConfig.fromMap(map);
        await localStorage.cacheWithTTL(_cacheKey, config.toJson(), _cacheTtl);
        return config;
      }
    } catch (_) {}
    return ShopConfig.defaults;
  }

  /// Call this after saving shop settings to refresh the cached config.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchAndCache);
  }

  /// Invalidate cache (e.g. after shop switch).
  Future<void> invalidate() async {
    final localStorage = ref.read(localStorageProvider);
    await localStorage.removeCache(_cacheKey);
    ref.invalidateSelf();
  }
}
