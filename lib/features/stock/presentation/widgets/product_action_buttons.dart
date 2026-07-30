import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';

class ProductActionButtons extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onHistory;
  final VoidCallback? onStockPdf;
  final VoidCallback? onSalesPdf;
  final VoidCallback? onPhotos;
  final VoidCallback? onRestock;
  final VoidCallback? onAdjust;
  final VoidCallback? onDelete;

  const ProductActionButtons({
    super.key,
    this.onEdit,
    this.onHistory,
    this.onStockPdf,
    this.onSalesPdf,
    this.onPhotos,
    this.onRestock,
    this.onAdjust,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildActionButton(
            icon: Icons.edit_rounded,
            label: 'Edit',
            color: AppColors.primary,
            onTap: onEdit,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.history_rounded,
            label: 'History',
            color: AppColors.primary,
            onTap: onHistory,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.description_rounded,
            label: 'Stock PDF',
            color: AppColors.primary,
            onTap: onStockPdf,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.receipt_rounded,
            label: 'Sales PDF',
            color: AppColors.primary,
            onTap: onSalesPdf,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.photo_library_rounded,
            label: 'Photos',
            color: AppColors.primary,
            onTap: onPhotos,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.refresh_rounded,
            label: 'Restock',
            color: AppColors.success,
            onTap: onRestock,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.tune_rounded,
            label: 'Adjust',
            color: AppColors.secondary,
            onTap: onAdjust,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.delete_rounded,
            label: 'Delete',
            color: AppColors.danger,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
