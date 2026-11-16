import 'package:dukaapp/core/l10n/countries.dart';
import 'package:dukaapp/core/l10n/l10n_store.dart';
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
import 'package:dukaapp/features/auth/data/models/auth_models.dart';

class RegisterCard extends StatelessWidget {
  final int currentStep;
  final TextEditingController usernameController;
  final TextEditingController shopNameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController referralController;
  final TextEditingController regionController;
  final String? shopType;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;
  final bool agreeToTerms;
  final bool showReferralCode;
  final bool isLoading;
  final List<BusinessCategory> businessCategories;
  final ValueChanged<String?> onShopTypeChanged;
  final VoidCallback onPasswordToggle;
  final VoidCallback onConfirmPasswordToggle;
  final ValueChanged<bool?> onTermsChanged;
  final VoidCallback onTermsLinkTap;
  final VoidCallback onReferralTap;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback? onRegister;
  /// Country dial code of the phone number (e.g. '255').
  /// ISO code of the chosen country (its dial code goes before the phone number).
  final String countryIso;
  final ValueChanged<String>? onCountryChanged;
  /// Fills Region from the phone's location.
  final VoidCallback? onDetectRegion;
  final bool isDetectingRegion;
  final bool isSwahili;


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
    required this.regionController,
    this.shopType,
    required this.isPasswordVisible,
    required this.isConfirmPasswordVisible,
    required this.agreeToTerms,
    required this.showReferralCode,
    this.isLoading = false,
    this.businessCategories = const [],
    required this.onShopTypeChanged,
    required this.onPasswordToggle,
    required this.onConfirmPasswordToggle,
    required this.onTermsChanged,
    required this.onTermsLinkTap,
    required this.onReferralTap,
    required this.onNext,
    required this.onBack,
    required this.onRegister,
    this.countryIso = 'TZ',
    this.onCountryChanged,
    this.onDetectRegion,
    this.isDetectingRegion = false,
    this.isSwahili = false,
  });

  /// Kiswahili for this card's text, used when the app language is Swahili.
  static const Map<String, String> _sw = {
    'Business Details': 'Taarifa za biashara',
    'Tell us about your business': 'Tueleze kuhusu biashara yako',
    'Security': 'Usalama',
    'Secure your account': 'Linda akaunti yako',
    'Account Info': 'Taarifa za akaunti',
    'Set up your login credentials': 'Weka taarifa za kuingia',
    'Username': 'Jina la mtumiaji',
    'Enter username': 'Andika jina la mtumiaji',
    'Phone Number': 'Namba ya simu',
    'Enter phone number': 'Andika namba ya simu',
    'Email': 'Barua pepe',
    'Enter email address': 'Andika barua pepe',
    'Shop Name': 'Jina la duka',
    'Enter shop name': 'Andika jina la duka',
    'Shop Type': 'Aina ya duka',
    'Select shop type': 'Chagua aina ya duka',
    'Product & Services': 'Bidhaa na huduma',
    'Manufacturing': 'Uzalishaji',
    'Online Shop': 'Duka la mtandaoni',
    'Region': 'Mkoa',
    'Enter your region': 'Andika mkoa wako',
    'Password': 'Nenosiri',
    'Create a password': 'Tengeneza nenosiri',
    'Confirm Password': 'Thibitisha nenosiri',
    'Re-enter password': 'Rudia nenosiri',
    'Referral Code': 'Code ya rufaa',
    'Enter referral code': 'Andika code ya rufaa',
    'Remove referral code? ': 'Ondoa code ya rufaa? ',
    'Have a referral code? ': 'Una code ya rufaa? ',
    'Enter Code': 'Andika code',
    'Remove': 'Ondoa',
    'Next': 'Endelea',
    'Register': 'Jisajili',
    'Back': 'Rudi',
    'I accept the ': 'Nakubali ',
    'Terms & Conditions': 'Masharti na Vigezo',
    'Use my location': 'Tumia mahali nilipo',
    'Detecting location…': 'Inatafuta mahali ulipo…',
    'Country code': 'Code ya nchi',
    'Country': 'Nchi',
  };

  // Kiswahili from this card's map, other languages from the registry.
  String t(String english) => isSwahili ? (_sw[english] ?? english) : L10nStore.fromEnglish(english);


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
          _buildStepContent(context),
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
            Text(t('Account Info'), style: AppTypography.h5),
            SizedBox(height: 4.h),
            Text(
              t('Set up your login credentials'),
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
            Text(t('Business Details'), style: AppTypography.h5),
            SizedBox(height: 4.h),
            Text(
              t('Tell us about your business'),
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
            Text(t('Security'), style: AppTypography.h5),
            SizedBox(height: 4.h),
            Text(
              t('Secure your account'),
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

  Widget _buildStepContent(BuildContext context) {
    switch (currentStep) {
      case 0:
        return _buildStep1(context);
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return const SizedBox.shrink();
    }
  }

  // Step 1: Account
  Widget _buildStep1(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          label: t('Username'),
          hintText: t('Enter username'),
          controller: usernameController,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.person_outline,
        ),
        SizedBox(height: 16.h),
        _buildCountryField(context),
        SizedBox(height: 16.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              height: AppConstants.buttonHeight.h,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Text(
                '+${_country.dial}',
                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: AppTextField(
                label: t('Phone Number'),
                hintText: '712 345 678',
                controller: phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.phone_outlined,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        AppTextField(
          label: t('Email'),
          hintText: t('Enter email address'),
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
          label: t('Shop Name'),
          hintText: t('Enter shop name'),
          controller: shopNameController,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.store_outlined,
        ),
        SizedBox(height: 16.h),
        _buildDropdown(
          label: t('Shop Type'),
          value: shopType,
          hint: t('Select shop type'),
          prefixIcon: Icons.category_outlined,
          items: [
            DropdownMenuItem(value: 'product_services', child: Text(t('Product & Services'))),
            DropdownMenuItem(value: 'manufacturing', child: Text(t('Manufacturing'))),
            DropdownMenuItem(value: 'onlineshop', child: Text(t('Online Shop'))),
          ],
          onChanged: onShopTypeChanged,
        ),
        SizedBox(height: 16.h),
        AppTextField(
          label: t('Region'),
          hintText: t('Enter your region'),
          controller: regionController,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.location_on_outlined,
        ),
        if (onDetectRegion != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: isDetectingRegion ? null : onDetectRegion,
              icon: isDetectingRegion
                  ? SizedBox(width: 14.w, height: 14.w, child: const CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location_rounded, size: 16),
              label: Text(isDetectingRegion ? t('Detecting location…') : t('Use my location')),
            ),
          ),
      ],
    );
  }

  // Step 3: Security
  Widget _buildStep3() {
    return Column(
      children: [
        AppTextField(
          label: t('Password'),
          hintText: t('Create a password'),
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
          label: t('Confirm Password'),
          hintText: t('Re-enter password'),
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
            label: t('Referral Code'),
            hintText: t('Enter referral code'),
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
                  ? t('Remove referral code? ')
                  : t('Have a referral code? '),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              children: [
                TextSpan(
                  text: showReferralCode ? t('Remove') : t('Enter Code'),
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
            text: t('Next'),
            onPressed: onNext,
          ),
        if (isLastStep)
          PrimaryButton(
            text: t('Register'),
            isLoading: isLoading,
            onPressed: onRegister,
          ),
        if (currentStep > 0) ...[
          SizedBox(height: 12.h),
          OutlinedAppButton(
            text: t('Back'),
            onPressed: onBack,
          ),
        ],
      ],
    );
  }

  Country get _country => Country.byIso(countryIso) ?? Country.tanzania;

  /// Country field: tap to pick from every country (searchable).
  Widget _buildCountryField(BuildContext context) {
    final c = _country;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(t('Country'), style: AppTypography.label.copyWith(color: AppColors.textPrimary)),
        SizedBox(height: 8.h),
        InkWell(
          borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
          onTap: () => _pickCountry(context),
          child: Container(
            width: double.infinity,
            height: AppConstants.buttonHeight.h,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(children: [
              Text(c.flag, style: const TextStyle(fontSize: 18)),
              SizedBox(width: 10.w),
              Expanded(
                child: Text('${c.name} (+${c.dial})',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _pickCountry(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _CountryPicker(selected: countryIso, searchHint: t('Search...')),
    );
    if (picked != null) onCountryChanged?.call(picked);
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
              text: t('I accept the '),
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              children: [
                TextSpan(
                  text: t('Terms & Conditions'),
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


/// Bottom sheet with every country and a search box.
class _CountryPicker extends StatefulWidget {
  final String selected;
  final String searchHint;
  const _CountryPicker({required this.selected, required this.searchHint});

  @override
  State<_CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<_CountryPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.toLowerCase().replaceAll('+', '').trim();
    final list = Country.all
        .where((c) => q.isEmpty || c.name.toLowerCase().contains(q) || c.dial.startsWith(q) || c.iso.toLowerCase() == q)
        .toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final c = list[i];
                  final sel = c.iso == widget.selected;
                  return ListTile(
                    leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                    title: Text(c.name, style: TextStyle(fontWeight: sel ? FontWeight.w700 : FontWeight.normal)),
                    trailing: Text('+${c.dial}', style: const TextStyle(color: AppColors.textSecondary)),
                    selected: sel,
                    onTap: () => Navigator.of(context).pop(c.iso),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
