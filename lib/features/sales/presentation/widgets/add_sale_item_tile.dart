import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

class AddSaleItemTile extends StatelessWidget {
  final String name;
  final double sellingPrice;
  final int quantity;
  final int stock;
  final double discount;
  final bool isWholesale;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;
  final ValueChanged<double> onDiscountChanged;

  const AddSaleItemTile({
    super.key,
    required this.name,
    required this.sellingPrice,
    required this.quantity,
    required this.stock,
    required this.discount,
    required this.isWholesale,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.onDiscountChanged,
  });

  double get lineTotal => (sellingPrice * quantity) - discount;

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###');
    return 'Tsh ${formatter.format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isLowStock = stock <= 5;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMD),
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
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isWholesale)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'WH',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SP: ${_formatCurrency(sellingPrice)}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isLowStock
                            ? AppColors.warningLight
                            : AppColors.successLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$stock left',
                        style: AppTypography.caption.copyWith(
                          color: isLowStock
                              ? AppColors.warning
                              : AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.danger,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildQuantityButton(
                icon: Icons.remove_rounded,
                onTap: quantity > 1 ? () => onQuantityChanged(-1) : null,
              ),
              const SizedBox(width: 16),
              Container(
                width: 44,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$quantity',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildQuantityButton(
                icon: Icons.add_rounded,
                onTap: quantity < stock ? () => onQuantityChanged(1) : null,
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    _formatCurrency(lineTotal),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDiscountRow(context),
        ],
      ),
    );
  }

  Widget _buildDiscountRow(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDiscountDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: discount > 0
              ? AppColors.dangerLight.withValues(alpha: 0.5)
              : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: discount > 0
                ? AppColors.danger.withValues(alpha: 0.3)
                : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.discount_rounded,
              size: 14,
              color: discount > 0 ? AppColors.danger : AppColors.textHint,
            ),
            const SizedBox(width: 4),
            Text(
              discount > 0
                  ? 'Discount: ${_formatCurrency(discount)}'
                  : 'Apply Discount',
              style: AppTypography.caption.copyWith(
                color: discount > 0 ? AppColors.danger : AppColors.textHint,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
            if (discount > 0) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => onDiscountChanged(0),
                child: Icon(
                  Icons.close_rounded,
                  size: 12,
                  color: AppColors.danger.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDiscountDialog(BuildContext context) {
    final controller = TextEditingController(
      text: discount > 0 ? discount.toStringAsFixed(0) : '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        ),
        title: Text(
          'Item Discount',
          style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Line total: ${_formatCurrency(sellingPrice * quantity)}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: AppTypography.bodyMedium,
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: 'Enter discount amount',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textHint,
                ),
                prefixText: 'Tsh ',
                prefixStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                  borderSide: const BorderSide(
                    color: AppColors.inputFocusBorder,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text) ?? 0;
              final maxDiscount = sellingPrice * quantity;
              final clamped = value.clamp(0.0, maxDiscount);
              onDiscountChanged(clamped);
              Navigator.pop(context);
            },
            child: Text(
              'Apply',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final bool isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isEnabled
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.borderLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isEnabled ? AppColors.primary : AppColors.textHint,
          size: 18,
        ),
      ),
    );
  }
}
