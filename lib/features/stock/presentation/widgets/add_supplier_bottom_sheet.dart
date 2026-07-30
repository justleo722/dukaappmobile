import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/app/typography.dart';

class AddSupplierBottomSheet extends StatefulWidget {
  final ValueChanged<String> onSupplierAdded;

  const AddSupplierBottomSheet({
    super.key,
    required this.onSupplierAdded,
  });

  static void show({
    required BuildContext context,
    required ValueChanged<String> onSupplierAdded,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddSupplierBottomSheet(
        onSupplierAdded: onSupplierAdded,
      ),
    );
  }

  @override
  State<AddSupplierBottomSheet> createState() => _AddSupplierBottomSheetState();
}

class _AddSupplierBottomSheetState extends State<AddSupplierBottomSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      widget.onSupplierAdded(_nameController.text.trim());
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
          maxHeight: MediaQuery.of(context).size.height * 0.55,
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
                          'Add Supplier',
                          style: AppTypography.h5.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter supplier details',
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      autofocus: true,
                      style: AppTypography.bodyMedium,
                      cursorColor: AppColors.primary,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'Supplier name',
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
                          return 'Please enter a supplier name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      style: AppTypography.bodyMedium,
                      cursorColor: AppColors.primary,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Phone number (optional)',
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
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: AppConstants.buttonHeight,
                child: ElevatedButton(
                  onPressed: _save,
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
                    'Add Supplier',
                    style: AppTypography.buttonLarge,
                  ),
                ),
              ),
            ),
            SizedBox(height: bottomPadding + 20),
          ],
        ),
      ),
    );
  }
}
