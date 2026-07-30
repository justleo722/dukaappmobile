import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

class AdjustmentSummaryCard extends StatelessWidget {
  final int productsSelected;
  final int adjustedQuantity;
  final int adjustmentTypeCount;

  const AdjustmentSummaryCard({
    super.key,
    required this.productsSelected,
    required this.adjustedQuantity,
    required this.adjustmentTypeCount,
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
            label: 'Adjusted Qty',
            value: '$adjustedQuantity',
            icon: Icons.numbers_rounded,
          ),
          _buildDivider(),
          _buildStat(
            label: 'Types',
            value: '$adjustmentTypeCount',
            icon: Icons.category_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
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
