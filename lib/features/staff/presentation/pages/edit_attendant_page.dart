import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/staff/presentation/providers/staff_provider.dart';

class EditAttendantPage extends ConsumerStatefulWidget {
  final String name;
  final String phone;
  final String role;
  final List<String> shops;
  final String? roleId;

  const EditAttendantPage({super.key, required this.name, required this.phone, required this.role, this.shops = const [], this.roleId});

  @override
  ConsumerState<EditAttendantPage> createState() => _EditAttendantPageState();
}

class _EditAttendantPageState extends ConsumerState<EditAttendantPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final _passwordController = TextEditingController();
  late final TextEditingController _roleController;
  bool _obscurePassword = true;

  String? _selectedAccessLevel;
  late final Set<String> _selectedShops;

  static const List<String> _accessLevels = ['Attendant Access', 'Manager Access'];
  static const List<String> _shops = ['SON COLLECTION', 'DUKA SMART', 'FASHION HOUSE'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _phoneController = TextEditingController(text: widget.phone);
    _roleController = TextEditingController(text: widget.role);
    _selectedShops = Set<String>.from(widget.shops);
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
            _buildTextField(_roleController, 'Enter role title', TextInputType.text),
            const SizedBox(height: 16),
            _buildSection('Access Level'),
            _buildDropdown(_accessLevels, _selectedAccessLevel, (v) => setState(() => _selectedAccessLevel = v)),
            const SizedBox(height: 16),
            _buildSection('Shop to Manage'),
            _buildShopCheckboxes(),
            const SizedBox(height: 20),
            _buildPermissionsButton(context),
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
      title: Text('Edit Attendant', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
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
      decoration: InputDecoration(hintText: 'Enter new password (leave blank to keep current)', hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint, fontSize: 13),
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

  Widget _buildShopCheckboxes() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 6), child: GestureDetector(
      onTap: _showShopPicker,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(border: Border.all(color: AppColors.inputBorder, width: 1.5),
          borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), color: AppColors.card),
        child: Row(children: [
          Expanded(child: _selectedShops.isEmpty
            ? Text('Select shops…', style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint))
            : Wrap(spacing: 6, runSpacing: 4, children: _selectedShops.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(s, style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
              )).toList()),
          ),
          Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint, size: 20),
        ]),
      ),
    ));
  }

  void _showShopPicker() {
    final tempSelected = Set<String>.from(_selectedShops);
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
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Done', style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600))),
            ])),
            const Divider(height: 1),
            Expanded(child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _shops.length,
              itemBuilder: (ctx, i) {
                final shop = _shops[i];
                final isSelected = tempSelected.contains(shop);
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (v) => setModalState(() {
                    if (v == true) { tempSelected.add(shop); } else { tempSelected.remove(shop); }
                  }),
                  title: Text(shop, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
                  activeColor: AppColors.primary,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                );
              },
            )),
          ]),
        ),
      ),
    ).then((_) { _selectedShops.clear(); _selectedShops.addAll(tempSelected); setState(() {}); });
  }

  Widget _buildPermissionsButton(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG), child: SizedBox(
      width: double.infinity, height: AppConstants.buttonHeightSM,
      child: OutlinedButton.icon(
        onPressed: () => context.push('/staff/permissions'),
        icon: Icon(Icons.security_rounded, size: 18, color: AppColors.primary),
        label: Text('Manage Permissions', style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD))),
      ),
    ));
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG), child: Row(children: [
      Expanded(child: SizedBox(height: AppConstants.buttonHeight, child: OutlinedButton(
        onPressed: () => context.pop(),
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary, side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD))),
        child: Text('Cancel', style: AppTypography.buttonLarge.copyWith(color: AppColors.textSecondary)),
      ))),
      const SizedBox(width: 12),
      Expanded(flex: 2, child: SizedBox(height: AppConstants.buttonHeight, child: ElevatedButton.icon(
        onPressed: () async {
          if (!(_formKey.currentState?.validate() ?? false)) return;
          try {
            final repo = ref.read(staffRepositoryProvider);
            await repo.updateMember({
              if (widget.roleId != null) 'role_id': widget.roleId,
              'username': _nameController.text.trim(),
              'phone': _phoneController.text.trim(),
              'role': _roleController.text.trim(),
              if (_passwordController.text.isNotEmpty) 'password': _passwordController.text,
            });
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendant updated'), backgroundColor: Colors.green));
            context.pop();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
          }
        },
        icon: const Icon(Icons.check_rounded, size: 18, color: AppColors.textWhite),
        label: Text('Update Attendant', style: AppTypography.buttonLarge.copyWith(color: AppColors.textWhite)),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD))),
      ))),
    ]));
  }
}
