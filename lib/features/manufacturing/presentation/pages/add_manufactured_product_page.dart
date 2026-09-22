import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';

class _RawMaterialRow {
  final String name;
  final String unit;
  double quantityToUse;
  final int availableStock;

  _RawMaterialRow({
    required this.name,
    required this.unit,
    required this.quantityToUse,
    required this.availableStock,
  });
}

class AddManufacturedProductPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? productData;

  const AddManufacturedProductPage({super.key, this.productData});

  @override
  ConsumerState<AddManufacturedProductPage> createState() => _AddManufacturedProductPageState();
}

class _AddManufacturedProductPageState extends ConsumerState<AddManufacturedProductPage> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _alertLevelController = TextEditingController(text: '10');
  final _sellingPriceController = TextEditingController();
  final _wholesalePriceController = TextEditingController();

  String? _selectedRecipeId;  // recipe_id as string
  String? _selectedRecipeName;
  int _yieldPerRecipe = 1;
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));
  DateTime _productionDate = DateTime.now();
  List<_RawMaterialRow> _rawMaterials = [];
  bool _isSaving = false;
  bool _isLoadingRecipes = false;

  // Loaded from API: list of raw recipe objects with recipe_id, recipe_name, yield_quantity, ingredients
  List<Map<String, dynamic>> _recipes = [];

  bool get _isEditMode => widget.productData != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecipes());
    if (_isEditMode) {
      final data = widget.productData!;
      _nameController.text = data['name'] ?? '';
      _quantityController.text = (data['quantity'] ?? 1).toString();
      _alertLevelController.text = (data['alertLevel'] ?? 10).toString();
      _sellingPriceController.text = (data['sellingPrice'] ?? 0).toString();
      _wholesalePriceController.text = (data['wholesalePrice'] ?? 0).toString();
      _selectedRecipeId = data['recipe_id']?.toString();
      _selectedRecipeName = data['recipe'];
    }
  }

  Future<void> _loadRecipes() async {
    if (!mounted) return;
    setState(() => _isLoadingRecipes = true);
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getMfRecipes();
      final raw = res.data;
      List<dynamic> list = raw is List ? raw : (raw is Map ? (raw['data'] ?? raw['recipes'] ?? []) : []);
      if (!mounted) return;
      setState(() {
        _recipes = list.whereType<Map<String, dynamic>>().toList();
        // If editing, find the matching recipe to populate materials
        if (_selectedRecipeId != null) {
          _applyRecipeById(_selectedRecipeId!);
        }
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingRecipes = false);
    }
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

  void _applyRecipeById(String recipeId) {
    if (_recipes.isEmpty) return;
    try {
      final recipe = _recipes.firstWhere((r) => r['recipe_id']?.toString() == recipeId);
      final yield_ = double.tryParse((recipe['yield_quantity'] ?? 1).toString()) ?? 1;
      final ingredients = (recipe['ingredients'] as List? ?? []);
      setState(() {
        _selectedRecipeId = recipeId;
        _selectedRecipeName = recipe['recipe_name']?.toString() ?? '';
        _yieldPerRecipe = yield_.toInt().clamp(1, 99999);
        _rawMaterials = ingredients.map((m) {
          final map = m as Map<String, dynamic>;
          return _RawMaterialRow(
            name: map['material_name']?.toString() ?? '',
            unit: map['unit']?.toString() ?? '',
            quantityToUse: double.tryParse((map['quantity_required'] ?? 0).toString()) ?? 0,
            availableStock: (double.tryParse((map['current_stock'] ?? 0).toString()) ?? 0).toInt(),
          );
        }).toList();
      });
    } catch (_) {
      setState(() { _rawMaterials = []; });
    }
  }

  double get _totalCost {
    double total = 0;
    for (final m in _rawMaterials) {
      total += m.quantityToUse * 50;
    }
    return total;
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(
          primary: AppColors.primary, onPrimary: AppColors.textWhite,
          surface: AppColors.card, onSurface: AppColors.textPrimary,
        )),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _pickProductionDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _productionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(
          primary: AppColors.primary, onPrimary: AppColors.textWhite,
          surface: AppColors.card, onSurface: AppColors.textPrimary,
        )),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _productionDate = picked);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final quantity = _quantityController.text.trim();
    final alertLevel = _alertLevelController.text.trim();
    final sellingPrice = _sellingPriceController.text.trim();
    final wholesalePrice = _wholesalePriceController.text.trim();

    if (name.isEmpty || _selectedRecipeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill in product name and select a recipe.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
      ));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiServiceProvider);
      final body = {
        'recipe_id': _selectedRecipeId!,
        'product_name': name,
        'quantity': quantity.isEmpty ? '1' : quantity,
        'selling_price': sellingPrice.isEmpty ? '0' : sellingPrice,
        'wholesale_price': wholesalePrice.isEmpty ? '0' : wholesalePrice,
        'production_date': DateFormat('yyyy-MM-dd').format(_productionDate),
        'expiry_date': DateFormat('yyyy-MM-dd').format(_expiryDate),
        'alert_level': alertLevel.isEmpty ? '10' : alertLevel,
      };
      final data = await api.postMfProductionSave(body);
      final status = data['status']?.toString() ?? '';
      if (!mounted) return;
      if (status == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            _isEditMode ? 'Product updated successfully' : 'Product saved successfully',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
        ));
        context.pop(true);
      } else {
        final msg = data['message']?.toString() ?? 'Failed to save product';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg, style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e', style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
      ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.paddingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildProductInfoCard(),
                    const SizedBox(height: 14),
                    _buildRawMaterialsCard(),
                    const SizedBox(height: 14),
                    _buildCostPricingCard(),
                    const SizedBox(height: 14),
                    _buildDatesCard(),
                    SizedBox(height: 24 + bottomPadding),
                  ],
                ),
              ),
            ),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.card, elevation: 0,
      leading: Padding(padding: const EdgeInsets.all(8.0), child: Container(
        decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
        child: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20)),
      )),
      leadingWidth: 56,
      title: Column(children: [
        Text(
          _isEditMode ? 'Edit Product' : 'Add New Product',
          style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          _isEditMode ? 'Update manufactured product details.' : 'Create a new manufactured product.',
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10),
        ),
      ]),
      centerTitle: true,
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.divider)),
    );
  }

  Widget _buildProductInfoCard() {
    return _formCard(
      title: 'Product Information',
      children: [
        _buildTextField('Product Name', _nameController, 'e.g. Pilau', TextInputType.text),
        const SizedBox(height: 14),
        _buildRecipeDropdown(),
        const SizedBox(height: 14),
        _buildReadOnlyField('Yield per Recipe', '$_yieldPerRecipe units'),
        const SizedBox(height: 14),
        _buildTextField('Quantity', _quantityController, '0', TextInputType.number),
        const SizedBox(height: 14),
        _buildTextField('Alert Level', _alertLevelController, '10', TextInputType.number),
        const SizedBox(height: 14),
        _buildDateField('Expiry Date', _expiryDate, _pickExpiryDate),
      ],
    );
  }

  Widget _buildRawMaterialsCard() {
    return _formCard(
      title: 'Raw Materials Needed',
      subtitle: _selectedRecipeName != null ? 'Linked to: $_selectedRecipeName' : 'Select a recipe first',
      children: [
        if (_rawMaterials.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Center(
              child: Text(
                _selectedRecipeId == null
                    ? 'Select a recipe to view raw materials'
                    : 'No raw materials linked',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
              ),
            ),
          )
        else
          ...List.generate(_rawMaterials.length, (i) {
            final m = _rawMaterials[i];
            return _rawMaterialRow(m, i);
          }),
      ],
    );
  }

  Widget _rawMaterialRow(_RawMaterialRow material, int index) {
    final isLow = material.quantityToUse > material.availableStock;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isLow ? AppColors.danger.withValues(alpha: 0.3) : AppColors.border, width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(material.name, style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('Available: ${material.availableStock} ${material.unit}', style: AppTypography.caption.copyWith(
              color: isLow ? AppColors.danger : AppColors.textSecondary, fontSize: 10,
            )),
          ])),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Quantity to Use', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 10)),
            const SizedBox(height: 4),
            TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTypography.bodySmall,
              controller: TextEditingController(text: material.quantityToUse.toStringAsFixed(1)),
              onChanged: (v) {
                final val = double.tryParse(v) ?? 0;
                setState(() => _rawMaterials[index].quantityToUse = val);
              },
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                filled: true, fillColor: const Color(0xFFF5F7FB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ])),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Unit', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 10)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(8)),
              child: Text(material.unit, style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary)),
            ),
          ])),
        ]),
      ]),
    );
  }

  Widget _buildCostPricingCard() {
    return _formCard(
      title: 'Cost & Pricing',
      children: [
        Row(children: [
          Expanded(child: _buildCostBox('Total Cost', 'Tsh ${_totalCost.toStringAsFixed(0)}')),
          const SizedBox(width: 10),
          Expanded(child: _buildCostBox('Expected Revenue', 'Tsh ${(_totalCost * 1.5).toStringAsFixed(0)}')),
        ]),
        const SizedBox(height: 14),
        _buildTextField('Selling Price (Tsh)', _sellingPriceController, '0', TextInputType.number),
        const SizedBox(height: 14),
        _buildTextField('Wholesale Price (Tsh)', _wholesalePriceController, '0', TextInputType.number),
      ],
    );
  }

  Widget _buildCostBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildDatesCard() {
    return _formCard(
      title: 'Production Date',
      children: [
        _buildDateField('Production Date', _productionDate, _pickProductionDate),
      ],
    );
  }

  Widget _formCard({required String title, String? subtitle, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTypography.label.copyWith(color: AppColors.textPrimary)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11)),
        ],
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }

  Widget _buildRecipeDropdown() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Select Recipe', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: _isLoadingRecipes
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
              )
            : DropdownButton<String>(
                value: _selectedRecipeId,
                isExpanded: true,
                underline: const SizedBox(),
                hint: Text('Choose a recipe', style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint)),
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                items: _recipes.map((r) {
                  final id = r['recipe_id']?.toString() ?? '';
                  final name = r['recipe_name']?.toString() ?? id;
                  return DropdownMenuItem<String>(value: id, child: Text(name));
                }).toList(),
                onChanged: (id) {
                  if (id != null) _applyRecipeById(id);
                },
              ),
      ),
    ]);
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, TextInputType keyboardType) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(
        controller: controller, keyboardType: keyboardType,
        style: AppTypography.bodyMedium,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
          filled: true, fillColor: const Color(0xFFF5F7FB),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5)),
        ),
      ),
    ]);
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: Text(value, style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
      ),
    ]);
  }

  Widget _buildDateField(String label, DateTime date, VoidCallback onTap) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(children: [
            Icon(Icons.calendar_today_rounded, color: AppColors.textHint, size: 18),
            const SizedBox(width: 10),
            Text('${date.day}/${date.month}/${date.year}', style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLG),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(children: [
        Expanded(
          child: SizedBox(
            height: AppConstants.buttonHeight,
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
              ),
              child: Text('Cancel', style: AppTypography.buttonLarge.copyWith(color: AppColors.textSecondary)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: AppConstants.buttonHeight,
            child: ElevatedButton(
              onPressed: (_nameController.text.isNotEmpty && !_isSaving) ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: AppColors.textWhite, elevation: 0,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEditMode ? 'Update Product' : 'Save Product', style: AppTypography.buttonLarge),
            ),
          ),
        ),
      ]),
    );
  }
}
