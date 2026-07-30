import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/app/typography.dart';

class StickyImportButtons extends StatelessWidget {
  final VoidCallback? onChangeFile;
  final VoidCallback? onCancel;
  final VoidCallback? onSave;
  final String? cancelLabel;
  final String? saveLabel;

  const StickyImportButtons({
    super.key,
    this.onChangeFile,
    this.onCancel,
    this.onSave,
    this.cancelLabel,
    this.saveLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onChangeFile != null) ...[
            SizedBox(
              width: double.infinity,
              height: AppConstants.buttonHeight,
              child: OutlinedButton.icon(
                onPressed: onChangeFile,
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: Text(
                  'Change File',
                  style: AppTypography.buttonLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: AppConstants.buttonHeight,
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(
                        color: AppColors.border,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusLG,
                        ),
                      ),
                    ),
                    child: Text(
                      cancelLabel ?? 'Cancel',
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
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusLG,
                        ),
                      ),
                    ),
                    child: Text(
                      saveLabel ?? 'Save Import',
                      style: AppTypography.buttonLarge,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
