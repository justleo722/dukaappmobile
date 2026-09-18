import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/stock/presentation/pages/barcode_scanner_screen.dart';
import 'package:dukaapp/features/stock/presentation/providers/stock_provider.dart';
import 'package:dukaapp/features/stock/presentation/widgets/adjust_product_card.dart';
import 'package:dukaapp/features/stock/presentation/widgets/adjustment_status_dropdown.dart';
import 'package:dukaapp/features/stock/presentation/widgets/adjustment_summary_card.dart';
import 'package:dukaapp/features/stock/presentation/widgets/adjust_bottom_bar.dart';

class _AdjustItem {
  final String name;
  final int currentStock;
  final dynamic productId;
  final dynamic stockId;
  int adjustQuantity;
  AdjustmentStatus status;

  _AdjustItem({
    required this.name,
    required this.currentStock,
    this.productId,
    this.stockId,
  })  : adjustQuantity = 0,
        status = AdjustmentStatus.none;
}

class AdjustStockPage extends ConsumerStatefulWidget {
  const AdjustStockPage({super.key});

  @override
  ConsumerState<AdjustStockPage> createState() => _AdjustStockPageState();
}

class _AdjustStockPageState extends ConsumerState<AdjustStockPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<_AdjustItem> _items = [];
  final Set<int> _selectedProducts = {};
  bool _isSaving = false;

  List<Map<String, dynamic>> _getFilteredProducts() {
    final stockState = ref.watch(stockProvider);
    final allProducts = stockState.whenOrNull(
          data: (s) => s.products
              .map((p) => {'name': p.name, 'stock': p.available.toInt(), 'product_id': p.productId, 'stock_id': p.stockId})
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

  int get _totalAdjustedQuantity =>
      _items.fold(0, (sum, item) => sum + item.adjustQuantity);

  int get _adjustmentTypeCount =>
      _items.where((item) => item.status != AdjustmentStatus.none).length;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addSelectedProducts() {
    final products = _getFilteredProducts();
    int addedCount = 0;
    for (final index in _selectedProducts) {
      if (index >= products.length) continue;
      final product = products[index];
      final name = product['name'] as String;
      if (_items.any((item) => item.name == name)) continue;
      _items.add(_AdjustItem(
        name: name,
        currentStock: (product['stock'] as num?)?.toInt() ?? 0,
        productId: product['product_id'],
        stockId: product['stock_id'],
      ));
      addedCount++;
    }
    setState(() => _selectedProducts.clear());
    if (addedCount > 0) {
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

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedProducts.contains(index)) {
        _selectedProducts.remove(index);
      } else {
        _selectedProducts.add(index);
      }
    });
  }

  void _toggleAll() {
    final products = _getFilteredProducts();
    final selectableIndices = products
        .asMap()
        .keys
        .where((i) => !_items.any((item) => item.name == products[i]['name']))
        .toSet();
    final allSelected = selectableIndices.every((i) => _selectedProducts.contains(i));
    setState(() {
      if (allSelected) {
        _selectedProducts.removeAll(selectableIndices);
      } else {
        _selectedProducts.addAll(selectableIndices);
      }
    });
  }

  Future<void> _saveAdjustments() async {
    final repo = ref.read(stockRepositoryProvider);
    final adjustedItems = _items
        .where((item) =>
            item.productId != null &&
            item.stockId != null &&
            item.status != AdjustmentStatus.none)
        .map((item) => {
              'product_id': item.productId,
              'stock_id': item.stockId,
              'quantity': item.adjustQuantity.abs(),
              // Map Flutter status → PHP movement_type
              'movement_type': item.status == AdjustmentStatus.balancing
                  ? 'balanced'
                  : item.status.name, // bad, expired, lost
            })
        .toList();

    if (adjustedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No quantities adjusted. Set quantity for at least one product.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite),
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final res = await repo.adjustStockBalance({'adjustments': adjustedItems});
      final ok = res['status']?.toString() == '1' || res['status'] == true || res['status']?.toString() == 'success';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Adjustments saved successfully' : (res['message']?.toString() ?? 'Failed to save adjustments'),
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
                    _buildSearchSection(),
                    const SizedBox(height: 12),
                    _buildProductsHeader(),
                    const SizedBox(height: 8),
                    if (_items.isNotEmpty) ...[
                      _buildAdjustmentCards(),
                      const SizedBox(height: 16),
                      AdjustmentSummaryCard(
                        productsSelected: _items.length,
                        adjustedQuantity: _totalAdjustedQuantity,
                        adjustmentTypeCount: _adjustmentTypeCount,
                      ),
                    ],
                    if (_items.isEmpty) _buildProductList(),
                    SizedBox(height: 24 + bottomPadding),
                  ],
                ),
              ),
            ),
            AdjustBottomBar(
              onClose: () => context.pop(),
              onSave: (_items.isNotEmpty && !_isSaving) ? _saveAdjustments : null,
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
            'Adjust Stock',
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Adjust product quantities and record adjustment reasons.',
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
                Icons.history_rounded,
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

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
        child: TextField(
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
                : InkWell(
                    onTap: () async {
                      final result = await Navigator.of(context).push<String>(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (_) => const BarcodeScannerScreen(),
                        ),
                      );
                      if (result != null && result.isNotEmpty) {
                        _searchController.text = result;
                        setState(() {});
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
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
                  ),
            filled: true,
            fillColor: AppColors.card,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
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
    final allSelected = selectableIndices.isNotEmpty &&
        selectableIndices.every((i) => _selectedProducts.contains(i));

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
            _items.isEmpty ? 'Products' : 'Adjustment Items',
            style: AppTypography.label.copyWith(color: AppColors.textPrimary),
          ),
          const Spacer(),
          if (_items.isEmpty && products.isNotEmpty) ...[
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
            const SizedBox(width: 6),
            Text(
              'Select All',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdjustmentCards() {
    return Column(
      children: List.generate(_items.length, (index) {
        final item = _items[index];
        return AdjustProductCard(
          productName: item.name,
          currentStock: item.currentStock,
          adjustQuantity: item.adjustQuantity,
          onQuantityChanged: (v) => setState(() => item.adjustQuantity = v),
          status: item.status,
          onStatusChanged: (v) => setState(() => item.status = v ?? AdjustmentStatus.none),
        );
      }),
    );
  }

  Widget _buildProductList() {
    final stockState = ref.watch(stockProvider);
    if (stockState.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
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
                'Search or scan a product to begin adjusting stock.',
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

    return Column(
      children: [
        ...products.asMap().entries.map((entry) {
          final index = entry.key;
          final product = entry.value;
          final name = product['name'] as String;
          final stock = product['stock'] as int;
          final isAlreadyAdded = _items.any((item) => item.name == name);
          final isSelected = _selectedProducts.contains(index);

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
                              'Stock: $stock',
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
        if (_selectedProducts.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
            child: SizedBox(
              width: double.infinity,
              height: AppConstants.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: _addSelectedProducts,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  'Add Selected (${_selectedProducts.length})',
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
