import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/features/auth/presentation/controllers/auth_controller.dart';

/// Controlled shop-picker for the "Import from shop" flow.
///
/// The parent owns [value] and updates it via [onChanged].  Using a plain
/// [DropdownButton] (not DropdownButtonFormField) keeps it fully controlled —
/// every rebuild reflects the parent's current selection.
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

    // All shops except the current active one (can't import from self).
    // Format: "Shop Name (shop_id)" — id is parsed by _extractShopId() in
    // the pages that consume this dropdown.
    final shops = (authState.shops ?? [])
        .where((s) => s.id?.toString() != activeId)
        .map((s) {
          final name = s.shopName ?? '';
          final id = s.id?.toString() ?? '';
          return name.isNotEmpty ? '$name ($id)' : id;
        })
        .where((label) => label.isNotEmpty)
        .toList();

    // Keep controlled value valid; reset if option no longer exists.
    final safeValue = shops.contains(value) ? value : null;

    final isEmpty = shops.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Import From',
          style: AppTypography.label.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: InputDecoration(
            filled: true,
            fillColor: isEmpty ? AppColors.background : AppColors.card,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
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
          child: DropdownButton<String>(
            value: safeValue,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textHint,
            ),
            hint: Text(
              isEmpty ? 'No other shops available' : 'Select Shop',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
            ),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            items: shops.map((shop) {
              return DropdownMenuItem(
                value: shop,
                child: Text(shop, style: AppTypography.bodyMedium),
              );
            }).toList(),
            onChanged: isEmpty ? null : onChanged,
          ),
        ),
      ],
    );
  }
}
