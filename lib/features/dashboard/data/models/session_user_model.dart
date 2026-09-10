/// SessionUserModel — parses the `getdata/session_user` API response.
///
/// The API returns all columns from the `roles` table joined with `users`
/// and `shops`. Permission flags (can_*) are returned as 0/1 integers.
///
/// Key fields used for module visibility gating:
///   role            — "owner" | "team"
///   is_manager      — 1 if team member has manager access
///   can_make_sales / can_view_sales
///   can_add_product / can_view_stock_balance / can_edit_stock
///   can_add_stockin / can_view_suppliers
///   can_view_profit / can_add_expense
///   can_view_cashin / can_view_cashout / can_manage_cashflow
///   can_manage_users / can_add_attendants
///   can_manage_manufacturing
///   can_manage_onlineshop
///   subscription_status  — 1 active, 0 expired
///   remaining_days
///   currency
///   username
///   name (full name)

class SessionUserModel {
  const SessionUserModel({
    required this.roleId,
    required this.role,
    required this.isManager,
    required this.username,
    required this.name,
    required this.currency,
    required this.subscriptionStatus,
    required this.remainingDays,
    required this.permissions,
  });

  final int roleId;
  final String role; // "owner" or "team"
  final bool isManager;
  final String username;
  final String name;
  final String currency;
  final int subscriptionStatus;
  final int remainingDays;

  /// All can_* permission flags from the roles table.
  final Map<String, bool> permissions;

  bool get isOwner => role == 'owner';
  bool get isActive => subscriptionStatus == 1;

  bool can(String permission) => isOwner || (permissions[permission] ?? false);

  /// Module visibility helpers — mirrors the groups in dashboard_helper.php.
  bool get canSeeSales =>
      isOwner || can('can_make_sales') || can('can_make_invoice') ||
      can('can_manage_orders') || can('can_pay_orders') ||
      can('can_view_sales') || can('can_manage_customers') ||
      can('can_print_receipt');

  bool get canSeeStock =>
      isOwner || can('can_add_product') || can('can_edit_stock') ||
      can('can_view_stock_balance') || can('can_count_stock') ||
      can('can_add_stockin') || can('can_view_suppliers');

  bool get canSeeProfitExpenses =>
      isOwner || can('can_view_profit') || can('can_add_expense') ||
      can('can_view_profit_report');

  bool get canSeeCashflow =>
      isOwner || can('can_view_cashin') || can('can_view_cashout') ||
      can('can_manage_cashflow');

  bool get canSeePurchases =>
      isOwner || can('can_add_stockin') || can('can_view_suppliers') ||
      can('can_view_reports');

  bool get canSeeStaff =>
      isOwner || can('can_manage_users') || can('can_add_attendants') ||
      can('can_assign_roles');

  bool get canSeeManufacturing =>
      isOwner || can('can_manage_manufacturing');

  bool get canSeeOnlineShop =>
      isOwner || can('can_manage_onlineshop');

  bool get canSeeSettings => isOwner || isManager;

  Map<String, dynamic> toJson() => {
    'role_id'             : roleId,
    'role'                : role,
    'is_manager'          : isManager ? 1 : 0,
    'username'            : username,
    'name'                : name,
    'currency'            : currency,
    'subscription_status' : subscriptionStatus,
    'remaining_days'      : remainingDays,
    ...permissions.map((k, v) => MapEntry(k, v ? 1 : 0)),
  };

  static bool _b(dynamic v) => v == 1 || v == true || v == '1';

  factory SessionUserModel.fromJson(Map<String, dynamic> json) {
    // Collect all can_* fields into the permissions map.
    final permissions = <String, bool>{};
    for (final entry in json.entries) {
      if (entry.key.startsWith('can_')) {
        permissions[entry.key] = _b(entry.value);
      }
    }

    return SessionUserModel(
      roleId: int.tryParse(json['role_id']?.toString() ?? '') ?? 0,
      role: json['role']?.toString() ?? 'team',
      isManager: _b(json['is_manager']),
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? json['username']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'Tsh',
      subscriptionStatus: int.tryParse(json['subscription_status']?.toString() ?? '0') ?? 0,
      remainingDays: int.tryParse(json['remaining_days']?.toString() ?? '0') ?? 0,
      permissions: permissions,
    );
  }
}
