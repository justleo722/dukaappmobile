import 'dart:async';
import 'package:dukaapp/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:dukaapp/features/auth/data/models/auth_models.dart';
import 'package:dukaapp/core/storage/secure_storage_service.dart';
import 'package:dukaapp/core/cache/cache_manager.dart';
import 'package:dukaapp/core/storage/local_storage_service.dart';
import 'package:dukaapp/core/network/api_exception.dart';

class AuthRepository {
  final AuthRemoteDatasource _remoteDatasource;
  final SecureStorageService _secureStorage;
  final CacheManager _cacheManager;
  final LocalStorageService _localStorage;

  AuthRepository({
    required AuthRemoteDatasource remoteDatasource,
    required SecureStorageService secureStorage,
    required CacheManager cacheManager,
    required LocalStorageService localStorage,
  })  : _remoteDatasource = remoteDatasource,
        _secureStorage = secureStorage,
        _cacheManager = cacheManager,
        _localStorage = localStorage;

  Future<AuthResult> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await _remoteDatasource.login(
        identifier: identifier,
        password: password,
      );

      if (response.success && response.data != null) {
        final result = response.data!;

        if (result.token != null) {
          await _secureStorage.saveToken(result.token!);
        }

        if (result.user != null) {
          await _secureStorage.saveUser(result.user!.toJson());
        }

        if (result.shop != null) {
          await _secureStorage.saveActiveShop(result.shop!.toJson());
        }

        if (result.shops != null) {
          final shopsJson = result.shops!.map((s) => s.toJson()).toList();
          await _localStorage.saveString('available_shops', shopsJson.toString());
        }

        return result;
      }

      return AuthResult.failure(
        response.message ?? 'Login failed. Please try again.',
      );
    } catch (e) {
      return AuthResult.failure(
        _getErrorMessage(e),
      );
    }
  }

  Future<AuthResult> register({
    required String username,
    required String email,
    required String phone,
    required String password,
    required String country,
    required String iso,
    required String region,
    required String shopName,
    required String shopType,
    required dynamic lobId,
    bool agreeToTerms = true,
  }) async {
    try {
      final response = await _remoteDatasource.register(
        username: username,
        email: email,
        phone: phone,
        password: password,
        country: country,
        iso: iso,
        region: region,
        shopName: shopName,
        shopType: shopType,
        lobId: lobId,
        agreeToTerms: agreeToTerms,
      );

      if (response.success && response.data != null) {
        final result = response.data!;

        if (result.token != null) {
          await _secureStorage.saveToken(result.token!);
        }

        if (result.user != null) {
          await _secureStorage.saveUser(result.user!.toJson());
        }

        if (result.shop != null) {
          await _secureStorage.saveActiveShop(result.shop!.toJson());
        }

        return result;
      }

      return AuthResult.failure(
        response.message ?? 'Registration failed. Please try again.',
      );
    } catch (e) {
      return AuthResult.failure(
        _getErrorMessage(e),
      );
    }
  }

  Future<void> sendPasswordReset({required String identifier}) async {
    try {
      final response = await _remoteDatasource.sendPasswordReset(
        identifier: identifier,
      );

      if (!response.success) {
        throw Exception(response.message ?? 'Failed to send reset code.');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _remoteDatasource.signOut();
    } catch (_) {}

    await clearLocalAuth();
  }

  Future<void> clearLocalAuth() async {
    await _secureStorage.clearAuthData();
    await _cacheManager.invalidateAll([
      'session_user',
      'active_shop',
      'permissions',
    ]);
  }

  Future<AuthResult> restoreSession() async {
    final token = await _secureStorage.getToken();

    if (token == null || token.isEmpty) {
      return AuthResult.failure('No session found.');
    }

    try {
      final response = await _remoteDatasource.validateSession();

      if (response.success && response.data != null) {
        final result = response.data!;

        if (result.user != null) {
          await _secureStorage.saveUser(result.user!.toJson());
        }

        if (result.shop != null) {
          await _secureStorage.saveActiveShop(result.shop!.toJson());
        }

        return result;
      }

      // API returned a response but success=false — session is invalid on server.
      // Clear auth data and force re-login.
      await _secureStorage.clearAuthData();
      return AuthResult.failure('Session expired.');
    } catch (e) {
      // Network or server error — use cached data, keep token.
      // If no cached user exists (e.g. old install before this fix), still mark
      // authenticated so the app can reach the dashboard and populate the cache.
      final cachedUser = await _secureStorage.getUser();
      final cachedShop = await _secureStorage.getActiveShop();

      if (cachedUser != null) {
        return AuthResult(
          success: true,
          user: User.fromJson(cachedUser),
          shop: cachedShop != null ? Shop.fromJson(cachedShop) : null,
        );
      }

      // Token exists but cache is empty (first run with old install / after fix).
      // Trust the token — dashboard will show real data from session_user.
      return const AuthResult(success: true);
    }
  }

  Future<AuthConstants> getConstants() async {
    final response = await _remoteDatasource.getConstants();

    if (response.success && response.data != null) {
      return response.data!;
    }

    return const AuthConstants();
  }

  Future<void> addShop({
    required String shopName,
    required String shopType,
    required dynamic lobId,
  }) async {
    final response = await _remoteDatasource.addShop(
      shopName: shopName,
      shopType: shopType,
      lobId: lobId,
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to add shop.');
    }
  }

  Future<void> switchShop(String shopId) async {
    final response = await _remoteDatasource.switchShop(shopId);

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to switch shop.');
    }

    await _cacheManager.invalidate('active_shop');
  }

  Future<bool> isAuthenticated() async {
    return await _secureStorage.hasToken();
  }

  String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      return error.friendlyMessage;
    }

    final msg = error.toString();

    if (msg.contains('SocketException') ||
        msg.contains('Connection refused') ||
        msg.contains('NetworkException')) {
      return 'Unable to connect to DukaApp. Please check your internet connection.';
    }

    if (msg.contains('TimeoutException') || msg.contains('timeout')) {
      return 'Connection timed out. Please check your internet connection.';
    }

    // TEMP: Show actual error to help debug — remove after fixing
    return msg;
  }
}
