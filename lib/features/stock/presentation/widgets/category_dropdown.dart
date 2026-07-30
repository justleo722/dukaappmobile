import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/app/typography.dart';

class CategoryDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final List<String> categories;

  const CategoryDropdown({
    super.key,
    this.value,
    required this.onChanged,
    this.categories = const [
      'Uncategorized',
      'Beverages',
      'Food',
      'Electronics',
      'Hardware',
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Category',
          style: AppTypography.label.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          hint: Text(
            'Select category',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textHint,
          ),
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
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
          items: categories.map((cat) {
            return DropdownMenuItem(value: cat, child: Text(cat));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
