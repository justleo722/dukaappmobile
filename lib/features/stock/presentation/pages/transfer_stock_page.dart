import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/stock/presentation/providers/stock_provider.dart';
import 'package:dukaapp/features/stock/presentation/widgets/transfer_shop_dropdown.dart';
import 'package:dukaapp/features/stock/presentation/widgets/transfer_product_card.dart';
import 'package:dukaapp/features/stock/presentation/widgets/transfer_summary_card.dart';
import 'package:dukaapp/features/stock/presentation/widgets/transfer_bottom_bar.dart';

class _TransferItem {
  final String name;
  final int availableStock;
  final dynamic productId;
  int transferQuantity;

  _TransferItem({
    required this.name,
    required this.availableStock,
    this.productId,
  }) : transferQuantity = 0;
}

class TransferStockPage extends ConsumerStatefulWidget {
  const TransferStockPage({super.key});

  @override
  ConsumerState<TransferStockPage> createState() => _TransferStockPageState();
}

class _TransferStockPageState extends ConsumerState<TransferStockPage> {
  String? _selectedShop;
  final TextEditingController _searchController = TextEditingController();
  final List<_TransferItem> _items = [];
  bool _isSaving = false;

  List<Map<String, dynamic>> _getFilteredProducts() {
    final stockState = ref.read(stockProvider);
    final allProducts = stockState.whenOrNull(
          data: (s) => s.products
              .map((p) => {
                    'name': p.name,
                    'stock': p.available.toInt(),
                    'product_id': p.productId,
                  })
              .toList(),
        ) ??
        [];
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return allProducts;
    return allProducts.where((p) {
      final name = (p['name'] as String).toLowerCase();
      return name.contains(query);
    }).toList();
  }

  /// Extract shop_id from label "Shop Name (shop_id)"
  String? _extractShopId(String? label) {
    if (label == null) return null;
    final match = RegExp(r'\(([^)]+)\)$').firstMatch(label);
    return match?.group(1);
  }

