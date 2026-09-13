import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/shared/widgets/auth_logo.dart';
import 'package:dukaapp/shared/widgets/step_indicator.dart';
import 'package:dukaapp/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dukaapp/features/auth/data/models/auth_models.dart';
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
  final _regionController = TextEditingController();
  String? _shopType;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToTerms = false;
  bool _showReferralCode = false;
  int _currentStep = 0;
  AuthConstants? _constants;

  static const _stepLabels = ['Account', 'Business', 'Security'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConstants();
    });
  }

  Future<void> _loadConstants() async {
    try {
      final constants = await ref.read(authProvider.notifier).getConstants();
      if (mounted) {
        setState(() {
          _constants = constants;
        });
      }
    } catch (_) {
      // Constants will remain null if fetch fails
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _shopNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralController.dispose();
    _regionController.dispose();
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
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final shopName = _shopNameController.text.trim();

    if (username.isEmpty) {
      _showSnackBar('Please enter your username.');
      return;
    }

    if (phone.isEmpty) {
      _showSnackBar('Please enter your phone number.');
      return;
    }

    if (password.isEmpty) {
      _showSnackBar('Please enter your password.');
      return;
    }

    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters.');
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match.');
      return;
    }

    if (shopName.isEmpty) {
      _showSnackBar('Please enter your shop name.');
      return;
    }

    if (_shopType == null) {
      _showSnackBar('Please select a shop type.');
      return;
    }

    final region = _regionController.text.trim();
    if (region.isEmpty) {
      _showSnackBar('Please enter your region.');
      return;
    }

    final lobId = _constants?.businessCategories.isNotEmpty == true
        ? _constants!.businessCategories.first.id
        : 1;

    ref.read(authProvider.notifier).register(
      username: username,
      email: email,
      phone: phone,
      password: password,
      country: 'Kenya',
      iso: '+254',
      region: region,
      shopName: shopName,
      shopType: _shopType!,
      lobId: lobId,
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
                      regionController: _regionController,
                      shopType: _shopType,
                      isPasswordVisible: _isPasswordVisible,
                      isConfirmPasswordVisible: _isConfirmPasswordVisible,
                      agreeToTerms: _agreeToTerms,
                      showReferralCode: _showReferralCode,
                      isLoading: authState.isLoading,
                      businessCategories: _constants?.businessCategories ?? [],
                      onShopTypeChanged: (value) {
                        setState(() => _shopType = value);
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
