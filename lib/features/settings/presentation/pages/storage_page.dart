import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

class StoragePage extends StatefulWidget {
  const StoragePage({super.key});

  @override
  State<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends State<StoragePage> {
  final List<Map<String, dynamic>> _categories = [
    {'title': 'Stock Items', 'records': 1247, 'icon': Icons.inventory_2_rounded, 'color': const Color(0xFF2563EB)},
    {'title': 'Sales', 'records': 8532, 'icon': Icons.point_of_sale_rounded, 'color': const Color(0xFF22C55E)},
    {'title': 'Expenses', 'records': 2156, 'icon': Icons.receipt_long_rounded, 'color': const Color(0xFFF59E0B)},
    {'title': 'Customers', 'records': 4321, 'icon': Icons.people_rounded, 'color': const Color(0xFF9333EA)},
    {'title': 'Purchases Records', 'records': 987, 'icon': Icons.shopping_cart_rounded, 'color': const Color(0xFF06B6D4)},
    {'title': 'Cashflow Records', 'records': 3421, 'icon': Icons.account_balance_wallet_rounded, 'color': const Color(0xFF14B8A6)},
    {'title': 'Suppliers', 'records': 156, 'icon': Icons.local_shipping_rounded, 'color': const Color(0xFF8B5CF6)},
    {'title': 'Logs', 'records': 0, 'icon': Icons.article_rounded, 'color': const Color(0xFF64748B)},
  ];

  final List<Map<String, dynamic>> _attendants = [
    {'name': 'ANNA', 'autoLock': 'No automatic lock set', 'todayMb': '2.4', 'totalMb': '156.8'},
    {'name': 'JANETH', 'autoLock': 'No automatic lock set', 'todayMb': '1.8', 'totalMb': '98.5'},
    {'name': 'Munira', 'autoLock': 'No automatic lock set', 'todayMb': '3.1', 'totalMb': '234.2'},
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.textHint),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Cancel', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      final idx = _categories.indexWhere((c) => c['title'] == category);
                      if (idx != -1) _categories[idx]['records'] = 0;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$category cleared successfully'), backgroundColor: AppColors.success),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Clear All', style: AppTypography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAttendantDialog(int index) {
    final att = _attendants[index];
    TimeOfDay lockTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay unlockTime = const TimeOfDay(hour: 17, minute: 0);

    String formatTime(TimeOfDay t) {
      final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      final m = t.minute.toString().padLeft(2, '0');
      final period = t.period == DayPeriod.am ? 'AM' : 'PM';
      return '$h:$m $period';
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
          title: Text(
            'Control ${att['name']} Usage',
            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 16),
                Text('Usage Statistics', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildStatChip('Today Usage', '${att['todayMb']} MB'),
                    const SizedBox(width: 10),
                    _buildStatChip('Total Usage', '${att['totalMb']} MB'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.textHint),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Close', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${att['name']} settings saved'), backgroundColor: AppColors.success),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Save', style: AppTypography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
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
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            const Spacer(),
            Text(time, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  void _viewLogs() {
    context.push('/shop-settings/storage/system-logs');
  }

  void _saveChanges() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Storage settings saved'), backgroundColor: AppColors.success),
    );
    context.go('/shop-settings');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 1.5),
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
            child: IconButton(
              onPressed: () => context.go('/shop-settings'),
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
            ),
          ),
        ),
        leadingWidth: 56,
        title: Text('Storage', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        centerTitle: true,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: SizedBox(height: 1)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Clear Shop Data', Icons.delete_sweep_rounded, const Color(0xFFEF4444)),
          const SizedBox(height: 12),
          _buildCard(
            child: Column(
              children: _categories.asMap().entries.map((entry) {
                final i = entry.key;
                final cat = entry.value;
                final isLogs = cat['title'] == 'Logs';
                return Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (cat['color'] as Color).withOpacity(0.1),
                        child: Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 20),
                      ),
                      title: Text(cat['title'], style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                      subtitle: Text(isLogs ? 'System activity logs' : '${cat['records']} records', style: AppTypography.caption.copyWith(fontSize: 11)),
                      trailing: isLogs
                          ? TextButton(onPressed: _viewLogs, child: const Text('View'))
                          : TextButton(
                              onPressed: () => _clearData(cat['title'], cat['records']),
                              child: Text('Clear', style: TextStyle(color: AppColors.danger)),
                            ),
                    ),
                    if (i < _categories.length - 1) const Divider(height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Attendant Settings', Icons.people_alt_rounded, const Color(0xFF9333EA)),
          const SizedBox(height: 12),
          _buildCard(
            child: Column(
              children: _attendants.asMap().entries.map((entry) {
                final i = entry.key;
                final att = entry.value;
                return Column(
                  children: [
                    ListTile(
                      onTap: () => _showAttendantDialog(i),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                      ),
                      title: Text(att['name'], style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${att['autoLock']}  •  ${att['todayMb']} MB today | ${att['totalMb']} MB total',
                        style: AppTypography.caption.copyWith(fontSize: 10),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
                    ),
                    if (i < _attendants.length - 1) const Divider(height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(title, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
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
