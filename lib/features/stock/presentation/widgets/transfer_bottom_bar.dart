import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/app/typography.dart';

class TransferBottomBar extends StatelessWidget {
  final VoidCallback? onClose;
  final VoidCallback? onTransfer;

  const TransferBottomBar({
    super.key,
    this.onClose,
    this.onTransfer,
  });

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
                onPressed: onTransfer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  ),
                ),
                child: Text(
                  'Transfer Stock',
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
