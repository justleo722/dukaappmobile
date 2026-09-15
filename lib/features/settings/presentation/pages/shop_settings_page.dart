import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

class ShopSettingsPage extends StatelessWidget {
  const ShopSettingsPage({super.key});

  final List<Map<String, dynamic>> _settingsOptions = const [
    {
      'icon': Icons.store_rounded,
      'title': 'Shop Details',
      'description': 'Manage shop name, contacts, address and branding.',
      'color': Color(0xFF2563EB),
    },
    {
      'icon': Icons.tune_rounded,
      'title': 'Custom Features',
      'description': 'Enable or disable optional business features.',
      'color': Color(0xFF14B8A6),
    },
    {
      'icon': Icons.backup_rounded,
      'title': 'Data Backup',
      'description': 'Backup, restore and secure your business data.',
      'color': Color(0xFFF59E0B),
    },
    {
      'icon': Icons.shopping_cart_rounded,
      'title': 'Online Store Settings',
      'description': 'Configure online selling, delivery and visibility.',
      'color': Color(0xFF22C55E),
    },
    {
      'icon': Icons.storage_rounded,
      'title': 'Storage',
      'description': 'Monitor storage usage, uploads and media files.',
      'color': Color(0xFF9333EA),
    },
    {
      'icon': Icons.delete_forever_rounded,
      'title': 'Delete Shop',
      'description': 'Permanently remove this shop and all related data.',
      'color': Color(0xFFEF4444),
    },
  ];

  void _onOptionTap(BuildContext context, String title) {
    switch (title) {
      case 'Shop Details':
        context.push('/shop-settings/details');
        break;
      case 'Custom Features':
        context.push('/shop-settings/custom-features');
        break;
      case 'Data Backup':
        context.push('/shop-settings/data-backup');
        break;
      case 'Online Store Settings':
        context.push('/online-shop/settings');
        break;
      case 'Storage':
        context.push('/shop-settings/storage');
        break;
      case 'Delete Shop':
        _showDeleteShopDialog(context);
        break;
    }
  }

  void _showDeleteShopDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        ),
        title: Text(
          'Delete Shop',
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to permanently delete this shop and all related data? This action cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
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
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusSM),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Cancel',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Shop deleted successfully'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusSM),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Delete',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
        ),
        leadingWidth: 56,
        title: Text(
          'Shop Settings',
          style: AppTypography.h6.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: _settingsOptions.length,
              itemBuilder: (context, index) {
                final option = _settingsOptions[index];
                return _SettingsPanel(
                  icon: option['icon'] as IconData,
                  title: option['title'] as String,
                  description: option['description'] as String,
                  color: option['color'] as Color,
                  onTap: () =>
                      _onOptionTap(context, option['title'] as String),
                );
              },
            ),
            SizedBox(height: 24 + bottomPadding),
          ],
        ),
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _SettingsPanel({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
