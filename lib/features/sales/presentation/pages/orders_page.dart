import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/sales/presentation/providers/sales_provider.dart';
import 'package:dukaapp/features/sales/presentation/widgets/sales_action_button.dart';
import 'package:dukaapp/features/sales/presentation/widgets/sale_product_tile.dart';
import 'package:dukaapp/features/sales/presentation/widgets/payment_summary_card.dart';
import 'package:dukaapp/features/sales/presentation/widgets/sales_bottom_actions.dart';
import 'package:dukaapp/features/sales/presentation/widgets/receipt_widget.dart';
import 'package:dukaapp/shared/dialogs/app_filter_dialog.dart';
import 'package:dukaapp/shared/providers/filter_provider.dart';

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _expandedOrderIndex;
  final Set<int> _selectedOrders = {};
  String _activeFilter = 'all';

  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
  }

  Future<void> _loadOrders({String? from, String? to}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(salesRepositoryProvider);
      final records = await repo.fetchOrders(from: from, to: to);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _orders = records.map((r) => {
          'sale_id': r.saleId,
          'date': r.date,
          'status': r.balance > 0.01 ? 'UNPAID' : 'PAID',
          'paymentMethod': r.paymentMethod,
          'paid': r.paid,
          'balance': r.balance,
          'total': r.totalRaw,
          'customer': r.customer,
          'soldBy': r.soldBy,
          'products': r.products.map((p) => {
            'name': p.name,
            'quantity': p.quantity,
            'price': p.price,
            'total': p.total,
          }).toList(),
        }).toList();
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double get _paidTotal {
    double total = 0;
    for (final order in _orders) {
      if (order['status'] == 'PAID') {
        total += order['paid'] as double;
      }
    }
    return total;
  }

  double get _unpaidTotal {
    double total = 0;
    for (final order in _orders) {
      total += order['balance'] as double;
    }
    return total;
  }

  List<Map<String, dynamic>> get _filteredOrders {
    var orders = _orders;

    if (_activeFilter == 'active') {
      orders = orders.where((o) => o['status'] == 'PENDING').toList();
    } else if (_activeFilter == 'cleared') {
      orders = orders.where((o) => o['status'] == 'PAID').toList();
    }

    if (_searchQuery.isEmpty) return orders;
    return orders.where((order) {
      final customer = (order['customer'] as String).toLowerCase();
      final products = (order['products'] as List)
          .map((p) => (p['name'] as String).toLowerCase())
          .join(' ');
      final query = _searchQuery.toLowerCase();
      return customer.contains(query) || products.contains(query);
    }).toList();
  }

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < formatted.length; i++) {
      if (i > 0 && (formatted.length - i) % 3 == 0) buffer.write(',');
      buffer.write(formatted[i]);
    }
    return 'Tsh ${buffer.toString()}';
  }

  void _toggleOrderExpansion(int index) {
    setState(() {
      _expandedOrderIndex = _expandedOrderIndex == index ? null : index;
    });
  }

  void _toggleOrderSelection(int index) {
    setState(() {
      if (_selectedOrders.contains(index)) {
        _selectedOrders.remove(index);
      } else {
        _selectedOrders.add(index);
      }
    });
  }

  void _deleteOrder(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        ),
        title: Text(
          'Delete Order',
          style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete this order?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final saleId = index < _orders.length ? _orders[index]['sale_id']?.toString() : null;
              if (saleId == null || saleId.isEmpty) {
                setState(() => _expandedOrderIndex = null);
                return;
              }
              try {
                final repo = ref.read(salesRepositoryProvider);
                final res = await repo.deleteRecord({'sale_id': saleId});
                final ok = res['status']?.toString() == '1' || res['status'] == true;
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'Order deleted' : (res['message']?.toString() ?? 'Delete failed')),
                  backgroundColor: ok ? AppColors.success : AppColors.danger,
                ));
                if (ok) {
                  setState(() => _expandedOrderIndex = null);
                  await _loadOrders();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
                );
              }
            },
            child: Text(
              'Delete',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteSelected() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Orders',
          style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete ${_selectedOrders.length} order(s)?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final ids = _selectedOrders
                  .where((i) => i < _orders.length)
                  .map((i) => _orders[i]['sale_id'])
                  .where((id) => id != null && id.toString().isNotEmpty)
                  .toList();
              if (ids.isEmpty) {
                setState(() => _selectedOrders.clear());
                return;
              }
              try {
                final repo = ref.read(salesRepositoryProvider);
                final res = await repo.bulkDelete({'sale_id': ids});
                final ok = res['status']?.toString() == '1' || res['status'] == true;
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'Orders deleted' : (res['message']?.toString() ?? 'Delete failed')),
                  backgroundColor: ok ? AppColors.success : AppColors.danger,
                ));
                if (ok) {
                  setState(() => _selectedOrders.clear());
                  await _loadOrders();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
                );
              }
            },
            child: Text(
              'Delete',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FilterState>(filterProvider, (_, f) => _loadOrders(from: f.from, to: f.to));
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildSummaryCards(),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    if (_selectedOrders.isNotEmpty) _buildDeleteBar(),
                    _buildOrdersList(),
                    SizedBox(height: 24 + bottomPadding),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
            'Orders',
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'SON COLLECTION',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              label: 'Paid Total',
              amount: _formatCurrency(_paidTotal),
              color: AppColors.success,
              bgColor: AppColors.successLight,
              icon: Icons.check_circle_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              label: 'Unpaid Total',
              amount: _formatCurrency(_unpaidTotal),
              color: AppColors.danger,
              bgColor: AppColors.dangerLight,
              icon: Icons.cancel_rounded,
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
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
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
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: AppTypography.bodyMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      height: 90,
      child: Center(
        child: ListView(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
          children: [
            SalesActionButton(
              icon: Icons.filter_list_rounded,
              label: 'Filter',
              onTap: () => AppFilterDialog.show(context),
            ),
            const SizedBox(width: 10),
            SalesActionButton(
              icon: Icons.receipt_long_rounded,
              label: 'Active Orders',
              isHighlighted: _activeFilter == 'active',
              onTap: () {
                setState(() {
                  _activeFilter = _activeFilter == 'active' ? 'all' : 'active';
                });
              },
            ),
            const SizedBox(width: 10),
            SalesActionButton(
              icon: Icons.check_circle_rounded,
              label: 'Cleared Orders',
              isHighlighted: _activeFilter == 'cleared',
              onTap: () {
                setState(() {
                  _activeFilter = _activeFilter == 'cleared' ? 'all' : 'cleared';
                });
              },
            ),
            const SizedBox(width: 10),
            SalesActionButton(
            icon: Icons.add_rounded,
            label: 'New Order',
            isHighlighted: true,
            onTap: () => context.push('/sales/add-order'),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMD,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
          border: Border.all(color: AppColors.inputBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: AppColors.textHint,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search sale by customer or product...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textHint,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedOrders.length} Selected',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _deleteSelected,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.delete_rounded,
                    color: AppColors.danger,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Delete',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_isLoading) return _buildSkeleton();
    if (_filteredOrders.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          border: Border.all(
            color: AppColors.border,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No orders found',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(_filteredOrders.length, (index) {
        final order = _filteredOrders[index];
        return _buildOrderAccordion(order, index);
      }),
    );
  }

  Widget _buildOrderAccordion(Map<String, dynamic> order, int index) {
    final products = List<Map<String, dynamic>>.from(order['products']);
    final isPaid = order['status'] == 'PAID';
    final totalAmount = products.fold<double>(
      0,
      (sum, p) => sum + (p['price'] as double) * (p['quantity'] as int),
    );

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLG,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: _selectedOrders.contains(index)
            ? AppColors.primary.withValues(alpha: 0.04)
            : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _selectedOrders.contains(index)
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => _toggleOrderExpansion(index),
              borderRadius: BorderRadius.circular(14),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: isPaid ? AppColors.success : AppColors.warning,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          bottomLeft: Radius.circular(14),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            _buildCheckbox(index),
                            const SizedBox(width: 10),
                            Expanded(child: _buildOrderInfo(order)),
                            _buildTotalAndChevron(order, totalAmount, index),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildExpandedContent(order, index, products, totalAmount),
        ],
      ),
    );
  }

  Widget _buildCheckbox(int index) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Checkbox(
        value: _selectedOrders.contains(index),
        onChanged: (_) => _toggleOrderSelection(index),
        activeColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: BorderSide(
          color: _selectedOrders.contains(index)
              ? AppColors.primary
              : AppColors.border,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildOrderInfo(Map<String, dynamic> order) {
    final isPaid = order['status'] == 'PAID';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          order['date'],
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isPaid
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                order['status'],
                style: AppTypography.caption.copyWith(
                  color: isPaid ? AppColors.success : AppColors.warning,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'BY ${order['createdBy']}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'To: ${order['customer']}',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalAndChevron(Map<String, dynamic> order, double totalAmount, int orderIndex) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Total',
              style: AppTypography.caption.copyWith(
                color: AppColors.textHint,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatCurrency(totalAmount),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(width: 6),
        AnimatedRotation(
          turns: _expandedOrderIndex == orderIndex ? 0.5 : 0,
          duration: const Duration(milliseconds: 250),
          child: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textHint,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent(
    Map<String, dynamic> order,
    int orderIndex,
    List<Map<String, dynamic>> products,
    double totalAmount,
  ) {
    final isExpanded = _expandedOrderIndex == orderIndex;
    final isPending = order['status'] == 'PENDING';
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: isExpanded
          ? Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 1,
                    color: AppColors.border,
                  ),
                  if (isPending) ...[
                    const SizedBox(height: 12),
                    _buildPendingActions(orderIndex),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Purchased Products',
                    style: AppTypography.captionBold.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...products.map(
                    (product) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SaleProductTile(
                        productName: product['name'] ?? '',
                        quantity: product['quantity'] ?? 0,
                        price: (product['price'] ?? 0).toDouble(),
                        total: (product['total'] ?? 0).toDouble(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PaymentSummaryCard(
                    paymentMethod: order['paymentMode'],
                    paid: order['paid'],
                    discount: order['discount'],
                    balance: order['balance'],
                  ),
                  const SizedBox(height: 12),
                  SalesBottomActions(
                    onDownload: () {},
                    onBackdate: () => _showBackdateDialog(orderIndex),
                    onPrint: () => _showReceiptPreview(order),
                    onPreview: () => _showReceiptPreview(order),
                    onEdit: () {},
                    onDelete: () => _deleteOrder(orderIndex),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildPendingActions(int orderIndex) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _showPayDialog(orderIndex),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Pay',
                    style: AppTypography.buttonMedium.copyWith(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => _showUpdateStatusDialog(orderIndex),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.update_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Update Status',
                    style: AppTypography.buttonMedium.copyWith(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showBackdateDialog(int orderIndex) async {
    final order = _orders[orderIndex];
    final dateStr = order['date'] as String;
    final parts = dateStr.split(' ');
    DateTime parsedDate;
    try {
      parsedDate = DateFormat('MMM dd, yyyy').parse('${parts[0]} ${parts[1]} ${parts[2]}');
    } catch (_) {
      parsedDate = DateTime.now();
    }

    DateTime selectedDate = parsedDate;

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          ),
          title: Text(
            'Backdate Order',
            style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select a new date for this order',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.primary,
                            onPrimary: AppColors.textWhite,
                            surface: AppColors.card,
                            onSurface: AppColors.textPrimary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (date != null) {
                    setDialogState(() => selectedDate = date);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('MMM dd, yyyy').format(selectedDate),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                    ],
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
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selectedDate),
              child: Text(
                'Backdate',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (picked != null && mounted) {
      final formatted = DateFormat('MMM dd, yyyy HH:mm').format(
        DateTime(picked.year, picked.month, picked.day, parsedDate.hour, parsedDate.minute),
      );
      setState(() {
        _orders[orderIndex]['date'] = formatted;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order date updated')),
        );
      }
    }
  }

  void _showPayDialog(int orderIndex) {
    final order = _orders[orderIndex];
    final balance = order['balance'] as double;
    final amountController = TextEditingController(text: balance.toStringAsFixed(0));
    DateTime selectedDate = DateTime.now();
    String selectedAccount = 'Cash';

    final accounts = ['Cash', 'Bank Account', 'Mobile Money', 'Savings'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          ),
          title: Text(
            'Add Payment',
            style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDialogField(
                  label: 'Balance',
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                    ),
                    child: Text(
                      'Tsh ${balance.toStringAsFixed(0)}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDialogField(
                  label: 'Date',
                  child: GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppColors.primary,
                                onPrimary: AppColors.textWhite,
                                surface: AppColors.card,
                                onSurface: AppColors.textPrimary,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        setDialogState(() => selectedDate = date);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('MMM dd, yyyy').format(selectedDate),
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                          ),
                          const Spacer(),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDialogField(
                  label: 'Amount to Collect',
                  child: TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: AppTypography.bodyMedium,
                    cursorColor: AppColors.primary,
                    decoration: InputDecoration(
                      hintText: 'Enter amount',
                      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
                      prefixText: 'Tsh ',
                      prefixStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                        borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDialogField(
                  label: 'Select Account',
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedAccount,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint),
                    style: AppTypography.bodyMedium,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                        borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5),
                      ),
                    ),
                    items: accounts.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                    onChanged: (v) => setDialogState(() => selectedAccount = v ?? 'Cash'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final amount = double.tryParse(amountController.text) ?? 0;
                      if (amount > 0) {
                        setState(() {
                          _orders[orderIndex]['paid'] = (_orders[orderIndex]['paid'] as double) + amount;
                          _orders[orderIndex]['balance'] = balance - amount;
                          if ((_orders[orderIndex]['balance'] as double) <= 0) {
                            _orders[orderIndex]['status'] = 'PAID';
                            _orders[orderIndex]['balance'] = 0.0;
                          }
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Payment recorded successfully')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      'Submit',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w600),
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

  void _showUpdateStatusDialog(int orderIndex) {
    final order = _orders[orderIndex];
    String selectedStatus = order['status'];
    DateTime selectedDate = DateTime.now();

    final statuses = ['PENDING', 'CONFIRMED ORDER', 'DELIVERING', 'DELIVERED', 'DECLINE ORDER'];

    final totalAmount = (order['products'] as List).fold<double>(
      0,
      (sum, p) => sum + (p['price'] as double) * (p['quantity'] as int),
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          ),
          title: Text(
            'Update Order Status',
            style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDialogField(
                  label: 'Customer Name',
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                    ),
                    child: Text(
                      order['customer'],
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDialogField(
                  label: 'Order Value',
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                    ),
                    child: Text(
                      'Tsh ${totalAmount.toStringAsFixed(0)}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDialogField(
                  label: 'Status',
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint),
                    style: AppTypography.bodyMedium,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                        borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5),
                      ),
                    ),
                    items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setDialogState(() => selectedStatus = v ?? 'PENDING'),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDialogField(
                  label: 'Status Date',
                  child: GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppColors.primary,
                                onPrimary: AppColors.textWhite,
                                surface: AppColors.card,
                                onSurface: AppColors.textPrimary,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        setDialogState(() => selectedDate = date);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('MMM dd, yyyy').format(selectedDate),
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                          ),
                          const Spacer(),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _orders[orderIndex]['status'] = selectedStatus;
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Order status updated')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      'Update Status',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w600),
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

  Widget _buildDialogField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.label.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  void _showReceiptPreview(Map<String, dynamic> order) {
    final products = List<Map<String, dynamic>>.from(order['products']);
    final totalAmount = products.fold<double>(
      0,
      (sum, p) => sum + (p['price'] as double) * (p['quantity'] as int),
    );

    ReceiptWidget.show(
      context,
      title: 'Sales Order Receipt',
      receiptNumber: 'RCP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      date: order['date'].split(' ').take(2).join(' '),
      time: order['date'].split(' ').last,
      cashier: order['createdBy'],
      paymentMode: order['paymentMode'],
      items: products,
      subtotal: totalAmount,
      totalPaid: order['paid'],
      amountReceived: order['paid'],
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Column(
        children: List.generate(6, (i) => _OrderSkeletonCard(key: ValueKey(i))),
      ),
    );
  }

}

class _OrderSkeletonCard extends StatefulWidget {
  const _OrderSkeletonCard({super.key});
  @override
  State<_OrderSkeletonCard> createState() => _OrderSkeletonCardState();
}

class _OrderSkeletonCardState extends State<_OrderSkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _c) {
        final c = Color.lerp(const Color(0xFFE0E0E0), const Color(0xFFF5F5F5), _anim.value)!;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppConstants.radiusMD), border: Border.all(color: const Color(0xFFEEEEEE))),
          child: Row(children: [
            Container(width: 4, height: 52, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 120, height: 13, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 8),
              Container(width: 80, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6))),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(width: 70, height: 13, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 8),
              Container(width: 50, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6))),
            ]),
          ]),
        );
      },
    );
  }
}
