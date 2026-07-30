import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

class StockSelectBar extends StatelessWidget {
  final bool isAllSelected;
  final ValueChanged<bool?>? onToggleAll;
  final int selectedCount;
  final VoidCallback? onDeleteAll;

  const StockSelectBar({
    super.key,
    this.isAllSelected = false,
    this.onToggleAll,
    this.selectedCount = 0,
    this.onDeleteAll,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCount > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: hasSelection
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(
          color: hasSelection
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.secondary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: isAllSelected,
              onChanged: onToggleAll,
              activeColor: AppColors.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            hasSelection ? '$selectedCount Selected' : 'Mark All',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (hasSelection)
            GestureDetector(
              onTap: onDeleteAll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.delete_rounded,
                      color: AppColors.danger,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Delete All',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
