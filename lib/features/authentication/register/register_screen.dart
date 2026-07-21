import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/shared/widgets/auth_logo.dart';
import 'package:dukaapp/shared/widgets/step_indicator.dart';
import 'widgets/register_card.dart';
import 'widgets/terms_and_conditions_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralController = TextEditingController();
  String? _shopType;
  String? _region;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToTerms = false;
  bool _showReferralCode = false;
  int _currentStep = 0;

  static const _stepLabels = ['Account', 'Business', 'Security'];

  @override
  void dispose() {
    _usernameController.dispose();
    _shopNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _handleRegister() {
    // TODO: Implement register with provider — no API yet
    context.pushNamed('dashboard');
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
                    SizedBox(height: 24.h),
                    _buildHeader(),
                    SizedBox(height: 20.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: StepIndicator(
                        currentStep: _currentStep,
                        totalSteps: 3,
                        labels: _stepLabels,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    RegisterCard(
                      currentStep: _currentStep,
                      usernameController: _usernameController,
                      shopNameController: _shopNameController,
                      phoneController: _phoneController,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                      referralController: _referralController,
                      shopType: _shopType,
                      region: _region,
                      isPasswordVisible: _isPasswordVisible,
                      isConfirmPasswordVisible: _isConfirmPasswordVisible,
                      agreeToTerms: _agreeToTerms,
                      showReferralCode: _showReferralCode,
                      onShopTypeChanged: (value) {
                        setState(() => _shopType = value);
                      },
                      onRegionChanged: (value) {
                        setState(() => _region = value);
                      },
                      onPasswordToggle: () {
                        setState(() => _isPasswordVisible = !_isPasswordVisible);
                      },
                      onConfirmPasswordToggle: () {
                        setState(() =>
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                      },
                      onTermsChanged: (value) {
                        setState(() => _agreeToTerms = value ?? false);
                      },
                      onTermsLinkTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TermsAndConditionsScreen(
                              onAccept: () {
                                Navigator.of(context).pop();
                                setState(() => _agreeToTerms = true);
                              },
                            ),
                          ),
                        );
                      },
                      onReferralTap: () {
                        setState(() => _showReferralCode = !_showReferralCode);
                      },
                      onNext: _nextStep,
                      onBack: _previousStep,
                      onRegister: _agreeToTerms ? _handleRegister : null,
                    ),
                    SizedBox(height: 24.h),
                    _buildLoginLink(),
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
        const AuthLogo(size: 64),
        SizedBox(height: 12.h),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Duka',
                style: AppTypography.h3.copyWith(
                  color: AppColors.secondary,
                ),
              ),
              TextSpan(
                text: 'App',
                style: AppTypography.h3.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Create your business account',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () => context.pushNamed('login'),
          child: Text(
            'Login',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
