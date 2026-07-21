import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/shared/cards/app_card.dart';
import 'package:dukaapp/shared/textfields/app_text_field.dart';
import 'package:dukaapp/shared/buttons/primary_button.dart';
import 'package:dukaapp/shared/buttons/outlined_button.dart';

class RegisterCard extends StatelessWidget {
  final int currentStep;
  final TextEditingController usernameController;
  final TextEditingController shopNameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController referralController;
  final String? shopType;
  final String? region;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;
  final bool agreeToTerms;
  final bool showReferralCode;
  final ValueChanged<String?> onShopTypeChanged;
  final ValueChanged<String?> onRegionChanged;
  final VoidCallback onPasswordToggle;
  final VoidCallback onConfirmPasswordToggle;
  final ValueChanged<bool?> onTermsChanged;
  final VoidCallback onTermsLinkTap;
  final VoidCallback onReferralTap;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback? onRegister;

  const RegisterCard({
    super.key,
    required this.currentStep,
    required this.usernameController,
    required this.shopNameController,
    required this.phoneController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.referralController,
    this.shopType,
    this.region,
    required this.isPasswordVisible,
    required this.isConfirmPasswordVisible,
    required this.agreeToTerms,
    required this.showReferralCode,
    required this.onShopTypeChanged,
    required this.onRegionChanged,
    required this.onPasswordToggle,
    required this.onConfirmPasswordToggle,
    required this.onTermsChanged,
    required this.onTermsLinkTap,
    required this.onReferralTap,
    required this.onNext,
    required this.onBack,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderRadius: 24,
      padding: EdgeInsets.symmetric(
        horizontal: 20.w,
        vertical: 28.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(),
          SizedBox(height: 24.h),
          _buildStepContent(),
          SizedBox(height: 24.h),
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildStepTitle() {
    switch (currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account Info', style: AppTypography.h5),
            SizedBox(height: 4.h),
            Text(
              'Set up your login credentials',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Business Details', style: AppTypography.h5),
            SizedBox(height: 4.h),
            Text(
              'Tell us about your business',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Security', style: AppTypography.h5),
            SizedBox(height: 4.h),
            Text(
              'Secure your account',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepContent() {
    switch (currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return const SizedBox.shrink();
    }
  }

  // Step 1: Account
  Widget _buildStep1() {
    return Column(
      children: [
        AppTextField(
          label: 'Username',
          hintText: 'Enter username',
          controller: usernameController,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.person_outline,
        ),
        SizedBox(height: 16.h),
        AppTextField(
          label: 'Phone Number',
          hintText: 'Enter phone number',
          controller: phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.phone_outlined,
        ),
        SizedBox(height: 16.h),
        AppTextField(
          label: 'Email',
          hintText: 'Enter email address',
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          prefixIcon: Icons.email_outlined,
        ),
      ],
    );
  }

  // Step 2: Business
  Widget _buildStep2() {
    return Column(
      children: [
        AppTextField(
          label: 'Shop Name',
          hintText: 'Enter shop name',
          controller: shopNameController,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.store_outlined,
        ),
        SizedBox(height: 16.h),
        _buildDropdown(
          label: 'Shop Type',
          value: shopType,
          hint: 'Select shop type',
          prefixIcon: Icons.category_outlined,
          items: const [
            DropdownMenuItem(value: 'retail', child: Text('Retail')),
            DropdownMenuItem(value: 'wholesale', child: Text('Wholesale')),
            DropdownMenuItem(value: 'online', child: Text('Online')),
            DropdownMenuItem(value: 'service', child: Text('Service')),
          ],
          onChanged: onShopTypeChanged,
        ),
        SizedBox(height: 16.h),
        _buildDropdown(
          label: 'Region',
          value: region,
          hint: 'Select region',
          prefixIcon: Icons.location_on_outlined,
          items: const [
            DropdownMenuItem(value: 'nairobi', child: Text('Nairobi')),
            DropdownMenuItem(value: 'mombasa', child: Text('Mombasa')),
            DropdownMenuItem(value: 'kisumu', child: Text('Kisumu')),
            DropdownMenuItem(value: 'nakuru', child: Text('Nakuru')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: onRegionChanged,
        ),
      ],
    );
  }

  // Step 3: Security
  Widget _buildStep3() {
    return Column(
      children: [
        AppTextField(
          label: 'Password',
          hintText: 'Create a password',
          controller: passwordController,
          obscureText: !isPasswordVisible,
          textInputAction: TextInputAction.next,
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
        ),
        SizedBox(height: 16.h),
        AppTextField(
          label: 'Confirm Password',
          hintText: 'Re-enter password',
          controller: confirmPasswordController,
          obscureText: !isConfirmPasswordVisible,
          textInputAction: TextInputAction.done,
          prefixIcon: Icons.lock_outline,
          suffix: IconButton(
            onPressed: onConfirmPasswordToggle,
            icon: Icon(
              isConfirmPasswordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20.h,
              color: AppColors.textHint,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        if (showReferralCode) ...[
          AppTextField(
            label: 'Referral Code',
            hintText: 'Enter referral code',
            controller: referralController,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.card_giftcard_outlined,
          ),
          SizedBox(height: 12.h),
        ],
        GestureDetector(
          onTap: onReferralTap,
          child: Text.rich(
            TextSpan(
              text: showReferralCode
                  ? 'Remove referral code? '
                  : 'Have a referral code? ',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              children: [
                TextSpan(
                  text: showReferralCode ? 'Remove' : 'Enter Code',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),
        _buildTermsCheckbox(),
      ],
    );
  }

  Widget _buildButtons() {
    final isLastStep = currentStep == 2;

    return Column(
      children: [
        if (!isLastStep)
          PrimaryButton(
            text: 'Next',
            onPressed: onNext,
          ),
        if (isLastStep)
          PrimaryButton(
            text: 'Register',
            onPressed: onRegister,
          ),
        if (currentStep > 0) ...[
          SizedBox(height: 12.h),
          OutlinedAppButton(
            text: 'Back',
            onPressed: onBack,
          ),
        ],
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required String hint,
    required IconData prefixIcon,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.label.copyWith(color: AppColors.textPrimary),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          height: AppConstants.buttonHeight.h,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Row(
                children: [
                  Icon(prefixIcon, size: 20.h, color: AppColors.textHint),
                  SizedBox(width: 12.w),
                  Text(
                    hint,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
              isExpanded: true,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20.h,
                color: AppColors.textHint,
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22.h,
          height: 22.h,
          child: Checkbox(
            value: agreeToTerms,
            onChanged: onTermsChanged,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'I accept the ',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              children: [
                TextSpan(
                  text: 'Terms & Conditions',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = onTermsLinkTap,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
