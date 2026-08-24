import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

class _ExpenseItem {
  final int sn;
  final String date;
  final String title;
  final String category;
  final double amount;
  final String status;

  const _ExpenseItem({
    required this.sn,
    required this.date,
    required this.title,
    required this.category,
    required this.amount,
    required this.status,
  });
}

class ProfitExpensesPage extends StatefulWidget {
  const ProfitExpensesPage({super.key});

  @override
  State<ProfitExpensesPage> createState() => _ProfitExpensesPageState();
}

class _ProfitExpensesPageState extends State<ProfitExpensesPage> {
  final TextEditingController _searchController = TextEditingController();

  static const List<_ExpenseItem> _allExpenses = [
    _ExpenseItem(sn: 1, date: '13 Aug 2026', title: 'Rent Payment', category: 'Utilities', amount: 500000, status: 'Paid'),
    _ExpenseItem(sn: 2, date: '13 Aug 2026', title: 'Electricity Bill', category: 'Utilities', amount: 85000, status: 'Paid'),
    _ExpenseItem(sn: 3, date: '12 Aug 2026', title: 'Staff Lunch', category: 'Food', amount: 25000, status: 'Paid'),
    _ExpenseItem(sn: 4, date: '12 Aug 2026', title: 'Transport Fare', category: 'Transport', amount: 15000, status: 'Pending'),
    _ExpenseItem(sn: 5, date: '11 Aug 2026', title: 'Cleaning Supplies', category: 'Maintenance', amount: 12000, status: 'Paid'),
    _ExpenseItem(sn: 6, date: '10 Aug 2026', title: 'Internet Subscription', category: 'Utilities', amount: 45000, status: 'Paid'),
    _ExpenseItem(sn: 7, date: '09 Aug 2026', title: 'Packaging Materials', category: 'Operations', amount: 30000, status: 'Paid'),
    _ExpenseItem(sn: 8, date: '08 Aug 2026', title: 'Water Bill', category: 'Utilities', amount: 18000, status: 'Pending'),
  ];

  List<_ExpenseItem> get _filteredExpenses {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return _allExpenses;
    return _allExpenses
        .where((e) =>
            e.title.toLowerCase().contains(query) ||
            e.category.toLowerCase().contains(query) ||
            e.status.toLowerCase().contains(query))
        .toList();
  }

  double get _todayExpenses => _allExpenses
      .where((e) => e.date == DateFormat('dd MMM yyyy').format(DateTime.now()))
      .fold(0, (s, e) => s + e.amount);

  double get _totalExpenses => _allExpenses.fold(0, (s, e) => s + e.amount);

  double get _todayNetProfit => 125000 - _todayExpenses;

  double get _totalSales => 2450000;
  double get _grossProfit => 680000;
  double get _badStock => 45000;
  double get _netProfit => _totalSales - _totalExpenses - _badStock;
  double get _cashInHand => 380000;

  String _fmt(double v) {
    final fmt = NumberFormat('#,###');
    return 'Tsh ${fmt.format(v)}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddExpenseDialog() {
    String? selectedCategory;
    String? selectedAccount;
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final categories = ['Purchases', 'Salaries', 'Utilities', 'Food', 'Transport', 'Maintenance', 'Operations', 'Miscellaneous'];
    final accounts = ['Bank', 'Cash', 'Mobile Money'];

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
                      'Add Expense',
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
                                  value: selectedCategory,
                                  hint: Text(
                                    'Select category',
                                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
                                  ),
                                  isExpanded: true,
                                  items: categories.map((c) {
                                    return DropdownMenuItem(
                                      value: c,
                                      child: Text(c, style: AppTypography.bodyMedium),
                                    );
                                  }).toList(),
                                  onChanged: (v) => setDialogState(() => selectedCategory = v),
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
                                        hintText: 'Category name',
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
                                          if (newCatController.text.isNotEmpty) {
                                            setDialogState(() {
                                              categories.add(newCatController.text);
                                              selectedCategory = newCatController.text;
                                            });
                                            Navigator.pop(ctx2);
                                          }
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
                      _buildDialogFieldLabel('Expense Name'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        style: AppTypography.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Enter expense name',
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
                            value: selectedAccount,
                            hint: Text(
                              'Select account',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
                            ),
                            isExpanded: true,
                            items: accounts.map((a) {
                              return DropdownMenuItem(
                                value: a,
                                child: Text(a, style: AppTypography.bodyMedium),
                              );
                            }).toList(),
                            onChanged: (v) => setDialogState(() => selectedAccount = v),
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
                          onPressed: () {
                            if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Expense saved successfully',
                                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite),
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.check_rounded, size: 18, color: AppColors.textWhite),
                          label: Text(
                            'Save Expense',
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
        ),
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

  void _showDeleteDialog(_ExpenseItem expense) {
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
              'Cancel',
              style: AppTypography.buttonLarge.copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {});
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              label: 'Today Total Expenses',
              amount: _fmt(_todayExpenses),
              color: AppColors.primary,
              bgColor: const Color(0xFFEBF2FF),
              icon: Icons.receipt_long_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              label: 'Today Net Profit',
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
              'Detailed Breakdown',
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
                  'Report',
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
                  'Add Expense',
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
  Widget _buildExpensesList(List<_ExpenseItem> expenses) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Column(
        children: expenses.map((e) => _buildExpenseCard(e)).toList(),
      ),
    );
  }

  Widget _buildExpenseCard(_ExpenseItem expense) {
    final isPaid = expense.status == 'Paid';
    final statusColor = isPaid ? AppColors.success : AppColors.warning;

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
                        expense.status,
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
