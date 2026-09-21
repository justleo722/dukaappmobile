// features/accounts/presentation/pages/accounts_cashflow_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/shared/dialogs/app_filter_dialog.dart';
import 'package:dukaapp/features/accounts/data/models/cashflow_models.dart';
import 'package:dukaapp/features/accounts/presentation/providers/cashflow_provider.dart';
import 'package:dukaapp/shared/providers/filter_provider.dart';
import 'package:dukaapp/core/providers.dart';

class AccountsCashflowPage extends ConsumerStatefulWidget {
  const AccountsCashflowPage({super.key});

  @override
  ConsumerState<AccountsCashflowPage> createState() => _AccountsCashflowPageState();
}

class _AccountsCashflowPageState extends ConsumerState<AccountsCashflowPage> {
  final TextEditingController _searchController = TextEditingController();

  List<CashflowItem> _allItems = [];
  CashflowSummary? _summary;
  bool _isLoading = false;
  // Payment accounts for from/to selectors in dialogs
  List<Map<String, dynamic>> _accounts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadCashflow();
      await _loadAccounts();
    });
  }

  Future<void> _loadAccounts() async {
    try {
      final api = ref.read(apiServiceProvider);
      // Cashbook accounts (from the accounts table) are what addfund expects
      // for from_account_id / to_account_id — not payment mode entries.
      final res = await api.getCashbookAccounts();
      final data = res.data;
      List raw = [];
      if (data is List) {
        raw = data;
      } else if (data is Map) {
        final v = data['data'] ?? data['accounts'] ?? data['result'] ?? [];
        if (v is List) raw = v;
      }
      if (!mounted) return;
      setState(() {
        _accounts = raw.whereType<Map<String, dynamic>>().toList();
      });
    } catch (_) {}
  }

  Future<void> _loadCashflow({String? from, String? to}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(cashflowRepositoryProvider);
      final results = await Future.wait([
        repo.fetchCashflow(from: from, to: to),
        repo.fetchCashflowSummary(from: from, to: to),
      ]);
      if (!mounted) return;
      setState(() {
        _allItems = results[0] as List<CashflowItem>;
        _summary = results[1] as CashflowSummary;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<CashflowItem> get _filteredItems {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return _allItems;
    return _allItems.where((e) => e.name.toLowerCase().contains(query)).toList();
  }

  double get _totalCashIn => _summary?.totalCashIn ?? _allItems.fold(0, (s, e) => s + e.cashIn);
  double get _totalCashOut => _summary?.totalCashOut ?? _allItems.fold(0, (s, e) => s + e.cashOut);
  double get _cashInHand => _summary?.cashInHand ?? (_totalCashIn - _totalCashOut);
  double get _customerWallet => _summary?.customerWallets ?? 0;

  String _fmt(double v) {
    final fmt = NumberFormat('#,###');
    return 'Tsh ${fmt.format(v)}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    ref.listen<FilterState>(filterProvider, (prev, next) {
      if (prev?.from != next.from || prev?.to != next.to) {
        _loadCashflow(from: next.from, to: next.to);
      }
    });
    final items = _filteredItems;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  const SizedBox(height: 12),
                  _buildSummaryCards(),
                  const SizedBox(height: 14),
                  _buildActionButtons(),
                  const SizedBox(height: 14),
                  _buildSearchField(),
                  const SizedBox(height: 14),
                  _buildSectionHeader(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: items.isEmpty ? _buildEmptyState() : _buildCashflowList(items),
                  ),
                ],
              ),
      ),
    );
  }

  void _showAddCashInDialog() {
    final s = ref.read(stringsProvider);
    String? selectedFromAccountId;
    String? selectedToAccountId;
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final categories = [s.capital, s.loan, s.balancing];
    String? selectedCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 14),
                child: Row(children: [
                  Text('Add Cash In', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded, color: AppColors.textHint, size: 22)),
                ]),
              ),
              const Divider(height: 1, color: AppColors.divider),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Title'),
                      const SizedBox(height: 6),
                      _buildTextInput(titleController, 'e.g. Capital injection'),
                      const SizedBox(height: 16),
                      _fieldLabel('Category'),
                      const SizedBox(height: 6),
                      _buildDropdown(ctx, setDialogState, selectedCategory, categories, (v) { setDialogState(() => selectedCategory = v); }),
                      const SizedBox(height: 16),
                      _fieldLabel('From Account (source)'),
                      const SizedBox(height: 6),
                      _buildAccountDropdown(ctx, setDialogState, selectedFromAccountId, (v) { setDialogState(() => selectedFromAccountId = v); }),
                      const SizedBox(height: 16),
                      _fieldLabel('To Account (destination)'),
                      const SizedBox(height: 6),
                      _buildAccountDropdown(ctx, setDialogState, selectedToAccountId, (v) { setDialogState(() => selectedToAccountId = v); }),
                      const SizedBox(height: 16),
                      _fieldLabel('Amount'),
                      const SizedBox(height: 6),
                      _buildAmountInput(amountController),
                      const SizedBox(height: 16),
                      _fieldLabel('Date'),
                      const SizedBox(height: 6),
                      _buildDatePicker(ctx, setDialogState, selectedDate, (d) { setDialogState(() => selectedDate = d); }),
                    ],
                  ),
                ),
              ),
              _buildDialogActions(ctx, () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                final title = titleController.text.trim();
                if (_accounts.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No accounts found. Configure payment accounts first.')));
                  return;
                }
                if (amount <= 0 || title.isEmpty || selectedFromAccountId == null || selectedToAccountId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.fillAllFieldsAndSelectBothAccounts)));
                  return;
                }
                Navigator.pop(ctx);
                try {
                  final repo = ref.read(cashflowRepositoryProvider);
                  await repo.addFund({
                    'type': 'cashin',
                    'title': title,
                    'amount': amount,
                    if (selectedFromAccountId != null) 'from_account_id': selectedFromAccountId,
                    if (selectedToAccountId != null) 'to_account_id': selectedToAccountId,
                    'record_date': DateFormat('yyyy-MM-dd').format(selectedDate),
                    if (selectedCategory != null) 'category': selectedCategory,
                  });
                  if (!mounted) return;
                  await _loadCashflow();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cash In recorded', style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM))),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.danger));
                }
              }, AppColors.primary, s.save),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCashOutDialog() {
    final s = ref.read(stringsProvider);
    String? selectedCategory;
    String? selectedFromAccountId;
    String? selectedToAccountId;
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final categories = [s.toBank, s.toPersonalUse, 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 14),
                child: Row(children: [
                  Text('Add Cash Out', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded, color: AppColors.textHint, size: 22)),
                ]),
              ),
              const Divider(height: 1, color: AppColors.divider),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Title'),
                      const SizedBox(height: 6),
                      _buildTextInput(titleController, 'e.g. Rent payment'),
                      const SizedBox(height: 16),
                      _fieldLabel('Category'),
                      const SizedBox(height: 6),
                      _buildDropdown(ctx, setDialogState, selectedCategory, categories, (v) { setDialogState(() => selectedCategory = v); }),
                      const SizedBox(height: 16),
                      _fieldLabel('From Account (source)'),
                      const SizedBox(height: 6),
                      _buildAccountDropdown(ctx, setDialogState, selectedFromAccountId, (v) { setDialogState(() => selectedFromAccountId = v); }),
                      const SizedBox(height: 16),
                      _fieldLabel('To Account (destination)'),
                      const SizedBox(height: 6),
                      _buildAccountDropdown(ctx, setDialogState, selectedToAccountId, (v) { setDialogState(() => selectedToAccountId = v); }),
                      const SizedBox(height: 16),
                      _fieldLabel('Amount'),
                      const SizedBox(height: 6),
                      _buildAmountInput(amountController),
                      const SizedBox(height: 16),
                      _fieldLabel('Date'),
                      const SizedBox(height: 6),
                      _buildDatePicker(ctx, setDialogState, selectedDate, (d) { setDialogState(() => selectedDate = d); }),
                    ],
                  ),
                ),
              ),
              _buildDialogActions(ctx, () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                final title = titleController.text.trim();
                if (_accounts.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No accounts found. Configure payment accounts first.')));
                  return;
                }
                if (amount <= 0 || title.isEmpty || selectedFromAccountId == null || selectedToAccountId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.fillAllFieldsAndSelectBothAccounts)));
                  return;
                }
                Navigator.pop(ctx);
                try {
                  final repo = ref.read(cashflowRepositoryProvider);
                  await repo.addFund({
                    'type': 'cashout',
                    'title': title,
                    'amount': amount,
                    if (selectedFromAccountId != null) 'from_account_id': selectedFromAccountId,
                    if (selectedToAccountId != null) 'to_account_id': selectedToAccountId,
                    'record_date': DateFormat('yyyy-MM-dd').format(selectedDate),
                    if (selectedCategory != null) 'category': selectedCategory,
                  });
                  if (!mounted) return;
                  await _loadCashflow();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cash Out recorded', style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM))),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.danger));
                }
              }, AppColors.danger, s.save),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600));
  }

  Widget _buildDropdown(BuildContext ctx, StateSetter setDialogState, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(border: Border.all(color: AppColors.inputBorder), borderRadius: BorderRadius.circular(AppConstants.textFieldRadius)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text('Select\u2026', style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint)),
          isExpanded: true,
          items: items.map((c) => DropdownMenuItem(value: c, child: Text(c, style: AppTypography.bodyMedium))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildAccountDropdown(BuildContext ctx, StateSetter setDialogState, String? value, ValueChanged<String?> onChanged) {
    final s = ref.read(stringsProvider);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(border: Border.all(color: AppColors.inputBorder), borderRadius: BorderRadius.circular(AppConstants.textFieldRadius)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(_accounts.isEmpty ? s.loadingAccounts : s.selectAccount, style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint)),
          isExpanded: true,
          items: _accounts.map((a) {
            final id = (a['account_id'] ?? a['id'] ?? '').toString();
            final name = (a['account_name'] ?? a['name'] ?? id).toString();
            return DropdownMenuItem(value: id, child: Text(name, style: AppTypography.bodyMedium));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTextInput(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: AppTypography.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5)),
      ),
    );
  }

  Widget _buildAmountInput(TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: AppTypography.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Enter amount',
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
        prefixText: 'Tsh ',
        prefixStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5)),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext ctx, StateSetter setDialogState, DateTime selectedDate, ValueChanged<DateTime> onPicked) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: ctx,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: AppColors.primary)), child: child!),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(border: Border.all(color: AppColors.inputBorder), borderRadius: BorderRadius.circular(AppConstants.textFieldRadius)),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textHint),
          const SizedBox(width: 10),
          Text(DateFormat('dd MMM yyyy').format(selectedDate), style: AppTypography.bodyMedium),
        ]),
      ),
    );
  }

  Widget _buildDialogActions(BuildContext ctx, Future<void> Function() onSave, Color saveColor, String saveLabel) {
    return Container(
      padding: EdgeInsets.only(left: AppConstants.paddingLG, right: AppConstants.paddingLG, top: 12, bottom: MediaQuery.of(ctx).padding.bottom + 12),
      decoration: const BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.divider, width: 1))),
      child: Row(children: [
        Expanded(
          child: SizedBox(
            height: AppConstants.buttonHeight,
            child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary, side: const BorderSide(color: AppColors.border, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD))), child: Text('Cancel', style: AppTypography.buttonLarge.copyWith(color: AppColors.textSecondary))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: AppConstants.buttonHeight,
            child: ElevatedButton.icon(onPressed: onSave, icon: const Icon(Icons.check_rounded, size: 18, color: AppColors.textWhite), label: Text(saveLabel, style: AppTypography.buttonLarge.copyWith(color: AppColors.textWhite)), style: ElevatedButton.styleFrom(backgroundColor: saveColor, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)))),
          ),
        ),
      ]),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final s = ref.read(stringsProvider);
    return AppBar(
      backgroundColor: AppColors.card,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
          child: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20)),
        ),
      ),
      leadingWidth: 56,
      title: Column(children: [
        Text(s.accountsAndCashflow, style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text('Track cash movement.', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10)),
      ]),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
            child: IconButton(onPressed: () => context.push('/accounts-reports'), icon: Icon(Icons.download_rounded, color: AppColors.textHint, size: 20)),
          ),
        ),
      ],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.divider)),
    );
  }

  Widget _buildSummaryCards() {
    final s = ref.read(stringsProvider);
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
        itemCount: 4,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          switch (index) {
            case 0: return _summaryCard(s.cashIn, _fmt(_totalCashIn), AppColors.success, AppColors.successLight, Icons.arrow_downward_rounded);
            case 1: return _summaryCard(s.cashOut, _fmt(_totalCashOut), AppColors.danger, AppColors.dangerLight, Icons.arrow_upward_rounded);
            case 2: return _summaryCard('Cash in Hand', _fmt(_cashInHand.abs()), _cashInHand >= 0 ? AppColors.primary : AppColors.danger, _cashInHand >= 0 ? const Color(0xFFEBF2FF) : AppColors.dangerLight, Icons.payments_rounded);
            case 3: return _summaryCard(s.customerWallet, _fmt(_customerWallet), const Color(0xFF14B8A6), const Color(0xFFE0FFF9), Icons.account_balance_wallet_rounded);
            default: return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _summaryCard(String label, String amount, Color color, Color bgColor, IconData icon) {
    return SizedBox(
      width: 155,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 18,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  amount,
                  style: AppTypography.bodyMedium.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _actionBtn(Icons.add_rounded, 'Add Cash In', AppColors.primary, _showAddCashInDialog),
          const SizedBox(width: 8),
          _actionBtn(Icons.remove_rounded, 'Add Cash Out', AppColors.danger, _showAddCashOutDialog),
          const SizedBox(width: 8),
          _actionBtn(Icons.filter_list_rounded, 'Filter', AppColors.primary, () => AppFilterDialog.show(context)),
          const SizedBox(width: 8),
          _actionBtn(Icons.download_rounded, 'Download', AppColors.primary, () => context.push('/accounts-reports')),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: AppTypography.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final s = ref.read(stringsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: AppTypography.bodyMedium,
        decoration: InputDecoration(
          hintText: s.searchCashflow,
          hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
          suffixIcon: _searchController.text.isNotEmpty ? IconButton(onPressed: () { _searchController.clear(); setState(() {}); }, icon: const Icon(Icons.close_rounded, color: AppColors.textHint, size: 18)) : null,
          filled: true,
          fillColor: AppColors.card,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5)),
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    final s = ref.read(stringsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Text(s.cashflow, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildCashflowList(List<CashflowItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      itemCount: items.length,
      itemBuilder: (ctx, i) => _buildCashflowCard(items[i]),
    );
  }

  Widget _buildCashflowCard(CashflowItem item) {
    final hasCashIn = item.cashIn > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: hasCashIn ? AppColors.successLight : AppColors.dangerLight, borderRadius: BorderRadius.circular(10)),
            child: Icon(hasCashIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: hasCashIn ? AppColors.success : AppColors.danger, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(item.date, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (item.cashIn > 0) Text('+${_fmt(item.cashIn)}', style: AppTypography.bodySmall.copyWith(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 12)),
              if (item.cashOut > 0) Text('-${_fmt(item.cashOut)}', style: AppTypography.bodySmall.copyWith(color: AppColors.danger, fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 2),
              Text('Bal: ${_fmt(item.balance)}', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXXL, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 100, height: 100, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), shape: BoxShape.circle), child: Icon(Icons.account_balance_rounded, size: 48, color: AppColors.primary.withValues(alpha: 0.4))),
            const SizedBox(height: 20),
            Text('No Cashflow Records Found', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Start by adding cash in or cash out.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
