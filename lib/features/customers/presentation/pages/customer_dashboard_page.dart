import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/customers/data/models/customer_model.dart';
import 'package:dukaapp/features/customers/presentation/widgets/add_cash_dialog.dart';
import 'package:dukaapp/features/customers/presentation/widgets/add_credit_dialog.dart';
import 'package:dukaapp/features/customers/presentation/widgets/clear_credit_dialog.dart';

class CustomerDashboardPage extends ConsumerStatefulWidget {
  final Customer customer;

  const CustomerDashboardPage({super.key, required this.customer});

  @override
  ConsumerState<CustomerDashboardPage> createState() => _CustomerDashboardPageState();
}

class _CustomerDashboardPageState extends ConsumerState<CustomerDashboardPage> {
  late Customer _customer;

  // Real data loaded from API
  List<Map<String, dynamic>> _salesRecords = [];
  List<Map<String, dynamic>> _walletTransactions = [];
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCustomerData());
  }

  Future<void> _loadCustomerData() async {
    if (!mounted) return;
    setState(() => _isLoadingData = true);
    try {
      final api = ref.read(apiServiceProvider);
      final customerId = _customer.id;
      final results = await Future.wait([
        api.getCustomerSales(customerId),
        api.getWalletCustomerStatement(customerId),
      ]);

      // Parse sales records
      final salesRaw = results[0].data;
      final salesList = _unwrapList(salesRaw);

      // Parse wallet transactions
      final walletRaw = results[1].data;
      final walletList = _unwrapList(walletRaw);

      if (!mounted) return;
      setState(() {
        _salesRecords = salesList;
        _walletTransactions = walletList;
        _isLoadingData = false;
      });
    } catch (e) {
      debugPrint('[CustomerDashboard] load error: $e');
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  List<Map<String, dynamic>> _unwrapList(dynamic raw) {
    if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
    if (raw is Map<String, dynamic>) {
      final v = raw['data'] ?? raw['result'] ?? raw['items'];
      if (v is List) return v.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  // Paid = sum of paid_amount from loaded sales records.
  double get _paid {
    double _d(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0.0;
    return _salesRecords.fold(0.0, (sum, s) => sum + _d(s['paid_amount'] ?? s['paid'] ?? s['amount_paid']));
  }

  double get _walletBalance => _customer.walletBalance;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppConstants.paddingLG,
          right: AppConstants.paddingLG,
          top: AppConstants.paddingMD,
          bottom: 24 + bottomPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomerDetailsCard(),
            const SizedBox(height: 16),
            _buildSalesSummaryCard(),
            const SizedBox(height: 16),
            _buildActionButtons(),
            const SizedBox(height: 20),
            _buildSectionHeader(
              icon: Icons.account_balance_wallet_rounded,
              title: s.walletTransactions,
            ),
            const SizedBox(height: 12),
            _buildWalletTransactions(),
            const SizedBox(height: 20),
            _buildSectionHeader(
              icon: Icons.receipt_long_rounded,
              title: s.salesRecords,
            ),
            const SizedBox(height: 12),
            _buildSalesRecords(),
          ],
        ),
      ),
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
      title: Text(
        s.customerDashboard,
        style: AppTypography.h6.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppColors.divider,
        ),
      ),
    );
  }

  Widget _buildCustomerDetailsCard() {
    final s = ref.read(stringsProvider);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _customer.name,
                        style: AppTypography.h6.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _customer.phone,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.email_outlined, 'Email',
                _customer.email ?? 'Not provided'),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.badge_outlined, 'TIN Number',
                _customer.tinNumber ?? 'Not provided'),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.location_on_outlined, 'Location',
                _customer.location ?? 'Not provided'),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.account_balance_wallet_outlined,
              s.creditLimit,
              'TZS ${_customer.creditLimit.toStringAsFixed(0)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textHint, size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSalesSummaryCard() {
    final s = ref.read(stringsProvider);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.salesSummary,
              style: AppTypography.label.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Sales',
                    '${_customer.totalPurchases}',
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryItem(
                    s.totalSpent,
                    'TZS ${_customer.totalSpent.toStringAsFixed(0)}',
                    AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Paid',
                    'TZS ${_paid.toStringAsFixed(0)}',
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryItem(
                    s.creditBalance,
                    'TZS ${_customer.creditBalance.toStringAsFixed(0)}',
                    _customer.creditBalance > 0
                        ? AppColors.danger
                        : AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    s.walletBalance,
                    'TZS ${_walletBalance.toStringAsFixed(0)}',
                    AppColors.primary,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final s = ref.read(stringsProvider);
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildActionChip(
            icon: Icons.picture_as_pdf_rounded,
            label: 'Statement PDF',
            color: AppColors.danger,
            onTap: () => _showComingSoon('Statement PDF'),
          ),
          const SizedBox(width: 8),
          _buildActionChip(
            icon: Icons.account_balance_wallet_rounded,
            label: s.walletStatement,
            color: AppColors.primary,
            onTap: () => context.push('/customers/wallet'),
          ),
          const SizedBox(width: 8),
          _buildActionChip(
            icon: Icons.shopping_cart_rounded,
            label: s.walletSales,
            color: AppColors.success,
            onTap: () => context.push('/customers/wallet'),
          ),
          const SizedBox(width: 8),
          _buildActionChip(
            icon: Icons.add_circle_outline_rounded,
            label: s.addCash,
            color: AppColors.secondary,
            onTap: () => _showAddCashDialog(),
          ),
          const SizedBox(width: 8),
          _buildActionChip(
            icon: Icons.edit_rounded,
            label: s.editCustomer,
            color: AppColors.primary,
            onTap: () => context.push('/customers/add', extra: _customer),
          ),
          const SizedBox(width: 8),
          _buildActionChip(
            icon: Icons.add_card_rounded,
            label: s.addCredit,
            color: AppColors.warning,
            onTap: () => _showAddCreditDialog(),
          ),
          const SizedBox(width: 8),
          _buildActionChip(
            icon: Icons.clear_all_rounded,
            label: s.clearCredit,
            color: AppColors.danger,
            onTap: () => _showClearCreditDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppConstants.radiusSM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTypography.label.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildWalletTransactions() {
    final s = ref.read(stringsProvider);
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_walletTransactions.isEmpty) {
      return _buildEmptyPlaceholder(
        icon: Icons.account_balance_wallet_outlined,
        message: s.noWalletTransactionsYet,
      );
    }
    // Build from real API data
    final transactions = _walletTransactions.map((t) => <String, String>{
      'date': t['created_at']?.toString() ?? t['date']?.toString() ?? '',
      'direction': (t['type']?.toString() ?? '').toUpperCase().contains('IN') ||
              (t['direction']?.toString() ?? '').toUpperCase() == 'IN'
          ? 'IN'
          : 'OUT',
      'from': t['from']?.toString() ?? t['source']?.toString() ?? '-',
      'to': t['to']?.toString() ?? t['destination']?.toString() ?? '-',
      'title': t['title']?.toString() ?? t['note']?.toString() ?? '-',
      'amount': 'TZS ${t['amount']?.toString() ?? '0'}',
      'balance': 'TZS ${t['balance']?.toString() ?? '0'}',
    }).toList();

    if (transactions.isEmpty) {
      return _buildEmptyPlaceholder(
        icon: Icons.account_balance_wallet_outlined,
        message: s.noWalletTransactionsYet,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            _buildWalletTableHeader(),
            ...transactions.map((t) => _buildWalletRow(t)),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          SizedBox(width: 90, child: _buildHeaderText('Date')),
          SizedBox(width: 40, child: _buildHeaderText('Dir')),
          SizedBox(width: 100, child: _buildHeaderText('From')),
          SizedBox(width: 100, child: _buildHeaderText('To')),
          SizedBox(width: 100, child: _buildHeaderText('Title')),
          SizedBox(width: 100, child: _buildHeaderText('Amount')),
          SizedBox(width: 100, child: _buildHeaderText('Balance')),
          SizedBox(width: 60, child: _buildHeaderText('Action')),
        ],
      ),
    );
  }

  static Widget _buildHeaderText(String text) {
    return Text(
      text,
      style: AppTypography.caption.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
        fontSize: 10,
      ),
    );
  }

  Widget _buildWalletRow(Map<String, String> transaction) {
    final isCredit = transaction['direction'] == 'IN';
    final amountColor = isCredit ? AppColors.success : AppColors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              transaction['date']!,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontSize: 10,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isCredit
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                transaction['direction']!,
                style: AppTypography.caption.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              transaction['from']!,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              transaction['to']!,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              transaction['title']!,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              transaction['amount']!,
              style: AppTypography.caption.copyWith(
                color: amountColor,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              transaction['balance']!,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showAddCashDialog(),
                  child: Icon(Icons.edit_rounded, color: AppColors.primary, size: 14),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showDeleteTransactionConfirmation(),
                  child: Icon(Icons.delete_rounded, color: AppColors.danger, size: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesRecords() {
    final s = ref.read(stringsProvider);
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_salesRecords.isEmpty) {
      return _buildEmptyPlaceholder(
        icon: Icons.receipt_long_outlined,
        message: s.noSalesRecordsYet,
      );
    }
    double _d(dynamic v) => num.tryParse(v?.toString() ?? '')?.toDouble() ?? 0.0;
    final sales = _salesRecords.map((s) {
      final total = _d(s['total_amount'] ?? s['total'] ?? s['amount']);
      final paid = _d(s['paid_amount'] ?? s['paid'] ?? s['amount_paid']);
      final balance = _d(s['balance'] ?? s['balance_amount'] ?? s['amount_due']);
      final status = balance > 0.01 ? 'Unpaid' : 'Paid';
      return <String, String>{
        'sale': '#${s['sale_id'] ?? s['invoice_no'] ?? s['id'] ?? ''}',
        'date': s['record_date']?.toString() ?? s['date']?.toString() ?? s['created_at']?.toString() ?? '',
        'type': s['payment_mode']?.toString() ?? s['type']?.toString() ?? 'Cash',
        'status': status,
        'total': 'TZS ${total.toStringAsFixed(0)}',
        'paid': 'TZS ${paid.toStringAsFixed(0)}',
        'balance': 'TZS ${balance.toStringAsFixed(0)}',
      };
    }).toList();

    if (sales.isEmpty) {
      return _buildEmptyPlaceholder(
        icon: Icons.receipt_long_outlined,
        message: s.noSalesRecordsYet,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            _buildSalesTableHeader(),
            ...sales.map((s) => _buildSalesRow(s)),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          SizedBox(width: 50, child: _buildHeaderText('Sale')),
          SizedBox(width: 90, child: _buildHeaderText('Date')),
          SizedBox(width: 70, child: _buildHeaderText('Type')),
          SizedBox(width: 70, child: _buildHeaderText('Status')),
          SizedBox(width: 90, child: _buildHeaderText('Total')),
          SizedBox(width: 90, child: _buildHeaderText('Paid')),
          SizedBox(width: 90, child: _buildHeaderText('Balance')),
          SizedBox(width: 60, child: _buildHeaderText('Action')),
        ],
      ),
    );
  }

  Widget _buildSalesRow(Map<String, String> sale) {
    final isPaid = sale['status'] == 'Paid';
    final statusColor = isPaid ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              sale['sale']!,
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              sale['date']!,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontSize: 10,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              sale['type']!,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontSize: 10,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                sale['status']!,
                style: AppTypography.caption.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              sale['total']!,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              sale['paid']!,
              style: AppTypography.caption.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              sale['balance']!,
              style: AppTypography.caption.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.push('/sales/add'),
                  child: Icon(Icons.edit_rounded, color: AppColors.primary, size: 14),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showComingSoon('Sale PDF'),
                  child: Icon(Icons.picture_as_pdf_rounded, color: AppColors.danger, size: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder({
    required IconData icon,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 40,
            color: AppColors.textHint.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }


  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature coming soon',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
        ),
      ),
    );
  }

  void _showAddCashDialog() {
    showDialog(
      context: context,
      builder: (context) => AddCashDialog(
        customer: _customer,
        onSuccess: _loadCustomerData,
      ),
    );
  }

  void _showAddCreditDialog() {
    showDialog(
      context: context,
      builder: (context) => AddCreditDialog(customer: _customer, onSuccess: _loadCustomerData),
    );
  }

  void _showClearCreditDialog() {
    showDialog(
      context: context,
      builder: (context) => ClearCreditDialog(
        customer: _customer,
        onSuccess: _loadCustomerData,
      ),
    );
  }

  void _showDeleteTransactionConfirmation() {
    final s = ref.read(stringsProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        ),
        title: Text(
          s.deleteTransaction,
          style: AppTypography.h6.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this wallet transaction? This action cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              s.cancel,
              style: AppTypography.buttonMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    s.transactionDeleted,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textWhite,
                    ),
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
              s.delete,
              style: AppTypography.buttonMedium.copyWith(
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
