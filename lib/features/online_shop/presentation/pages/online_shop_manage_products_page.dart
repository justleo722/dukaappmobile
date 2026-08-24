// features/online_shop/presentation/pages/online_shop_manage_products_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/online_shop/presentation/widgets/online_shop_sidebar.dart';

class OnlineShopManageProductsPage extends StatefulWidget {
  const OnlineShopManageProductsPage({super.key});

  @override
  State<OnlineShopManageProductsPage> createState() =>
      _OnlineShopManageProductsPageState();
}

class _OnlineShopManageProductsPageState
    extends State<OnlineShopManageProductsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final String _activeSidebarItem = 'Products';

  void _onSidebarItemTap(String label) {
    Navigator.of(context).pop();
    final currentLocation = GoRouterState.of(context).matchedLocation;

    if (label == 'Dashboard') {
      if (currentLocation != '/online-shop') {
        context.go('/online-shop');
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
                  _buildSummaryHeader(),
                  const SizedBox(height: 16),
                  _buildAddProductButton(),
                  const SizedBox(height: 16),
                  _buildProductsList(),
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
        'Manage Products',
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

  Widget _buildSummaryHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
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
            'All Products (${_products.length})',
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddProductButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
      child: SizedBox(
        width: double.infinity,
        height: AppConstants.buttonHeight,
        child: ElevatedButton(
          onPressed: () => context.push('/stock/manage/add'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, size: 20),
              const SizedBox(width: 8),
              Text(
                'Add Product',
                style: AppTypography.buttonLarge.copyWith(
                  color: AppColors.textWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    if (_products.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
      child: Column(
        children: List.generate(_products.length, (index) {
          final product = _products[index];
          return _ProductCard(
            product: product,
            onEdit: () => context.push('/stock/manage/add', extra: product),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
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
            Icons.inventory_2_rounded,
            size: 48,
            color: AppColors.textHint.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'No products found',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add your first product to get started',
            style: AppTypography.caption.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onEdit;

  const _ProductCard({
    required this.product,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final status = product['status'] as String;
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
                      product['name'] as String,
                      style: AppTypography.h6.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product['shop'] as String,
                      style: AppTypography.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
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
          Row(
            children: [
              _buildInfoColumn('Price', product['price'] as String),
              const SizedBox(width: 16),
              _buildInfoColumn('Sales', '${product['sales']}'),
              const SizedBox(width: 16),
              _buildInfoColumn('Stock', '${product['stock']}'),
              const SizedBox(width: 16),
              _buildInfoColumn('Alert', '${product['alertLevel']}'),
              const Spacer(),
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
    if (status == 'In Stock') return AppColors.success;
    if (status == 'Low Stock') return AppColors.danger;
    return AppColors.textHint;
  }
}

const List<Map<String, dynamic>> _products = [
  {
    'name': 'Beauty Cream',
    'shop': 'SON COLLECTION',
    'buyingPrice': 12000.0,
    'sellingPrice': 18000.0,
    'price': 'Tsh 18,000',
    'sales': 48,
    'stock': 25,
    'alertLevel': 5,
    'status': 'In Stock',
    'category': 'Cosmetics',
  },
  {
    'name': 'Face Mask',
    'shop': 'SON COLLECTION',
    'buyingPrice': 5000.0,
    'sellingPrice': 9000.0,
    'price': 'Tsh 9,000',
    'sales': 35,
    'stock': 4,
    'alertLevel': 5,
    'status': 'Low Stock',
    'category': 'Beauty',
  },
  {
    'name': 'Air Freshener',
    'shop': 'SON COLLECTION',
    'buyingPrice': 4000.0,
    'sellingPrice': 7000.0,
    'price': 'Tsh 7,000',
    'sales': 22,
    'stock': 12,
    'alertLevel': 3,
    'status': 'In Stock',
    'category': 'Household',
  },
  {
    'name': 'Dish Soap',
    'shop': 'SON COLLECTION',
    'buyingPrice': 2000.0,
    'sellingPrice': 3500.0,
    'price': 'Tsh 3,500',
    'sales': 60,
    'stock': 30,
    'alertLevel': 10,
    'status': 'In Stock',
    'category': 'Household',
  },
  {
    'name': 'Charger Cable',
    'shop': 'SON COLLECTION',
    'buyingPrice': 3500.0,
    'sellingPrice': 6000.0,
    'price': 'Tsh 6,000',
    'sales': 18,
    'stock': 2,
    'alertLevel': 5,
    'status': 'Low Stock',
    'category': 'Electronics',
  },
  {
    'name': 'Car Phone Holder',
    'shop': 'SON COLLECTION',
    'buyingPrice': 8000.0,
    'sellingPrice': 15000.0,
    'price': 'Tsh 15,000',
    'sales': 15,
    'stock': 8,
    'alertLevel': 3,
    'status': 'In Stock',
    'category': 'Accessories',
  },
  {
    'name': 'Hand Sanitizer',
    'shop': 'SON COLLECTION',
    'buyingPrice': 2500.0,
    'sellingPrice': 4500.0,
    'price': 'Tsh 4,500',
    'sales': 42,
    'stock': 20,
    'alertLevel': 8,
    'status': 'In Stock',
    'category': 'Health',
  },
  {
    'name': 'USB Fan',
    'shop': 'SON COLLECTION',
    'buyingPrice': 7000.0,
    'sellingPrice': 12000.0,
    'price': 'Tsh 12,000',
    'sales': 10,
    'stock': 6,
    'alertLevel': 3,
    'status': 'In Stock',
    'category': 'Electronics',
  },
];
