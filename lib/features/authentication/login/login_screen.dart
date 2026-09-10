import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/shared/widgets/auth_logo.dart';
import 'package:dukaapp/features/auth/presentation/controllers/auth_controller.dart';
import 'widgets/login_card.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final identifier = _userIdController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty) {
      _showSnackBar('Please enter your user ID, email, or phone.');
      return;
    }

    if (password.isEmpty) {
      _showSnackBar('Please enter your password.');
      return;
    }

    ref.read(authProvider.notifier).login(
      identifier: identifier,
      password: password,
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        if (next.successMessage != null && next.successMessage!.isNotEmpty) {
          _showSuccessSnackBar(next.successMessage!);
          ref.read(authProvider.notifier).clearSuccess();
        }
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (context.mounted) context.go('/dashboard');
        });
      } else if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        _showSnackBar(next.errorMessage!);
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: AppConstants.maxWidthMobile,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingXL.w,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 12.h),
                        _buildOnlineShopButton(),
                        SizedBox(height: 32.h),
                        _buildLogoSection(),
                        SizedBox(height: 32.h),
                        _buildLoginCard(authState.isLoading),
                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineShopButton() {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        margin: EdgeInsets.only(top: 4.h),
        child: Material(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppConstants.radiusFull),
            onTap: () {
              context.push('/storefront');
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 8.h,
              ),
              child: Text(
                'Online Shop',
                style: AppTypography.buttonSmall.copyWith(
                  color: AppColors.textWhite,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        const AuthLogo(size: 72),
        SizedBox(height: 12.h),
        _buildAppTitle(),
        SizedBox(height: 8.h),
        Text(
          'Sign in to continue managing your business',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAppTitle() {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Duka',
            style: AppTypography.h2.copyWith(
              color: AppColors.secondary,
            ),
          ),
          TextSpan(
            text: 'App',
            style: AppTypography.h2.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(bool isLoading) {
    return LoginCard(
      userIdController: _userIdController,
      passwordController: _passwordController,
      isPasswordVisible: _isPasswordVisible,
      isLoading: isLoading,
      onPasswordToggle: () {
        setState(() => _isPasswordVisible = !_isPasswordVisible);
      },
      onLogin: _handleLogin,
      onRegister: () => context.pushNamed('register'),
      onResetPassword: () => context.pushNamed('reset-password'),
    );
  }
}
