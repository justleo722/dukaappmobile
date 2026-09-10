import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/features/auth/data/models/auth_models.dart';
import 'package:dukaapp/features/auth/data/repositories/auth_repository.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/core/database/local_database.dart';

/// Decode a JWT and return its payload as a Map.
Map<String, dynamic> _jwtPayload(String token) {
  try {
    final parts = token.split('.');
    if (parts.length < 2) return {};
    // Base64Url decode (pad to multiple of 4)
    String payload = parts[1];
    payload += '=' * ((4 - payload.length % 4) % 4);
    return json.decode(utf8.decode(base64Url.decode(payload)))
        as Map<String, dynamic>;
  } catch (_) {
    return {};
  }
}

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final Shop? activeShop;
  final List<Shop>? shops;
  final String? errorMessage;
  final String? successMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.activeShop,
    this.shops,
    this.errorMessage,
    this.successMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    Shop? activeShop,
    List<Shop>? shops,
    String? errorMessage,
    String? successMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      activeShop: activeShop ?? this.activeShop,
      shops: shops ?? this.shops,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final LocalDatabase  _localDb;

  AuthNotifier({
    required AuthRepository authRepository,
    required LocalDatabase  localDb,
  })  : _authRepository = authRepository,
        _localDb        = localDb,
        super(const AuthState());

  /// Open the local DB for the given role+shop.
  /// Never throws — DB errors are non-fatal; app works online if DB fails.
  Future<void> _openDb({
    String? token,
    String? roleId,
    String? shopId,
  }) async {
    try {
      String? rid = roleId;
      String? sid = shopId;

      // Fall back to JWT payload when role/shop not provided
      if ((rid == null || sid == null) && token != null) {
        final payload = _jwtPayload(token);
        rid ??= payload['role_id']?.toString();
        sid ??= payload['shop_id']?.toString();
      }

      if (rid != null && sid != null) {
        await _localDb.open(rid, sid);
      }
    } catch (e) {
      // DB failure is non-fatal — app continues online-only
      debugPrint('[AuthNotifier] _openDb failed (non-fatal): $e');
    }
  }

  /// Close and wipe the local DB on logout.
  Future<void> _closeDb() async {
    try {
      if (_localDb.isOpen) {
        await _localDb.clearAll();
        await _localDb.close();
      }
    } catch (e) {
      debugPrint('[AuthNotifier] _closeDb failed (non-fatal): $e');
    }
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final result = await _authRepository.login(
      identifier: identifier,
      password: password,
    );

    if (result.success) {
      // Open unique DB for this role+shop — use JWT payload for role_id
      final token = await _authRepository.getToken();
      await _openDb(
        token : token,
        roleId: result.roleId,
        shopId: result.shop?.id?.toString(),
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        activeShop: result.shop,
        shops: result.shops,
        successMessage: 'Welcome back, ${result.user?.username ?? 'User'}!',
      );
      return true;
    } else {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: result.message,
      );
      return false;
    }
  }

  Future<bool> register({
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
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final result = await _authRepository.register(
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
      agreeToTerms: true,
    );

    if (result.success) {
      final token = await _authRepository.getToken();
      await _openDb(
        token : token,
        roleId: result.roleId,
        shopId: result.shop?.id?.toString(),
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        activeShop: result.shop,
        shops: result.shops,
        successMessage: 'Account created successfully! Welcome to DukaApp.',
      );
      return true;
    } else {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: result.message,
      );
      return false;
    }
  }

  Future<void> sendPasswordReset({required String identifier}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null, successMessage: null);

    try {
      await _authRepository.sendPasswordReset(identifier: identifier);
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        successMessage: 'Password reset code sent successfully. Please check your phone.',
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().contains('Exception')
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Failed to send reset code. Please try again.',
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      await _authRepository.signOut();
    } catch (_) {
      // Continue with local cleanup even if API call fails
    }

    await _closeDb();
    await _authRepository.clearLocalAuth();

    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> restoreSession() async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _authRepository.restoreSession();

    if (result.success) {
      // Re-open the DB for this session (token still valid from before)
      final token = await _authRepository.getToken();
      await _openDb(
        token : token,
        shopId: result.shop?.id?.toString(),
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        activeShop: result.shop,
        shops: result.shops,
      );
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Switch the active shop.
  /// Calls the backend, saves new session data, re-opens the local DB,
  /// and updates the state — all in one step.
  Future<void> switchShop(String shopId) async {
    // Call backend + update secureStorage/localStorage
    final result = await _authRepository.switchShop(shopId);

    // Re-open local DB for the new shop (role_id stays the same)
    final token = await _authRepository.getToken();
    await _openDb(token: token, shopId: shopId);

    // Prefer server-returned shop; fallback to finding it in the local list
    final newShop = result.shop ??
        state.shops?.firstWhere(
          (s) => s.id?.toString() == shopId || s.shopId?.toString() == shopId,
          orElse: () => Shop(id: shopId),
        );

    state = state.copyWith(
      activeShop: newShop,
      // Use updated shops list from server if provided
      shops: (result.shops != null && result.shops!.isNotEmpty)
          ? result.shops
          : state.shops,
    );
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void clearSuccess() {
    state = state.copyWith(successMessage: null);
  }

  Future<AuthConstants> getConstants() async {
    return await _authRepository.getConstants();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    authRepository: ref.watch(authRepositoryProvider),
    localDb       : ref.watch(localDatabaseProvider),
  );
});
