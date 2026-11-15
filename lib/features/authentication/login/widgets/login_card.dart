import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/shared/cards/app_card.dart';
import 'package:dukaapp/shared/textfields/app_text_field.dart';
import 'package:dukaapp/shared/buttons/primary_button.dart';

class LoginCard extends StatelessWidget {
  final bool isSwahili;

  /// Kiswahili for this card's text, used when the app language is Swahili.
  static const Map<String, String> _sw = {
    'Login': 'Ingia',
    'User ID, Email, Phone, or Attendant ID': 'User ID, Barua pepe, Simu, au Attendant ID',
    'Enter user ID, email, phone, or attendant ID': 'Andika user ID, barua pepe, simu au attendant ID',
    'Password': 'Nenosiri',
    'Enter your password': 'Andika nenosiri lako',
    'Reset Password': 'Badilisha nenosiri',
    'Register': 'Jisajili',
  };

  String t(String english) => isSwahili ? (_sw[english] ?? english) : english;

  final TextEditingController userIdController;
  final TextEditingController passwordController;
  final bool isPasswordVisible;
  final bool isLoading;
  final VoidCallback onPasswordToggle;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onResetPassword;

  const LoginCard({
    this.isSwahili = false,
    super.key,
    required this.userIdController,
    required this.passwordController,
    required this.isPasswordVisible,
    this.isLoading = false,
    required this.onPasswordToggle,
    required this.onLogin,
    required this.onRegister,
    required this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderRadius: 24,
      padding: EdgeInsets.symmetric(
        horizontal: 24.w,
        vertical: 28.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4.h),
          _buildUserIdField(),
          SizedBox(height: 16.h),
          _buildPasswordField(),
          SizedBox(height: 8.h),
          _buildResetPasswordLink(),
          SizedBox(height: 24.h),
          PrimaryButton(
            text: t('Login'),
            isLoading: isLoading,
            onPressed: onLogin,
          ),
          SizedBox(height: 20.h),
          _buildRegisterLink(),
        ],
      ),
    );
  }

  Widget _buildUserIdField() {
    return AppTextField(
      label: t('User ID, Email, Phone, or Attendant ID'),
      hintText: t('Enter user ID, email, phone, or attendant ID'),
      controller: userIdController,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      prefixIcon: Icons.person_outline,
    );
  }

  Widget _buildPasswordField() {
    return AppTextField(
      label: t('Password'),
      hintText: t('Enter your password'),
      controller: passwordController,
      obscureText: !isPasswordVisible,
      textInputAction: TextInputAction.done,
      prefixIcon: Icons.lock_outline,
      suffix: IconButton(
        onPressed: onPasswordToggle,
        icon: Icon(
          isPasswordVisible
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          size: 20.h,
          color: AppColors.textHint,
        ),
      ),
    );
  }

  Widget _buildResetPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: onResetPassword,
        child: Text(
          t('Reset Password'),
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Center(
      child: GestureDetector(
        onTap: onRegister,
        child: Text.rich(
          TextSpan(
            text: "Don't have an account? ",
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            children: [
              TextSpan(
                text: t('Register'),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
