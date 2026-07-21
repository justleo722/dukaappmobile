import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/shared/widgets/auth_logo.dart';
import 'widgets/reset_password_card.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _identifierController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  void _handleSendCode() {
    // TODO: Implement reset code sending with provider — no API yet
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                    SizedBox(height: 60.h),
                    _buildHeader(),
                    SizedBox(height: 32.h),
                    ResetPasswordCard(
                      identifierController: _identifierController,
                      onSendCode: _handleSendCode,
                    ),
                    SizedBox(height: 24.h),
                    _buildBackToLogin(),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const AuthLogo(size: 72),
        SizedBox(height: 16.h),
        Text('Reset Password', style: AppTypography.h3),
        SizedBox(height: 8.h),
        Text(
          'Enter your email, phone number, or username\nto receive a reset code.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBackToLogin() {
    return GestureDetector(
      onTap: () => context.pushNamed('login'),
      child: Text.rich(
        TextSpan(
          text: 'Back to ',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          children: [
            TextSpan(
              text: 'Login',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
