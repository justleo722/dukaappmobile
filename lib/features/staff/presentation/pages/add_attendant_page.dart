import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/staff/presentation/providers/staff_provider.dart';

class AddAttendantPage extends ConsumerStatefulWidget {
  const AddAttendantPage({super.key});

  @override
  ConsumerState<AddAttendantPage> createState() => _AddAttendantPageState();
}

class _AddAttendantPageState extends ConsumerState<AddAttendantPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _roleController = TextEditingController(text: 'Normal Attendant');
  bool _obscurePassword = true;
  bool _isSaving = false;

  String? _selectedAccessLevel;
  // shops from API: {shop_id, shop_name}
  List<Map<String, dynamic>> _availableShops = [];
  final Set<String> _selectedShopIds = {};
  bool _loadingShops = true;

  static const List<String> _accessLevels = ['Attendant Access', 'Manager Access'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadShops());
  }

  Future<void> _loadShops() async {
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getMyShops();
      final raw = res.data;
      List<dynamic> list = [];
      if (raw is List) {
        list = raw;
      } else if (raw is Map) {
        final d = raw['data'] ?? raw['shops'] ?? raw['result'] ?? [];
        if (d is List) list = d;
      }
      if (!mounted) return;
      setState(() {
        _availableShops = list.whereType<Map<String, dynamic>>().toList();
        _loadingShops = false;
        // pre-select current shop if only one
        if (_availableShops.length == 1) {
          final id = (_availableShops.first['shop_id'] ?? '').toString();
          if (id.isNotEmpty) _selectedShopIds.add(id);
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingShops = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 16),
            _buildSection('Full Name'),
            _buildTextField(_nameController, 'Enter full name', TextInputType.text),
            const SizedBox(height: 16),
            _buildSection('Phone Number'),
            _buildTextField(_phoneController, 'Enter phone number', TextInputType.phone),
            const SizedBox(height: 16),
            _buildSection('Password'),
            _buildPasswordField(),
            const SizedBox(height: 16),
            _buildSection('Role Title'),
            _buildTextField(_roleController, 'e.g. Cashier, Salesperson', TextInputType.text),
            const SizedBox(height: 16),
            _buildSection('Access Level'),
            _buildDropdown(_accessLevels, _selectedAccessLevel, (v) => setState(() => _selectedAccessLevel = v)),
            const SizedBox(height: 16),
            _buildSection('Shop(s) to Manage'),
            _buildShopSelector(),
            const SizedBox(height: 30),
            _buildActionButtons(context),
          ]),
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
      title: Text('Add New Attendant', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      centerTitle: true,
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.divider)),
    );
  }

  Widget _buildSection(String label) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG), child: Text(label,
      style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)));
  }

  Widget _buildTextField(TextEditingController controller, String hint, TextInputType type) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 6), child: TextField(
      controller: controller, keyboardType: type, style: AppTypography.bodyMedium,
      decoration: InputDecoration(hintText: hint, hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
        filled: true, fillColor: AppColors.card, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5)),
      ),
    ));
  }

  Widget _buildPasswordField() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 6), child: TextField(
      controller: _passwordController, obscureText: _obscurePassword, style: AppTypography.bodyMedium,
      decoration: InputDecoration(hintText: 'Enter password', hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
        filled: true, fillColor: AppColors.card, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        suffixIcon: IconButton(onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.textHint, size: 20)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5)),
      ),
    ));
  }

  Widget _buildDropdown(List<String> items, String? value, ValueChanged<String?> onChanged) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 6), child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(border: Border.all(color: AppColors.inputBorder, width: 1.5), borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), color: AppColors.card),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: value, isExpanded: true,
        hint: Text('Select…', style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint)),
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint, size: 20),
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        onChanged: onChanged,
      )),
    ));
  }

  Widget _buildShopSelector() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 6), child: GestureDetector(
      onTap: _loadingShops ? null : _showShopPicker,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(border: Border.all(color: AppColors.inputBorder, width: 1.5),
          borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), color: AppColors.card),
        child: Row(children: [
          Expanded(child: _loadingShops
            ? Text('Loading shops…', style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint))
            : _selectedShopIds.isEmpty
              ? Text('Select shops…', style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint))
              : Wrap(spacing: 6, runSpacing: 4, children: _selectedShopIds.map((id) {
                  final shop = _availableShops.firstWhere(
                    (s) => s['shop_id'].toString() == id,
                    orElse: () => {'shop_name': id},
                  );
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(shop['shop_name']?.toString() ?? id, style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  );
                }).toList()),
          ),
          Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint, size: 20),
        ]),
      ),
    ));
  }

  void _showShopPicker() {
    final tempSelected = Set<String>.from(_selectedShopIds);
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.45,
          decoration: const BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0), child: Row(children: [
              Expanded(child: Text('Select Shops', style: AppTypography.h6.copyWith(fontWeight: FontWeight.w700))),
              TextButton(onPressed: () { Navigator.pop(ctx); setState(() { _selectedShopIds.clear(); _selectedShopIds.addAll(tempSelected); }); },
                child: Text('Done', style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600))),
            ])),
            const Divider(height: 1),
            Expanded(child: _availableShops.isEmpty
              ? Center(child: Text('No shops found', style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _availableShops.length,
                  itemBuilder: (ctx, i) {
                    final shop = _availableShops[i];
                    final id = (shop['shop_id'] ?? '').toString();
                    final name = (shop['shop_name'] ?? shop['name'] ?? id).toString();
                    final isSelected = tempSelected.contains(id);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (v) => setModalState(() {
                        if (v == true) { tempSelected.add(id); } else { tempSelected.remove(id); }
                      }),
                      title: Text(name, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
                      activeColor: AppColors.primary,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    );
                  },
                )),
          ]),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG), child: Row(children: [
      Expanded(child: SizedBox(height: AppConstants.buttonHeight, child: OutlinedButton(
        onPressed: _isSaving ? null : () => context.pop(),
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary, side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD))),
        child: Text('Cancel', style: AppTypography.buttonLarge.copyWith(color: AppColors.textSecondary)),
      ))),
      const SizedBox(width: 12),
      Expanded(flex: 2, child: SizedBox(height: AppConstants.buttonHeight, child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _save,
        icon: _isSaving
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppColors.textWhite, strokeWidth: 2))
          : const Icon(Icons.check_rounded, size: 18, color: AppColors.textWhite),
        label: Text('Save Attendant', style: AppTypography.buttonLarge.copyWith(color: AppColors.textWhite)),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD))),
      ))),
    ]));
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final staffRole = _roleController.text.trim();

    if (name.isEmpty) {
      _snack('Enter full name', AppColors.warning); return;
    }
    if (phone.isEmpty) {
      _snack('Enter phone number', AppColors.warning); return;
    }
    if (password.isEmpty) {
      _snack('Enter password', AppColors.warning); return;
    }
    if (_selectedShopIds.isEmpty) {
      _snack('Select at least one shop', AppColors.warning); return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(staffRepositoryProvider);
      final isManager = _selectedAccessLevel == 'Manager Access';

      // PHP reads shops[] as array — use bracket notation like items[]
      final body = <String, dynamic>{
        'username': name,
        'phone': phone,
        'password': password,
        'staff_role': staffRole.isEmpty ? 'Normal Attendant' : staffRole,
        'is_manager': isManager ? '1' : '0',
        'shops_submitted': '1',
        for (int i = 0; i < _selectedShopIds.length; i++)
          'shops[$i]': _selectedShopIds.elementAt(i),
      };

      final res = await repo.addStaff(body);
      if (!mounted) return;
      final status = res['status']?.toString() ?? '';
      final message = res['message']?.toString() ?? 'Done';
      if (status == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
        context.pop();
      } else {
        _snack(message, AppColors.danger);
      }
    } catch (e) {
      if (!mounted) return;
      _snack('Failed: $e', AppColors.danger);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM))),
    );
  }
}
