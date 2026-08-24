import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

class EditManufacturedProductPage extends StatelessWidget {
  final String name;
  final String recipe;
  final int quantity;
  final double unitCost;
  final double sellingPrice;
  final double wholesalePrice;
  final int alertLevel;

  const EditManufacturedProductPage({
    super.key,
    required this.name,
    required this.recipe,
    required this.quantity,
    required this.unitCost,
    required this.sellingPrice,
    this.wholesalePrice = 0,
    this.alertLevel = 10,
  });

  @override
  Widget build(BuildContext context) {
    return _EditProductForm(
      productData: {
        'name': name,
        'recipe': recipe,
        'quantity': quantity,
        'unitCost': unitCost,
        'sellingPrice': sellingPrice,
        'wholesalePrice': wholesalePrice,
        'alertLevel': alertLevel,
      },
    );
  }
}

class _EditProductForm extends StatefulWidget {
  final Map<String, dynamic> productData;
  const _EditProductForm({required this.productData});

  @override
  State<_EditProductForm> createState() => _EditProductFormState();
}

class _EditProductFormState extends State<_EditProductForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _alertLevelController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _wholesalePriceController;

  String? _selectedRecipe;
  int _yieldPerRecipe = 1;
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));
  DateTime _productionDate = DateTime.now();

  final List<Map<String, dynamic>> _recipes = [
    {'name': 'Basic Tee', 'yield': 10, 'materials': [
      {'name': 'Cotton Fabric', 'unit': 'meters', 'qty': 5.0, 'stock': 120},
      {'name': 'Thread', 'unit': 'rolls', 'qty': 2.0, 'stock': 80},
      {'name': 'Dye', 'unit': 'liters', 'qty': 1.0, 'stock': 50},
    ]},
    {'name': 'Slim Fit Denim', 'yield': 8, 'materials': [
      {'name': 'Denim Fabric', 'unit': 'meters', 'qty': 6.0, 'stock': 90},
      {'name': 'Zipper', 'unit': 'pcs', 'qty': 1.0, 'stock': 200},
      {'name': 'Button', 'unit': 'pcs', 'qty': 3.0, 'stock': 300},
    ]},
    {'name': 'Winter Hoodie', 'yield': 5, 'materials': [
      {'name': 'Fleece Fabric', 'unit': 'meters', 'qty': 8.0, 'stock': 60},
      {'name': 'Zipper', 'unit': 'pcs', 'qty': 1.0, 'stock': 200},
      {'name': 'Drawstring', 'unit': 'pcs', 'qty': 1.0, 'stock': 150},
    ]},
    {'name': 'Casual Linen', 'yield': 12, 'materials': [
      {'name': 'Linen Fabric', 'unit': 'meters', 'qty': 4.0, 'stock': 75},
      {'name': 'Thread', 'unit': 'rolls', 'qty': 1.5, 'stock': 80},
    ]},
    {'name': 'Active Shorts', 'yield': 15, 'materials': [
      {'name': 'Polyester Fabric', 'unit': 'meters', 'qty': 3.0, 'stock': 100},
      {'name': 'Elastic Band', 'unit': 'meters', 'qty': 1.0, 'stock': 90},
      {'name': 'Drawstring', 'unit': 'pcs', 'qty': 1.0, 'stock': 150},
    ]},
  ];

  @override
  void initState() {
    super.initState();
    final data = widget.productData;
    _nameController = TextEditingController(text: data['name'] ?? '');
    _quantityController = TextEditingController(text: '${data['quantity'] ?? 1}');
    _alertLevelController = TextEditingController(text: '${data['alertLevel'] ?? 10}');
    _sellingPriceController = TextEditingController(text: '${data['sellingPrice'] ?? 0}');
    _wholesalePriceController = TextEditingController(text: '${data['wholesalePrice'] ?? 0}');
    _selectedRecipe = data['recipe'];
    _loadRecipeMaterials();
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

  void _loadRecipeMaterials() {
    if (_selectedRecipe == null) return;
    final recipe = _recipes.firstWhere((r) => r['name'] == _selectedRecipe);
    _yieldPerRecipe = recipe['yield'] as int;
  }

  Future<void> _pickDate({required bool isExpiry}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isExpiry ? _expiryDate : _productionDate,
      firstDate: isExpiry ? DateTime.now() : DateTime(2020),
      lastDate: isExpiry ? DateTime(2100) : DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(
          primary: AppColors.primary, onPrimary: AppColors.textWhite,
          surface: AppColors.card, onSurface: AppColors.textPrimary,
        )),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isExpiry) {
          _expiryDate = picked;
        } else {
          _productionDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.card, elevation: 0,
        leading: Padding(padding: const EdgeInsets.all(8.0), child: Container(
          decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
          child: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20)),
        )),
        leadingWidth: 56,
        title: Column(children: [
          Text('Edit Product', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('Update manufactured product details.', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10)),
        ]),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.divider)),
      ),
      body: SafeArea(
        top: false,
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLG),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 8),
                _formCard('Product Information', [
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
                  _buildDateField('Expiry Date', _expiryDate, () => _pickDate(isExpiry: true)),
                ]),
                const SizedBox(height: 14),
                _formCard('Cost & Pricing', [
                  _buildTextField('Selling Price (Tsh)', _sellingPriceController, '0', TextInputType.number),
                  const SizedBox(height: 14),
                  _buildTextField('Wholesale Price (Tsh)', _wholesalePriceController, '0', TextInputType.number),
                ]),
                const SizedBox(height: 14),
                _formCard('Production Date', [
                  _buildDateField('Production Date', _productionDate, () => _pickDate(isExpiry: false)),
                ]),
                SizedBox(height: 24 + bottomPadding),
              ]),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingLG),
            decoration: BoxDecoration(color: AppColors.card, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2))]),
            child: Row(children: [
              Expanded(child: SizedBox(height: AppConstants.buttonHeight, child: OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary, side: const BorderSide(color: AppColors.border, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD))),
                child: Text('Cancel', style: AppTypography.buttonLarge.copyWith(color: AppColors.textSecondary)),
              ))),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: SizedBox(height: AppConstants.buttonHeight, child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Product updated successfully', style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
                  ));
                  context.pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.textWhite, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD))),
                child: Text('Update Product', style: AppTypography.buttonLarge),
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
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTypography.label.copyWith(color: AppColors.textPrimary)),
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
        decoration: BoxDecoration(color: const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), border: Border.all(color: AppColors.inputBorder)),
        child: DropdownButton<String>(
          value: _selectedRecipe, isExpanded: true, underline: const SizedBox(),
          hint: Text('Choose a recipe', style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint)),
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          items: _recipes.map((r) => DropdownMenuItem(value: r['name'] as String, child: Text(r['name'] as String))).toList(),
          onChanged: (v) => setState(() { _selectedRecipe = v; _loadRecipeMaterials(); }),
        ),
      ),
    ]);
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, TextInputType keyboardType) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(controller: controller, keyboardType: keyboardType, style: AppTypography.bodyMedium,
        decoration: InputDecoration(hintText: hint, hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint), filled: true, fillColor: const Color(0xFFF5F7FB),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5)),
        )),
    ]);
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), border: Border.all(color: AppColors.primary.withValues(alpha: 0.15))),
        child: Text(value, style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600))),
    ]);
  }

  Widget _buildDateField(String label, DateTime date, VoidCallback onTap) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      GestureDetector(onTap: onTap, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), border: Border.all(color: AppColors.inputBorder)),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded, color: AppColors.textHint, size: 18),
          const SizedBox(width: 10),
          Text('${date.day}/${date.month}/${date.year}', style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
        ]),
      )),
    ]);
  }
}
