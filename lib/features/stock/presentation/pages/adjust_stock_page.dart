import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/stock/presentation/pages/barcode_scanner_screen.dart';
import 'package:dukaapp/features/stock/presentation/providers/stock_provider.dart';
import 'package:dukaapp/features/stock/presentation/widgets/adjustment_status_dropdown.dart';
import 'package:dukaapp/features/stock/presentation/widgets/adjustment_summary_card.dart';
import 'package:dukaapp/features/stock/presentation/widgets/adjust_bottom_bar.dart';
import 'package:dukaapp/features/stock/presentation/widgets/compact_qty_stepper.dart';

class _AdjustItem {
  final String name;
  final int currentStock;
  final double openingStock;
  final dynamic productId;
  final dynamic stockId;
  int adjustQuantity;
  AdjustmentStatus status;

  _AdjustItem({
    required this.name,
    required this.currentStock,
    this.openingStock = 0,
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
  bool _isSaving = false;

  // Full unfiltered product list, updated every build.
  List<Map<String, dynamic>> _allProductsCache = [];

  /// Products matching the current search query (name or barcode).
  List<Map<String, dynamic>> _getFilteredProducts({bool updateCache = false}) {
    if (updateCache) {
      final stockState = ref.watch(stockProvider);
      final list = stockState.whenOrNull(
        data: (s) => s.products
            .map((p) => {
                  'name': p.name,
                  'stock': p.available.toInt(),
                  'stock_exact': p.available,
                  'product_id': p.productId,
                  'stock_id': p.stockId,
                  'barcode': p.barcode ?? '',
                })
            .toList(),
      );
      if (list != null) _allProductsCache = list;
    }
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return _allProductsCache;
    return _allProductsCache.where((p) {
      final name = (p['name'] as String).toLowerCase();
      final barcode = (p['barcode']?.toString() ?? '').toLowerCase();
      return name.contains(query) || barcode.contains(query);
    }).toList();
  }

  /// Items currently part of the adjustment (quantity > 0).
  List<_AdjustItem> get _selectedItems =>
      _items.where((item) => item.adjustQuantity > 0).toList();

  int get _totalAdjustedQuantity =>
      _selectedItems.fold(0, (sum, item) => sum + item.adjustQuantity);

  int get _adjustmentTypeCount =>
      _selectedItems.where((item) => item.status != AdjustmentStatus.none).length;

  int _itemIndexByName(String name) =>
      _items.indexWhere((item) => item.name == name);

  int _qtyFor(String name) {
    final i = _itemIndexByName(name);
    return i < 0 ? 0 : _items[i].adjustQuantity;
  }

  /// Select (or bump) a product straight from the catalog / barcode scan.
  void _incrementProduct(Map<String, dynamic> product) {
    final name = product['name'] as String;
    final i = _itemIndexByName(name);
    setState(() {
      if (i < 0) {
        _items.add(_AdjustItem(
          name: name,
          currentStock: (product['stock'] as num?)?.toInt() ?? 0,
          openingStock: (product['stock_exact'] as num?)?.toDouble() ?? 0,
          productId: product['product_id'],
          stockId: product['stock_id'],
        )..adjustQuantity = 1);
      } else {
        _items[i].adjustQuantity += 1;
      }
    });
  }

  void _decrementProduct(String name) {
    final i = _itemIndexByName(name);
    if (i < 0) return;
    setState(() {
      if (_items[i].adjustQuantity <= 1) {
        // Deselect: keep the item (and its status) but drop it out of the
        // active adjustment by setting quantity to 0.
        _items[i].adjustQuantity = 0;
      } else {
        _items[i].adjustQuantity -= 1;
      }
    });
  }

  /// Per-item status change: balancing seeds the stepper with the current
  /// stock (the user types the target balance); other statuses reset it so
  /// the user enters the amount to remove.
  void _onStatusChanged(_AdjustItem item, AdjustmentStatus? value) {
    final newStatus = value ?? AdjustmentStatus.none;
    setState(() {
      item.status = newStatus;
      if (newStatus == AdjustmentStatus.balancing) {
        item.adjustQuantity = item.currentStock;
      } else {
        item.adjustQuantity = 0;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Open the camera and scan a barcode. An exact match is selected (or its
  /// quantity bumped) straight from the catalog; otherwise the code becomes
  /// the search query.
  Future<void> _scanBarcode() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const BarcodeScannerScreen(),
      ),
    );
    if (result == null || result.isEmpty || !mounted) return;
    final code = result.trim();

    final matches = _allProductsCache.where(
      (p) => (p['barcode']?.toString() ?? '').trim() == code,
    );

    if (matches.isNotEmpty) {
      _incrementProduct(matches.first);
    } else {
      setState(() => _searchController.text = code);
    }
  }

  Future<void> _saveAdjustments() async {
    final repo = ref.read(stockRepositoryProvider);

    final adjustedItems = _items
        .where((item) =>
            // Only products with quantity > 0 take part in the adjustment.
            item.adjustQuantity > 0 &&
            item.productId != null &&
            item.status != AdjustmentStatus.none &&
            (item.status == AdjustmentStatus.balancing || item.adjustQuantity != 0))
        .map((item) {
          final isBalancing = item.status == AdjustmentStatus.balancing;
          return {
            'name': item.name,
            'product_id': item.productId,
            'stock_id': item.stockId,
            // Exact balance (may be fractional) so the 'balanced' delta is right.
            'opening_quantity': item.openingStock,
            // balanced: adjustQuantity IS the target (stepper initialized to currentStock)
            // outflow (bad/lost/stolen/expired): adjustQuantity is the amount to remove
            'quantity': isBalancing
                ? item.adjustQuantity.abs()
                : item.adjustQuantity.abs(),
            'movement_type': isBalancing ? 'balanced' : item.status.name,
          };
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
        await ref.read(stockProvider.notifier).refresh();
        if (mounted) context.pop();
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
            // Pinned header: search stays fixed.
            _buildStickyHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildProductsHeader(),
                    const SizedBox(height: 8),
                    _buildCatalogList(),
                    if (_selectedItems.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      AdjustmentSummaryCard(
                        productsSelected: _selectedItems.length,
                        adjustedQuantity: _totalAdjustedQuantity,
                        adjustmentTypeCount: _adjustmentTypeCount,
                      ),
                    ],
                    SizedBox(height: 24 + bottomPadding),
                  ],
                ),
              ),
            ),
            AdjustBottomBar(
              onClose: () => context.pop(),
              onSave: (_selectedItems.isNotEmpty && !_isSaving)
                  ? _saveAdjustments
                  : null,
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

  Widget _buildStickyHeader() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.paddingLG,
          12,
          AppConstants.paddingLG,
          10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search bar
            _buildSearchBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: AppTypography.bodyMedium,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search product or scan barcode',
                hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() => _searchController.clear()),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.close_rounded, color: AppColors.textHint, size: 18),
              ),
            ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              _scanBarcode();
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsHeader() {
    // Cache is refreshed here (called first in build) so the catalog list
    // below always renders against fresh stock data.
    final products = _getFilteredProducts(updateCache: true);
    final selectedCount = _selectedItems.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Row(
        children: [
          if (selectedCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$selectedCount item${selectedCount == 1 ? '' : 's'}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            selectedCount > 0 ? 'Adjustment Items' : 'Products',
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            '${products.length} available',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogList() {
    // Cache is updated by _buildProductsHeader (called first in build).
    // Show loading only when cache is still empty (initial load).
    if (_allProductsCache.isEmpty) {
      final stockState = ref.watch(stockProvider);
      if (stockState.isLoading) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        );
      }
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Column(
        children: products.map(_buildCatalogCard).toList(),
      ),
    );
  }

  Widget _buildCatalogCard(Map<String, dynamic> product) {
    final name = product['name'] as String;
    final stock = (product['stock'] as num?)?.toInt() ?? 0;
    final qty = _qtyFor(name);
    final selected = qty > 0;
    final idx = _itemIndexByName(name);
    final item = idx >= 0 ? _items[idx] : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: avatar + name/stock + stepper
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty
                        ? name.substring(0, name.length.clamp(0, 2)).toUpperCase()
                        : '??',
                    style: AppTypography.captionBold.copyWith(
                      color: AppColors.primary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Stock: $stock',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              CompactQtyStepper(
                qty: qty,
                onAdd: () => _incrementProduct(product),
                onRemove: () => _decrementProduct(name),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Per-item adjustment status once selected.
          if (selected && item != null)
            AdjustmentStatusDropdown(
              status: item.status,
              onChanged: (v) => _onStatusChanged(item, v),
            )
          else
            _buildUnselectedFooter(stock),
        ],
      ),
    );
  }

  Widget _buildUnselectedFooter(int stock) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Stock: $stock units — tap + to adjust',
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
          fontSize: 10,
        ),
      ),
    );
  }
}
