import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/online_shop/presentation/constants/online_shop_constants.dart';

class OnlineShopSidebar extends StatelessWidget {
  final String activeItem;
  final ValueChanged<String> onItemTap;

  const OnlineShopSidebar({
    super.key,
    required this.activeItem,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.78,
      backgroundColor: AppColors.card,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingSM),
                itemCount: OnlineShopConstants.sidebarMenuItems.length,
                itemBuilder: (context, index) {
                  final item = OnlineShopConstants.sidebarMenuItems[index];
                  final isActive = activeItem == item['label'];
                  return _SidebarMenuItem(
                    icon: item['icon'] as IconData,
                    label: item['label'] as String,
                    isActive: isActive,
                    onTap: () => onItemTap(item['label'] as String),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLG),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Color(0xFF14B8A6),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Online Shop',
                style: AppTypography.h6.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Management',
                style: AppTypography.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SidebarMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarMenuItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isActive
            ? const Color(0xFF14B8A6).withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMD,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive
                      ? const Color(0xFF14B8A6)
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isActive
                        ? const Color(0xFF14B8A6)
                        : AppColors.textPrimary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
