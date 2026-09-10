import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/features/auth/data/models/auth_models.dart';
import 'package:dukaapp/features/auth/data/repositories/auth_repository.dart';
import 'package:dukaapp/core/providers.dart';

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

  AuthNotifier({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState());

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

    await _authRepository.clearLocalAuth();

    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> restoreSession() async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _authRepository.restoreSession();

    if (result.success) {
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
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository: repository);
});
