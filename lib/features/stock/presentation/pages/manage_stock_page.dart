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

class ManageStockPage extends StatefulWidget {
  const ManageStockPage({super.key});

  @override
  State<ManageStockPage> createState() => _ManageStockPageState();
}

class _ManageStockPageState extends State<ManageStockPage> {
  bool _categoryMode = false;
  bool _allSelected = false;
  final TextEditingController _searchController = TextEditingController();

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(),
      body: Column(
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
                    allProducts: 0,
                  ),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                  const SizedBox(height: 16),
                  StockSearchField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {});
                    },
                    onClear: () {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  StockCategorySwitch(
                    value: _categoryMode,
                    onChanged: (value) {
                      setState(() {
                        _categoryMode = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  StockSelectBar(
                    isAllSelected: _allSelected,
                    onToggleAll: (value) {
                      setState(() {
                        _allSelected = value ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildProductList(),
                  SizedBox(height: 100 + bottomPadding),
                ],
              ),
            ),
          ),
        ],
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
          const StockActionButton(
            icon: Icons.file_download_rounded,
            label: 'Import',
          ),
          const SizedBox(width: 10),
          const StockActionButton(
            icon: Icons.transfer_within_a_station_rounded,
            label: 'Import From Shop',
          ),
          const SizedBox(width: 10),
          const StockActionButton(
            icon: Icons.shopping_cart_rounded,
            label: 'Purchase',
          ),
          const SizedBox(width: 10),
          const StockActionButton(
            icon: Icons.swap_horiz_rounded,
            label: 'Transfer',
          ),
          const SizedBox(width: 10),
          const StockActionButton(
            icon: Icons.tune_rounded,
            label: 'Adjust',
          ),
          const SizedBox(width: 10),
          const StockActionButton(
            icon: Icons.filter_list_rounded,
            label: 'Filter',
          ),
          const SizedBox(width: 10),
          const StockActionButton(
            icon: Icons.file_download_done_rounded,
            label: 'Download',
          ),
          const SizedBox(width: 10),
          const StockActionButton(
            icon: Icons.add_rounded,
            label: 'Add Product',
            isHighlighted: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return Column(
      children: _products.map((product) {
        return StockProductCard(
          productName: product['name'],
          category: product['category'],
          buyingPrice: product['buyingPrice'],
          sellingPrice: product['sellingPrice'],
          currentStock: product['stock'],
        );
      }).toList(),
    );
  }
}
