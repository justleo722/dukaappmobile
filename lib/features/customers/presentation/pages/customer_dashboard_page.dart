import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/customers/data/models/customer_model.dart';
import 'package:dukaapp/features/customers/presentation/widgets/add_cash_dialog.dart';
import 'package:dukaapp/features/customers/presentation/widgets/add_credit_dialog.dart';
import 'package:dukaapp/features/customers/presentation/widgets/clear_credit_dialog.dart';

class CustomerDashboardPage extends StatefulWidget {
  final Customer customer;

  const CustomerDashboardPage({super.key, required this.customer});

  @override
  State<CustomerDashboardPage> createState() => _CustomerDashboardPageState();
}

class _CustomerDashboardPageState extends State<CustomerDashboardPage> {
  late Customer _customer;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
  }

  double get _paid => _customer.totalSpent - _customer.creditBalance;
  double get _walletBalance => 0;

  @override
  Widget build(BuildContext context) {
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
              title: 'Wallet Transactions',
            ),
            const SizedBox(height: 12),
            _buildWalletTransactions(),
            const SizedBox(height: 20),
            _buildSectionHeader(
              icon: Icons.receipt_long_rounded,
              title: 'Sales Records',
            ),
            const SizedBox(height: 12),
            _buildSalesRecords(),
          ],
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
      title: Text(
        'Customer Dashboard',
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
              'Credit Limit',
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
              'Sales Summary',
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
                    'Total Spent',
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
                    'Credit Balance',
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
                    'Wallet Balance',
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
            label: 'Wallet Statement',
            color: AppColors.primary,
            onTap: () => _showComingSoon('Wallet Statement'),
          ),
          const SizedBox(width: 8),
          _buildActionChip(
            icon: Icons.shopping_cart_rounded,
            label: 'Wallet Sales',
            color: AppColors.success,
            onTap: () => _showComingSoon('Wallet Sales'),
          ),
          const SizedBox(width: 8),
          _buildActionChip(
            icon: Icons.add_circle_outline_rounded,
            label: 'Add Cash',
            color: AppColors.secondary,
            onTap: () => _showAddCashDialog(),
          ),
          const SizedBox(width: 8),
          _buildActionChip(
            icon: Icons.edit_rounded,
            label: 'Edit Customer',
            color: AppColors.primary,
            onTap: () => context.push('/customers/add', extra: _customer),
          ),
          const SizedBox(width: 8),
          _buildActionChip(
            icon: Icons.add_card_rounded,
            label: 'Add Credit',
            color: AppColors.warning,
            onTap: () => _showAddCreditDialog(),
          ),
          const SizedBox(width: 8),
          _buildActionChip(
            icon: Icons.clear_all_rounded,
            label: 'Clear Credit',
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
    final transactions = _generateSampleTransactions();

    if (transactions.isEmpty) {
      return _buildEmptyPlaceholder(
        icon: Icons.account_balance_wallet_outlined,
        message: 'No wallet transactions yet',
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
    final sales = _generateSampleSales();

    if (sales.isEmpty) {
      return _buildEmptyPlaceholder(
        icon: Icons.receipt_long_outlined,
        message: 'No sales records yet',
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

  List<Map<String, String>> _generateSampleTransactions() {
    if (_walletBalance == 0 && _customer.creditBalance == 0) {
      return [];
    }
    return [
      {
        'date': '01/08/2026',
        'direction': 'IN',
        'from': 'Customer',
        'to': 'Wallet',
        'title': 'Cash Deposit',
        'amount': 'TZS 100,000',
        'balance': 'TZS 100,000',
      },
      {
        'date': '28/07/2026',
        'direction': 'OUT',
        'from': 'Wallet',
        'to': 'Sale #1045',
        'title': 'Payment',
        'amount': 'TZS 50,000',
        'balance': 'TZS 0',
      },
    ];
  }

  List<Map<String, String>> _generateSampleSales() {
    if (_customer.totalPurchases == 0) {
      return [];
    }
    return [
      {
        'sale': '#1045',
        'date': '01/08/2026',
        'type': 'Retail',
        'status': 'Paid',
        'total': 'TZS 85,000',
        'paid': 'TZS 85,000',
        'balance': 'TZS 0',
      },
      {
        'sale': '#1032',
        'date': '25/07/2026',
        'type': 'Credit',
        'status': 'Unpaid',
        'total': 'TZS 120,000',
        'paid': 'TZS 0',
        'balance': 'TZS 120,000',
      },
      {
        'sale': '#1018',
        'date': '18/07/2026',
        'type': 'Retail',
        'status': 'Paid',
        'total': 'TZS 45,000',
        'paid': 'TZS 45,000',
        'balance': 'TZS 0',
      },
    ];
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
      builder: (context) => AddCashDialog(customer: _customer),
    );
  }

  void _showAddCreditDialog() {
    showDialog(
      context: context,
      builder: (context) => AddCreditDialog(customer: _customer),
    );
  }

  void _showClearCreditDialog() {
    showDialog(
      context: context,
      builder: (context) => ClearCreditDialog(customer: _customer),
    );
  }

  void _showDeleteTransactionConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        ),
        title: Text(
          'Delete Transaction',
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
              'Cancel',
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
                    'Transaction deleted',
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
              'Delete',
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
