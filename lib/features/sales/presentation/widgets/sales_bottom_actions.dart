import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';

class SalesBottomActions extends StatelessWidget {
  final VoidCallback? onDownload;
  final VoidCallback? onBackdate;
  final VoidCallback? onPrint;
  final VoidCallback? onPreview;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SalesBottomActions({
    super.key,
    this.onDownload,
    this.onBackdate,
    this.onPrint,
    this.onPreview,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildOutlinedButton(
            icon: Icons.download_rounded,
            label: 'Download',
            onTap: onDownload,
          ),
          const SizedBox(width: 8),
          _buildOutlinedButton(
            icon: Icons.date_range_rounded,
            label: 'Backdate',
            onTap: onBackdate,
          ),
          const SizedBox(width: 8),
          _buildOutlinedButton(
            icon: Icons.print_rounded,
            label: 'Print',
            onTap: onPrint,
          ),
          const SizedBox(width: 8),
          _buildOutlinedButton(
            icon: Icons.visibility_rounded,
            label: 'Preview',
            onTap: onPreview,
          ),
          const SizedBox(width: 8),
          _buildOutlinedButton(
            icon: Icons.edit_rounded,
            label: 'Edit',
            onTap: onEdit,
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

  Widget _buildOutlinedButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
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
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
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
