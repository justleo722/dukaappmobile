import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/staff/presentation/providers/staff_provider.dart';

/// A permission entry: [key] is the DB column name, [label] is the display name.
class _Permission {
  final String key;
  final String label;
  const _Permission(this.key, this.label);
}

class _PermissionGroup {
  final String title;
  final List<_Permission> permissions;
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
      _Permission('can_delete_record',              'Can Delete Record'),
      _Permission('can_edit_profile',               'Can edit profile'),
      _Permission('can_edit_password',              'Can edit password'),
      _Permission('can_manage_sales_receipt',       'Can manage sales & Receipt'),
      _Permission('can_manage_stock_setup',         'Can manage stock setup'),
      _Permission('can_add_attendants',             'Can add attendants'),
      _Permission('can_manage_profit_expenses_cashflow', 'Can manage profit expenses & Cashflow'),
      _Permission('can_manage_purchases',           'Can manage purchases'),
    ]),
    _PermissionGroup(title: 'Sales & Receipt', permissions: [
      _Permission('can_make_sales',         'Can make Sales'),
      _Permission('can_make_invoice',       'Can Create Invoice'),
      _Permission('can_manage_orders',      'Can manage orders'),
      _Permission('can_pay_orders',         'Can pay orders'),
      _Permission('can_view_sales',         'Can view sales reports'),
      _Permission('can_manage_customers',   'Can view and manage customers'),
      _Permission('can_print_receipt',      'Can Print Receipt'),
      _Permission('can_enable_commission',  'Can enable sales commission'),
    ]),
    _PermissionGroup(title: 'Stock Setup', permissions: [
      _Permission('can_add_product',          'Can add new products'),
      _Permission('can_edit_stock',           'Can edit stock items'),
      _Permission('can_view_stock_balance',   'Can view stock balance list'),
      _Permission('can_count_stock',          'Can count and update stock'),
      _Permission('can_add_stockin',          'Can add stock-ins'),
      _Permission('can_view_suppliers',       'Can manage suppliers'),
      _Permission('can_add_bad_stock',        'Can record bad stock'),
      _Permission('can_view_profit_estimate', 'Can view profit estimate'),
      _Permission('can_view_stock_value',     'Can view stock value'),
      _Permission('can_view_loss',            'Can view loss'),
    ]),
    _PermissionGroup(title: 'Stock Reports', permissions: [
      _Permission('can_view_reports', 'Can view reports'),
    ]),
    _PermissionGroup(title: 'Profit Expense & Cashflow', permissions: [
      _Permission('can_view_profit',        'Can View Profit'),
      _Permission('can_add_expense',        'Can add expenses'),
      _Permission('can_view_cashin',        'Can view cash-in records'),
      _Permission('can_view_cashout',       'Can view cash-out records'),
      _Permission('can_manage_cashflow',    'Can view Accounts & cash flow report'),
      _Permission('can_view_profit_report', 'Can view profit and loss report'),
    ]),
    _PermissionGroup(title: 'SMS', permissions: [
      _Permission('can_send_sms',     'Can send SMS'),
      _Permission('can_set_senderid', 'Can set SMS sender ID'),
      _Permission('can_add_contact',  'Can add contact'),
    ]),
    _PermissionGroup(title: 'Email', permissions: [
      _Permission('can_send_email', 'Can send Email'),
    ]),
    _PermissionGroup(title: 'Campaign', permissions: [
      _Permission('can_add_contact_category', 'Can add contact category'),
    ]),
    _PermissionGroup(title: 'Other', permissions: [
      _Permission('can_view_dashboard_summary', 'Can View Dashboard Summary'),
      _Permission('can_give_discount',          'Can give discounts'),
      _Permission('can_edit_entry',             'Can edit daily entries'),
      _Permission('can_delete_entry',           'Can delete daily entries'),
      _Permission('can_backdate_entry',         'Can backdate entries'),
      _Permission('can_return_stock',           'Can return stock'),
      _Permission('can_generate_barcode',       'Can generate barcodes'),
      _Permission('can_preview_receipt',        'Can preview receipts before printing'),
      _Permission('can_manage_warehouse',       'Can manage warehouse'),
    ]),
    _PermissionGroup(title: 'Manufacturing', permissions: [
      _Permission('can_manage_manufacturing', 'Can manage manufacturing module'),
    ]),
    _PermissionGroup(title: 'Online Shop', permissions: [
      _Permission('can_manage_onlineshop', 'Can manage online shop module'),
    ]),
  ];

  /// Map<dbColumnKey, enabled>
  late Map<String, bool> _permissionValues;

  @override
  void initState() {
    super.initState();
    _permissionValues = {};
    for (final group in _groups) {
      for (final p in group.permissions) {
        _permissionValues[p.key] = false;
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

  Widget _buildPermissionTile(_Permission permission) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
      Row(children: [
        Expanded(child: Text(permission.label, style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary, fontSize: 13))),
        Switch(
          value: _permissionValues[permission.key] ?? false,
          onChanged: (v) => setState(() => _permissionValues[permission.key] = v),
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
          if (widget.roleId != null) {
            try {
              final repo = ref.read(staffRepositoryProvider);
              // Backend expects one call per permission: {role_id, col, status}
              for (final entry in _permissionValues.entries) {
                await repo.updatePermission({
                  'role_id': widget.roleId,
                  'col': entry.key,
                  'status': entry.value ? '1' : '0',
                });
              }
            } catch (_) {}
          }
          if (!mounted) return;
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
