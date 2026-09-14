import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/online_shop/presentation/widgets/online_shop_sidebar.dart';

class OnlineShopReportsPage extends ConsumerStatefulWidget {
  const OnlineShopReportsPage({super.key});

  @override
  ConsumerState<OnlineShopReportsPage> createState() => _OnlineShopReportsPageState();
}

class _OnlineShopReportsPageState extends ConsumerState<OnlineShopReportsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final String _activeSidebarItem = 'Reports';

  // KPI data (loaded from API)
  double _thisMonthRevenue = 0;
  double _avgOrderValue = 0;
  int _conversionRate = 0;
  double _cancellationRate = 0;

  List<Map<String, dynamic>> _monthlyRevenue = [];
  List<Map<String, dynamic>> _orderStatus = [];
  List<Map<String, dynamic>> _salesByCategory = [];
  List<Map<String, dynamic>> _paymentMethods = [];
  bool _isLoading = false;

  static const _statusColors = {
    'Received': Color(0xFF22C55E),
    'Processing': Color(0xFF2563EB),
    'Delivering': Color(0xFFFF7A00),
    'Delivered': Color(0xFF14B8A6),
    'Cancelled': Color(0xFFEF4444),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getOnlineShopAdmin();
      final raw = res.data;
      final data = raw is Map ? (raw as Map<String, dynamic>) : <String, dynamic>{};
      final reports = data['reports'] is Map ? (data['reports'] as Map<String, dynamic>) : <String, dynamic>{};
      final summary = data['summary'] is Map ? (data['summary'] as Map<String, dynamic>) : <String, dynamic>{};

      // Monthly revenue
      final monthlyList = (reports['monthly_revenue'] ?? []) as List;
      final monthly = monthlyList.map((m) {
        final mm = m as Map<String, dynamic>;
        return {
          'month': mm['label'] ?? '',
          'revenue': double.tryParse(mm['revenue']?.toString() ?? '') ?? 0.0,
        };
      }).toList();

      // Order status counts
      final statusCountsRaw = reports['status_counts'];
      final statusMap = statusCountsRaw is Map ? statusCountsRaw : {};
      final statuses = statusMap.entries.map((e) {
        final label = e.key.toString();
        final count = int.tryParse(e.value?.toString() ?? '') ?? 0;
        return {
          'status': label,
          'count': count,
          'color': _statusColors[label] ?? const Color(0xFF9CA3AF),
        };
      }).toList()..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      // Category sales
      final catList = (reports['category_sales'] ?? []) as List;
      final cats = catList.map((c) {
        final m = c as Map<String, dynamic>;
        return {
          'category': m['category'] ?? '',
          'sales': (double.tryParse(m['sales']?.toString() ?? '') ?? 0).toInt(),
          'revenue': double.tryParse(m['revenue']?.toString() ?? '') ?? 0.0,
        };
      }).toList();

      // KPIs from summary
      final revenue = double.tryParse(reports['current_month_revenue']?.toString() ?? '') ?? 0;
      final totalOrders = int.tryParse(summary['orders']?.toString() ?? '') ?? 0;
      final totalRevenue = double.tryParse(summary['revenue']?.toString() ?? '') ?? 0;
      final cancelled = int.tryParse(summary['cancelled']?.toString() ?? '') ?? 0;
      final avg = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;
      final cancRate = totalOrders > 0 ? (cancelled / totalOrders * 100) : 0.0;

      setState(() {
        _thisMonthRevenue = revenue;
        _avgOrderValue = avg;
        _conversionRate = totalOrders;
        _cancellationRate = cancRate;
        _monthlyRevenue = monthly;
        _orderStatus = statuses;
        _salesByCategory = cats;
        _paymentMethods = []; // Payment method breakdown not in reports data
      });
    } catch (_) {
      // keep zeros
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    } else if (label == 'Orders') {
      if (currentLocation != '/online-shop/manage-orders') {
        context.go('/online-shop/manage-orders');
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
    } else if (label == 'Settings') {
      if (currentLocation != '/online-shop/settings') {
        context.go('/online-shop/settings');
      }
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return 'Tsh ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    return 'Tsh ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
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
                  _buildKPIs(),
                  const SizedBox(height: 20),
                  _buildMonthlyRevenueChart(),
                  const SizedBox(height: 20),
                  _buildOrderStatusSection(),
                  const SizedBox(height: 20),
                  _buildSalesByCategoryTable(),
                  const SizedBox(height: 20),
                  _buildPaymentMethodsTable(),
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
        'Reports',
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

  Widget _buildKPIs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _KPICard(
                  title: 'This Month Revenue',
                  value: _formatCurrency(_thisMonthRevenue),
                  icon: Icons.attach_money_rounded,
                  color: const Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KPICard(
                  title: 'Avg Order Value',
                  value: _formatCurrency(_avgOrderValue),
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _KPICard(
                  title: 'Conversion Rate',
                  value: '$_conversionRate orders',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF14B8A6),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KPICard(
                  title: 'Cancellation Rate',
                  value: '${_cancellationRate.toStringAsFixed(1)}%',
                  icon: Icons.cancel_rounded,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyRevenueChart() {
    if (_monthlyRevenue.isEmpty) return const SizedBox.shrink();
    final maxRevenue = _monthlyRevenue
        .map((e) => e['revenue'] as double)
        .fold<double>(1.0, (prev, e) => e > prev ? e : prev);

    return _SectionCard(
      title: 'Monthly Revenue',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(_monthlyRevenue.length, (index) {
              final item = _monthlyRevenue[index];
              final revenue = item['revenue'] as double;
              final barHeight = (revenue / maxRevenue) * 140;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(revenue),
                        style: AppTypography.caption.copyWith(fontSize: 8),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: const Color(0xFF14B8A6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['month'] as String,
                        style: AppTypography.caption.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderStatusSection() {
    if (_orderStatus.isEmpty) return const SizedBox.shrink();
    final totalOrders =
        _orderStatus.map((e) => e['count'] as int).fold<int>(0, (a, b) => a + b);
    if (totalOrders == 0) return const SizedBox.shrink();

    return _SectionCard(
      title: 'Order Status',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: _orderStatus.map((item) {
            final count = item['count'] as int;
            final percentage = (count / totalOrders * 100);
            final color = item['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['status'] as String,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$count (${percentage.toStringAsFixed(1)}%)',
                        style: AppTypography.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                    child: LinearProgressIndicator(
                      value: count / totalOrders,
                      minHeight: 8,
                      backgroundColor: AppColors.border.withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSalesByCategoryTable() {
    if (_salesByCategory.isEmpty) return const SizedBox.shrink();
    return _SectionCard(
      title: 'Sales by Category',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            _buildTableRow(
              ['Category', 'Sales', 'Revenue'],
              isHeader: true,
            ),
            const Divider(height: 1, color: AppColors.divider),
            ..._salesByCategory.map((item) {
              return _buildTableRow([
                item['category'] as String,
                '${item['sales']}',
                _formatCurrency(item['revenue'] as double),
              ]);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsTable() {
    if (_paymentMethods.isEmpty) return const SizedBox.shrink();
    return _SectionCard(
      title: 'Payment Methods',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            _buildTableRow(
              ['Method', 'Orders', 'Share'],
              isHeader: true,
            ),
            const Divider(height: 1, color: AppColors.divider),
            ..._paymentMethods.map((item) {
              return _buildTableRow([
                item['method'] as String,
                '${item['orders']}',
                '${(item['share'] as double).toStringAsFixed(1)}%',
              ]);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(List<String> cells, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: List.generate(cells.length, (index) {
          final isLast = index == cells.length - 1;
          return Expanded(
            flex: isLast ? 0 : 1,
            child: isLast
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      cells[index],
                      style: isHeader
                          ? AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            )
                          : AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                    ),
                  )
                : Text(
                    cells[index],
                    style: isHeader
                        ? AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          )
                        : AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                  ),
          );
        }),
      ),
    );
  }
}

class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KPICard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTypography.caption.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF14B8A6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTypography.h6.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}
