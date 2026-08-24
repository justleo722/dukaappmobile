// features/online_shop/presentation/pages/online_shop_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/online_shop/presentation/widgets/online_shop_sidebar.dart';
import 'package:dukaapp/features/online_shop/presentation/widgets/online_shop_summary_cards.dart';
import 'package:dukaapp/features/online_shop/presentation/widgets/recent_orders_table.dart';
import 'package:dukaapp/features/online_shop/presentation/widgets/top_products_table.dart';

class OnlineShopDashboardPage extends StatefulWidget {
  const OnlineShopDashboardPage({super.key});

  @override
  State<OnlineShopDashboardPage> createState() =>
      _OnlineShopDashboardPageState();
}

class _OnlineShopDashboardPageState extends State<OnlineShopDashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final String _activeSidebarItem = 'Dashboard';

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
                  const OnlineShopSummaryCards(),
                  const SizedBox(height: 20),
                  const RecentOrdersTable(),
                  const SizedBox(height: 20),
                  const TopProductsTable(),
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
