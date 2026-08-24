import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/shared/dialogs/app_filter_dialog.dart';

class SystemLogsPage extends StatefulWidget {
  const SystemLogsPage({super.key});

  @override
  State<SystemLogsPage> createState() => _SystemLogsPageState();
}

class _SystemLogsPageState extends State<SystemLogsPage> {
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _filters = [
    {'label': 'All', 'count': 1044},
    {'label': 'Products', 'count': 1004},
    {'label': 'Purchases', 'count': 12},
    {'label': 'Stockins', 'count': 8},
    {'label': 'Cashflow', 'count': 5},
    {'label': 'Expenses', 'count': 3},
    {'label': 'Sales', 'count': 6},
    {'label': 'Suppliers', 'count': 2},
    {'label': 'Customers', 'count': 1},
    {'label': 'Users', 'count': 3},
    {'label': 'Filter', 'count': 0},
  ];

  final List<Map<String, dynamic>> _logs = [
    {
      'category': 'Customers',
      'title': 'Deleted customer',
      'subject': 'John Mwangi',
      'details': 'Customer record removed from system',
      'date': '2026-08-18 14:32',
      'amount': '-',
      'created': '2025-01-15',
      'deleted': '2026-08-18',
    },
    {
      'category': 'Products',
      'title': 'Deleted product',
      'subject': 'Wireless Mouse',
      'details': 'Product removed from inventory',
      'date': '2026-08-17 10:15',
      'amount': 'TZS 25,000',
      'created': '2025-06-20',
      'deleted': '2026-08-17',
    },
    {
      'category': 'Products',
      'title': 'Deleted product',
      'subject': 'USB-C Cable',
      'details': 'Product removed from inventory',
      'date': '2026-08-16 09:45',
      'amount': 'TZS 8,000',
      'created': '2025-03-10',
      'deleted': '2026-08-16',
    },
    {
      'category': 'Sales',
      'title': 'Deleted sale',
      'subject': 'Invoice #1042',
      'details': 'Sale record voided by admin',
      'date': '2026-08-15 16:20',
      'amount': 'TZS 150,000',
      'created': '2026-08-15',
      'deleted': '2026-08-15',
    },
    {
      'category': 'Expenses',
      'title': 'Deleted expense',
      'subject': 'Transport cost',
      'details': 'Expense entry removed',
      'date': '2026-08-14 11:30',
      'amount': 'TZS 35,000',
      'created': '2026-08-14',
      'deleted': '2026-08-14',
    },
    {
      'category': 'Suppliers',
      'title': 'Deleted supplier',
      'subject': 'Tech Supplies Ltd',
      'details': 'Supplier profile removed',
      'date': '2026-08-13 08:00',
      'amount': '-',
      'created': '2024-11-05',
      'deleted': '2026-08-13',
    },
  ];

  List<Map<String, dynamic>> get _filteredLogs {
    if (_selectedFilter == 'All') return _logs;
    return _logs.where((l) => l['category'] == _selectedFilter).toList();
  }

  void _restoreLog(int index) {
    final log = _filteredLogs[index];
    setState(() {
      _logs.removeWhere((l) => l['date'] == log['date'] && l['subject'] == log['subject']);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${log['title']} restored'), backgroundColor: AppColors.success),
    );
  }

  void _deletePermanently(int index) {
    final log = _filteredLogs[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
        title: Text('Delete Permanently', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to permanently delete "${log['subject']}"? This action cannot be undone.',
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
                      _logs.removeWhere((l) => l['date'] == log['date'] && l['subject'] == log['subject']);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${log['subject']} deleted permanently'), backgroundColor: AppColors.danger),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Delete', style: AppTypography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
              onPressed: () => context.go('/shop-settings/storage'),
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
            ),
          ),
        ),
        leadingWidth: 56,
        title: Text('System Logs', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        centerTitle: true,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: SizedBox(height: 1)),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          const SizedBox(height: 8),
          Expanded(
            child: _filteredLogs.isEmpty
                ? Center(
                    child: Text('No logs found', style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredLogs.length,
                    itemBuilder: (ctx, i) => _buildLogCard(_filteredLogs[i], i),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final f = _filters[i];
          final selected = _selectedFilter == f['label'];
          final isFilterBtn = f['label'] == 'Filter';
          return GestureDetector(
            onTap: () {
              if (isFilterBtn) {
                AppFilterDialog.show(context);
              } else {
                setState(() => _selectedFilter = f['label']);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                border: Border.all(color: selected ? AppColors.primary : AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    f['label'],
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  if (!isFilterBtn) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white.withOpacity(0.2) : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                      ),
                      child: Text(
                        '${f['count']}',
                        style: AppTypography.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                  ),
                  child: Text(log['category'], style: AppTypography.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.danger)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(log['title'], style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(log['subject'], style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(log['details'], style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildMetaChip(Icons.calendar_today_rounded, log['date']),
                if (log['amount'] != '-') ...[
                  const SizedBox(width: 8),
                  _buildMetaChip(Icons.attach_money_rounded, log['amount']),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Created: ${log['created']}', style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.textHint)),
                const SizedBox(width: 12),
                Text('Deleted: ${log['deleted']}', style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.textHint)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: OutlinedButton(
                      onPressed: () => _restoreLog(index),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
                      ),
                      child: Text('Restore', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: () => _deletePermanently(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
                        elevation: 0,
                      ),
                      child: Text('Delete Permanently', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(text, style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}
