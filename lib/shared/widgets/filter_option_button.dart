import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/app/typography.dart';

class FilterOptionButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterOptionButton({
    super.key,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primary : AppColors.card,
          foregroundColor: isSelected ? AppColors.textWhite : AppColors.primary,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.primary,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingSM,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.buttonMedium.copyWith(
            color: isSelected ? AppColors.textWhite : AppColors.primary,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
