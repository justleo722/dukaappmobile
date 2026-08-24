import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

class _Ingredient {
  String material;
  String quantity;
  String unit;

  _Ingredient({this.material = '', this.quantity = '1', this.unit = 'kg'});
}

class EditRecipePage extends StatefulWidget {
  final String name;
  final String yieldAmount;
  final List<String> ingredients;
  final double estimatedCost;

  const EditRecipePage({
    super.key,
    required this.name,
    required this.yieldAmount,
    required this.ingredients,
    required this.estimatedCost,
  });

  @override
  State<EditRecipePage> createState() => _EditRecipePageState();
}

class _EditRecipePageState extends State<EditRecipePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _yieldController;
  late final List<_Ingredient> _ingredients = [];

  static const List<String> _materials = [
    'Cotton Fabric (White)', 'Polyester Thread', 'Denim Fabric',
    'Zipper (Metal)', 'Button (Plastic)', 'Elastic Band',
    'Fabric Dye (Blue)', 'Bleach Solution', 'Interfacing Cloth',
    'Sewing Needles', 'Linen Fabric', 'Silk Thread',
  ];

  static const List<String> _units = [
    'Kilograms (kg)', 'Grams (g)', 'Milligrams (mg)', 'Pounds (lb)', 'Ounces (oz)',
    'Liters (ltr)', 'Milliliters (ml)', 'Gallons (gal)', 'Pints (pt)', 'Quarts (qt)',
    'Cups', 'Tablespoons (tbsp)', 'Teaspoons (tsp)',
    'Bottle Pieces (pcs)', 'Items', 'Dozen', 'Slice', 'Roll', 'Stick', 'Bar',
    'Packet', 'Box', 'Tray', 'Carton', 'Bag', 'Sack', 'Bundle', 'Pack',
  ];

  static const Map<String, double> _materialCosts = {
    'Cotton Fabric (White)': 3500,
    'Polyester Thread': 1200,
    'Denim Fabric': 5500,
    'Zipper (Metal)': 200,
    'Button (Plastic)': 50,
    'Elastic Band': 150,
    'Fabric Dye (Blue)': 4500,
    'Bleach Solution': 2200,
    'Interfacing Cloth': 1800,
    'Sewing Needles': 300,
    'Linen Fabric': 6000,
    'Silk Thread': 2500,
  };

  double get _totalCost {
    double total = 0;
    for (final ing in _ingredients) {
      final cost = _materialCosts[ing.material] ?? 0;
      final qty = double.tryParse(ing.quantity) ?? 0;
      total += cost * qty;
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _yieldController = TextEditingController(text: widget.yieldAmount);
    for (final name in widget.ingredients) {
      _ingredients.add(_Ingredient(material: name, quantity: '1', unit: 'kg'));
    }
    if (_ingredients.isEmpty) _ingredients.add(_Ingredient());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yieldController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    setState(() => _ingredients.add(_Ingredient()));
  }

  void _removeIngredient(int index) {
    if (_ingredients.length <= 1) return;
    setState(() => _ingredients.removeAt(index));
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
                    _buildRecipeInfoCard(),
                    const SizedBox(height: 14),
                    _buildIngredientsSection(),
                    const SizedBox(height: 14),
                    _buildTotalCostCard(),
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
      title: Text('Edit Recipe', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      centerTitle: true,
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.divider)),
    );
  }

  Widget _buildRecipeInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recipe Information', style: AppTypography.label.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          _buildTextField('Recipe Name', _nameController, 'e.g. Bread Large', TextInputType.text),
          const SizedBox(height: 14),
          _buildTextField('Yield Quantity', _yieldController, '1', TextInputType.number),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Ingredients', style: AppTypography.label.copyWith(color: AppColors.textPrimary)),
              const Spacer(),
              Text('${_ingredients.length} item${_ingredients.length == 1 ? '' : 's'}',
                style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(_ingredients.length, (i) => _buildIngredientRow(i)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _addIngredient,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 6),
                  Text('Add Ingredient', style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientRow(int index) {
    final ing = _ingredients[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildInlineDropdown('Material', ing.material, ['Select material', ..._materials], (v) {
                  setState(() => ing.material = v == 'Select material' ? '' : v!);
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _buildInlineTextField('Qty', ing.quantity, TextInputType.number, (v) {
                  setState(() => ing.quantity = v);
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _buildInlineDropdown('Unit', ing.unit, _units, (v) => setState(() => ing.unit = v!)),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _removeIngredient(index),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                  child: Icon(Icons.delete_rounded, size: 14, color: AppColors.danger),
                ),
              ),
            ],
          ),
          if (ing.material.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 12, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  'Unit cost: ${_fmt(_materialCosts[ing.material] ?? 0)} × ${ing.quantity} = ${_fmt((_materialCosts[ing.material] ?? 0) * (double.tryParse(ing.quantity) ?? 0))}',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInlineDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    final isValidValue = value.isNotEmpty && items.contains(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.textHint, fontSize: 9)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(color: const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.inputBorder)),
          child: DropdownButton<String>(
            value: isValidValue ? value : null,
            isExpanded: true, underline: const SizedBox(),
            hint: Text(items.first, style: AppTypography.caption.copyWith(color: AppColors.textHint, fontSize: 10)),
            style: AppTypography.caption.copyWith(color: AppColors.textPrimary, fontSize: 10),
            items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: AppTypography.caption.copyWith(fontSize: 10)))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildInlineTextField(String label, String value, TextInputType keyboardType, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.textHint, fontSize: 9)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(color: const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.inputBorder)),
          child: TextField(
            controller: TextEditingController(text: value),
            keyboardType: keyboardType,
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600, fontSize: 10),
            decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 8)),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, TextInputType keyboardType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildTotalCostCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.attach_money_rounded, color: AppColors.success, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Cost', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(_fmt(_totalCost), style: AppTypography.h6.copyWith(color: AppColors.success, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(6)),
            child: Text('${_ingredients.where((i) => i.material.isNotEmpty).length} materials',
              style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLG),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
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
                onPressed: _nameController.text.isNotEmpty ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Recipe updated successfully', style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
                    ),
                  );
                  context.pop();
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: AppColors.textWhite, elevation: 0,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
                ),
                child: Text('Update Recipe', style: AppTypography.buttonLarge),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    return 'Tsh ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }
}
