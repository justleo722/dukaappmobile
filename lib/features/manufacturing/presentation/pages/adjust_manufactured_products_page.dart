import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/stock/presentation/pages/barcode_scanner_screen.dart';
import 'package:dukaapp/features/stock/presentation/widgets/adjustment_status_dropdown.dart';
import 'package:dukaapp/features/stock/presentation/widgets/adjustment_summary_card.dart';
import 'package:dukaapp/features/stock/presentation/widgets/adjust_bottom_bar.dart';
import 'package:dukaapp/features/stock/presentation/widgets/compact_qty_stepper.dart';

class _AdjustItem {
  final String productId;
  final String name;
  final int currentStock;
  int adjustQuantity;
  AdjustmentStatus status;

  _AdjustItem({required this.productId, required this.name, required this.currentStock})
      : adjustQuantity = 0,
        status = AdjustmentStatus.none;
}

class AdjustManufacturedProductsPage extends ConsumerStatefulWidget {
  const AdjustManufacturedProductsPage({super.key});

  @override
  ConsumerState<AdjustManufacturedProductsPage> createState() => _AdjustManufacturedProductsPageState();
}

class _AdjustManufacturedProductsPageState extends ConsumerState<AdjustManufacturedProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<_AdjustItem> _items = [];
  List<Map<String, dynamic>> _allProducts = [];
  bool _isLoadingProducts = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getMfManufacturedProducts();
      final body = res.data;
      List<Map<String, dynamic>> products = [];
      List rawList = [];
      if (body is List) {
        rawList = body;
      } else if (body is Map) {
        final data = body['data'] ?? body['products'] ?? [];
        if (data is List) rawList = data;
      }
      products = rawList.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return {
          'product_id': (m['product_id'] ?? m['id'] ?? '').toString(),
          'name': m['product_name'] ?? m['name'] ?? '',
          'stock': num.tryParse((m['quantity'] ?? m['stock'] ?? 0).toString()) ?? 0,
          'barcode': (m['barcode'] ?? m['bar_code'] ?? '').toString(),
        };
      }).toList();
      if (mounted) setState(() { _allProducts = products; _isLoadingProducts = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  /// Products matching the current search query (name or barcode).
  List<Map<String, dynamic>> get _filteredProducts {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return _allProducts;
    return _allProducts.where((p) {
      final name = (p['name'] as String).toLowerCase();
      final barcode = (p['barcode']?.toString() ?? '').toLowerCase();
      return name.contains(query) || barcode.contains(query);
    }).toList();
  }

  /// Items currently part of the adjustment (quantity > 0).
  List<_AdjustItem> get _selectedItems =>
      _items.where((i) => i.adjustQuantity > 0).toList();

  int get _totalAdjustedQuantity => _selectedItems.fold(0, (sum, item) => sum + item.adjustQuantity);
  int get _adjustmentTypeCount => _selectedItems.where((item) => item.status != AdjustmentStatus.none).length;

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  /// Products to render: the filtered catalog, plus any already-selected
  /// items whose product isn't in the catalog.
  List<Map<String, dynamic>> get _displayProducts {
    final list = List<Map<String, dynamic>>.from(_filteredProducts);
    final names = list.map((p) => p['name'] as String).toSet();
    for (final item in _items) {
      if (item.adjustQuantity > 0 && !names.contains(item.name)) {
        list.add({
          'product_id': item.productId,
          'name': item.name,
          'stock': item.currentStock,
          'barcode': '',
        });
      }
    }
    return list;
  }

  int _itemIndexByName(String name) => _items.indexWhere((item) => item.name == name);

  int _qtyFor(String name) {
    final i = _itemIndexByName(name);
    return i < 0 ? 0 : _items[i].adjustQuantity;
  }

  void _incrementProduct(Map<String, dynamic> product) {
    final name = product['name'] as String;
    final i = _itemIndexByName(name);
    setState(() {
      if (i < 0) {
        _items.add(_AdjustItem(
          productId: (product['product_id'] ?? '').toString(),
          name: name,
          currentStock: (product['stock'] as num).toInt(),
        ));
        _items.last.adjustQuantity = 1;
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
        // Deselect: keep the item (and its state) but drop it out of the
        // active adjustment by setting quantity to 0.
        _items[i].adjustQuantity = 0;
      } else {
        _items[i].adjustQuantity -= 1;
      }
    });
  }

  /// Open the camera and scan a barcode. An exact match is selected straight
  /// away; otherwise the code becomes the search query.
  Future<void> _scanBarcode() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const BarcodeScannerScreen(),
      ),
    );
    if (result == null || result.isEmpty || !mounted) return;
    final code = result.trim();

    final matches = _allProducts.where(
      (p) => (p['barcode']?.toString() ?? '').trim() == code,
    );

    if (matches.isNotEmpty) {
      final product = matches.first;
      final name = product['name'] as String;
      if (_items.any((item) => item.name == name && item.adjustQuantity > 0)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$name is already selected'),
          backgroundColor: AppColors.warning,
        ));
        return;
      }
      _incrementProduct(product);
      _showSelectedSnack(name);
    } else {
      setState(() => _searchController.text = code);
    }
  }

  void _showSelectedSnack(String name) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        '$name selected',
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite),
      ),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
    ));
  }

  Future<void> _save() async {
    final validItems = _items.where((i) => i.adjustQuantity > 0 && i.status != AdjustmentStatus.none && i.productId.isNotEmpty).toList();
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Set quantity and reason for at least one product.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)),
        backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM))));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiServiceProvider);
      // Backend reads: product_id[], quantity[product_id], reason[product_id]
      // reason values: balancing, bad, expired, lost
      final body = <String, dynamic>{};
      for (int i = 0; i < validItems.length; i++) {
        final item = validItems[i];
        final pid = item.productId;
        body['product_id[$i]'] = pid;
        body['quantity[$pid]'] = item.adjustQuantity.toString();
        body['reason[$pid]'] = item.status.name; // 'balancing','bad','expired','lost'
      }
      final result = await api.postMfProductionAdjust(body);
      if (!mounted) return;
      final status = result['status']?.toString() ?? '';
      if (status == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Adjustments saved successfully', style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)),
          backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM))));
        context.pop(true);
      } else {
        final msg = result['message']?.toString() ?? 'Failed to save adjustments';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg, style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)),
          backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM))));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e', style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)),
        backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM))));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(backgroundColor: const Color(0xFFF5F7FB), appBar: _buildAppBar(),
      body: SafeArea(top: false, child: Column(children: [
        _buildStickyHeader(),
        Expanded(child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 12),
            _buildProductsHeader(), const SizedBox(height: 8),
            _buildCatalogList(),
            if (_selectedItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              AdjustmentSummaryCard(productsSelected: _selectedItems.length, adjustedQuantity: _totalAdjustedQuantity, adjustmentTypeCount: _adjustmentTypeCount),
            ],
            SizedBox(height: 24 + bottomPadding),
          ]),
        )),
        AdjustBottomBar(
          onClose: () => context.pop(),
          onSave: (_selectedItems.isNotEmpty && !_isSaving) ? _save : null,
        ),
      ])),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(backgroundColor: AppColors.card, elevation: 0,
      leading: Padding(padding: const EdgeInsets.all(8.0), child: Container(
        decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
        child: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20)),
      )),
      leadingWidth: 56,
      title: Column(children: [
        Text('Adjust Manufactured Products', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text('Adjust product quantities and record adjustment reasons.', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10)),
      ]),
      centerTitle: true, bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.divider)),
    );
  }

  Widget _buildStickyHeader() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        border: Border(bottom: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppConstants.paddingLG, 12, AppConstants.paddingLG, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          _buildSearchBar(),
        ]),
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(children: [
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
      ]),
    );
  }

  Widget _buildProductsHeader() {
    final products = _displayProducts;
    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Row(children: [
        Text('Products', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppConstants.radiusFull)),
          child: Text('${products.length}', style: AppTypography.captionBold.copyWith(color: AppColors.primary, fontSize: 11))),
        const Spacer(),
        if (_selectedItems.isNotEmpty)
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
            child: Text('${_selectedItems.length} selected', style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _buildCatalogList() {
    if (_isLoadingProducts) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    final products = _displayProducts;
    if (products.isEmpty) {
      if (_searchController.text.isNotEmpty) {
        return Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXXL, vertical: 60),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 120, height: 120, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), shape: BoxShape.circle),
              child: Icon(Icons.search_off_rounded, size: 56, color: AppColors.primary.withValues(alpha: 0.4))),
            const SizedBox(height: 24),
            Text('No Products Found', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Search a product to begin adjusting stock.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
          ]),
        ));
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: [
            const Icon(Icons.inventory_2_rounded, size: 32, color: AppColors.textHint),
            const SizedBox(height: 8),
            Text('No products available yet', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ]),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Column(children: products.map(_buildCatalogCard).toList()),
    );
  }

  Widget _buildCatalogCard(Map<String, dynamic> product) {
    final name = product['name'] as String;
    final stock = (product['stock'] as num).toInt();
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: avatar + name/stock + stepper
          Row(children: [
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
          ]),
          const SizedBox(height: 8),
          // Selected: stock info + per-item status (all original fields).
          if (selected && item != null) ...[
            _buildCompactStockRow(item),
            const SizedBox(height: 8),
            AdjustmentStatusDropdown(
              status: item.status,
              onChanged: (v) => setState(() => item.status = v ?? AdjustmentStatus.none),
            ),
          ] else
            _buildUnselectedFooter(stock),
        ],
      ),
    );
  }

  Widget _buildCompactStockRow(_AdjustItem item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        const Icon(Icons.inventory_2_rounded, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          'Current Stock',
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10),
        ),
        const Spacer(),
        Text(
          '${item.currentStock} Units  •  Adjust Qty: ${item.adjustQuantity}',
          style: AppTypography.captionBold.copyWith(
            color: AppColors.textPrimary,
            fontSize: 11,
          ),
        ),
      ]),
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
        'Stock: $stock — tap + to adjust',
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
          fontSize: 10,
        ),
      ),
    );
  }
}
