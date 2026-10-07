import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';

class SystemLogsPage extends ConsumerStatefulWidget {
  const SystemLogsPage({super.key});

  @override
  ConsumerState<SystemLogsPage> createState() => _SystemLogsPageState();
}

class _SystemLogsPageState extends ConsumerState<SystemLogsPage> {
  String _selectedFilter = 'All';
  bool _isLoading = true;
  List<Map<String, dynamic>> _logs = [];

  // Unique categories derived from data
  List<String> get _categories {
    final cats = _logs.map((l) => l['category'] as String? ?? 'Other').toSet().toList()..sort();
    return ['All', ...cats];
  }

  // log_type → [table, key] for Settings::deleterecord, as in the web shopsettings.php.
  static const Map<String, List<String>> _restoreTargets = {
    'sales': ['sales', 'sale_id'],
    'products': ['products', 'product_id'],
    'purchases': ['purchases', 'purchase_id'],
    'stockins': ['purchases', 'purchase_id'],
    'cashflow': ['cashflow', 'flow_id'],
    'expenses': ['cashflow', 'flow_id'],
    'suppliers': ['suppliers', 'supplier_id'],
    'customers': ['customers', 'customer_id'],
    'users': ['roles', 'role_id'],
  };

  List<Map<String, dynamic>> get _filteredLogs =>
      _selectedFilter == 'All' ? _logs : _logs.where((l) => l['category'] == _selectedFilter).toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLogs());
  }

  Future<void> _loadLogs() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getLogs();
      final raw = res.data;
      List<dynamic> list = [];
      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic>) {
        final d = raw['data'];
        if (d is List) list = d;
      }
      final mapped = list.whereType<Map<String, dynamic>>().map((row) {
        // Keys from Logs_model::logs().
        final type = (row['log_type'] ?? row['type'] ?? row['category'] ?? 'Other').toString();
        final cat = _capitalize(type);
        final deletedAt = (row['deleted_at_label'] ?? row['deleted_at'] ?? '').toString();
        final deletedBy = (row['deleted_by'] ?? '').toString();
        return {
          'category': cat,
          'title': row['title']?.toString() ?? row['action']?.toString() ?? 'Log entry',
          'subject': row['subject']?.toString() ?? row['name']?.toString() ?? '',
          'details': row['details']?.toString() ?? row['description']?.toString() ?? '',
          'date': (row['original_date_label'] ?? row['original_date'] ?? row['date'] ?? '').toString(),
          'amount': row['amount']?.toString() ?? '-',
          'created': (row['created_by'] ?? '-').toString(),
          'deleted': [deletedAt, if (deletedBy.isNotEmpty) 'by $deletedBy'].where((v) => v.isNotEmpty).join(' ').ifEmpty('-'),
          'log_id': row['log_id']?.toString() ?? row['id']?.toString() ?? '',
          'reference_id': row['reference_id']?.toString() ?? '',
          'type': type.toLowerCase(),
        };
      }).toList();
      if (mounted) setState(() { _logs = mapped; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restore(Map<String, dynamic> log) async {
    final target = _restoreTargets[log['type']];
    final refId = (log['reference_id'] ?? '').toString();
    if (target == null || refId.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore record'),
        content: Text('Restore "${log['subject'].toString().isNotEmpty ? log['subject'] : log['title']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final res = await ref.read(apiServiceProvider).postSettingsRecordDelete({
        'method': 'active',
        'table': target[0],
        'key': target[1],
        'row_id': refId,
      });
      if (!mounted) return;
      final ok = res['status']?.toString() == 'success';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Record restored' : (res['message']?.toString() ?? 'Restore failed')),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
      ));
      if (ok) _loadLogs();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger));
    }
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.card, elevation: 0,
        leading: Padding(padding: const EdgeInsets.all(8.0), child: Container(
          decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
          child: IconButton(onPressed: () => context.go('/shop-settings/storage'),
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20)),
        )),
        leadingWidth: 56,
        title: Text('System Logs', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _loadLogs, icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary)),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.divider)),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(children: [
            _buildFilterBar(),
            const SizedBox(height: 4),
            Expanded(child: _filteredLogs.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.history_rounded, size: 48, color: AppColors.textHint.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text('No logs found', style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredLogs.length,
                  itemBuilder: (ctx, i) => _buildLogCard(_filteredLogs[i]),
                )),
          ]),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(height: 48, child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      scrollDirection: Axis.horizontal,
      itemCount: _categories.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (ctx, i) {
        final cat = _categories[i];
        final selected = _selectedFilter == cat;
        final count = cat == 'All' ? _logs.length : _logs.where((l) => l['category'] == cat).length;
        return GestureDetector(
          onTap: () => setState(() => _selectedFilter = cat),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.card,
              borderRadius: BorderRadius.circular(AppConstants.radiusFull),
              border: Border.all(color: selected ? AppColors.primary : AppColors.border),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(cat, style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textPrimary)),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                ),
                child: Text('$count', style: AppTypography.caption.copyWith(
                  fontSize: 10, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.primary)),
              ),
            ]),
          ),
        );
      },
    ));
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final hasAmount = log['amount'] != null && log['amount'] != '-' && log['amount'] != '';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
      elevation: 1,
      child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppConstants.radiusFull)),
            child: Text(log['category'], style: AppTypography.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.danger)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(log['title'], style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 8),
        if ((log['subject'] as String).isNotEmpty)
          Text(log['subject'], style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
        if ((log['details'] as String).isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(log['details'], style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
        const SizedBox(height: 8),
        Row(children: [
          if ((log['date'] as String).isNotEmpty) _chip(Icons.calendar_today_rounded, log['date']),
          if (hasAmount) ...[const SizedBox(width: 8), _chip(Icons.attach_money_rounded, log['amount'])],
        ]),
        if ((log['created'] as String) != '-') ...[
          const SizedBox(height: 4),
          Row(children: [
            Text('Created: ${log['created']}', style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.textHint)),
            const SizedBox(width: 12),
            Expanded(child: Text('Deleted: ${log['deleted']}', style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.textHint))),
          ]),
        ],
        if (_restoreTargets.containsKey(log['type']) && (log['reference_id'] as String).isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _restore(log),
              icon: const Icon(Icons.restore_rounded, size: 16),
              label: const Text('Restore'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.success,
                side: const BorderSide(color: AppColors.success),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ])),
    );
  }

  Widget _chip(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 12, color: AppColors.textHint), const SizedBox(width: 4),
    Text(text, style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.textSecondary)),
  ]);
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
