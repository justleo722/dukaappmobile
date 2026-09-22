// features/online_shop/presentation/pages/online_shop_manage_orders_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/online_shop/presentation/widgets/online_shop_sidebar.dart';

class OnlineShopManageOrdersPage extends ConsumerStatefulWidget {
  const OnlineShopManageOrdersPage({super.key});

  @override
  ConsumerState<OnlineShopManageOrdersPage> createState() =>
      _OnlineShopManageOrdersPageState();
}

class _OnlineShopManageOrdersPageState
    extends ConsumerState<OnlineShopManageOrdersPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final String _activeSidebarItem = 'Orders';
  String _selectedStatus = 'All Status';
  DateTime? _fromDate;
  DateTime? _toDate;
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  List<Map<String, dynamic>> _allOrders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getOnlineShopAdmin();
      final raw = res.data;
      final data = raw is Map ? (raw as Map<String, dynamic>) : <String, dynamic>{};
      final orders = (data['orders'] ?? []) as List;
      final fmt = NumberFormat('#,###');
      setState(() {
        _allOrders = orders.map((o) {
          final m = o as Map<String, dynamic>;
          final total = double.tryParse(m['total_amount']?.toString() ?? '') ?? 0;
          final dateStr = (m['record_date'] ?? '').toString();
          // Format date for display: YYYY-MM-DD → "Jan 1, 2024"
          String displayDate = dateStr;
          try {
            if (dateStr.isNotEmpty) {
              final d = DateTime.parse(dateStr.length > 10 ? dateStr : '${dateStr}T00:00:00');
              displayDate = DateFormat('MMM d, y').format(d);
            }
          } catch (_) {}
          return {
            'orderId': (m['order_code'] ?? m['invoice_no'] ?? 'ORD-${m['sale_id'] ?? ''}').toString(),
            'customer': m['customer'] ?? 'Unknown',
            'items': int.tryParse(m['items_count']?.toString() ?? '') ?? 0,
            'total': 'Tsh ${fmt.format(total.round())}',
            'payment': m['payment_method'] ?? '-',
            'date': displayDate,
            'status': _normalizeStatus(m['status']?.toString() ?? 'Pending'),
            '_rawDate': dateStr,
          };
        }).toList();
      });
    } catch (_) {
      if (mounted) setState(() => _allOrders = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _normalizeStatus(String s) {
    switch (s.toLowerCase()) {
      case 'received': return 'Received';
      case 'processing': return 'Processing';
      case 'delivering': return 'Delivering';
      case 'delivered': return 'Delivered';
      case 'cancelled':
      case 'canceled':
      case 'decline order': return 'Cancelled';
      default: return 'Received';
    }
  }

  void _onSidebarItemTap(String label) {
    Navigator.of(context).pop();
    final currentLocation = GoRouterState.of(context).matchedLocation;

    if (label == 'Dashboard') {
      if (currentLocation != '/online-shop') {
        context.go('/online-shop');
      }
    } else if (label == 'Products') {
      if (currentLocation != '/online-shop/manage-products') {
        context.go('/online-shop/manage-products');
      }
    } else if (label == 'Coupons') {
      if (currentLocation != '/online-shop/coupons') {
        context.go('/online-shop/coupons');
      }
    } else if (label == 'Categories') {
      if (currentLocation != '/online-shop/categories') {
        context.go('/online-shop/categories');
      }
    } else if (label == 'Delivery') {
      if (currentLocation != '/online-shop/delivery') {
        context.go('/online-shop/delivery');
      }
    } else if (label == 'Payments') {
      if (currentLocation != '/online-shop/payments') {
        context.go('/online-shop/payments');
      }
    } else if (label == 'Reports') {
      if (currentLocation != '/online-shop/reports') {
        context.go('/online-shop/reports');
      }
    } else if (label == 'Settings') {
      if (currentLocation != '/online-shop/settings') {
        context.go('/online-shop/settings');
      }
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    var orders = _allOrders;
    if (_selectedStatus != 'All Status') {
      orders = orders.where((o) => o['status'] == _selectedStatus).toList();
    }
    if (_fromDate != null) {
      orders = orders.where((o) {
        final raw = o['_rawDate']?.toString() ?? '';
        try {
          final d = DateTime.parse(raw.length > 10 ? raw : '${raw}T00:00:00');
          return !d.isBefore(_fromDate!);
        } catch (_) { return true; }
      }).toList();
    }
    if (_toDate != null) {
      orders = orders.where((o) {
        final raw = o['_rawDate']?.toString() ?? '';
        try {
          final d = DateTime.parse(raw.length > 10 ? raw : '${raw}T00:00:00');
          return !d.isAfter(_toDate!);
        } catch (_) { return true; }
      }).toList();
    }
    return orders;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(context),
      drawer: OnlineShopSidebar(
        activeItem: _activeSidebarItem,
        onItemTap: _onSidebarItemTap,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildFilterSection(),
                  const SizedBox(height: 16),
                  _buildOrdersList(),
                  SizedBox(height: 24 + bottomPadding),
                ],
              ),
            ),
          ),
        ],
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
            onPressed: () => context.go('/online-shop'),
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
        'Manage Orders',
        style: AppTypography.h6.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 1.5),
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
            child: IconButton(
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              icon: const Icon(
                Icons.menu_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.divider),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Filter Orders',
                style: AppTypography.h6.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
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
            child: Column(
              children: [
                _buildStatusDropdown(),
                const SizedBox(height: 12),
                _buildDateRow(),
                const SizedBox(height: 12),
                _buildFilterButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatus,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          items: _statusOptions.map((String status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Text(status),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() => _selectedStatus = newValue!);
          },
        ),
      ),
    );
  }

  Widget _buildDateRow() {
    return Row(
      children: [
        Expanded(
          child: _buildDateField(
            label: 'From',
            controller: _fromDateController,
            selectedDate: _fromDate,
            onDateSelected: (date) => setState(() => _fromDate = date),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDateField(
            label: 'To',
            controller: _toDateController,
            selectedDate: _toDate,
            onDateSelected: (date) => setState(() => _toDate = date),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required DateTime? selectedDate,
    required ValueChanged<DateTime> onDateSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption.copyWith(fontSize: 11)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              onDateSelected(date);
              controller.text =
                  '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: selectedDate != null
                    ? AppColors.primary
                    : AppColors.border,
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              color: selectedDate != null
                  ? AppColors.primary.withValues(alpha: 0.03)
                  : null,
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 16,
                    color: selectedDate != null
                        ? AppColors.primary
                        : AppColors.textHint),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.text.isEmpty ? 'Select date' : controller.text,
                    style: AppTypography.bodySmall.copyWith(
                      color: controller.text.isEmpty
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (selectedDate != null)
                  GestureDetector(
                    onTap: () {
                      controller.clear();
                      if (label == 'From') {
                        setState(() => _fromDate = null);
                      } else {
                        setState(() => _toDate = null);
                      }
                    },
                    child: Icon(Icons.close_rounded,
                        size: 16, color: AppColors.textHint),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: () {
          setState(() {});
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          ),
          elevation: 0,
        ),
        child: Text(
          'Filter',
          style: AppTypography.buttonMedium.copyWith(color: AppColors.textWhite),
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    final orders = _filteredOrders;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A00),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Orders (${orders.length})',
                style: AppTypography.h6.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (orders.isEmpty)
            _buildEmptyState()
          else
            ...orders.map((order) => _OrderCard(
                  order: order,
                  onViewDetails: () => context.push(
                    '/online-shop/order-details',
                    extra: order,
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingXXL),
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
      child: Column(
        children: [
          Icon(
            Icons.shopping_bag_rounded,
            size: 48,
            color: AppColors.textHint.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'No orders found',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Orders will appear here once customers place them',
            style: AppTypography.caption.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onViewDetails;

  const _OrderCard({
    required this.order,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String;
    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['orderId'] as String,
                      style: AppTypography.h6.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order['customer'] as String,
                      style: AppTypography.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onViewDetails,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                  ),
                  child: const Icon(
                    Icons.visibility_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildInfoColumn('Items', '${order['items']}'),
              _buildInfoColumn('Total', order['total'] as String),
              _buildInfoColumn('Payment', order['payment'] as String),
              _buildInfoColumn('Date', order['date'] as String),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                ),
                child: Text(
                  status,
                  style: AppTypography.labelSmall.copyWith(
                    color: statusColor,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Delivered':
        return AppColors.success;
      case 'Delivering':
        return AppColors.secondary;
      case 'Received':
        return AppColors.primary;
      case 'Cancelled':
        return AppColors.danger;
      case 'Processing':
        return AppColors.warning;
      default:
        return AppColors.textHint;
    }
  }
}

const List<String> _statusOptions = [
  'All Status',
  'Received',
  'Processing',
  'Delivering',
  'Delivered',
  'Cancelled',
];

// Orders loaded from API in _loadData()
