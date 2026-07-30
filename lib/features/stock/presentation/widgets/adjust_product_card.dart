import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/stock/presentation/widgets/quantity_stepper.dart';
import 'package:dukaapp/features/stock/presentation/widgets/stock_balance_badge.dart';
import 'package:dukaapp/features/stock/presentation/widgets/adjustment_status_dropdown.dart';

class AdjustProductCard extends StatelessWidget {
  final String productName;
  final int currentStock;
  final int adjustQuantity;
  final ValueChanged<int> onQuantityChanged;
  final AdjustmentStatus status;
  final ValueChanged<AdjustmentStatus?> onStatusChanged;

  const AdjustProductCard({
    super.key,
    required this.productName,
    required this.currentStock,
    required this.adjustQuantity,
    required this.onQuantityChanged,
    required this.status,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLG,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              _buildCurrentStock(),
              const SizedBox(height: 14),
              _buildQuantitySection(),
              const SizedBox(height: 14),
              AdjustmentStatusDropdown(
                status: status,
                onChanged: onStatusChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              productName.isNotEmpty
                  ? productName.substring(0, productName.length.clamp(0, 2)).toUpperCase()
                  : '??',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            productName,
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        StockBalanceBadge(stock: currentStock),
      ],
    );
  }

  Widget _buildCurrentStock() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.inventory_2_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Text(
            'Current Stock',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            '$currentStock Units',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySection() {
    return Row(
      children: [
        Text(
          'Adjust Quantity',
          style: AppTypography.captionBold.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        const Spacer(),
        QuantityStepper(
          value: adjustQuantity,
          onChanged: onQuantityChanged,
        ),
      ],
    );
  }
}
