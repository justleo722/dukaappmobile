import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/auth/presentation/controllers/auth_controller.dart';

class RenewPage extends ConsumerStatefulWidget {
  const RenewPage({super.key});

  @override
  ConsumerState<RenewPage> createState() => _RenewPageState();
}

class _RenewPageState extends ConsumerState<RenewPage> {
  List<Map<String, dynamic>> _packages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.postSubscriptionPackageList({});
      final data = result['data'];
      if (data is List) {
        setState(() {
          _packages = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _onChoosePackage(BuildContext context, Map<String, dynamic> pkg) {
    final rawPhone = ref.read(authProvider).user?.phone ?? '';
    String phone = rawPhone;
    if (phone.startsWith('+255')) {
      phone = '0${phone.substring(4)}';
    } else if (phone.startsWith('255') && phone.length > 3) {
      phone = '0${phone.substring(3)}';
    }
    final phoneController = TextEditingController(text: phone);
    bool isPaying = false;

    final packageName = pkg['package_name']?.toString() ?? '';
    final amount = pkg['amount']?.toString() ?? '';
    final packageId = pkg['package_id']?.toString() ?? '';
    final price = 'TZS ${_formatAmount(amount)}';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
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
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: '07XX XXX XXX',
                    counterText: '',
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
                    onPressed: isPaying ? null : () => Navigator.of(ctx).pop(),
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
                    onPressed: isPaying
                        ? null
                        : () async {
                            final phone = phoneController.text.trim();
                            if (phone.length < 10) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ingiza namba sahihi ya simu (tarakimu 10)'), backgroundColor: AppColors.danger),
                              );
                              return;
                            }
                            setModalState(() => isPaying = true);
                            try {
                              final api = ref.read(apiServiceProvider);
                              final result = await api.postSubscriptionPaymentComplete({
                                'package_id': packageId,
                                'phone': phone,
                              });
                              if (!context.mounted) return;
                              Navigator.of(ctx).pop();
                              final status = result['status']?.toString() ?? '';
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(result['message']?.toString() ?? (status == 'success' ? 'Malipo yameanzishwa' : 'Imeshindwa')),
                                backgroundColor: status == 'success' ? AppColors.success : AppColors.danger,
                              ));
                            } catch (e) {
                              if (!context.mounted) return;
                              setModalState(() => isPaying = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Hitilafu: $e'), backgroundColor: AppColors.danger),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: isPaying
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Pay', style: AppTypography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(String amount) {
    try {
      final n = double.parse(amount).toInt();
      final s = n.toString();
      final buffer = StringBuffer();
      int count = 0;
      for (int i = s.length - 1; i >= 0; i--) {
        if (count > 0 && count % 3 == 0) buffer.write(',');
        buffer.write(s[i]);
        count++;
      }
      return buffer.toString().split('').reversed.join();
    } catch (_) {
      return amount;
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _packages.isEmpty
              ? Center(child: Text('Hakuna packages zinazopatikana', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)))
              : ListView(
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
                              for (int i = 0; i < _packages.length; i++) ...[
                                if (i > 0) const SizedBox(height: 16),
                                _buildPackageCard(_packages[i]),
                              ],
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int i = 0; i < _packages.length; i++) ...[
                                if (i > 0) const SizedBox(width: 16),
                                Expanded(child: _buildPackageCard(_packages[i])),
                              ],
                            ],
                          ),
                    SizedBox(height: 24 + bottomPadding),
                  ],
                ),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> pkg) {
    final name = pkg['package_name']?.toString() ?? '';
    final amount = pkg['amount']?.toString() ?? '0';
    final duration = pkg['duration']?.toString() ?? '12';
    final badge = pkg['badge_label']?.toString() ?? '';
    final isPopular = badge.toLowerCase().contains('popular') || badge.toLowerCase().contains('most');
    final featuresRaw = pkg['features']?.toString() ?? '';
    final features = featuresRaw.isNotEmpty
        ? featuresRaw.split('\n').where((f) => f.trim().isNotEmpty).toList()
        : <String>[];
    final price = 'TZS ${_formatAmount(amount)}';
    final period = 'per $duration months';

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
                badge.isNotEmpty ? badge : 'Most Popular',
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
                      const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(f.trim(), style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: AppConstants.buttonHeight,
                  child: ElevatedButton(
                    onPressed: () => _onChoosePackage(context, pkg),
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
