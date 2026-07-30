import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/app/typography.dart';

class BottomImportBar extends StatelessWidget {
  final VoidCallback? onClose;
  final VoidCallback? onImport;
  final int selectedCount;

  const BottomImportBar({
    super.key,
    this.onClose,
    this.onImport,
    this.selectedCount = 0,
  });

  bool get _hasSelection => selectedCount > 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppConstants.paddingLG,
        right: AppConstants.paddingLG,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: const Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: AppConstants.buttonHeight,
              child: OutlinedButton(
                onPressed: onClose,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(
                    color: AppColors.border,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  ),
                ),
                child: Text(
                  'Close',
                  style: AppTypography.buttonLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: AppConstants.buttonHeight,
              child: ElevatedButton(
                onPressed: _hasSelection ? onImport : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  disabledBackgroundColor: AppColors.primary.withAlpha(128),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  ),
                ),
                child: Text(
                  _hasSelection
                      ? 'Import Selected ($selectedCount)'
                      : 'Import Selected',
                  style: AppTypography.buttonLarge,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
