import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/core/network/api_client.dart';
import 'package:dukaapp/core/storage/secure_storage_service.dart';
import 'package:dukaapp/core/storage/local_storage_service.dart';
import 'package:dukaapp/core/cache/cache_manager.dart';
import 'package:dukaapp/core/utils/connectivity_service.dart';
import 'package:dukaapp/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:dukaapp/features/auth/data/repositories/auth_repository.dart';

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
