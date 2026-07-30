import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/stock/presentation/widgets/quantity_stepper.dart';
import 'package:dukaapp/features/stock/presentation/widgets/price_input.dart';
import 'package:dukaapp/features/stock/presentation/widgets/expiry_picker.dart';

class PurchaseProductCard extends StatelessWidget {
  final String productName;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final TextEditingController buyingPriceController;
  final TextEditingController sellingPriceController;
  final TextEditingController wholesalePriceController;
  final DateTime? expiryDate;
  final ValueChanged<DateTime?> onExpiryChanged;
  final int currentStock;
  final VoidCallback? onDelete;

  const PurchaseProductCard({
    super.key,
    required this.productName,
    required this.quantity,
    required this.onQuantityChanged,
    required this.buyingPriceController,
    required this.sellingPriceController,
    required this.wholesalePriceController,
    this.expiryDate,
    required this.onExpiryChanged,
    required this.currentStock,
    this.onDelete,
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
              _buildQuantitySection(),
              const SizedBox(height: 14),
              _buildPriceFields(),
              const SizedBox(height: 14),
              ExpiryPicker(
                label: 'Expiry Date',
                selectedDate: expiryDate,
                onDateSelected: onExpiryChanged,
              ),
              const SizedBox(height: 12),
              _buildCurrentStockBadge(),
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
        if (onDelete != null)
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.danger,
              size: 22,
            ),
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  Widget _buildQuantitySection() {
    return Row(
      children: [
        Text(
          'Quantity',
          style: AppTypography.captionBold.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        const Spacer(),
        QuantityStepper(
          value: quantity,
          onChanged: onQuantityChanged,
        ),
      ],
    );
  }

  Widget _buildPriceFields() {
    return Column(
      children: [
        PriceInput(
          label: 'Buying Price',
          controller: buyingPriceController,
          hintText: 'Enter buying price',
        ),
        const SizedBox(height: 12),
        PriceInput(
          label: 'Selling Price',
          controller: sellingPriceController,
          hintText: 'Enter selling price',
        ),
        const SizedBox(height: 12),
        PriceInput(
          label: 'Wholesale Price',
          controller: wholesalePriceController,
          hintText: 'Enter wholesale price',
        ),
      ],
    );
  }

  Widget _buildCurrentStockBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_rounded,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            'Current Stock: $currentStock',
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
