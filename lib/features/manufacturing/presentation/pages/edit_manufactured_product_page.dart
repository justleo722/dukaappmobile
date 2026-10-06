import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';

class EditManufacturedProductPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> productData;

  const EditManufacturedProductPage({super.key, required this.productData});

  @override
  ConsumerState<EditManufacturedProductPage> createState() =>
      _EditManufacturedProductPageState();
}

class _EditManufacturedProductPageState
    extends ConsumerState<EditManufacturedProductPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _alertLevelController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _wholesalePriceController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.productData;
    _nameController = TextEditingController(
        text: (p['product_name'] ?? p['name'] ?? '').toString());
    _quantityController = TextEditingController(
        text: (p['quantity'] ?? p['stock'] ?? 0).toString());
    _alertLevelController = TextEditingController(
        text: (p['alert_level'] ?? p['reorder_level'] ?? p['alertLevel'] ?? 0).toString());
    _sellingPriceController = TextEditingController(
        text: (p['selling_price'] ?? p['sellingPrice'] ?? 0).toString());
    _wholesalePriceController = TextEditingController(
        text: (p['wholesale_price'] ?? p['wholesalePrice'] ?? 0).toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _alertLevelController.dispose();
    _sellingPriceController.dispose();
    _wholesalePriceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final productId = (widget.productData['product_id'] ??
            widget.productData['id'] ??
            '')
        .toString();
    if (productId.isEmpty) {
      _showSnack('Product ID not found.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.postMfProductionUpdate({
        'product_id': productId,
        'product_name': _nameController.text.trim(),
        'quantity': _quantityController.text.trim(),
        'reorder_level': _alertLevelController.text.trim(),
        'selling_price': _sellingPriceController.text.trim(),
        'wholesale_price': _wholesalePriceController.text.trim(),
      });

      if ((res['status'] ?? '') == 'success') {
        if (mounted) {
          _showSnack('Product updated successfully.');
          context.pop(true);
        }
      } else {
        _showSnack(res['message']?.toString() ?? 'Update failed.', isError: true);
      }
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)),
      backgroundColor: isError ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final recipe = (widget.productData['recipe_name'] ??
            widget.productData['recipe'] ??
            '—')
        .toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 1.5),
                borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
            child: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.textPrimary, size: 20),
            ),
          ),
        ),
        leadingWidth: 56,
        title: Column(children: [
          Text('Edit Product',
              style: AppTypography.h6
                  .copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('Update manufactured product details.',
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary, fontSize: 10)),
        ]),
        centerTitle: true,
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.divider)),
      ),
      body: SafeArea(
        top: false,
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLG),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _formCard('Product Information', [
                      _buildTextField('Product Name', _nameController,
                          'e.g. Pilau', TextInputType.text),
                      const SizedBox(height: 14),
                      _buildReadOnlyField('Recipe', recipe),
                      const SizedBox(height: 14),
                      _buildTextField('Quantity (Balance)', _quantityController,
                          '0', TextInputType.number),
                      const SizedBox(height: 14),
                      _buildTextField('Alert Level', _alertLevelController,
                          '10', TextInputType.number),
                    ]),
                    const SizedBox(height: 14),
                    _formCard('Cost & Pricing', [
                      _buildTextField('Selling Price (Tsh)',
                          _sellingPriceController, '0', TextInputType.number),
                      const SizedBox(height: 14),
                      _buildTextField('Wholesale Price (Tsh)',
                          _wholesalePriceController, '0', TextInputType.number),
                    ]),
                    SizedBox(height: 24 + bottomPadding),
                  ]),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingLG),
            decoration: BoxDecoration(
                color: AppColors.card,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -2))
                ]),
            child: Row(children: [
              Expanded(
                  child: SizedBox(
                      height: AppConstants.buttonHeight,
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : () => context.pop(),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(
                                color: AppColors.border, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppConstants.radiusMD))),
                        child: Text('Cancel',
                            style: AppTypography.buttonLarge
                                .copyWith(color: AppColors.textSecondary)),
                      ))),
              const SizedBox(width: 12),
              Expanded(
                  flex: 2,
                  child: SizedBox(
                      height: AppConstants.buttonHeight,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textWhite,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppConstants.radiusMD))),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textWhite))
                            : Text('Update Product',
                                style: AppTypography.buttonLarge),
                      ))),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _formCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: AppTypography.label.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      String hint, TextInputType keyboardType) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: AppTypography.caption
              .copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
            filled: true,
            fillColor: const Color(0xFFF5F7FB),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.textFieldRadius),
                borderSide: const BorderSide(color: AppColors.inputBorder)),
            enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.textFieldRadius),
                borderSide: const BorderSide(color: AppColors.inputBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.textFieldRadius),
                borderSide: const BorderSide(
                    color: AppColors.inputFocusBorder, width: 1.5)),
          )),
    ]);
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: AppTypography.caption
              .copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius:
                  BorderRadius.circular(AppConstants.textFieldRadius),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15))),
          child: Text(value,
              style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.w600))),
    ]);
  }
}
