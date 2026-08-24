import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/app/typography.dart';

class AddShopBottomSheet extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onShopCreated;

  const AddShopBottomSheet({
    super.key,
    required this.onShopCreated,
  });

  static void show({
    required BuildContext context,
    required ValueChanged<Map<String, dynamic>> onShopCreated,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddShopBottomSheet(
        onShopCreated: onShopCreated,
      ),
    );
  }

  @override
  State<AddShopBottomSheet> createState() => _AddShopBottomSheetState();
}

class _AddShopBottomSheetState extends State<AddShopBottomSheet> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedShopType = 'Product & Service';
  String _selectedBusinessCategory = 'Default';

  final List<String> _shopTypes = [
    'Product & Service',
    'Product Only',
    'Service Only',
  ];

  final List<String> _businessCategories = [
    'Default',
    'Retail',
    'Wholesale',
    'Manufacturing',
    'Service',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createShop() {
    if (_formKey.currentState!.validate()) {
      final shopData = {
        'name': _nameController.text.trim(),
        'shopType': _selectedShopType,
        'businessCategory': _selectedBusinessCategory,
      };
      widget.onShopCreated(shopData);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Shop',
                          style: AppTypography.h5.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create a new shop',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Shop Name'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        autofocus: true,
                        style: AppTypography.bodyMedium,
                        cursorColor: AppColors.primary,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'Enter shop name',
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textHint,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.textFieldRadius,
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.inputBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.textFieldRadius,
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.inputBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.textFieldRadius,
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.inputFocusBorder,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter a shop name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Shop Type'),
                      const SizedBox(height: 8),
                      _buildDropdown<String>(
                        value: _selectedShopType,
                        items: _shopTypes,
                        onChanged: (value) {
                          setState(() {
                            _selectedShopType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Business Category'),
                      const SizedBox(height: 8),
                      _buildDropdown<String>(
                        value: _selectedBusinessCategory,
                        items: _businessCategories,
                        onChanged: (value) {
                          setState(() {
                            _selectedBusinessCategory = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: AppConstants.buttonHeight,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppColors.inputBorder,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppConstants.radiusLG,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: AppTypography.buttonLarge.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: AppConstants.buttonHeight,
                              child: ElevatedButton(
                                onPressed: _createShop,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.textWhite,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppConstants.radiusLG,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Create Shop',
                                  style: AppTypography.buttonLarge,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: bottomPadding + 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTypography.bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textHint,
          ),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                item.toString(),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