  int get _totalTransferQuantity =>
      _items.fold(0, (sum, item) => sum + item.transferQuantity);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addSelectedProducts(List<Map<String, dynamic>> products, Set<int> indices) {
    int addedCount = 0;
    for (final index in indices) {
      if (index >= products.length) continue;
      final product = products[index];
      final name = product['name'] as String;
      if (_items.any((item) => item.name == name)) continue;
      _items.add(_TransferItem(
        name: name,
        availableStock: product['stock'] as int,
        productId: product['product_id'],
      ));
      addedCount++;
    }
    if (addedCount > 0) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$addedCount product${addedCount == 1 ? '' : 's'} added',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          ),
        ),
      );
    }
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
                    const SizedBox(height: 16),
                    _buildInfoSection(),
                    const SizedBox(height: 12),
                    _buildProductsHeader(),
                    const SizedBox(height: 8),
                    if (_items.isNotEmpty) ...[
                      _buildTransferCards(),
                      const SizedBox(height: 16),
                      TransferSummaryCard(
                        productsSelected: _items.length,
                        totalQuantity: _totalTransferQuantity,
                        destinationShop: _selectedShop ?? '',
                      ),
                    ] else ...[
                      _buildProductList(),
                    ],
                    SizedBox(height: 24 + bottomPadding),
                  ],
                ),
              ),
            ),
            TransferBottomBar(
              onClose: () => context.pop(),
              onTransfer: (_items.isNotEmpty && _selectedShop != null && !_isSaving)
                  ? _transfer
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _transfer() async {
    final shopId = _extractShopId(_selectedShop);
    if (shopId == null) return;
    final transferItems = _items
        .where((item) => item.transferQuantity > 0 && item.productId != null)
        .map((item) => {'product_id': item.productId, 'quantity': item.transferQuantity})
        .toList();
    if (transferItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Set transfer quantity for at least one product.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(stockRepositoryProvider);
      final res = await repo.transferStock({'to_shop_id': shopId, 'products': transferItems});
      final ok = res['status']?.toString() == '1' || res['status'] == true || res['status']?.toString() == 'success';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Transfer initiated successfully' : (res['message']?.toString() ?? 'Transfer failed'),
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite),
          ),
          backgroundColor: ok ? AppColors.success : AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
        ),
      );
      if (ok) {
        ref.read(stockProvider.notifier).refresh();
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
            'Transfer Stock',
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Transfer stock items from the current shop to another shop.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
            child: IconButton(
              onPressed: null,
              icon: Icon(
                Icons.swap_horiz_rounded,
                color: AppColors.textHint,
                size: 20,
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppColors.divider,
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TransferShopDropdown(
            value: _selectedShop,
            onChanged: (v) => setState(() => _selectedShop = v),
          ),
          const SizedBox(height: 14),
          _buildSearchField(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      style: AppTypography.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Search product name or scan barcode',
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
            : Container(
                margin: const EdgeInsets.all(6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.barcode_reader,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
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
    );
  }

  Widget _buildProductsHeader() {
    final products = _getFilteredProducts();
    final selectableIndices = products
        .asMap()
        .keys
        .where((i) => !_items.any((item) => item.name == products[i]['name']))
        .toSet();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Row(
        children: [
          if (_items.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_items.length} item${_items.length == 1 ? '' : 's'}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            _items.isEmpty ? 'Products' : 'Transfer Items',
            style: AppTypography.label.copyWith(color: AppColors.textPrimary),
          ),
          const Spacer(),
          if (_items.isEmpty && products.isNotEmpty)
            Text(
              '${selectableIndices.length} available',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransferCards() {
    return Column(
      children: List.generate(_items.length, (index) {
        final item = _items[index];
        return TransferProductCard(
          productName: item.name,
          availableStock: item.availableStock,
          transferQuantity: item.transferQuantity,
          onQuantityChanged: (v) => setState(() => item.transferQuantity = v),
        );
      }),
    );
  }

  Widget _buildProductList() {
    final products = _getFilteredProducts();

    if (_searchController.text.isNotEmpty && products.isEmpty) {
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
                  Icons.search_off_rounded,
                  size: 56,
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Products Found',
                style: AppTypography.h6.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Search or scan a product to begin transferring stock.',
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

    return _ProductSelectionList(
      products: products,
      addedNames: _items.map((i) => i.name).toSet(),
      onAddProducts: (indices) => _addSelectedProducts(products, indices),
    );
  }
}

class _ProductSelectionList extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final Set<String> addedNames;
  final ValueChanged<Set<int>> onAddProducts;

  const _ProductSelectionList({
    required this.products,
    required this.addedNames,
    required this.onAddProducts,
  });

  @override
  State<_ProductSelectionList> createState() => _ProductSelectionListState();
}

class _ProductSelectionListState extends State<_ProductSelectionList> {
  final Set<int> _selectedIndices = {};

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _toggleAll() {
    final selectable = widget.products
        .asMap()
        .keys
        .where((i) => !widget.addedNames.contains(widget.products[i]['name']))
        .toSet();
    final allSelected = selectable.every((i) => _selectedIndices.contains(i));
    setState(() {
      if (allSelected) {
        _selectedIndices.removeAll(selectable);
      } else {
        _selectedIndices.addAll(selectable);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.products;
    final selectableIndices = products
        .asMap()
        .keys
        .where((i) => !widget.addedNames.contains(products[i]['name']))
        .toSet();
    final allSelected = selectableIndices.isNotEmpty &&
        selectableIndices.every((i) => _selectedIndices.contains(i));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: allSelected,
                  onChanged: selectableIndices.isNotEmpty ? (_) => _toggleAll() : null,
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
              Text(
                'Select All',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ...products.asMap().entries.map((entry) {
          final index = entry.key;
          final product = entry.value;
          final name = product['name'] as String;
          final stock = product['stock'] as int;
          final isAlreadyAdded = widget.addedNames.contains(name);
          final isSelected = _selectedIndices.contains(index);

          return Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingLG,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.04)
                  : AppColors.card,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: isAlreadyAdded ? null : () => _toggleSelection(index),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      if (!isAlreadyAdded)
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleSelection(index),
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: 1.5,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 24),
                      const SizedBox(width: 12),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            name.substring(0, name.length.clamp(0, 2)).toUpperCase(),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Available: $stock',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isAlreadyAdded)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Added',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        if (_selectedIndices.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
            child: SizedBox(
              width: double.infinity,
              height: AppConstants.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.onAddProducts(Set.from(_selectedIndices));
                  setState(() => _selectedIndices.clear());
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  'Add Selected (${_selectedIndices.length})',
                  style: AppTypography.buttonLarge,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
