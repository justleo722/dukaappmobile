import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/core/network/api_client.dart';
import 'package:dukaapp/core/storage/secure_storage_service.dart';
import 'package:dukaapp/core/storage/local_storage_service.dart';
import 'package:dukaapp/core/cache/cache_manager.dart';
import 'package:dukaapp/core/utils/connectivity_service.dart';
import 'package:dukaapp/core/services/api_service.dart';
import 'package:dukaapp/core/database/local_database.dart';
import 'package:dukaapp/core/database/database_service.dart';
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
