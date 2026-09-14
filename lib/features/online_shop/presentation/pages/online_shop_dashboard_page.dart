// features/online_shop/presentation/pages/online_shop_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/online_shop/presentation/widgets/online_shop_sidebar.dart';
import 'package:dukaapp/features/online_shop/presentation/widgets/online_shop_summary_cards.dart';
import 'package:dukaapp/features/online_shop/presentation/widgets/recent_orders_table.dart';
import 'package:dukaapp/features/online_shop/presentation/widgets/top_products_table.dart';

class OnlineShopDashboardPage extends ConsumerStatefulWidget {
  const OnlineShopDashboardPage({super.key});

  @override
  ConsumerState<OnlineShopDashboardPage> createState() =>
      _OnlineShopDashboardPageState();
}

class _OnlineShopDashboardPageState extends ConsumerState<OnlineShopDashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final String _activeSidebarItem = 'Dashboard';

  String _revenue = 'Tsh 0';
  String _productCount = '0';
  String _orderCount = '0';
  String _customerCount = '0';
  List<Map<String, dynamic>> _recentOrders = [];
  List<Map<String, dynamic>> _topProducts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getOnlineShopAdmin();
      final raw = res.data;
      final data = raw is Map ? (raw as Map<String, dynamic>) : <String, dynamic>{};
      final summary = data['summary'] is Map ? (data['summary'] as Map<String, dynamic>) : <String, dynamic>{};
      final fmt = NumberFormat('#,###');

      final rev = double.tryParse(summary['revenue']?.toString() ?? '') ?? 0;
      final prods = int.tryParse(summary['product_count']?.toString() ?? '') ?? (data['products'] as List?)?.length ?? 0;
      final orders = int.tryParse(summary['orders']?.toString() ?? '') ?? 0;

      // Recent orders (last 5)
      final orderList = (data['orders'] ?? []) as List;
      final recentOrders = orderList.take(5).map((o) {
        final m = o as Map<String, dynamic>;
        final total = double.tryParse(m['total_amount']?.toString() ?? '') ?? 0;
        return {
          'orderId': 'ORD-${m['sale_id'] ?? ''}',
          'customer': m['customer'] ?? 'Unknown',
          'amount': 'Tsh ${fmt.format(total.round())}',
          'status': _normalizeStatus(m['status']?.toString() ?? 'Pending'),
        };
      }).toList();

      // Top products by sales_count
      final productList = List<Map<String, dynamic>>.from((data['products'] ?? []) as List);
      productList.sort((a, b) {
        final aSales = double.tryParse(a['sales_count']?.toString() ?? '') ?? 0;
        final bSales = double.tryParse(b['sales_count']?.toString() ?? '') ?? 0;
        return bSales.compareTo(aSales);
      });
      final topProducts = productList.take(5).map((p) {
        final price = double.tryParse(p['price']?.toString() ?? '') ?? 0;
        final avail = (double.tryParse(p['available']?.toString() ?? '') ?? 0).toInt();
        final reorder = (double.tryParse(p['reorder_level']?.toString() ?? '') ?? 0).toInt();
        return {
          'product': p['product_name'] ?? p['name'] ?? '',
          'price': 'Tsh ${fmt.format(price.round())}',
          'sales': (double.tryParse(p['sales_count']?.toString() ?? '') ?? 0).toInt(),
          'stock': avail <= reorder ? 'Low Stock' : 'In Stock',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _revenue = 'Tsh ${fmt.format(rev.round())}';
          _productCount = '$prods';
          _orderCount = '$orders';
          _customerCount = summary['customers']?.toString() ?? '0';
          _recentOrders = recentOrders;
          _topProducts = topProducts;
        });
      }
    } catch (_) {
      // keep defaults
    }
  }

  String _normalizeStatus(String s) {
    switch (s.toLowerCase()) {
      case 'received': return 'Received';
      case 'processing': return 'Processing';
      case 'delivering': return 'Delivering';
      case 'delivered': return 'Delivered';
      case 'cancelled': case 'canceled': return 'Cancelled';
      default: return 'Received';
    }
  }

  void _onSidebarItemTap(String label) {
    Navigator.of(context).pop();
    final currentLocation = GoRouterState.of(context).matchedLocation;

    if (label == 'Products') {
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
                  OnlineShopSummaryCards(
                    revenue: _revenue,
                    productCount: _productCount,
                    orderCount: _orderCount,
                    customerCount: _customerCount,
                  ),
                  const SizedBox(height: 20),
                  RecentOrdersTable(orders: _recentOrders),
                  const SizedBox(height: 20),
                  TopProductsTable(products: _topProducts),
                  SizedBox(height: 20 + bottomPadding),
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
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
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
            'Online Shop Dashboard',
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Manage your online store',
            style: AppTypography.caption.copyWith(fontSize: 10),
          ),
        ],
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
}
