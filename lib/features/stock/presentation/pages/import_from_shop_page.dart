import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/stock/presentation/widgets/shop_dropdown.dart';
import 'package:dukaapp/features/stock/presentation/widgets/product_import_card.dart';
import 'package:dukaapp/features/stock/presentation/widgets/bottom_import_bar.dart';

class ImportFromShopPage extends StatefulWidget {
  const ImportFromShopPage({super.key});

  @override
  State<ImportFromShopPage> createState() => _ImportFromShopPageState();
}

class _ImportFromShopPageState extends State<ImportFromShopPage> {
  String? _selectedShop;
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedProducts = {};

  static const List<Map<String, dynamic>> _allProducts = [
    {
      'name': 'APPLE PUNCH',
      'barcode': '000036240005',
      'buyingPrice': 800.0,
      'sellingPrice': 1000.0,
      'wholesalePrice': 1000.0,
      'stock': 4,
    },
    {
      'name': 'COCA COLA 600ML',
      'barcode': '00017330006',
      'buyingPrice': 800.0,
      'sellingPrice': 1000.0,
      'wholesalePrice': 1000.0,
      'stock': 3,
    },
    {
      'name': 'FANTA ORANGE',
      'barcode': '00017330013',
      'buyingPrice': 800.0,
      'sellingPrice': 1000.0,
      'wholesalePrice': 1000.0,
      'stock': 7,
    },
    {
      'name': 'SPRITE 500ML',
      'barcode': '00017330020',
      'buyingPrice': 700.0,
      'sellingPrice': 900.0,
      'wholesalePrice': 900.0,
      'stock': 2,
    },
    {
      'name': 'KONYAGI 350ML',
      'barcode': '00060200015',
      'buyingPrice': 12000.0,
      'sellingPrice': 15000.0,
      'wholesalePrice': 14500.0,
      'stock': 12,
    },
    {
      'name': 'SMIRNOFF VODKA',
      'barcode': '00060200022',
      'buyingPrice': 18000.0,
      'sellingPrice': 22000.0,
      'wholesalePrice': 21000.0,
      'stock': 5,
    },
    {
      'name': 'SAFARI LAGER',
      'barcode': '00080010003',
      'buyingPrice': 1500.0,
      'sellingPrice': 2000.0,
      'wholesalePrice': 1900.0,
      'stock': 24,
    },
    {
      'name': 'KILIMANJARO PREMIUM',
      'barcode': '00080010010',
      'buyingPrice': 1800.0,
      'sellingPrice': 2500.0,
      'wholesalePrice': 2300.0,
      'stock': 18,
    },
  ];

  List<Map<String, dynamic>> get _filteredProducts {
    if (_selectedShop == null) return [];

    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return _allProducts;

      return _allProducts.where((product) {
      final name = (product['name'] as String).toLowerCase();
      final barcode = (product['barcode'] as String).toLowerCase();
      return name.contains(query) || barcode.contains(query);
    }).toList();
  }

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

  void _toggleAllSelection(List<Map<String, dynamic>> products) {
    final indices = products.map((p) => _allProducts.indexOf(p)).toSet();
    final allSelected = indices.every((i) => _selectedProducts.contains(i));
    setState(() {
      if (allSelected) {
        _selectedProducts.removeAll(indices);
      } else {
        _selectedProducts.addAll(indices);
      }
    });
  }

  void _closePage() {
    context.pop();
  }

  void _importSelected() {
    if (_selectedProducts.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_selectedProducts.length} product(s) imported successfully',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
        ),
      ),
    );
    setState(() => _selectedProducts.clear());
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final products = _filteredProducts;
    final hasShop = _selectedShop != null;

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
                    const SizedBox(height: 16),
                    _buildShopSection(),
                    const SizedBox(height: 12),
                    if (hasShop) ...[
                      _buildSearchSection(),
                      const SizedBox(height: 16),
                      _buildProductCountLabel(products.length),
                      const SizedBox(height: 8),
                    ],
                    if (hasShop && products.isNotEmpty)
                      _buildProductList(products)
                    else if (hasShop && products.isEmpty)
                      _buildEmptyState()
                    else
                      _buildSelectShopPrompt(),
                    SizedBox(height: 24 + bottomPadding),
                  ],
                ),
              ),
            ),
            BottomImportBar(
              onClose: _closePage,
              onImport: _importSelected,
              selectedCount: _selectedProducts.length,
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
            'Import From Shop',
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Import products from another shop into your current shop.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
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

  Widget _buildShopSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: ShopDropdown(
        value: _selectedShop,
        onChanged: (value) {
          setState(() {
            _selectedShop = value;
            _selectedProducts.clear();
          });
        },
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: AppTypography.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search by product name or barcode',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textHint,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textHint,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textHint,
                    size: 18,
                  ),
                )
              : null,
          filled: true,
          fillColor: AppColors.card,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
            borderSide: const BorderSide(
              color: AppColors.inputFocusBorder,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCountLabel(int count) {
    final displayProducts = _filteredProducts;
    final indices = displayProducts.map((p) => _allProducts.indexOf(p)).toSet();
    final allSelected =
        indices.isNotEmpty && indices.every((i) => _selectedProducts.contains(i));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: allSelected,
              onChanged: indices.isEmpty
                  ? null
                  : (_) => _toggleAllSelection(displayProducts),
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(
                color: allSelected ? AppColors.primary : AppColors.border,
                width: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count product${count == 1 ? '' : 's'} found',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Select All',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List<Map<String, dynamic>> products) {
    return Column(
      children: List.generate(products.length, (index) {
        final product = products[index];
        final globalIndex = _allProducts.indexOf(product);
        return ProductImportCard(
          productName: product['name'] as String,
          barcode: product['barcode'] as String,
          buyingPrice: product['buyingPrice'] as double,
          sellingPrice: product['sellingPrice'] as double,
          wholesalePrice: product['wholesalePrice'] as double,
          stock: product['stock'] as int,
          isSelected: _selectedProducts.contains(globalIndex),
          onTap: () => _toggleProductSelection(globalIndex),
          onSelectionChanged: (_) => _toggleProductSelection(globalIndex),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingXXL,
          vertical: 60,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 56,
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Products Available',
              style: AppTypography.h6.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select another shop or try searching.',
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

  Widget _buildSelectShopPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingXXL,
          vertical: 60,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.storefront_outlined,
                size: 56,
                color: AppColors.secondary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select a Shop',
              style: AppTypography.h6.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a shop above to view available products for import.',
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
}
