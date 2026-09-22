import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';

class _Ingredient {
  String materialId;
  String materialName;
  String quantity;
  String unit;

  _Ingredient({this.materialId = '', this.materialName = '', this.quantity = '1', this.unit = 'kg'});
}

class CreateRecipePage extends ConsumerStatefulWidget {
  const CreateRecipePage({super.key});

  @override
  ConsumerState<CreateRecipePage> createState() => _CreateRecipePageState();
}

class _CreateRecipePageState extends ConsumerState<CreateRecipePage> {
  final _nameController = TextEditingController();
  final _yieldController = TextEditingController(text: '1');
  final List<_Ingredient> _ingredients = [_Ingredient()];

  List<Map<String, dynamic>> _rawMaterials = [];
  bool _isLoadingMaterials = false;
  bool _isSaving = false;

  static const List<String> _units = [
    'kg', 'g', 'mg', 'lb', 'oz',
    'ltr', 'ml', 'gal', 'pint', 'qt',
    'cups', 'tbsp', 'tsp',
    'pcs', 'items', 'dozen', 'slice', 'roll', 'stick', 'bar',
    'packet', 'box', 'tray', 'carton', 'bag', 'sack', 'bundle', 'pack',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMaterials());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yieldController.dispose();
    super.dispose();
  }

  Future<void> _loadMaterials() async {
    if (!mounted) return;
    setState(() => _isLoadingMaterials = true);
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getMfRawMaterials();
      final raw = res.data;
      final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? raw['materials'] ?? []) : []);
      if (!mounted) return;
      setState(() {
        _rawMaterials = (list as List).whereType<Map<String, dynamic>>().toList();
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingMaterials = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final validIngredients = _ingredients
        .where((i) => i.materialId.isNotEmpty && (double.tryParse(i.quantity) ?? 0) > 0)
        .toList();

    if (validIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Add at least one ingredient.',
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
      // Backend expects: recipe_name, yield_quantity, ingredients as JSON string
      // Each ingredient: raw_material_id, quantity_required, unit
      final ingredientsData = validIngredients.map((i) => {
        'raw_material_id': i.materialId,
        'quantity_required': i.quantity,
        'unit': i.unit,
      }).toList();

      final body = {
        'recipe_name': name,
        'yield_quantity': _yieldController.text.trim().isEmpty ? '1' : _yieldController.text.trim(),
        'ingredients': ingredientsData,
      };

      final result = await api.postMfRecipeSave(body);
      if (!mounted) return;
      final status = result['status']?.toString() ?? '';
      if (status == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Recipe saved successfully',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
        ));
        context.pop(true);
      } else {
        final msg = result['message']?.toString() ?? 'Failed to save recipe';
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
      title: Text('Create New Recipe', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
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
              if (_isLoadingMaterials)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              else
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
    final materialItems = _rawMaterials.map((m) {
      final id = m['raw_material_id']?.toString() ?? m['id']?.toString() ?? '';
      final name = m['material_name']?.toString() ?? m['name']?.toString() ?? id;
      return DropdownMenuItem<String>(value: id, child: Text(name, style: AppTypography.caption.copyWith(fontSize: 10)));
    }).toList();
    final isValidMaterial = ing.materialId.isNotEmpty && _rawMaterials.any((m) =>
        (m['raw_material_id']?.toString() ?? m['id']?.toString() ?? '') == ing.materialId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Material', style: AppTypography.caption.copyWith(color: AppColors.textHint, fontSize: 9)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(color: const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.inputBorder)),
                  child: _isLoadingMaterials
                      ? const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)))
                      : DropdownButton<String>(
                          value: isValidMaterial ? ing.materialId : null,
                          isExpanded: true, underline: const SizedBox(),
                          hint: Text('Select', style: AppTypography.caption.copyWith(color: AppColors.textHint, fontSize: 10)),
                          items: materialItems,
                          onChanged: (id) {
                            final mat = _rawMaterials.firstWhere(
                              (m) => (m['raw_material_id']?.toString() ?? m['id']?.toString() ?? '') == id,
                              orElse: () => {},
                            );
                            setState(() {
                              ing.materialId = id ?? '';
                              ing.materialName = mat['material_name']?.toString() ?? mat['name']?.toString() ?? '';
                            });
                          },
                        ),
                ),
              ],
            ),
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
    );
  }

  Widget _buildInlineDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    final isValid = items.contains(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.textHint, fontSize: 9)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(color: const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.inputBorder)),
          child: DropdownButton<String>(
            value: isValid ? value : null,
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
                onPressed: (_nameController.text.isNotEmpty && !_isSaving) ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: AppColors.textWhite, elevation: 0,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Save Recipe', style: AppTypography.buttonLarge),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
