import 'dart:async';
import 'dart:convert';
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
          await _localStorage.saveString('available_shops', jsonEncode(shopsJson));
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

        // Restore saved shops list — prefer localStorage (fast), else fetch fresh
        var shops = await _loadSavedShops();
        if (shops == null || shops.isEmpty) {
          shops = await _remoteDatasource.fetchMyShops();
          if (shops.isNotEmpty) {
            await _localStorage.saveString(
                'available_shops', jsonEncode(shops.map((s) => s.toJson()).toList()));
          }
        }

        // Enrich activeShop with shopName from shops list if missing
        var activeShop = result.shop;
        final allShops = shops.isEmpty ? (result.shops ?? []) : shops;
        if (activeShop != null && (activeShop.shopName == null || activeShop.shopName!.isEmpty)) {
          final match = allShops.firstWhere(
            (s) => s.id?.toString() == activeShop!.id?.toString(),
            orElse: () => activeShop!,
          );
          if (match.shopName != null && match.shopName!.isNotEmpty) {
            activeShop = Shop(
              id: activeShop.id,
              shopName: match.shopName,
              shopType: match.shopType ?? activeShop.shopType,
            );
            await _secureStorage.saveActiveShop(activeShop.toJson());
          }
        }

        return AuthResult(
          success: result.success,
          user: result.user,
          shop: activeShop,
          shops: allShops.isEmpty ? result.shops : allShops,
          token: result.token,
          roleId: result.roleId,
          message: result.message,
        );
      }

      // API returned a response but success=false — session is invalid on server.
      // Clear auth data and force re-login.
      await _secureStorage.clearAuthData();
      return AuthResult.failure('Session expired.');
    } catch (e) {
      // Network or server error — use cached data, keep token.
      final cachedUser = await _secureStorage.getUser();
      final cachedShop = await _secureStorage.getActiveShop();
      final shops = await _loadSavedShops();

      if (cachedUser != null) {
        return AuthResult(
          success: true,
          user: User.fromJson(cachedUser),
          shop: cachedShop != null ? Shop.fromJson(cachedShop) : null,
          shops: shops ?? [],
        );
      }

      // Token exists but cache is empty — trust the token.
      return const AuthResult(success: true);
    }
  }

  /// Load the shops list saved during login from localStorage.
  Future<List<Shop>?> _loadSavedShops() async {
    try {
      final raw = await _localStorage.getString('available_shops');
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => Shop.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<AuthConstants> getConstants() async {
    final response = await _remoteDatasource.getConstants();

    if (response.success && response.data != null) {
      return response.data!;
    }

    return const AuthConstants();
  }

  Future<AuthResult> addShop({
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

    final result = response.data ?? const AuthResult(success: true);

    // Save updated shops list returned by backend
    if (result.shops != null && result.shops!.isNotEmpty) {
      await _localStorage.saveString(
        'available_shops',
        jsonEncode(result.shops!.map((s) => s.toJson()).toList()),
      );
    }

    return result;
  }

  /// Switch the active shop on the server, then update local caches.
  /// Returns the new session data (user+shop+shops) so the controller can
  /// update its state without a second network round-trip.
  Future<AuthResult> switchShop(String shopId) async {
    final response = await _remoteDatasource.switchShop(shopId);

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to switch shop.');
    }

    final result = response.data!;

    // Save new token (backend generates one with new shop_id in JWT payload)
    if (result.token != null && result.token!.isNotEmpty) {
      await _secureStorage.saveToken(result.token!);
    }

    // Persist the new active shop
    if (result.shop != null) {
      await _secureStorage.saveActiveShop(result.shop!.toJson());
    }

    // Re-save shops list if the server returned them
    if (result.shops != null && result.shops!.isNotEmpty) {
      await _localStorage.saveString(
        'available_shops',
        jsonEncode(result.shops!.map((s) => s.toJson()).toList()),
      );
    }

    // Invalidate cached dashboard/session data so it is re-fetched for new shop
    await _cacheManager.invalidateAll(['active_shop', 'session_user', 'dashboard']);

    return result;
  }

  /// Fetch the current user's shops directly from the API.
  Future<List<Shop>> fetchMyShops() async {
    return _remoteDatasource.fetchMyShops();
  }

  Future<bool> isAuthenticated() async {
    return await _secureStorage.hasToken();
  }

  Future<String?> getToken() async {
    return await _secureStorage.getToken();
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
