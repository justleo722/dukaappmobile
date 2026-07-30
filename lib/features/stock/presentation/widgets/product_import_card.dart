import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/stock/presentation/widgets/price_chip.dart';
import 'package:dukaapp/features/stock/presentation/widgets/stock_badge.dart';

class ProductImportCard extends StatelessWidget {
  final String productName;
  final String barcode;
  final double buyingPrice;
  final double sellingPrice;
  final double wholesalePrice;
  final int stock;
  final bool isSelected;
  final VoidCallback? onTap;
  final ValueChanged<bool?>? onSelectionChanged;

  const ProductImportCard({
    super.key,
    required this.productName,
    required this.barcode,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.wholesalePrice,
    required this.stock,
    this.isSelected = false,
    this.onTap,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLG,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.04)
            : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopRow(),
                const SizedBox(height: 10),
                _buildBarcodeRow(),
                const SizedBox(height: 10),
                _buildPricingRow(),
                const SizedBox(height: 10),
                _buildStockRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: isSelected,
            onChanged: onSelectionChanged,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            productName,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBarcodeRow() {
    return Padding(
      padding: const EdgeInsets.only(left: 36),
      child: Row(
        children: [
          Icon(
            Icons.qr_code_rounded,
            size: 14,
            color: AppColors.textHint,
          ),
          const SizedBox(width: 6),
          Text(
            barcode,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontFamily: 'monospace',
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingRow() {
    return Padding(
      padding: const EdgeInsets.only(left: 36),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          PriceChip(type: PriceType.bp, price: buyingPrice),
          PriceChip(type: PriceType.sp, price: sellingPrice),
          PriceChip(type: PriceType.wp, price: wholesalePrice),
        ],
      ),
    );
  }

  Widget _buildStockRow() {
    return Padding(
      padding: const EdgeInsets.only(left: 36),
      child: StockBadge(stock: stock),
    );
  }
}
