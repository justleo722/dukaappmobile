import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/stock/presentation/widgets/stock_product_card.dart';
import 'package:dukaapp/features/stock/presentation/widgets/stock_select_bar.dart';

class CategoryProductsPage extends StatefulWidget {
  final String categoryName;
  final List<Map<String, dynamic>> products;

  const CategoryProductsPage({
    super.key,
    required this.categoryName,
    required this.products,
  });

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  final Set<int> _selectedProducts = {};
  int? _expandedProductIndex;

  List<Map<String, dynamic>> get _filteredProducts {
    return widget.products
        .where((p) => p['category'] == widget.categoryName)
        .toList();
  }

  bool get _allSelected =>
      _selectedProducts.length == _filteredProducts.length &&
      _filteredProducts.isNotEmpty;

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
        _selectedProducts.addAll(
          List.generate(_filteredProducts.length, (i) => i),
        );
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

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final filteredProducts = _filteredProducts;

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
                    StockSelectBar(
                      isAllSelected: _allSelected,
                      onToggleAll: (_) => _toggleAllSelection(),
                      selectedCount: _selectedProducts.length,
                      onDeleteAll: _deleteSelected,
                    ),
                    const SizedBox(height: 12),
                    if (filteredProducts.isEmpty)
                      _buildEmptyState()
                    else
                      _buildProductList(filteredProducts),
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
            widget.categoryName,
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${_filteredProducts.length} products',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                color: AppColors.textHint,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'No products in this category yet.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(List<Map<String, dynamic>> products) {
    return Column(
      children: List.generate(products.length, (index) {
        final product = products[index];
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
