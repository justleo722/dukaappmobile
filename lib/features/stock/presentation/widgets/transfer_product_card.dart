import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/stock/presentation/widgets/quantity_stepper.dart';
import 'package:dukaapp/features/stock/presentation/widgets/available_stock_badge.dart';

class TransferProductCard extends StatelessWidget {
  final String productName;
  final int availableStock;
  final int transferQuantity;
  final ValueChanged<int> onQuantityChanged;

  const TransferProductCard({
    super.key,
    required this.productName,
    required this.availableStock,
    required this.transferQuantity,
    required this.onQuantityChanged,
  });

  int get _remaining => availableStock - transferQuantity;

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
              _buildAvailableStock(),
              const SizedBox(height: 14),
              _buildQuantitySection(),
              const SizedBox(height: 14),
              _buildTransferSummary(),
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
        AvailableStockBadge(stock: availableStock),
      ],
    );
  }

  Widget _buildAvailableStock() {
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
            'Available Stock',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            '$availableStock Units',
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
          'Transfer Quantity',
          style: AppTypography.captionBold.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        const Spacer(),
        QuantityStepper(
          value: transferQuantity,
          maxValue: availableStock,
          onChanged: onQuantityChanged,
        ),
      ],
    );
  }

  Widget _buildTransferSummary() {
    return Row(
      children: [
        _buildChip('Available', '$availableStock', AppColors.primary),
        const SizedBox(width: 8),
        _buildChip('Transfer', '$transferQuantity', AppColors.secondary),
        const SizedBox(width: 8),
        _buildChip('Remaining', '$_remaining', _remaining < 0 ? AppColors.danger : AppColors.success),
      ],
    );
  }

  Widget _buildChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: color,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
