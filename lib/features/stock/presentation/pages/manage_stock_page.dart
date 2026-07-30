// features/stock/presentation/pages/manage_stock_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/stock/presentation/widgets/stock_status_chip.dart';
import 'package:dukaapp/features/stock/presentation/widgets/stock_summary_card.dart';
import 'package:dukaapp/features/stock/presentation/widgets/stock_action_button.dart';
import 'package:dukaapp/features/stock/presentation/widgets/stock_search_field.dart';
import 'package:dukaapp/features/stock/presentation/widgets/stock_category_switch.dart';
import 'package:dukaapp/features/stock/presentation/widgets/stock_select_bar.dart';
import 'package:dukaapp/features/stock/presentation/widgets/stock_product_card.dart';
import 'package:dukaapp/features/stock/presentation/widgets/stock_categories_grid.dart';
import 'package:dukaapp/features/stock/presentation/pages/import_stock_page.dart';
import 'package:dukaapp/shared/dialogs/app_filter_dialog.dart';

class ManageStockPage extends StatefulWidget {
  const ManageStockPage({super.key});

  @override
  State<ManageStockPage> createState() => _ManageStockPageState();
}

class _ManageStockPageState extends State<ManageStockPage> {
  bool _categoryMode = false;
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedProducts = {};
  int? _expandedProductIndex;

  final List<Map<String, dynamic>> _products = const [
    {
      'name': 'AIR',
      'category': 'Uncategorized',
      'buyingPrice': 4500.0,
      'sellingPrice': 7000.0,
      'stock': 15,
    },
    {
      'name': 'BEAUTY CREAM',
      'category': 'Cosmetics',
      'buyingPrice': 12000.0,
      'sellingPrice': 18000.0,
      'stock': 3,
    },
    {
      'name': 'CAR PHONE HOLDER',
      'category': 'Accessories',
      'buyingPrice': 8000.0,
      'sellingPrice': 15000.0,
      'stock': 8,
    },
    {
      'name': 'CHARGER CABLE',
      'category': 'Electronics',
      'buyingPrice': 3500.0,
      'sellingPrice': 6000.0,
      'stock': 2,
    },
    {
      'name': 'DISH SOAP',
      'category': 'Household',
      'buyingPrice': 2000.0,
      'sellingPrice': 3500.0,
      'stock': 25,
    },
    {
      'name': 'FACE MASK',
      'category': 'Beauty',
      'buyingPrice': 5000.0,
      'sellingPrice': 9000.0,
      'stock': 4,
    },
  ];

  bool get _allSelected =>
      _selectedProducts.length == _products.length && _products.isNotEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleProductSelection(int index) {
    setState(() {
      if (_selectedProducts.contains(index)) {
        _selectedProducts.remove(index);
      } else {
        _selectedProducts.add(index);
      }
    });
  }

  void _toggleAllSelection() {
    setState(() {
      if (_allSelected) {
        _selectedProducts.clear();
      } else {
        _selectedProducts.addAll(List.generate(_products.length, (i) => i));
      }
    });
  }

  void _toggleProductExpansion(int index) {
    setState(() {
      _expandedProductIndex = _expandedProductIndex == index ? null : index;
    });
  }

  void _deleteSelected() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Products',
          style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete ${_selectedProducts.length} product(s)?',
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
            onPressed: () {
              Navigator.pop(context);
              setState(() => _selectedProducts.clear());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Products deleted')),
              );
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

