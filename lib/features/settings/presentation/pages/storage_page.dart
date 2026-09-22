import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';

class StoragePage extends ConsumerStatefulWidget {
  const StoragePage({super.key});

  @override
  ConsumerState<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends ConsumerState<StoragePage> {
  bool _isLoading = false;

  // Record counts from storage_usage API
  int _products  = 0;
  int _sales     = 0;
  int _expenses  = 0;
  int _cashflow  = 0;
  int _purchases = 0;
  int _customers = 0;
  int _suppliers = 0;

  // Attendants from storage_summary API
  List<Map<String, dynamic>> _attendants = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final results = await Future.wait([
        api.getStorageUsage(),
        api.getAttendantSettings(),
      ]);

      // --- storage_usage ---
      final usageBody = results[0].data;
      Map<String, dynamic>? usage;
      if (usageBody is Map<String, dynamic>) {
        usage = usageBody['data'] is Map ? usageBody['data'] as Map<String, dynamic> : usageBody;
      }
      if (usage != null) {
        _products  = _toInt(usage['products']);
        _sales     = _toInt(usage['sales']);
        _expenses  = _toInt(usage['expenses']);
        _cashflow  = _toInt(usage['cashflow']);
        _purchases = _toInt(usage['purchases']);
        _customers = _toInt(usage['customers']);
        _suppliers = _toInt(usage['suppliers']);
      }

      // --- attendant_settings ---
      final attBody = results[1].data;
      List rawAtt = [];
      if (attBody is List) {
        rawAtt = attBody;
      } else if (attBody is Map) {
        final d = attBody['data'] ?? attBody['result'] ?? attBody['attendants'];
        if (d is List) rawAtt = d;
      }
      _attendants = rawAtt.whereType<Map<String, dynamic>>().toList();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  int _toInt(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;

  List<Map<String, dynamic>> get _categories => [
    {'title': 'Stock Items',       'records': _products,  'icon': Icons.inventory_2_rounded,          'color': const Color(0xFF2563EB)},
    {'title': 'Sales',             'records': _sales,     'icon': Icons.point_of_sale_rounded,        'color': const Color(0xFF22C55E)},
    {'title': 'Expenses',          'records': _expenses,  'icon': Icons.receipt_long_rounded,         'color': const Color(0xFFF59E0B)},
    {'title': 'Customers',         'records': _customers, 'icon': Icons.people_rounded,               'color': const Color(0xFF9333EA)},
    {'title': 'Purchases Records', 'records': _purchases, 'icon': Icons.shopping_cart_rounded,        'color': const Color(0xFF06B6D4)},
    {'title': 'Cashflow Records',  'records': _cashflow,  'icon': Icons.account_balance_wallet_rounded,'color': const Color(0xFF14B8A6)},
    {'title': 'Suppliers',         'records': _suppliers, 'icon': Icons.local_shipping_rounded,       'color': const Color(0xFF8B5CF6)},
    {'title': 'Logs',              'records': 0,          'icon': Icons.article_rounded,              'color': const Color(0xFF64748B)},
  ];

  void _clearData(String category, int count) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
        title: Text('Clear $category', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to clear all $count $category records? This action cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.textHint),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('Cancel', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$category cleared successfully'), backgroundColor: AppColors.success),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('Clear All', style: AppTypography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
            )),
          ]),
        ],
      ),
    );
  }

  TimeOfDay _parseTime(String? raw, {required int defaultHour}) {
    if (raw == null || raw.isEmpty) return TimeOfDay(hour: defaultHour, minute: 0);
    final parts = raw.split(':');
    final h = int.tryParse(parts[0]) ?? defaultHour;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return TimeOfDay(hour: h, minute: m);
  }

  void _showAttendantDialog(Map<String, dynamic> att) {
    final name = att['username']?.toString() ?? att['name']?.toString() ?? 'Attendant';
    final roleId = att['role_id']?.toString() ?? '';
    TimeOfDay lockTime   = _parseTime(att['auto_lock_time']?.toString(), defaultHour: 8);
    TimeOfDay unlockTime = _parseTime(att['auto_unlock_time']?.toString(), defaultHour: 17);
    bool isSaving = false;

    String formatTime(TimeOfDay t) {
      final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      final m = t.minute.toString().padLeft(2, '0');
      return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
    }

    String toHHMM(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
          title: Text('Control $name Usage', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('App Lock', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            _buildTimePickerRow('Lock Time', formatTime(lockTime), () async {
              final picked = await showTimePicker(context: ctx, initialTime: lockTime);
              if (picked != null) setDialogState(() => lockTime = picked);
            }),
            const SizedBox(height: 10),
            _buildTimePickerRow('Unlock Time', formatTime(unlockTime), () async {
              final picked = await showTimePicker(context: ctx, initialTime: unlockTime);
              if (picked != null) setDialogState(() => unlockTime = picked);
            }),
          ])),
          actions: [
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.textHint),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('Close', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: isSaving ? null : () async {
                  setDialogState(() => isSaving = true);
                  try {
                    final api = ref.read(apiServiceProvider);
                    final result = await api.postSettingsAttendantSaveAccess({
                      'role_id': roleId,
                      'lock_time': toHHMM(lockTime),
                      'unlock_time': toHHMM(unlockTime),
                    });
                    if (!ctx.mounted) return;
                    Navigator.of(ctx).pop();
                    final status = result['status']?.toString() ?? '';
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(status == 'success' ? '$name settings saved' : (result['message']?.toString() ?? 'Failed to save')),
                      backgroundColor: status == 'success' ? AppColors.success : AppColors.danger,
                    ));
                  } catch (e) {
                    if (!ctx.mounted) return;
                    setDialogState(() => isSaving = false);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error: $e'), backgroundColor: AppColors.danger));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Save', style: AppTypography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickerRow(String label, String time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textHint.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
        ),
        child: Row(children: [
          const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          Text(time, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cats = _categories;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.card, elevation: 0,
        leading: Padding(padding: const EdgeInsets.all(8.0), child: Container(
          decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
          child: IconButton(
            onPressed: () => context.go('/shop-settings'),
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
          ),
        )),
        leadingWidth: 56,
        title: Text('Storage', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary, size: 20),
          ),
        ],
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: SizedBox(height: 1)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionTitle('Clear Shop Data', Icons.delete_sweep_rounded, const Color(0xFFEF4444)),
                const SizedBox(height: 12),
                _buildCard(child: Column(children: cats.asMap().entries.map((entry) {
                  final i   = entry.key;
                  final cat = entry.value;
                  final isLogs = cat['title'] == 'Logs';
                  return Column(children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (cat['color'] as Color).withOpacity(0.1),
                        child: Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 20),
                      ),
                      title: Text(cat['title'], style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                      subtitle: Text(isLogs ? 'System activity logs' : '${cat['records']} records', style: AppTypography.caption.copyWith(fontSize: 11)),
                      trailing: isLogs
                          ? TextButton(onPressed: () => context.push('/shop-settings/storage/system-logs'), child: const Text('View'))
                          : TextButton(
                              onPressed: () => _clearData(cat['title'], cat['records'] as int),
                              child: Text('Clear', style: TextStyle(color: AppColors.danger)),
                            ),
                    ),
                    if (i < cats.length - 1) const Divider(height: 1),
                  ]);
                }).toList())),
                const SizedBox(height: 24),
                _buildSectionTitle('Attendant Settings', Icons.people_alt_rounded, const Color(0xFF9333EA)),
                const SizedBox(height: 12),
                _attendants.isEmpty
                    ? _buildCard(child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: Text('No attendants found', style: TextStyle(color: AppColors.textHint))),
                      ))
                    : _buildCard(child: Column(children: _attendants.asMap().entries.map((entry) {
                        final i   = entry.key;
                        final att = entry.value;
                        final name = att['username']?.toString() ?? att['name']?.toString() ?? 'Attendant';
                        return Column(children: [
                          ListTile(
                            onTap: () => _showAttendantDialog(att),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                            ),
                            title: Text(name, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              att['staff_role']?.toString() ?? att['role']?.toString() ?? 'Attendant',
                              style: AppTypography.caption.copyWith(fontSize: 10),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
                          ),
                          if (i < _attendants.length - 1) const Divider(height: 1),
                        ]);
                      }).toList())),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 8),
      Text(title, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
      elevation: 1,
      child: child,
    );
  }
}
