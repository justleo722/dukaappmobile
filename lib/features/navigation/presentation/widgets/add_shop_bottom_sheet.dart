import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/features/auth/presentation/controllers/auth_controller.dart';

class AddShopBottomSheet extends ConsumerStatefulWidget {
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
  ConsumerState<AddShopBottomSheet> createState() => _AddShopBottomSheetState();
}

class _AddShopBottomSheetState extends ConsumerState<AddShopBottomSheet> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedShopType = 'Product & Services';
  int _selectedLobId = 1;
  bool _isLoading = false;
  String? _error;

  // Lobs from backend (lob_id, lob_name)
  final List<Map<String, dynamic>> _lobs = [
    {'lob_id': 1, 'lob_name': 'Product & Services'},
    {'lob_id': 2, 'lob_name': 'Manufacturing'},
    {'lob_id': 3, 'lob_name': 'Online Shop'},
    {'lob_id': 4, 'lob_name': 'Microfinance'},
  ];

  final List<String> _shopTypes = [
    'Product & Services',
    'Product Only',
    'Service Only',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createShop() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(authProvider.notifier).addShop(
        shopName: _nameController.text.trim(),
        shopType: _selectedShopType,
        lobId: _selectedLobId,
      );

      if (!mounted) return;
      Navigator.pop(context);
      widget.onShopCreated({
        'name': _nameController.text.trim(),
        'shopType': _selectedShopType,
        'lobId': _selectedLobId,
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
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
                        labelOf: (v) => v,
                        onChanged: (value) {
                          setState(() => _selectedShopType = value!);
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Business Category'),
                      const SizedBox(height: 8),
                      _buildDropdown<Map<String, dynamic>>(
                        value: _lobs.firstWhere((l) => l['lob_id'] == _selectedLobId),
                        items: _lobs,
                        labelOf: (l) => l['lob_name'] as String,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedLobId = value['lob_id'] as int);
                          }
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: AppConstants.buttonHeight,
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : () => Navigator.pop(context),
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
                                onPressed: _isLoading ? null : _createShop,
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
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.textWhite,
                                        ),
                                      )
                                    : Text(
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
    required String Function(T) labelOf,
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
                labelOf(item),
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