  void _navigateToCategory(String categoryName) {
    context.push(
      '/stock/manage/category',
      extra: {
        'categoryName': categoryName,
        'products': _products,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    _buildStatusChips(),
                    const SizedBox(height: 16),
                    const StockSummaryCard(
                      totalStockValue: 'Tsh 0',
                      profitEstimate: 'Tsh 0',
                      allProducts: 6,
                    ),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                    const SizedBox(height: 16),
                    StockSearchField(
                      controller: _searchController,
                      onChanged: (value) => setState(() {}),
                      onClear: () => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    StockCategorySwitch(
                      value: _categoryMode,
                      onChanged: (value) {
                        setState(() {
                          _categoryMode = value;
                          _selectedProducts.clear();
                          _expandedProductIndex = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (!_categoryMode) ...[
                      StockSelectBar(
                        isAllSelected: _allSelected,
                        onToggleAll: (_) => _toggleAllSelection(),
                        selectedCount: _selectedProducts.length,
                        onDeleteAll: _deleteSelected,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_categoryMode)
                      StockCategoriesGrid(
                        products: _products,
                        onCategoryTap: _navigateToCategory,
                      )
                    else
                      _buildProductList(),
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
      title: Text(
        'Manage Stock',
        style: AppTypography.h6.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildStatusChips() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
        children: const [
          StockStatusChip(
            icon: Icons.inventory_2_rounded,
            count: 15,
            label: 'All',
            color: AppColors.textSecondary,
            backgroundColor: AppColors.background,
          ),
          SizedBox(width: 8),
          StockStatusChip(
            icon: Icons.remove_shopping_cart_rounded,
            count: 3,
            label: 'Out of Stock',
            color: AppColors.danger,
            backgroundColor: AppColors.dangerLight,
          ),
          SizedBox(width: 8),
          StockStatusChip(
            icon: Icons.schedule_rounded,
            count: 4,
            label: 'To Expire',
            color: Color(0xFFFF9800),
            backgroundColor: Color(0xFFFFF3E0),
          ),
          SizedBox(width: 8),
          StockStatusChip(
            icon: Icons.event_busy_rounded,
            count: 1,
            label: 'Expired',
            color: Color(0xFFE64A19),
            backgroundColor: Color(0xFFFBE9E7),
          ),
          SizedBox(width: 8),
          StockStatusChip(
            icon: Icons.trending_down_rounded,
            count: 6,
            label: 'Running Low',
            color: AppColors.primary,
            backgroundColor: Color(0xFFE3F2FD),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
        children: [
          StockActionButton(
            icon: Icons.file_download_rounded,
            label: 'Import',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => const ImportStockPage(),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          StockActionButton(
            icon: Icons.transfer_within_a_station_rounded,
            label: 'Import From Shop',
            onTap: () => context.push('/stock/manage/import-from-shop'),
          ),
          const SizedBox(width: 10),
          StockActionButton(
            icon: Icons.shopping_cart_rounded,
            label: 'Purchase',
            onTap: () => context.push('/stock/manage/purchase'),
          ),
          const SizedBox(width: 10),
          StockActionButton(
            icon: Icons.swap_horiz_rounded,
            label: 'Transfer',
            onTap: () => context.push('/transfer'),
          ),
          const SizedBox(width: 10),
          StockActionButton(
            icon: Icons.tune_rounded,
            label: 'Adjust',
            onTap: () => context.push('/adjust'),
          ),
          const SizedBox(width: 10),
          StockActionButton(
            icon: Icons.filter_list_rounded,
            label: 'Filter',
            onTap: () => AppFilterDialog.show(context),
          ),
          const SizedBox(width: 10),
          StockActionButton(
            icon: Icons.file_download_done_rounded,
            label: 'Download',
            onTap: () => context.push('/stock-reports'),
          ),
          const SizedBox(width: 10),
          StockActionButton(
            icon: Icons.add_rounded,
            label: 'Add Product',
            isHighlighted: true,
            onTap: () => context.push('/stock/manage/add'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return Column(
      children: List.generate(_products.length, (index) {
        final product = _products[index];
        return StockProductCard(
          productName: product['name'],
          category: product['category'],
          buyingPrice: product['buyingPrice'],
          sellingPrice: product['sellingPrice'],
          currentStock: product['stock'],
          isSelected: _selectedProducts.contains(index),
          onSelectionChanged: (_) => _toggleProductSelection(index),
          isExpanded: _expandedProductIndex == index,
          onExpandToggle: () => _toggleProductExpansion(index),
          onEdit: () {},
          onHistory: () {},
          onStockPdf: () {},
          onSalesPdf: () {},
          onPhotos: () {},
          onRestock: () {},
          onAdjust: () {},
          onDelete: () {},
        );
      }),
    );
  }
}
