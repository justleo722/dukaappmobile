import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/auth/presentation/controllers/auth_controller.dart';

class RenewPage extends ConsumerWidget {
  const RenewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 1.5),
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
            child: IconButton(
              onPressed: () => context.go('/dashboard'),
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
            ),
          ),
        ),
        leadingWidth: 56,
        title: Text('Renew', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        centerTitle: true,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: SizedBox(height: 1)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Choose a subscription package',
            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Select the plan that best fits your business needs.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          isMobile
              ? Column(
                  children: [
                    _buildPackageCard(
                      name: 'Starter',
                      price: 'TZS 150,000',
                      period: 'per 12 months',
                      features: const [
                        'POS System',
                        'Online Shopping',
                        'Stock & Purchase Management',
                        'Sales, Order & Invoice Tracking',
                        'Customer & Staff Management',
                        'Profit & Expenses Management',
                        'Advanced Reports',
                      ],
                      isPopular: false,
                      onChoose: () => _onChoosePackage(context, ref, 'Starter', 'TZS 150,000'),
                    ),
                    const SizedBox(height: 16),
                    _buildPackageCard(
                      name: 'Business',
                      price: 'TZS 350,000',
                      period: 'per 12 months',
                      features: const [
                        'Product Manufacturing',
                        'POS System',
                        'Online Shopping',
                        'Stock & Purchase Management',
                        'Sales, Order & Invoice Tracking',
                        'Customer & Staff Management',
                        'Profit & Expenses Management',
                        'Advanced Reports',
                      ],
                      isPopular: true,
                      onChoose: () => _onChoosePackage(context, ref, 'Business', 'TZS 350,000'),
                    ),
                    const SizedBox(height: 16),
                    _buildPackageCard(
                      name: 'Enterprise',
                      price: 'TZS 600,000',
                      period: 'per 12 months',
                      features: const [
                        'Microfinance Management',
                        'Product Manufacturing',
                        'POS System',
                        'Online Shopping',
                        'Stock & Purchase Management',
                        'Sales, Order & Invoice Tracking',
                        'Customer & Staff Management',
                        'Profit & Expenses Management',
                        'Advanced Reports',
                      ],
                      isPopular: false,
                      onChoose: () => _onChoosePackage(context, ref, 'Enterprise', 'TZS 600,000'),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildPackageCard(
                        name: 'Starter',
                        price: 'TZS 150,000',
                        period: 'per 12 months',
                        features: const [
                          'POS System',
                          'Online Shopping',
                          'Stock & Purchase Management',
                          'Sales, Order & Invoice Tracking',
                          'Customer & Staff Management',
                          'Profit & Expenses Management',
                          'Advanced Reports',
                        ],
                        isPopular: false,
                        onChoose: () => _onChoosePackage(context, ref, 'Starter', 'TZS 150,000'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPackageCard(
                        name: 'Business',
                        price: 'TZS 350,000',
                        period: 'per 12 months',
                        features: const [
                          'Product Manufacturing',
                          'POS System',
                          'Online Shopping',
                          'Stock & Purchase Management',
                          'Sales, Order & Invoice Tracking',
                          'Customer & Staff Management',
                          'Profit & Expenses Management',
                          'Advanced Reports',
                        ],
                        isPopular: true,
                        onChoose: () => _onChoosePackage(context, ref, 'Business', 'TZS 350,000'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPackageCard(
                        name: 'Enterprise',
                        price: 'TZS 600,000',
                        period: 'per 12 months',
                        features: const [
                          'Microfinance Management',
                          'Product Manufacturing',
                          'POS System',
                          'Online Shopping',
                          'Stock & Purchase Management',
                          'Sales, Order & Invoice Tracking',
                          'Customer & Staff Management',
                          'Profit & Expenses Management',
                          'Advanced Reports',
                        ],
                        isPopular: false,
                        onChoose: () => _onChoosePackage(context, ref, 'Enterprise', 'TZS 600,000'),
                      ),
                    ),
                  ],
                ),
          SizedBox(height: 24 + bottomPadding),
        ],
      ),
    );
  }

  void _onChoosePackage(BuildContext context, WidgetRef ref, String packageName, String price) {
    // Read user's phone from auth state and convert to local format (0XXXXXXXXX)
    final rawPhone = ref.read(authProvider).user?.phone ?? '';
    String phone = rawPhone;
    if (phone.startsWith('+255')) {
      phone = '0${phone.substring(4)}';
    } else if (phone.startsWith('255') && phone.length > 3) {
      phone = '0${phone.substring(3)}';
    }
    final phoneController = TextEditingController(text: phone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
        title: Text('Complete Payment', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Package', style: AppTypography.caption.copyWith(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(packageName, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 10),
                    Text('Price', style: AppTypography.caption.copyWith(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(price, style: AppTypography.h5.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Payment Phone', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '07XX XXX XXX',
                  hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textHint),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM), borderSide: BorderSide(color: AppColors.textHint.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM), borderSide: const BorderSide(color: AppColors.primary)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.textHint),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Cancel', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Payment for $packageName initiated'), backgroundColor: AppColors.success),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Pay', style: AppTypography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard({
    required String name,
    required String price,
    required String period,
    required List<String> features,
    required bool isPopular,
    required VoidCallback onChoose,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: isPopular ? Border.all(color: AppColors.primary, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: isPopular ? AppColors.primary.withOpacity(0.15) : Colors.black.withOpacity(0.04),
            blurRadius: isPopular ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusMD)),
              ),
              child: Text(
                'Most Popular',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(name, style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text(price, style: AppTypography.h4.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary)),
                const SizedBox(height: 2),
                Text(period, style: AppTypography.bodySmall.copyWith(color: AppColors.textHint)),
                const SizedBox(height: 20),
                ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(f, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: AppConstants.buttonHeight,
                  child: ElevatedButton(
                    onPressed: onChoose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? AppColors.primary : AppColors.primary.withOpacity(0.1),
                      foregroundColor: isPopular ? Colors.white : AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Choose Package',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isPopular ? Colors.white : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
