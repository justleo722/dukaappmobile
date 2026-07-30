import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/stock/presentation/widgets/add_category_bottom_sheet.dart';
import 'package:dukaapp/features/stock/presentation/widgets/add_supplier_bottom_sheet.dart';
import 'package:dukaapp/features/stock/presentation/pages/barcode_scanner_screen.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _buyingPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _discountController = TextEditingController();
  final _reorderLevelController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _supplierController = TextEditingController();
  final _expiryDateController = TextEditingController();

  String? _selectedType;
  String? _selectedCategory;
  String? _selectedTaxable;
  String? _selectedOnlineShop;
  String? _selectedUnit;

  final Set<int> _expandedOptions = {};
  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedPhotos = [];

  final List<String> _types = ['Product', 'Service'];
  final List<String> _categories = [
    'Uncategorized',
    'Cosmetics',
    'Accessories',
    'Electronics',
    'Household',
    'Beauty',
  ];
  final List<String> _suppliers = [];
  final List<String> _yesNoOptions = ['Yes', 'No'];
  final List<String> _units = [
    'Piece',
    'Kilogram',
    'Gram',
    'Litre',
    'Millilitre',
    'Metre',
    'Centimetre',
    'Box',
    'Pack',
    'Dozen',
    'Pair',
    'Set',
  ];

  static const String _addNewCategoryValue = '__add_new_category__';
  static const String _addNewSupplierValue = '__add_new_supplier__';

  bool get _isService => _selectedType == 'Service';

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _buyingPriceController.dispose();
    _sellingPriceController.dispose();
    _discountController.dispose();
    _reorderLevelController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    _wholesalePriceController.dispose();
    _supplierController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully')),
      );
      context.pop();
    }
  }

  void _toggleOption(int index) {
    setState(() {
      if (_expandedOptions.contains(index)) {
        _expandedOptions.remove(index);
      } else {
        _expandedOptions.add(index);
      }
    });
  }

  void _addCategory(String name) {
    setState(() {
      _categories.add(name);
      _selectedCategory = name;
    });
  }

  void _addSupplier(String name) {
    setState(() {
      _suppliers.add(name);
      _supplierController.text = name;
    });
  }

  Future<void> _openBarcodeScanner() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const BarcodeScannerScreen(),
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _barcodeController.text = result;
      });
    }
  }

  Future<void> _pickPhotos() async {
    if (_selectedPhotos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 3 photos allowed')),
      );
      return;
    }

    final remaining = 3 - _selectedPhotos.length;
    final images = await _picker.pickMultiImage(imageQuality: 80);

    if (images.isNotEmpty) {
      setState(() {
        final toAdd = images.take(remaining);
        _selectedPhotos.addAll(toAdd.map((e) => File(e.path)));
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingLG,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildRow([
                  _buildTypeDropdown(),
                  const SizedBox(width: 12),
                  _buildCategoryDropdownWithAddNew(),
                ]),
                const SizedBox(height: 16),
                if (_isService) ...[
                  _buildTextField(
                    controller: _nameController,
                    label: 'Service Name',
                    hintText: 'Enter service name',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _sellingPriceController,
                    label: 'Selling Price',
                    hintText: '0',
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('More Options'),
                  const SizedBox(height: 8),
                  _buildExpandableDropdown(
                    index: 3,
                    icon: Icons.receipt_rounded,
                    label: 'Taxable',
                    value: _selectedTaxable,
                    options: _yesNoOptions,
                    onChanged: (v) =>
                        setState(() => _selectedTaxable = v),
                  ),
                  _buildExpandableOption(
                    index: 7,
                    icon: Icons.description_rounded,
                    label: 'Description',
                    controller: _descriptionController,
                    hintText: 'Enter service description',
                    maxLines: 3,
                  ),
                  _buildExpandablePhoto(),
                ] else ...[
                  _buildRow([
                    _buildTextField(
                      controller: _nameController,
                      label: 'Product Name',
                      hintText: 'Enter name',
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(width: 12),
                    _buildTextField(
                      controller: _quantityController,
                      label: 'Quantity',
                      hintText: '0',
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildRow([
                    _buildTextField(
                      controller: _buyingPriceController,
                      label: 'Buying Price',
                      hintText: '0',
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(width: 12),
                    _buildTextField(
                      controller: _sellingPriceController,
                      label: 'Selling Price',
                      hintText: '0',
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle('More Options'),
                  const SizedBox(height: 8),
                  _buildExpandableOption(
                    index: 0,
                    icon: Icons.discount_rounded,
                    label: 'Discount',
                    controller: _discountController,
                    hintText: 'Enter discount %',
                    keyboardType: TextInputType.number,
                  ),
                  _buildExpandableOption(
                    index: 1,
                    icon: Icons.notifications_active_rounded,
                    label: 'Reorder Level',
                    controller: _reorderLevelController,
                    hintText: 'Enter minimum stock level',
                    keyboardType: TextInputType.number,
                  ),
                  _buildExpandableBarcode(),
                  _buildExpandableDropdown(
                    index: 3,
                    icon: Icons.receipt_rounded,
                    label: 'Taxable',
                    value: _selectedTaxable,
                    options: _yesNoOptions,
                    onChanged: (v) =>
                        setState(() => _selectedTaxable = v),
                  ),
                  _buildExpandableDropdown(
                    index: 4,
                    icon: Icons.storefront_rounded,
                    label: 'Online Shop',
                    value: _selectedOnlineShop,
                    options: _yesNoOptions,
                    onChanged: (v) =>
                        setState(() => _selectedOnlineShop = v),
                  ),
                  _buildExpandableDropdown(
                    index: 5,
                    icon: Icons.straighten_rounded,
                    label: 'Unit',
                    value: _selectedUnit,
                    options: _units,
                    onChanged: (v) =>
                        setState(() => _selectedUnit = v),
                  ),
                  _buildExpandableDate(
                    index: 6,
                    icon: Icons.event_rounded,
                    label: 'Expiry Date',
                    controller: _expiryDateController,
                  ),
                  _buildExpandableOption(
                    index: 7,
                    icon: Icons.description_rounded,
                    label: 'Description',
                    controller: _descriptionController,
                    hintText: 'Enter product description',
                    maxLines: 3,
                  ),
                  _buildExpandableOption(
                    index: 8,
                    icon: Icons.local_offer_rounded,
                    label: 'Wholesale Price',
                    controller: _wholesalePriceController,
                    hintText: 'Enter wholesale price',
                    keyboardType: TextInputType.number,
                  ),
                  _buildExpandableSupplierDropdown(),
                  _buildExpandablePhoto(),
                ],
                const SizedBox(height: 32),
                _buildSaveButton(),
                const SizedBox(height: 24),
                SizedBox(height: bottomPadding),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.card,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, width: 1.5),
            borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          ),
          child: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
      ),
      leadingWidth: 56,
      title: Text(
        _isService ? 'Add Service' : 'Add Product',
        style: AppTypography.h6.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildRow(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.map((child) {
        if (child is SizedBox) return child;
        return Expanded(child: child);
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.bodyLarge.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.label.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: AppTypography.bodyMedium,
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
            filled: true,
            fillColor: AppColors.card,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.textFieldRadius,
              ),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.textFieldRadius,
              ),
              borderSide: const BorderSide(color: AppColors.inputBorder),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.textFieldRadius,
              ),
              borderSide: const BorderSide(
                color: AppColors.inputErrorBorder,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.textFieldRadius,
              ),
              borderSide: const BorderSide(
                color: AppColors.inputErrorBorder,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required String hintText,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.label.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          hint: Text(
            hintText,
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
              borderRadius: BorderRadius.circular(
                AppConstants.textFieldRadius,
              ),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.textFieldRadius,
              ),
              borderSide: const BorderSide(color: AppColors.inputBorder),
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
          items: options.map((opt) {
            return DropdownMenuItem(value: opt, child: Text(opt));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTypeDropdown() {
    return _buildDropdownField(
      label: 'Type',
      value: _selectedType,
      hintText: 'Select type',
      options: _types,
      onChanged: (v) => setState(() {
        _selectedType = v;
        _expandedOptions.clear();
      }),
    );
  }

  // --- CATEGORY DROPDOWN WITH ADD NEW ---

  Widget _buildCategoryDropdownWithAddNew() {
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
          initialValue: _selectedCategory,
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
              borderRadius: BorderRadius.circular(
                AppConstants.textFieldRadius,
              ),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.textFieldRadius,
              ),
              borderSide: const BorderSide(color: AppColors.inputBorder),
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
          items: [
            ..._categories.map((opt) {
              return DropdownMenuItem(value: opt, child: Text(opt));
            }),
            DropdownMenuItem(
              value: _addNewCategoryValue,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Add New Category',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (v) {
            if (v == _addNewCategoryValue) {
              AddCategoryBottomSheet.show(
                context: context,
                onCategoryAdded: _addCategory,
              );
            } else {
              setState(() => _selectedCategory = v);
            }
          },
        ),
      ],
    );
  }

  // --- BARCODE FIELD WITH SCANNER ICON ---

  Widget _buildExpandableBarcode() {
    final isExpanded = _expandedOptions.contains(2);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleOption(2),
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.qr_code_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Barcode',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_barcodeController.text.isNotEmpty)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _barcodeController.text,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _barcodeController,
                            keyboardType: TextInputType.number,
                            style: AppTypography.bodyMedium,
                            cursorColor: AppColors.primary,
                            decoration: InputDecoration(
                              hintText: 'Enter or scan barcode',
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
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.textFieldRadius,
                                ),
                                borderSide: BorderSide.none,
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
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _openBarcodeScanner,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(
                                AppConstants.textFieldRadius,
                              ),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // --- SUPPLIER DROPDOWN WITH ADD NEW ---

  Widget _buildExpandableSupplierDropdown() {
    final isExpanded = _expandedOptions.contains(9);
    final allOptions = [..._suppliers, _addNewSupplierValue];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleOption(9),
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Supplier',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_supplierController.text.isNotEmpty)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _supplierController.text,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: DropdownButtonFormField<String>(
                      initialValue: _supplierController.text.isNotEmpty
                          ? _supplierController.text
                          : null,
                      isExpanded: true,
                      hint: Text(
                        'Select supplier',
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
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.textFieldRadius,
                          ),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.textFieldRadius,
                          ),
                          borderSide: BorderSide.none,
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
                      items: [
                        ...allOptions.map((opt) {
                          if (opt == _addNewSupplierValue) {
                            return DropdownMenuItem(
                              value: opt,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.add_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Add New Supplier',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return DropdownMenuItem(
                            value: opt,
                            child: Text(opt),
                          );
                        }),
                      ],
                      onChanged: (v) {
                        if (v == _addNewSupplierValue) {
                          AddSupplierBottomSheet.show(
                            context: context,
                            onSupplierAdded: _addSupplier,
                          );
                        } else {
                          setState(() {
                            _supplierController.text = v ?? '';
                          });
                        }
                      },
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // --- PHOTO UPLOAD (UP TO 3) ---

  Widget _buildExpandablePhoto() {
    final isExpanded = _expandedOptions.contains(10);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleOption(10),
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.photo_camera_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Photo Upload',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_selectedPhotos.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_selectedPhotos.length}/3',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_selectedPhotos.isNotEmpty) ...[
                          SizedBox(
                            height: 100,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedPhotos.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        AppConstants.textFieldRadius,
                                      ),
                                      child: Image.file(
                                        _selectedPhotos[index],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _removePhoto(index),
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: AppColors.danger,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (_selectedPhotos.length < 3)
                          GestureDetector(
                            onTap: _pickPhotos,
                            child: Container(
                              width: double.infinity,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(
                                  AppConstants.textFieldRadius,
                                ),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1.5,
                                  strokeAlign:
                                      BorderSide.strokeAlignInside,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_a_photo_rounded,
                                    color: AppColors.textHint,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _selectedPhotos.isEmpty
                                        ? 'Tap to upload photos'
                                        : 'Add more (${3 - _selectedPhotos.length} remaining)',
                                    style: AppTypography.caption
                                        .copyWith(
                                          color: AppColors.textHint,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableOption({
    required int index,
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final isExpanded = _expandedOptions.contains(index);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleOption(index),
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: TextFormField(
                      controller: controller,
                      keyboardType: keyboardType,
                      maxLines: maxLines,
                      style: AppTypography.bodyMedium,
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        hintText: hintText,
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
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.textFieldRadius,
                          ),
                          borderSide: BorderSide.none,
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
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableDropdown({
    required int index,
    required IconData icon,
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    final isExpanded = _expandedOptions.contains(index);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleOption(index),
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (value != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        value,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: DropdownButtonFormField<String>(
                      initialValue: value,
                      isExpanded: true,
                      hint: Text(
                        'Select',
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
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.textFieldRadius,
                          ),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.textFieldRadius,
                          ),
                          borderSide: BorderSide.none,
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
                      items: options.map((opt) {
                        return DropdownMenuItem(
                          value: opt,
                          child: Text(opt),
                        );
                      }).toList(),
                      onChanged: onChanged,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableDate({
    required int index,
    required IconData icon,
    required String label,
    required TextEditingController controller,
  }) {
    final isExpanded = _expandedOptions.contains(index);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleOption(index),
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (controller.text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        controller.text,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: TextFormField(
                      controller: controller,
                      readOnly: true,
                      style: AppTypography.bodyMedium,
                      cursorColor: AppColors.primary,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365 * 5),
                          ),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppColors.primary,
                                  onPrimary: AppColors.textWhite,
                                  surface: AppColors.card,
                                  onSurface: AppColors.textPrimary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          setState(() {
                            controller.text =
                                '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                          });
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Select date',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textHint,
                        ),
                        prefixIcon: const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
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
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.textFieldRadius,
                          ),
                          borderSide: BorderSide.none,
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
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: AppConstants.buttonHeight,
      child: ElevatedButton(
        onPressed: _saveProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          ),
        ),
        child: Text(
          'Save ${_isService ? 'Service' : 'Product'}',
          style: AppTypography.buttonLarge,
        ),
      ),
    );
  }
}
