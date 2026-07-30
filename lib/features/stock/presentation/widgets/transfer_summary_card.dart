import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

class TransferSummaryCard extends StatelessWidget {
  final int productsSelected;
  final int totalQuantity;
  final String destinationShop;

  const TransferSummaryCard({
    super.key,
    required this.productsSelected,
    required this.totalQuantity,
    required this.destinationShop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStat(
            label: 'Products',
            value: '$productsSelected',
            icon: Icons.inventory_2_rounded,
          ),
          _buildDivider(),
          _buildStat(
            label: 'Total Qty',
            value: '$totalQuantity',
            icon: Icons.shopping_cart_rounded,
          ),
          _buildDivider(),
          _buildStat(
            label: 'Destination',
            value: destinationShop.isNotEmpty ? _shortName(destinationShop) : 'None',
            icon: Icons.storefront_rounded,
            isWide: true,
          ),
        ],
      ),
    );
  }

  String _shortName(String shop) {
    if (shop.length <= 12) return shop;
    return '${shop.substring(0, 10)}...';
  }

  Widget _buildStat({
    required String label,
    required String value,
    required IconData icon,
    bool isWide = false,
  }) {
    return Expanded(
      flex: isWide ? 2 : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.divider,
    );
  }
}
