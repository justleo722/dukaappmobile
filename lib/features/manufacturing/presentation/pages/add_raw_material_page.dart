import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';

class AddRawMaterialPage extends ConsumerStatefulWidget {
  const AddRawMaterialPage({super.key});

  @override
  ConsumerState<AddRawMaterialPage> createState() => _AddRawMaterialPageState();
}

class _AddRawMaterialPageState extends ConsumerState<AddRawMaterialPage> {
  final _nameController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _initialStockController = TextEditingController();
  final _alertLevelController = TextEditingController(text: '10');

  String _selectedUnit = 'Kilograms (kg)';
  String _selectedAccount = 'Cash';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));
  bool _isSaving = false;

  final List<String> _units = [
    'Kilograms (kg)', 'Grams (g)', 'Milligrams (mg)', 'Pounds (lb)', 'Ounces (oz)',
    'Liters (ltr)', 'Milliliters (ml)', 'Gallons (gal)', 'Pints (pt)', 'Quarts (qt)',
    'Cups', 'Tablespoons (tbsp)', 'Teaspoons (tsp)',
    'Bottle Pieces (pcs)', 'Items', 'Dozen', 'Slice', 'Roll', 'Stick', 'Bar',
    'Packet', 'Box', 'Tray', 'Carton', 'Bag', 'Sack', 'Bundle', 'Pack',
  ];
  final List<String> _accounts = ['Cash', 'Bank', 'Mobile Money'];

  String _unitShort(String full) {
    final m = RegExp(r'\(([^)]+)\)').firstMatch(full);
    return m != null ? m.group(1)! : full.toLowerCase().split(' ').first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitCostController.dispose();
    _initialStockController.dispose();
    _alertLevelController.dispose();
    super.dispose();
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

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.postMfRawMaterialSave({
        'material_name': _nameController.text.trim(),
        'unit': _unitShort(_selectedUnit),
        'unit_cost': _unitCostController.text.trim(),
        'initial_stock': _initialStockController.text.trim(),
        'alert_level': _alertLevelController.text.trim(),
        'expiry_date': '${_expiryDate.year}-${_expiryDate.month.toString().padLeft(2, '0')}-${_expiryDate.day.toString().padLeft(2, '0')}',
      });
      if (!mounted) return;
      final status = result['status']?.toString() ?? '';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(status == 'success' ? 'Raw material saved successfully' : (result['message']?.toString() ?? 'Failed to save')),
        backgroundColor: status == 'success' ? AppColors.success : AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
      ));
      if (status == 'success') context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'), backgroundColor: AppColors.danger,
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
                    _buildFormCard(),
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
      title: Text('Add New Raw Material', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      centerTitle: true,
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.divider)),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Material Information', style: AppTypography.label.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          _buildTextField('Material Name', _nameController, 'e.g. Wheat Flour', TextInputType.text),
          const SizedBox(height: 14),
          _buildDropdown('Unit', _selectedUnit, _units, (v) => setState(() => _selectedUnit = v!)),
          const SizedBox(height: 14),
          _buildTextField('Unit Cost (Tsh)', _unitCostController, '0', TextInputType.number),
          const SizedBox(height: 14),
          _buildTextField('Initial Stock', _initialStockController, '0', TextInputType.number),
          const SizedBox(height: 14),
          _buildTextField('Alert Level', _alertLevelController, '10', TextInputType.number),
          const SizedBox(height: 14),
          _buildDateField('Expiry Date', _expiryDate, _pickExpiryDate),
          const SizedBox(height: 14),
          _buildDropdown('From Account', _selectedAccount, _accounts, (v) => setState(() => _selectedAccount = v!)),
        ],
      ),
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
          onChanged: (_) => setState(() {}),
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

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: DropdownButton<String>(
            value: value, isExpanded: true, underline: const SizedBox(),
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
            items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: AppColors.textHint, size: 18),
                const SizedBox(width: 10),
                Text('${date.day}/${date.month}/${date.year}', style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
              ],
            ),
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
                    : Text('Save Raw Material', style: AppTypography.buttonLarge),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
