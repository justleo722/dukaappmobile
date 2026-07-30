import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

class TransferShopDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  static const List<String> _shops = [
    'ABC MARKET (S0021)',
    'BLACK MAGIC DESIGN (S0018)',
    'JOHN PERFORMS (S0020)',
    'SON COLLECTION (S0003)',
  ];

  const TransferShopDropdown({
    super.key,
    this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Transfer To',
          style: AppTypography.label.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          hint: Text(
            'Select destination shop',
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
          items: _shops.map((shop) {
            return DropdownMenuItem(
              value: shop,
              child: Text(shop),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
