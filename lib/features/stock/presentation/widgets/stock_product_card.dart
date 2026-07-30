import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/stock/presentation/widgets/product_action_buttons.dart';

class StockProductCard extends StatelessWidget {
  final String productName;
  final String category;
  final double buyingPrice;
  final double sellingPrice;
  final int currentStock;
  final int lowStockThreshold;
  final String? imageUrl;
  final VoidCallback? onTap;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectionChanged;
  final bool isExpanded;
  final VoidCallback? onExpandToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onHistory;
  final VoidCallback? onStockPdf;
  final VoidCallback? onSalesPdf;
  final VoidCallback? onPhotos;
  final VoidCallback? onRestock;
  final VoidCallback? onAdjust;
  final VoidCallback? onDelete;

  const StockProductCard({
    super.key,
    required this.productName,
    required this.category,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.currentStock,
    this.lowStockThreshold = 5,
    this.imageUrl,
    this.onTap,
    this.isSelected = false,
    this.onSelectionChanged,
    this.isExpanded = false,
    this.onExpandToggle,
    this.onEdit,
    this.onHistory,
    this.onStockPdf,
    this.onSalesPdf,
    this.onPhotos,
    this.onRestock,
    this.onAdjust,
    this.onDelete,
  });

  bool get _isLowStock => currentStock <= lowStockThreshold;

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
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onExpandToggle,
          borderRadius: BorderRadius.circular(14),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    _buildCheckbox(),
                    const SizedBox(width: 8),
                    _buildProductImage(),
                    const SizedBox(width: 12),
                    Expanded(child: _buildProductInfo()),
                    _buildStockInfo(),
                    const SizedBox(width: 4),
                    _buildExpandIcon(),
                  ],
                ),
              ),
              _buildAccordionContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox() {
    return SizedBox(
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
    );
  }

  Widget _buildProductImage() {
    final initials = productName.isNotEmpty
        ? productName.substring(0, productName.length.clamp(0, 2)).toUpperCase()
        : '??';

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildInitials(initials),
              ),
            )
          : _buildInitials(initials),
    );
  }

  Widget _buildInitials(String initials) {
    return Center(
      child: Text(
        initials,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          productName,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                category,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStockInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Tsh ${buyingPrice.toStringAsFixed(0)}',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Tsh ${sellingPrice.toStringAsFixed(0)}',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _isLowStock
                ? AppColors.danger.withValues(alpha: 0.1)
                : AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$currentStock',
            style: AppTypography.caption.copyWith(
              color: _isLowStock ? AppColors.danger : AppColors.success,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandIcon() {
    return AnimatedRotation(
      turns: isExpanded ? 0.5 : 0,
      duration: const Duration(milliseconds: 250),
      child: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textHint,
        size: 20,
      ),
    );
  }

  Widget _buildAccordionContent() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: isExpanded
          ? Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  Container(
                    height: 1,
                    color: AppColors.border,
                  ),
                  const SizedBox(height: 12),
                  ProductActionButtons(
                    onEdit: onEdit,
                    onHistory: onHistory,
                    onStockPdf: onStockPdf,
                    onSalesPdf: onSalesPdf,
                    onPhotos: onPhotos,
                    onRestock: onRestock,
                    onAdjust: onAdjust,
                    onDelete: onDelete,
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
