import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/expenses/data/models/expense_models.dart';
import 'package:dukaapp/features/expenses/presentation/providers/expense_provider.dart';
import 'package:dukaapp/shared/providers/filter_provider.dart';
import 'package:dukaapp/core/providers.dart';

class ProfitExpensesPage extends ConsumerStatefulWidget {
  const ProfitExpensesPage({super.key});

  @override
  ConsumerState<ProfitExpensesPage> createState() => _ProfitExpensesPageState();
}

class _ProfitExpensesPageState extends ConsumerState<ProfitExpensesPage> {
  final TextEditingController _searchController = TextEditingController();

  List<ExpenseItem> _expenses = [];
  List<ExpenseAccount> _expenseAccounts = [];
  List<ExpenseAccount> _cashbookAccounts = [];
  bool _isLoading = false;
  ExpenseSummary _summary = ExpenseSummary.empty;

  static const _kCategoryCache = 'expense_accounts_cache';
  static const _kCashbookCache = 'cashbook_accounts_cache';

  Future<void> _saveAccountsCache(String key, List<ExpenseAccount> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = list.map((a) => {'account_id': a.accountId, 'account_name': a.name}).toList();
      await prefs.setString(key, jsonEncode(json));
    } catch (_) {}
  }

  Future<List<ExpenseAccount>> _loadAccountsCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list.map((j) => ExpenseAccount(
        accountId: j['account_id']?.toString() ?? '',
        name: j['account_name']?.toString() ?? '',
      )).where((a) => a.accountId.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load from cache first so dropdowns are ready immediately
      final cachedCategories = await _loadAccountsCache(_kCategoryCache);
      final cachedCashbook = await _loadAccountsCache(_kCashbookCache);
      if (mounted && (cachedCategories.isNotEmpty || cachedCashbook.isNotEmpty)) {
        setState(() {
          if (cachedCategories.isNotEmpty) _expenseAccounts = cachedCategories;
          if (cachedCashbook.isNotEmpty) _cashbookAccounts = cachedCashbook;
        });
      }
      _loadExpenses();
    });
  }

  Future<void> _loadExpenses({String? from, String? to}) async {
    if (!mounted) return;
    // Serve cached expenses immediately
    final cache = ref.read(localCacheProvider);
    final cachedExpenses = await cache.loadList('expenses', 'list');
    if (mounted && cachedExpenses.isNotEmpty) {
      setState(() { _expenses = cachedExpenses.map(ExpenseItem.fromJson).toList(); });
    } else {
      setState(() => _isLoading = true);
    }
    final repo = ref.read(expenseRepositoryProvider);

    // Fetch summary + expenses independently so account errors don't block them
    final summaryFuture = repo.fetchExpenseSummary(from: from, to: to)
        .catchError((_) => ExpenseSummary.empty);
    final expensesFuture = repo.fetchExpenses(from: from, to: to)
        .catchError((_) => <ExpenseItem>[]);
    final accountsFuture = repo.fetchExpenseAccounts()
        .catchError((_) => <ExpenseAccount>[]);
    final cashbookFuture = repo.fetchCashbookAccounts()
        .catchError((_) => <ExpenseAccount>[]);

    final results = await Future.wait([
      summaryFuture, expensesFuture, accountsFuture, cashbookFuture,
    ]);
    if (!mounted) return;

    final summary = results[0] as ExpenseSummary;
    final freshExpenses = results[1] as List<ExpenseItem>;
    final fetchedCategories = results[2] as List<ExpenseAccount>;
    final fetchedCashbook = results[3] as List<ExpenseAccount>;

    if (fetchedCategories.isNotEmpty) _saveAccountsCache(_kCategoryCache, fetchedCategories);
    if (fetchedCashbook.isNotEmpty) _saveAccountsCache(_kCashbookCache, fetchedCashbook);
    if (freshExpenses.isNotEmpty) {
      cache.save('expenses', 'list', freshExpenses.map((e) => {
        'flow_id': e.flowId, 'record_date': e.date, 'title': e.title,
        'account_name': e.category, 'amount': e.amount,
        'currency': e.currency, 'note': e.note,
      }).toList());
    }
    setState(() {
      _summary = summary;
      _expenses = freshExpenses;
      if (fetchedCategories.isNotEmpty) _expenseAccounts = fetchedCategories;
      if (fetchedCashbook.isNotEmpty) _cashbookAccounts = fetchedCashbook;
      _isLoading = false;
    });
  }

  List<ExpenseItem> get _filteredExpenses {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return _expenses;
    return _expenses
        .where((e) =>
            e.title.toLowerCase().contains(query) ||
            e.category.toLowerCase().contains(query))
        .toList();
  }

  double get _totalExpenses => _expenses.fold(0, (s, e) => s + e.amount);
  double get _todayExpenses => _summary.todayExpenses;
  double get _todayNetProfit => _summary.grossProfit - _todayExpenses;

  double get _totalSales => _summary.totalSales;
  double get _grossProfit => _summary.grossProfit;
  double get _badStock => _summary.badStock;
  double get _netProfit => _summary.netProfit > 0 ? _summary.netProfit : (_totalSales - _totalExpenses);
  double get _cashInHand => _summary.cashInHand;

  String _fmt(double v) {
    final fmt = NumberFormat('#,###');
    return 'Tsh ${fmt.format(v)}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showAddExpenseDialog() async {
    final s = ref.read(stringsProvider);
    // Ensure categories are loaded before opening dialog
    List<ExpenseAccount> expenseAccounts = List.of(_expenseAccounts);
    List<ExpenseAccount> cashbookAccounts = List.of(_cashbookAccounts);

    if (expenseAccounts.isEmpty || cashbookAccounts.isEmpty) {
      try {
        final repo = ref.read(expenseRepositoryProvider);
        final results = await Future.wait([
          if (expenseAccounts.isEmpty) repo.fetchExpenseAccounts()
              else Future.value(<ExpenseAccount>[]),
          if (cashbookAccounts.isEmpty) repo.fetchCashbookAccounts()
              else Future.value(<ExpenseAccount>[]),
        ]);
        final fetched = results[0] as List<ExpenseAccount>;
        final fetchedCb = results[1] as List<ExpenseAccount>;
        if (fetched.isNotEmpty) {
          expenseAccounts = fetched;
          if (mounted) setState(() => _expenseAccounts = fetched);
          _saveAccountsCache(_kCategoryCache, fetched);
        }
        if (fetchedCb.isNotEmpty) {
          cashbookAccounts = fetchedCb;
          if (mounted) setState(() => _cashbookAccounts = fetchedCb);
          _saveAccountsCache(_kCashbookCache, fetchedCb);
        }
      } catch (_) {}
    }

    if (!mounted) return;

    String? selectedCategoryId;
    String? selectedAccountId;
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 14),
                child: Row(
                  children: [
                    Text(
                      s.addExpense,
                      style: AppTypography.h6.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, color: AppColors.textHint, size: 22),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDialogFieldLabel('Expense Category'),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.inputBorder),
                          borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedCategoryId,
                                  hint: Text(
                                    s.selectCategory,
                                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
                                  ),
                                  isExpanded: true,
                                  items: expenseAccounts.map((a) => DropdownMenuItem(
                                        value: a.accountId,
                                        child: Text(a.name, style: AppTypography.bodyMedium),
                                      )).toList(),
                                  onChanged: (v) => setDialogState(() => selectedCategoryId = v),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                final newCatController = TextEditingController();
                                showDialog(
                                  context: ctx,
                                  builder: (ctx2) => AlertDialog(
                                    title: Text('Add Category', style: AppTypography.h6),
                                    content: TextField(
                                      controller: newCatController,
                                      decoration: InputDecoration(
                                        hintText: s.categoryNameHint,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx2),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx2);
                                        },
                                        child: const Text('Add'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDialogFieldLabel(s.expenseName),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        style: AppTypography.bodyMedium,
                        decoration: InputDecoration(
                          hintText: s.enterExpenseName,
                          hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
                          filled: true,
                          fillColor: AppColors.card,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                            borderSide: const BorderSide(color: AppColors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                            borderSide: const BorderSide(color: AppColors.inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                            borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDialogFieldLabel('Amount'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        style: AppTypography.bodyMedium,
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
                          prefixText: 'Tsh ',
                          prefixStyle: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          filled: true,
                          fillColor: AppColors.card,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                            borderSide: const BorderSide(color: AppColors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                            borderSide: const BorderSide(color: AppColors.inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                            borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDialogFieldLabel('Date'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(primary: AppColors.primary),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) setDialogState(() => selectedDate = picked);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.inputBorder),
                            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textHint),
                              const SizedBox(width: 10),
                              Text(
                                DateFormat('dd MMM yyyy').format(selectedDate),
                                style: AppTypography.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDialogFieldLabel('From Account'),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.inputBorder),
                          borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedAccountId,
                            hint: Text(
                              'Select account',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
                            ),
                            isExpanded: true,
                            items: cashbookAccounts.isNotEmpty
                                ? cashbookAccounts.map((a) => DropdownMenuItem(
                                      value: a.accountId,
                                      child: Text(a.name, style: AppTypography.bodyMedium),
                                    )).toList()
                                : ['Cash', 'Bank', 'Mobile Money']
                                    .map((a) => DropdownMenuItem(value: a, child: Text(a, style: AppTypography.bodyMedium)))
                                    .toList(),
                            onChanged: (v) => setDialogState(() => selectedAccountId = v),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDialogFieldLabel('Notes (Optional)'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        style: AppTypography.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Write additional notes\u2026',
                          hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
                          filled: true,
                          fillColor: AppColors.card,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                            borderSide: const BorderSide(color: AppColors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                            borderSide: const BorderSide(color: AppColors.inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                            borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.only(
                  left: AppConstants.paddingLG,
                  right: AppConstants.paddingLG,
                  top: 12,
                  bottom: MediaQuery.of(ctx).padding.bottom + 12,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: AppConstants.buttonHeight,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.border, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTypography.buttonLarge.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: AppConstants.buttonHeight,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                              if (selectedCategoryId == null || selectedAccountId == null) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('Select expense category and cash account')),
                                );
                                return;
                              }
                              try {
                                final repo = ref.read(expenseRepositoryProvider);
                                final result = await repo.addExpense({
                                  'title': nameController.text.trim(),
                                  'amount': double.tryParse(amountController.text) ?? 0,
                                  'record_date': DateFormat('yyyy-MM-dd').format(selectedDate),
                                  'note': notesController.text.trim(),
                                  'to_account_id': selectedCategoryId,
                                  'from_account_id': selectedAccountId,
                                });
                                final status = result['status']?.toString() ?? '';
                                if (status != 'success') {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result['message']?.toString() ?? s.failedToSaveExpense),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                if (!mounted) return;
                                Navigator.pop(ctx);
                                await _loadExpenses();
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      s.expenseSavedSuccessfully,
                                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite),
                                    ),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.danger),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.check_rounded, size: 18, color: AppColors.textWhite),
                          label: Text(
                            s.saveExpense,
                            style: AppTypography.buttonLarge.copyWith(color: AppColors.textWhite),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        },
      ),
    );
  }

  Widget _buildDialogFieldLabel(String label) {
    return Text(
      label,
      style: AppTypography.bodySmall.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _showDeleteDialog(ExpenseItem expense) {
    final s = ref.read(stringsProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Delete Expense',
              style: AppTypography.h6.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${expense.title}"? This action cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              s.cancel,
              style: AppTypography.buttonLarge.copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final repo = ref.read(expenseRepositoryProvider);
                await repo.deleteExpense({'flow_id': expense.flowId});
                if (!mounted) return;
                await _loadExpenses();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${expense.title} deleted',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite),
                    ),
                    backgroundColor: AppColors.danger,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                    ),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete failed: $e'), backgroundColor: AppColors.danger),
                );
              }
            },
            child: Text(
              'Delete',
              style: AppTypography.buttonLarge.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  // ─── UI ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    ref.listen<FilterState>(filterProvider, (_, f) => _loadExpenses(from: f.from, to: f.to));
    final expenses = _filteredExpenses;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildTodaySummary(),
              const SizedBox(height: 14),
              _buildBreakdownCards(),
              const SizedBox(height: 14),
              _buildActionButtons(context),
              const SizedBox(height: 14),
              _buildSearchField(),
              const SizedBox(height: 14),
              _buildSectionHeader(),
              const SizedBox(height: 8),
              expenses.isEmpty
                  ? _buildEmptyState()
                  : _buildExpensesList(expenses),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
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
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
      ),
      leadingWidth: 56,
      title: Column(
        children: [
          Text(
            'Profit & Expenses',
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Track profit and expenses.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
            child: IconButton(
              onPressed: null,
              icon: Icon(
                Icons.download_rounded,
                color: AppColors.textHint,
                size: 20,
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppColors.divider,
        ),
      ),
    );
  }

  // ─── TODAY SUMMARY ───────────────────────────────────────────────────
  Widget _buildTodaySummary() {
    final s = ref.read(stringsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              label: s.todayTotalExpenses,
              amount: _fmt(_todayExpenses),
              color: AppColors.primary,
              bgColor: const Color(0xFFEBF2FF),
              icon: Icons.receipt_long_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              label: s.todayNetProfit,
              amount: _fmt(_todayNetProfit.abs()),
              color: AppColors.primary,
              bgColor: const Color(0xFFEBF2FF),
              icon: Icons.trending_up_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String amount,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: AppTypography.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─── BREAKDOWN CARDS ────────────────────────────────────────────────
  Widget _buildBreakdownCards() {
    final s = ref.read(stringsProvider);
    final items = [
      _BreakdownData('Total Sales', _fmt(_totalSales), Icons.point_of_sale_rounded, AppColors.primary, AppColors.primaryLight),
      _BreakdownData('Gross Profit', _fmt(_grossProfit), Icons.trending_up_rounded, AppColors.success, AppColors.successLight),
      _BreakdownData('Bad/Lost/Expired Stock', _fmt(_badStock), Icons.warning_amber_rounded, AppColors.danger, AppColors.dangerLight),
      _BreakdownData('Expenses', _fmt(_totalExpenses), Icons.receipt_long_rounded, AppColors.warning, AppColors.warningLight),
      _BreakdownData('Net Profit', _fmt(_netProfit), Icons.account_balance_rounded, _netProfit >= 0 ? AppColors.success : AppColors.danger, _netProfit >= 0 ? AppColors.successLight : AppColors.dangerLight),
      _BreakdownData('Cash in Hand', _fmt(_cashInHand), Icons.payments_rounded, const Color(0xFF0EA5E9), const Color(0xFFE0F7FF)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.detailedBreakdown,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => _buildBreakdownRow(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(_BreakdownData item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: item.bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: item.color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            item.amount,
            style: AppTypography.bodySmall.copyWith(
              color: item.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ─── ACTION BUTTONS ─────────────────────────────────────────────────
  Widget _buildActionButtons(BuildContext context) {
    final s = ref.read(stringsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: AppConstants.buttonHeight,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/profit-expenses/reports'),
                icon: const Icon(Icons.assessment_rounded, size: 18, color: AppColors.primary),
                label: Text(
                  s.report,
                  style: AppTypography.buttonLarge.copyWith(color: AppColors.primary),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: AppConstants.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: _showAddExpenseDialog,
                icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.textWhite),
                label: Text(
                  s.addExpense,
                  style: AppTypography.buttonLarge.copyWith(color: AppColors.textWhite),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SEARCH ─────────────────────────────────────────────────────────
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: AppTypography.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search expense\u2026',
          hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.close_rounded, color: AppColors.textHint, size: 18),
                )
              : null,
          filled: true,
          fillColor: AppColors.card,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
            borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ─── SECTION HEADER ─────────────────────────────────────────────────
  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Row(
        children: [
          Text(
            'Expenses',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ─── EXPENSES LIST ──────────────────────────────────────────────────
  Widget _buildExpensesList(List<ExpenseItem> expenses) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Column(
        children: expenses.map((e) => _buildExpenseCard(e)).toList(),
      ),
    );
  }

  Widget _buildExpenseCard(ExpenseItem expense) {
    const statusColor = AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEBF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      expense.date,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: AppColors.textHint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Paid',
                        style: AppTypography.caption.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _fmt(expense.amount),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.danger,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showDeleteDialog(expense),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ─── EMPTY STATE ────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingXXL,
          vertical: 40,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Expenses Found',
              style: AppTypography.h6.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different search term.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _BreakdownData {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _BreakdownData(this.label, this.amount, this.icon, this.color, this.bgColor);
}
