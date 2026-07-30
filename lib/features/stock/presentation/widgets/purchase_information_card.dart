import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

class PurchaseInformationCard extends StatelessWidget {
  final VoidCallback? onSearchTap;
  final String? selectedAccount;
  final ValueChanged<String?> onAccountChanged;
  final String? selectedSupplier;
  final ValueChanged<String?> onSupplierChanged;

  static const List<String> _accounts = [
    'Cash',
    'Bank',
    'Supplier Credit',
    'Mobile Money',
  ];

  static const List<String> _suppliers = [
    'TANZANIA BEVERAGES LTD',
    'KILIMANJARO PREMIUM LTD',
    'Coca-Cola Kwanza Ltd',
    'SAFARI BREWERIES LTD',
    'Local Wholesaler',
  ];

  const PurchaseInformationCard({
    super.key,
    this.onSearchTap,
    this.selectedAccount,
    required this.onAccountChanged,
    this.selectedSupplier,
    required this.onSupplierChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchField(),
          const SizedBox(height: 14),
          _buildDropdownRow(),
          const SizedBox(height: 14),
          _buildSupplierDropdown(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return GestureDetector(
      onTap: onSearchTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Search product or scan barcode',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.barcode_reader,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownRow() {
    return Row(
      children: [
        Expanded(
          child: _buildDropdown(
            label: 'From Account',
            value: selectedAccount,
            hint: 'Select account',
            items: _accounts,
            onChanged: onAccountChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSupplierDropdown() {
    return _buildDropdown(
      label: 'Supplier (Optional)',
      value: selectedSupplier,
      hint: 'Select supplier',
      items: _suppliers,
      onChanged: onSupplierChanged,
    );
  }

  Widget _buildDropdown({
    required String label,
    String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
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
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          hint: Text(
            hint,
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
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
