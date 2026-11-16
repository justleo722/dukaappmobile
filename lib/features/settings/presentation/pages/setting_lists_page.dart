import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/core/providers.dart';

/// Settings → Payment Modes & Categories (Settings::settingList / saveSettingItem /
/// deleteSettingItem). Built-in items are shown but can't be changed.
class SettingListsPage extends ConsumerStatefulWidget {
  const SettingListsPage({super.key});

  @override
  ConsumerState<SettingListsPage> createState() => _SettingListsPageState();
}

class _SettingListsPageState extends ConsumerState<SettingListsPage> with SingleTickerProviderStateMixin {
  static const _kinds = [
    ('payment_modes', 'Payment Modes'),
    ('expense_categories', 'Expense Categories'),
    ('product_categories', 'Product Categories'),
  ];

  late final TabController _tabs = TabController(length: _kinds.length, vsync: this)
    ..addListener(() {
      if (!_tabs.indexIsChanging) _load();
    });
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  String get _kind => _kinds[_tabs.index].$1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ref.read(apiServiceProvider).postSettingsList(_kind);
      final items = res['items'];
      _items = items is List ? items.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList() : [];
    } catch (_) {
      _items = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  void _toast(Map<String, dynamic> res) {
    final ok = res['status']?.toString() == 'success';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res['message']?.toString() ?? (ok ? 'Saved' : 'Failed')),
      backgroundColor: ok ? AppColors.success : AppColors.danger,
    ));
  }

  Future<void> _edit([Map<String, dynamic>? item]) async {
    final name = TextEditingController(text: item?['name']?.toString() ?? '');
    final accountNo = TextEditingController(text: item?['account_no']?.toString() ?? '');
    final isPayment = _kind == 'payment_modes';
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
        title: Text(item == null ? 'Add' : 'Edit'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, autofocus: true, maxLength: 100, decoration: const InputDecoration(labelText: 'Name')),
          if (isPayment)
            TextField(controller: accountNo, maxLength: 100, decoration: const InputDecoration(labelText: 'Account / phone number (optional)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Save')),
        ],
      ),
    );
    if (save != true) return;
    try {
      final res = await ref.read(apiServiceProvider).postSettingsListSave({
        'kind': _kind,
        'id': item?['id']?.toString() ?? '',
        'name': name.text.trim(),
        'account_no': accountNo.text.trim(),
      });
      if (!mounted) return;
      _toast(res);
      if (res['status']?.toString() == 'success') _load();
    } catch (_) {
      if (mounted) _toast({'status': 'error', 'message': 'Failed to save'});
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${item['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      final res = await ref.read(apiServiceProvider).postSettingsListDelete(_kind, item['id'].toString());
      if (!mounted) return;
      _toast(res);
      if (res['status']?.toString() == 'success') _load();
    } catch (_) {
      if (mounted) _toast({'status': 'error', 'message': 'Failed to delete'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        ),
        title: Text('Payment Modes & Categories',
            style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [for (final k in _kinds) Tab(text: k.$2)],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(children: const [SizedBox(height: 120), Center(child: Text('No records found.'))])
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final it = _items[i];
                        final locked = it['locked'] == true;
                        final used = int.tryParse('${it['used'] ?? 0}') ?? 0;
                        final accountNo = (it['account_no'] ?? '').toString();
                        return Container(
                          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text('${it['name']}', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              [if (accountNo.isNotEmpty) accountNo, 'Used $used', if (locked) 'Built-in'].join(' • '),
                              style: AppTypography.caption,
                            ),
                            trailing: locked
                                ? const Icon(Icons.lock_outline_rounded, color: AppColors.textHint, size: 18)
                                : Row(mainAxisSize: MainAxisSize.min, children: [
                                    IconButton(icon: const Icon(Icons.edit_rounded, color: AppColors.primary), onPressed: () => _edit(it)),
                                    IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger), onPressed: () => _delete(it)),
                                  ]),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
