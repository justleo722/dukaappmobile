import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/app/typography.dart';

class DateInputField extends StatelessWidget {
  final String label;
  final String hintText;
  final String? value;
  final VoidCallback? onTap;

  const DateInputField({
    super.key,
    required this.label,
    required this.hintText,
    this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.label.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? hintText,
                    style: value != null
                        ? AppTypography.bodyMedium
                        : AppTypography.bodyMedium.copyWith(
                            color: AppColors.textHint,
                          ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
