import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/app/typography.dart';

class ImportProductCard extends StatelessWidget {
  final int rowNumber;
  final String productName;
  final bool isValid;
  final String? validationMessage;
  final TextEditingController? nameController;
  final TextEditingController? quantityController;
  final TextEditingController? buyingPriceController;
  final TextEditingController? sellingPriceController;
  final TextEditingController? wholesaleController;
  final TextEditingController? reorderController;
  final TextEditingController? barcodeController;
  final TextEditingController? expiryController;
  final String? unit;

  const ImportProductCard({
    super.key,
    required this.rowNumber,
    required this.productName,
    required this.isValid,
    this.validationMessage,
    this.nameController,
    this.quantityController,
    this.buyingPriceController,
    this.sellingPriceController,
    this.wholesaleController,
    this.reorderController,
    this.barcodeController,
    this.expiryController,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildFields(),
                if (!isValid && validationMessage != null) ...[
                  const SizedBox(height: 12),
                  _buildValidationMessage(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '$rowNumber',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                productName,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isValid
                ? AppColors.success.withAlpha(20)
                : AppColors.danger.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isValid ? 'READY' : 'INVALID',
            style: AppTypography.labelSmall.copyWith(
              color: isValid ? AppColors.success : AppColors.danger,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFields() {
    return Column(
      children: [
        _buildEditableField(
          label: 'Product Name',
          controller: nameController,
          icon: Icons.inventory_2_rounded,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildEditableField(
                label: 'Quantity',
                controller: quantityController,
                keyboardType: TextInputType.number,
                icon: Icons.numbers_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEditableField(
                label: 'Reorder Level',
                controller: reorderController,
                keyboardType: TextInputType.number,
                icon: Icons.notifications_active_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildEditableField(
                label: 'Buying Price',
                controller: buyingPriceController,
                keyboardType: TextInputType.number,
                icon: Icons.shopping_cart_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEditableField(
                label: 'Selling Price',
                controller: sellingPriceController,
                keyboardType: TextInputType.number,
                icon: Icons.sell_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildEditableField(
          label: 'Wholesale Price',
          controller: wholesaleController,
          keyboardType: TextInputType.number,
          icon: Icons.store_rounded,
        ),
        const SizedBox(height: 12),
        _buildEditableField(
          label: 'Barcode',
          controller: barcodeController,
          icon: Icons.qr_code_rounded,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildEditableField(
                label: 'Expiry Date',
                controller: expiryController,
                icon: Icons.event_rounded,
                hintText: 'YYYY-MM-DD',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildUnitField(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditableField({
    required String label,
    TextEditingController? controller,
    TextInputType? keyboardType,
    required IconData icon,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.captionBold.copyWith(fontSize: 11),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: AppTypography.bodyMedium.copyWith(fontSize: 13),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: hintText ?? 'Enter $label',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textHint,
              fontSize: 13,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
              borderSide: const BorderSide(
                color: AppColors.inputFocusBorder,
                width: 1.5,
              ),
            ),
            prefixIcon: Icon(icon, size: 16, color: AppColors.textHint),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Unit',
          style: AppTypography.captionBold.copyWith(fontSize: 11),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: unit,
          isExpanded: true,
          hint: Text(
            'Select unit',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textHint,
              fontSize: 13,
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textHint,
            size: 20,
          ),
          style: AppTypography.bodyMedium.copyWith(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
              borderSide: const BorderSide(
                color: AppColors.inputFocusBorder,
                width: 1.5,
              ),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'pcs', child: Text('pcs')),
            DropdownMenuItem(value: 'kg', child: Text('kg')),
            DropdownMenuItem(value: 'litre', child: Text('litre')),
            DropdownMenuItem(value: 'box', child: Text('box')),
            DropdownMenuItem(value: 'pack', child: Text('pack')),
          ],
          onChanged: (_) {},
        ),
      ],
    );
  }

  Widget _buildValidationMessage() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.dangerLight.withAlpha(60),
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: AppColors.danger,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              validationMessage!,
              style: AppTypography.caption.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
