import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/features/auth/presentation/controllers/auth_controller.dart';

class ShopDropdown extends ConsumerWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const ShopDropdown({
    super.key,
    this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final activeId = authState.activeShop?.id?.toString() ?? '';

    // All shops except the current active one (can't import from self)
    final shops = (authState.shops ?? [])
        .where((s) => s.id?.toString() != activeId)
        .map((s) => s.shopName ?? s.id?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    // If current value no longer in list, reset
    final safeValue = shops.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Import From',
          style: AppTypography.label.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: safeValue,
          isExpanded: true,
          hint: Text(
            shops.isEmpty ? 'No other shops available' : 'Select Shop',
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
          items: shops.map((shop) {
            return DropdownMenuItem(
              value: shop,
              child: Text(
                shop,
                style: AppTypography.bodyMedium,
              ),
            );
          }).toList(),
          onChanged: shops.isEmpty ? null : onChanged,
        ),
      ],
    );
  }
}
