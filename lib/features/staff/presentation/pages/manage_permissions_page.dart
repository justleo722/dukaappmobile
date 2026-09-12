import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/staff/presentation/providers/staff_provider.dart';

class _PermissionGroup {
  final String title;
  final List<String> permissions;
  const _PermissionGroup({required this.title, required this.permissions});
}

class ManagePermissionsPage extends ConsumerStatefulWidget {
  final String? roleId;
  const ManagePermissionsPage({super.key, this.roleId});

  @override
  ConsumerState<ManagePermissionsPage> createState() => _ManagePermissionsPageState();
}

class _ManagePermissionsPageState extends ConsumerState<ManagePermissionsPage> {
  static const List<_PermissionGroup> _groups = [
    _PermissionGroup(title: 'Management', permissions: [
      'Can Delete Record', 'Can edit profile', 'Can edit password',
      'Can manage sales & Receipt', 'Can manage stock setup', 'Can add attendants',
      'Can manage profit expenses & Cashflow', 'Can manage purchases',
    ]),
    _PermissionGroup(title: 'Sales & Receipt', permissions: [
      'Can make Sales', 'Can Create Invoice', 'Can manage orders', 'Can pay orders',
      'Can view sales reports', 'Can view and manage customers', 'Can Print Receipt',
      'Can enable sales commission',
    ]),
    _PermissionGroup(title: 'Stock Setup', permissions: [
      'Can add new products', 'Can edit stock items', 'Can view stock balance list',
      'Can count and update stock', 'Can add stock‑ins', 'Can manage suppliers',
      'Can record bad stock', 'Can view profit estimate', 'Can view stock value', 'Can view loss',
    ]),
    _PermissionGroup(title: 'Stock Reports', permissions: [
      'Can view reports',
    ]),
    _PermissionGroup(title: 'Profit Expense & Cashflow', permissions: [
      'Can View Profit', 'Can add expenses', 'Can view cash‑in records',
      'Can view cash‑out records', 'Can view Accounts & cash flow report',
      'Can view profit and loss report',
    ]),
    _PermissionGroup(title: 'SMS', permissions: [
      'Can send SMS', 'Can set SMS sender ID', 'Can add contact',
    ]),
    _PermissionGroup(title: 'Email', permissions: [
      'Can send Email',
    ]),
    _PermissionGroup(title: 'Campaign', permissions: [
      'Can add contact category',
    ]),
    _PermissionGroup(title: 'Other', permissions: [
      'Can View Dashboard Summary', 'Can give discounts', 'Can edit daily entries',
      'Can delete daily entries', 'Can backdate entries', 'Can return stock',
      'Can generate barcodes', 'Can preview receipts before printing', 'Can manage warehouse',
    ]),
    _PermissionGroup(title: 'Manufacturing', permissions: [
      'Can manage manufacturing module',
    ]),
    _PermissionGroup(title: 'Online Shop', permissions: [
      'Can manage online shop module',
    ]),
    _PermissionGroup(title: 'Display', permissions: [
      'Enable Category Mode', 'Enable Customer Mode', 'Enable Team Mode',
      'Enable Non‑staff Mode', 'List order items',
    ]),
  ];

  late Map<String, bool> _permissionValues;

  @override
  void initState() {
    super.initState();
    _permissionValues = {};
    for (final group in _groups) {
      for (final p in group.permissions) {
        _permissionValues[p] = false;
      }
    }
  }

  void _toggleAll(bool value) {
    setState(() {
      for (final key in _permissionValues.keys) {
        _permissionValues[key] = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final allEnabled = _permissionValues.values.every((v) => v);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(context),
      body: Column(children: [
        _buildToggleAllBar(allEnabled),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: _groups.length,
          itemBuilder: (ctx, i) => _buildGroup(_groups[i]),
        )),
        _buildDoneButton(context),
      ]),
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
      title: Text('Manage Permissions', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      centerTitle: true,
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.divider)),
    );
  }

  Widget _buildToggleAllBar(bool allEnabled) {
    return Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 10), color: AppColors.card,
      child: Row(children: [
        Icon(allEnabled ? Icons.toggle_on_rounded : Icons.toggle_off_rounded, color: allEnabled ? AppColors.primary : AppColors.textHint, size: 28),
        const SizedBox(width: 8),
        Expanded(child: Text('Toggle All Permissions', style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
        Switch(value: allEnabled, onChanged: _toggleAll, activeThumbColor: AppColors.primary),
      ]),
    );
  }

  Widget _buildGroup(_PermissionGroup group) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 6),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 8), child: Text(group.title,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700))),
        const Divider(height: 1, indent: 16, endIndent: 16),
        ...group.permissions.map((p) => _buildPermissionTile(p)),
      ]),
    );
  }

  Widget _buildPermissionTile(String permission) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
      Row(children: [
        Expanded(child: Text(permission, style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary, fontSize: 13))),
        Switch(
          value: _permissionValues[permission] ?? false,
          onChanged: (v) => setState(() => _permissionValues[permission] = v),
          activeThumbColor: AppColors.primary,
        ),
      ]),
      const Divider(height: 1),
    ]));
  }

  Widget _buildDoneButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: AppConstants.paddingLG, right: AppConstants.paddingLG, top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.divider, width: 1))),
      child: SizedBox(width: double.infinity, height: AppConstants.buttonHeight, child: ElevatedButton.icon(
        onPressed: () async {
          try {
            final repo = ref.read(staffRepositoryProvider);
            final perms = _permissionValues.entries.where((e) => e.value).map((e) => e.key).toList();
            await repo.updatePermission({
              if (widget.roleId != null) 'role_id': widget.roleId,
              'permissions': perms.join(','),
            });
            if (!mounted) return;
          } catch (_) {}
          context.pop();
        },
        icon: const Icon(Icons.check_rounded, size: 18, color: AppColors.textWhite),
        label: Text('Done', style: AppTypography.buttonLarge.copyWith(color: AppColors.textWhite)),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD))),
      )),
    );
  }
}
