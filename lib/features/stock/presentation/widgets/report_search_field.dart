import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

class ReportSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const ReportSearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTypography.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search reports...',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textHint,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textHint,
            size: 20,
          ),
          suffixIcon: controller != null && controller!.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    controller?.clear();
                    onClear?.call();
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textHint,
                    size: 18,
                  ),
                )
              : null,
          filled: true,
          fillColor: AppColors.card,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
            borderSide: const BorderSide(color: AppColors.inputBorder),
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
    );
  }
}
