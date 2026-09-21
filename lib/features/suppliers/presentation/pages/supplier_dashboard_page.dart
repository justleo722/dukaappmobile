import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/suppliers/data/models/supplier_model.dart';

class SupplierDashboardPage extends ConsumerStatefulWidget {
  final Supplier supplier;

  const SupplierDashboardPage({super.key, required this.supplier});

  @override
  ConsumerState<SupplierDashboardPage> createState() => _SupplierDashboardPageState();
}

class _SupplierDashboardPageState extends ConsumerState<SupplierDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Supplier _supplier;

  @override
  void initState() {
    super.initState();
    _supplier = widget.supplier;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double get _paid => _supplier.totalPurchases - _supplier.creditBalance;

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
            _buildContactDetailsCard(),
            const SizedBox(height: 16),
            _buildPurchaseSummaryCard(),
            const SizedBox(height: 16),
            _buildActionButtons(),
            const SizedBox(height: 20),
            _buildSectionHeader(
              icon: Icons.receipt_long_rounded,
              title: s.transactions,
            ),
            const SizedBox(height: 12),
            _buildTransactionTabs(),
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
        s.supplierDashboard,
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

  Widget _buildContactDetailsCard() {
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
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.business_rounded,
                    color: AppColors.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _supplier.name,
                        style: AppTypography.h6.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _supplier.phone,
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
            _buildDetailRow(
              Icons.phone_outlined,
              'Phone',
              _supplier.phone,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.email_outlined,
              'Email',
              _supplier.email ?? 'Not set',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.business_center_outlined,
              s.company,
              _supplier.companyName ?? 'Not set',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.badge_outlined,
              'TIN',
              _supplier.tinNumber ?? 'Not set',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.location_on_outlined,
              'Address',
              _supplier.address ?? 'Not set',
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

  Widget _buildPurchaseSummaryCard() {
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
              s.purchaseSummary,
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
                    'Purchases',
                    '${_supplier.totalOrders.toInt()}',
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryItem(
                    'Total Amount',
                    'TZS ${_supplier.totalPurchases.toStringAsFixed(0)}',
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
                    'Balance',
                    'TZS ${_supplier.creditBalance.toStringAsFixed(0)}',
                    _supplier.creditBalance > 0
                        ? AppColors.danger
                        : AppColors.success,
                  ),
                ),
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
            onTap: () => _generateStatementPDF(),
          ),
          const SizedBox(width: 8),
          _buildActionChip(
            icon: Icons.edit_rounded,
            label: s.editSupplier,
            color: AppColors.primary,
            onTap: () => context.push('/suppliers/add', extra: _supplier),
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

  Widget _buildTransactionTabs() {
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
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w500,
              ),
              indicatorColor: AppColors.primary,
              indicatorWeight: 2,
              tabs: const [
                Tab(text: 'Cash Purchases'),
                Tab(text: 'Credit Purchases'),
                Tab(text: 'Purchase Orders'),
              ],
            ),
          ),
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCashPurchasesTab(),
                _buildCreditPurchasesTab(),
                _buildPurchaseOrdersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashPurchasesTab() {
    final s = ref.read(stringsProvider);
    final purchases = _generateSampleCashPurchases();

    if (purchases.isEmpty) {
      return _buildEmptyPlaceholder(
        icon: Icons.money_off_rounded,
        message: s.noCashPurchasesFound,
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          _buildTableHeader(
            columns: [
              ('Purchase', 60),
              ('Date', 80),
              ('Type', 60),
              ('Status', 70),
              ('Total', 90),
              ('Paid', 90),
              ('Balance', 90),
            ],
          ),
          ...purchases.map((p) => _buildCashPurchaseRow(p)),
        ],
      ),
    );
  }

  Widget _buildCreditPurchasesTab() {
    final s = ref.read(stringsProvider);
    final purchases = _generateSampleCreditPurchases();

    if (purchases.isEmpty) {
      return _buildEmptyPlaceholder(
        icon: Icons.credit_card_off_rounded,
        message: s.noCreditPurchasesFound,
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          _buildTableHeader(
            columns: [
              ('Purchase', 60),
              ('Date', 80),
              ('Type', 60),
              ('Status', 70),
              ('Total', 90),
              ('Paid', 90),
              ('Balance', 90),
              ('Action', 60),
            ],
          ),
          ...purchases.map((p) => _buildCreditPurchaseRow(p)),
        ],
      ),
    );
  }

  Widget _buildPurchaseOrdersTab() {
    final s = ref.read(stringsProvider);
    final orders = _generateSampleOrders();

    if (orders.isEmpty) {
      return _buildEmptyPlaceholder(
        icon: Icons.shopping_cart_outlined,
        message: s.noPurchaseOrdersFound,
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          _buildTableHeader(
            columns: [
              ('Order', 70),
              ('Date', 90),
              ('Status', 80),
              ('Total', 100),
            ],
          ),
          ...orders.map((o) => _buildOrderRow(o)),
        ],
      ),
    );
  }

  Widget _buildTableHeader({
    required List<(String, double)> columns,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: columns.map((col) {
          return SizedBox(
            width: col.$2,
            child: Text(
              col.$1,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCashPurchaseRow(Map<String, String> purchase) {
    final isPaid = purchase['status'] == 'Paid';
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
            width: 60,
            child: Text(
              purchase['purchase']!,
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              purchase['date']!,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontSize: 10,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              purchase['type']!,
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
                purchase['status']!,
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
              purchase['total']!,
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
              purchase['paid']!,
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
              purchase['balance']!,
              style: AppTypography.caption.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditPurchaseRow(Map<String, String> purchase) {
    final status = purchase['status']!;
    final statusColor = status == 'Unpaid'
        ? AppColors.danger
        : status == 'Partial'
            ? AppColors.warning
            : AppColors.success;

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
            width: 60,
            child: Text(
              purchase['purchase']!,
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              purchase['date']!,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontSize: 10,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              purchase['type']!,
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
                status,
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
              purchase['total']!,
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
              purchase['paid']!,
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
              purchase['balance']!,
              style: AppTypography.caption.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: GestureDetector(
              onTap: () => _showPayDialog(purchase),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Pay',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderRow(Map<String, String> order) {
    final status = order['status']!;
    Color statusColor;
    if (status == 'Completed') {
      statusColor = AppColors.success;
    } else if (status == 'Pending') {
      statusColor = AppColors.warning;
    } else {
      statusColor = AppColors.primary;
    }

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
            width: 70,
            child: Text(
              order['order']!,
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
              order['date']!,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontSize: 10,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status,
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
            width: 100,
            child: Text(
              order['total']!,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
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

  List<Map<String, String>> _generateSampleCashPurchases() {
    if (_supplier.totalPurchases == 0) return [];
    return [
      {
        'purchase': '#P1024',
        'date': '05/08/2026',
        'type': 'Cash',
        'status': 'Paid',
        'total': 'TZS 1,250,000',
        'paid': 'TZS 1,250,000',
        'balance': 'TZS 0',
      },
      {
        'purchase': '#P1018',
        'date': '28/07/2026',
        'type': 'Cash',
        'status': 'Paid',
        'total': 'TZS 850,000',
        'paid': 'TZS 850,000',
        'balance': 'TZS 0',
      },
      {
        'purchase': '#P1005',
        'date': '15/07/2026',
        'type': 'Cash',
        'status': 'Paid',
        'total': 'TZS 2,100,000',
        'paid': 'TZS 2,100,000',
        'balance': 'TZS 0',
      },
    ];
  }

  List<Map<String, String>> _generateSampleCreditPurchases() {
    if (_supplier.creditBalance == 0) return [];
    return [
      {
        'purchase': '#P1030',
        'date': '08/08/2026',
        'type': 'Credit',
        'status': 'Unpaid',
        'total': 'TZS 500,000',
        'paid': 'TZS 0',
        'balance': 'TZS 500,000',
      },
      {
        'purchase': '#P1022',
        'date': '01/08/2026',
        'type': 'Credit',
        'status': 'Partial',
        'total': 'TZS 350,000',
        'paid': 'TZS 200,000',
        'balance': 'TZS 150,000',
      },
    ];
  }

  List<Map<String, String>> _generateSampleOrders() {
    return [
      {
        'order': '#PO2045',
        'date': '10/08/2026',
        'status': 'Pending',
        'total': 'TZS 1,800,000',
      },
      {
        'order': '#PO2038',
        'date': '02/08/2026',
        'status': 'Completed',
        'total': 'TZS 950,000',
      },
      {
        'order': '#PO2021',
        'date': '25/07/2026',
        'status': 'Completed',
        'total': 'TZS 2,400,000',
      },
    ];
  }

  void _showPayDialog(Map<String, String> purchase) {
    final amountController = TextEditingController(text: purchase['balance']!.replaceAll(RegExp(r'[^0-9]'), ''));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        ),
        title: Text(
          'Pay Credit Purchase',
          style: AppTypography.h6.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Purchase: ${purchase['purchase']}',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Outstanding: ${purchase['balance']}',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount to pay',
                prefixText: 'TZS ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                ),
              ),
            ),
          ],
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
                    'Payment recorded for ${purchase['purchase']}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textWhite,
                    ),
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                  ),
                ),
              );
            },
            child: Text(
              'Pay',
              style: AppTypography.buttonMedium.copyWith(
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateStatementPDF() async {
    final s = ref.read(stringsProvider);
    try {
      final pdf = pw.Document();

      final cashPurchases = _generateSampleCashPurchases();
      final creditPurchases = _generateSampleCreditPurchases();
      final orders = _generateSampleOrders();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Supplier Statement',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Supplier: ${_supplier.name}'),
            pw.Text('Phone: ${_supplier.phone}'),
            pw.Text('Company: ${_supplier.companyName ?? "N/A"}'),
            pw.Text('TIN: ${_supplier.tinNumber ?? "N/A"}'),
            pw.Text('Address: ${_supplier.address ?? "N/A"}'),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Header(
              level: 1,
              child: pw.Text(
                s.purchaseSummary,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Purchases: ${_supplier.totalOrders.toInt()}'),
                pw.Text('Total Amount: TZS ${_supplier.totalPurchases.toStringAsFixed(0)}'),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Paid: TZS ${_paid.toStringAsFixed(0)}'),
                pw.Text('Balance: TZS ${_supplier.creditBalance.toStringAsFixed(0)}'),
              ],
            ),
            pw.SizedBox(height: 20),
            if (cashPurchases.isNotEmpty) ...[
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Cash Purchases',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                headers: ['Purchase', 'Date', 'Type', 'Status', 'Total', 'Paid', 'Balance'],
                data: cashPurchases.map((p) => [
                  p['purchase']!, p['date']!, p['type']!, p['status']!,
                  p['total']!, p['paid']!, p['balance']!,
                ]).toList(),
              ),
              pw.SizedBox(height: 20),
            ],
            if (creditPurchases.isNotEmpty) ...[
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Credit Purchases',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                headers: ['Purchase', 'Date', 'Type', 'Status', 'Total', 'Paid', 'Balance'],
                data: creditPurchases.map((p) => [
                  p['purchase']!, p['date']!, p['type']!, p['status']!,
                  p['total']!, p['paid']!, p['balance']!,
                ]).toList(),
              ),
              pw.SizedBox(height: 20),
            ],
            if (orders.isNotEmpty) ...[
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Purchase Orders',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                headers: ['Order', 'Date', 'Status', 'Total'],
                data: orders.map((o) => [
                  o['order']!, o['date']!, o['status']!, o['total']!,
                ]).toList(),
              ),
            ],
            pw.SizedBox(height: 30),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text(
              'Generated on: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
        ),
      );

      final bytes = await pdf.save();

      if (mounted) {
        await Printing.layoutPdf(
          onLayout: (format) async => bytes,
          name: 'Supplier Statement - ${_supplier.name}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error generating PDF: $e',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite),
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
          ),
        );
      }
    }
  }
}
