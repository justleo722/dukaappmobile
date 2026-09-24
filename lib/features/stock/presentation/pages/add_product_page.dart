import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/stock/presentation/providers/stock_provider.dart';
import 'package:dukaapp/features/stock/presentation/widgets/add_category_bottom_sheet.dart';
import 'package:dukaapp/features/stock/presentation/widgets/add_supplier_bottom_sheet.dart';
import 'package:dukaapp/features/stock/presentation/pages/barcode_scanner_screen.dart';

class AddProductPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? product;

  const AddProductPage({super.key, this.product});

  @override
  ConsumerState<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends ConsumerState<AddProductPage> {
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
  final List<String> _categories = [];
  // Suppliers loaded from API: list of {supplier_id, name}
  final List<Map<String, dynamic>> _suppliersList = [];
  String? _selectedSupplierId;
  // Map category name → category_id for API call
  final Map<String, dynamic> _categoryIds = {};
  bool _isSaving = false;
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
  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.product!;
      _nameController.text = p['name'] ?? '';
      _buyingPriceController.text = (p['buyingPrice'] ?? 0).toString();
      _sellingPriceController.text = (p['sellingPrice'] ?? 0).toString();
      _wholesalePriceController.text = (p['wholesalePrice'] ?? 0).toString();
      _reorderLevelController.text = (p['reorderLevel'] ?? 0).toString();
      _barcodeController.text = (p['barcode'] ?? '').toString();
      _selectedUnit = p['unit']?.toString();
      _selectedCategory = p['category'];
    }
    // Load categories from cached stock state, and suppliers from API
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadCategories();
      await _loadSuppliers();
    });
  }

  Future<void> _loadSuppliers() async {
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getSuppliers();
      final raw = res.data;
      final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? raw['suppliers'] ?? []) : []);
      if (!mounted) return;
      setState(() {
        _suppliersList.clear();
        for (final s in list) {
          if (s is Map) {
            final id = (s['supplier_id'] ?? s['id'])?.toString();
            final name = (s['supplier_name'] ?? s['name'] ?? '').toString();
            if (id != null && name.isNotEmpty) {
              _suppliersList.add({'id': id, 'name': name});
            }
          }
        }
      });
    } catch (_) {}
  }

  void _loadCategories() {
    final stockState = ref.read(stockProvider);
    stockState.whenData((stock) {
      if (!mounted) return;
      setState(() {
        _categories.clear();
        _categoryIds.clear();
        for (final c in stock.categories) {
          _categories.add(c.name);
          _categoryIds[c.name] = c.categoryId;
        }
        // Keep selected category valid
        if (_selectedCategory != null && !_categories.contains(_selectedCategory)) {
          _selectedCategory = null;
        }
      });
    });
  }

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
    _expiryDateController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(stockRepositoryProvider);
      final categoryId = _categoryIds[_selectedCategory];
      final isEditing = _isEditing;

      // Convert expiry date from DD/MM/YYYY → YYYY-MM-DD for backend
      String? expiryForApi;
      final rawExpiry = _expiryDateController.text.trim();
      if (rawExpiry.isNotEmpty) {
        try {
          final parsed = DateFormat('dd/MM/yyyy').parse(rawExpiry);
          expiryForApi = DateFormat('yyyy-MM-dd').format(parsed);
        } catch (_) {
          expiryForApi = rawExpiry; // already in correct format
        }
      }

      final body = {
        'product_name': _nameController.text.trim(),
        'type': (_selectedType ?? 'Product').toLowerCase(),
        'category_id': categoryId?.toString() ?? '',
        'bp': _buyingPriceController.text.trim(),
        'sp': _sellingPriceController.text.trim(),
        'wp': _wholesalePriceController.text.trim(),
        'quantity': _quantityController.text.trim(),
        'reorder_level': _reorderLevelController.text.trim(),
        'barcode': _barcodeController.text.trim(),
        'unit': _selectedUnit ?? '',
        'description': _descriptionController.text.trim(),
        'is_taxable': _selectedTaxable == 'Yes' ? '1' : '0',
        'ecommerce_enabled': _selectedOnlineShop == 'Yes' ? '1' : '0',
        if (expiryForApi != null && expiryForApi.isNotEmpty) 'expiry_date': expiryForApi,
        if (_selectedSupplierId != null) 'supplier_id': _selectedSupplierId,
        if (isEditing) 'product_id': widget.product!['product_id']?.toString() ?? '',
        if (isEditing && widget.product!['stock_id'] != null) 'stock_id': widget.product!['stock_id']?.toString() ?? '',
      };

      final photos = _selectedPhotos.isNotEmpty ? _selectedPhotos : null;
      final result = isEditing
          ? await repo.updateProduct(body, photos: photos)
          : await repo.createProduct(body, photos: photos);

      final status = result['status']?.toString() ?? '';
      final message = result['message']?.toString() ??
          (isEditing ? 'Product updated' : 'Product added successfully');

      if (!mounted) return;

      if (status == 'success') {
        // Refresh stock list in background
        ref.read(stockProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.success),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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

  Future<void> _addCategory(String name) async {
    // Optimistically add to local list first
    setState(() {
      if (!_categories.contains(name)) _categories.add(name);
      _selectedCategory = name;
    });
    try {
      final result = await ref.read(stockRepositoryProvider).createCategory(name);
      final categoryId = result['category_id'];
      if (categoryId != null) {
        setState(() => _categoryIds[name] = categoryId);
      }
      // Refresh categories in background
      ref.read(stockProvider.notifier).refresh();
    } catch (_) {}
  }

  void _addSupplier(String name) {
    // After adding a supplier via the bottom sheet, reload to get its ID
    _loadSuppliers();
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
                          !_isEditing && (v == null || v.isEmpty) ? 'Required' : null,
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
        _isEditing
            ? (_isService ? 'Edit Service' : 'Edit Product')
            : (_isService ? 'Add Service' : 'Add Product'),
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
    final selectedName = _suppliersList
        .where((s) => s['id'] == _selectedSupplierId)
        .map((s) => s['name'] as String)
        .firstOrNull ?? '';
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
                  if (selectedName.isNotEmpty)
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
                          selectedName,
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
                      value: _selectedSupplierId,
                      isExpanded: true,
                      hint: Text(
                        _suppliersList.isEmpty ? 'Loading suppliers…' : 'Select supplier',
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
                        ..._suppliersList.map((s) => DropdownMenuItem(
                          value: s['id'] as String,
                          child: Text(s['name'] as String),
                        )),
                        DropdownMenuItem(
                          value: _addNewSupplierValue,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Flexible(child: Text('Add New Supplier',
                                style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == _addNewSupplierValue) {
                          AddSupplierBottomSheet.show(
                            context: context,
                            onSupplierAdded: _addSupplier,
                          );
                        } else {
                          setState(() => _selectedSupplierId = v);
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
        onPressed: _isSaving ? null : _saveProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textWhite),
              )
            : Text(
                _isEditing
                    ? 'Update ${_isService ? 'Service' : 'Product'}'
                    : 'Save ${_isService ? 'Service' : 'Product'}',
                style: AppTypography.buttonLarge,
              ),
      ),
    );
  }
}
