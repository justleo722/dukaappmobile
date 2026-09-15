/// Data models for the Staff module.
class Attendant {
  final dynamic roleId;
  final String? userId;    // users.user_id — displayed in the card
  final String name;
  final String phone;
  final String email;
  final String role;       // 'team' | 'waiter'
  final bool isManager;
  final String status;     // 'active' | 'inactive'
  final String? attendantId;
  final String? shopId;
  final String staffRole;

  const Attendant({
    required this.roleId,
    this.userId,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    required this.isManager,
    required this.status,
    this.attendantId,
    this.shopId,
    this.staffRole = 'Normal Attendant',
  });

  bool get isActive => status == 'active' || status == '1';

  factory Attendant.fromJson(Map<String, dynamic> j) {
    return Attendant(
      roleId: j['role_id'],
      userId: j['user_id']?.toString(),
      name: j['username']?.toString() ?? j['name']?.toString() ?? '',
      phone: j['phone']?.toString() ?? '',
      email: j['email']?.toString() ?? '',
      role: j['role']?.toString() ?? 'team',
      isManager: (j['is_manager'] == 1 || j['is_manager'] == true || j['is_manager'] == '1'),
      status: j['status']?.toString() ?? 'active',
      attendantId: j['attendant_id']?.toString(),
      shopId: j['shop_id']?.toString(),
      staffRole: j['staff_role']?.toString() ?? 'Normal Attendant',
    );
  }
}
