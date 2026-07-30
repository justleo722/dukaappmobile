import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

class PriceInput extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? prefix;

  const PriceInput({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.onChanged,
    this.prefix = 'Tsh',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.captionBold.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText ?? '0',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
            prefixText: '$prefix ',
            prefixStyle: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: AppColors.card,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
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
      ],
    );
  }
}
