import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/stock/presentation/pages/barcode_scanner_screen.dart';
import 'package:dukaapp/features/stock/presentation/widgets/compact_qty_stepper.dart';
import 'package:dukaapp/features/stock/presentation/widgets/transfer_shop_dropdown.dart';
import 'package:dukaapp/features/stock/presentation/widgets/transfer_summary_card.dart';
import 'package:dukaapp/features/stock/presentation/widgets/transfer_bottom_bar.dart';

class _TransferItem {
  final String productId;
  final String name;
  final int availableStock;
  int transferQuantity;

  _TransferItem({required this.productId, required this.name, required this.availableStock}) : transferQuantity = 0;
}

class TransferProductsPage extends ConsumerStatefulWidget {
  const TransferProductsPage({super.key});

  @override
  ConsumerState<TransferProductsPage> createState() => _TransferProductsPageState();
}

class _TransferProductsPageState extends ConsumerState<TransferProductsPage> {
  String? _selectedShop;
  final TextEditingController _searchController = TextEditingController();
  final List<_TransferItem> _items = [];
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
        };
      }).toList();
      setState(() { _allProducts = products; _isLoadingProducts = false; });
    } catch (_) {
      setState(() => _isLoadingProducts = false);
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _allProducts;
    return _allProducts.where((p) {
      final name = (p['name'] as String).toLowerCase();
      final barcode = (p['barcode']?.toString() ?? '').toLowerCase();
      return name.contains(query) || barcode.contains(query);
    }).toList();
  }

  /// Products to render: the filtered catalog, plus any already-selected
  /// items whose product isn't in the catalog.
  List<Map<String, dynamic>> get _displayProducts {
    final list = List<Map<String, dynamic>>.from(_filteredProducts);
    final names = list.map((p) => p['name'] as String).toSet();
    for (final item in _items) {
      if (item.transferQuantity > 0 && !names.contains(item.name)) {
        list.add({
          'product_id': item.productId,
          'name': item.name,
          'stock': item.availableStock,
        });
      }
    }
    return list;
  }

  /// Items currently part of the transfer (quantity >= 1).
  List<_TransferItem> get _selectedItems =>
      _items.where((item) => item.transferQuantity > 0).toList();

  int get _totalTransferQuantity => _items.fold(0, (sum, item) => sum + item.transferQuantity);

  int _itemIndexByName(String name) => _items.indexWhere((item) => item.name == name);

  int _qtyFor(String name) {
    final i = _itemIndexByName(name);
    return i < 0 ? 0 : _items[i].transferQuantity;
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  /// Select a product (quantity 1) or bump its quantity, capped at the
  /// available stock — mirroring the old stepper's maxValue.
  void _incrementProduct(Map<String, dynamic> product) {
    final name = product['name'] as String;
    final i = _itemIndexByName(name);
    setState(() {
      if (i < 0) {
        final stock = ((product['stock'] as num?) ?? 0).toInt();
        if (stock <= 0) return;
        final item = _TransferItem(
          productId: (product['product_id'] ?? '').toString(),
          name: name,
          availableStock: stock,
        );
        item.transferQuantity = 1;
        _items.add(item);
      } else if (_items[i].transferQuantity < _items[i].availableStock) {
        _items[i].transferQuantity += 1;
      }
    });
  }

  /// Deselect at quantity 1 — the item is kept with quantity 0.
  void _decrementProduct(String name) {
    final i = _itemIndexByName(name);
    if (i < 0) return;
    setState(() {
      if (_items[i].transferQuantity <= 1) {
        _items[i].transferQuantity = 0;
      } else {
        _items[i].transferQuantity -= 1;
      }
    });
  }

  /// Open the camera and scan a barcode. An exact match is selected straight
  /// from the catalog; otherwise the code becomes the search query.
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
      if (_qtyFor(name) > 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$name is already selected'),
          backgroundColor: AppColors.warning,
        ));
        return;
      }
      _incrementProduct(product);
      _showAddedSnack(name);
    } else {
      setState(() => _searchController.text = code);
    }
  }

  void _showAddedSnack(String name) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        '$name added to transfer',
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite),
      ),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
      ),
    ));
  }

  // TransferShopDropdown values look like "Shop Name (shop_id)".
  String? _extractShopId(String? label) {
    if (label == null) return null;
    final match = RegExp(r'\(([^)]+)\)$').firstMatch(label);
    return match?.group(1);
  }

  Future<void> _save() async {
    if (_selectedShop == null || _items.isEmpty) return;
    final toShopId = _extractShopId(_selectedShop);
    if (toShopId == null || toShopId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Select a valid destination shop.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)),
        backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM))));
      return;
    }
    final itemsWithQty = _items.where((i) => i.transferQuantity > 0).toList();
    if (itemsWithQty.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Enter quantity for at least one product.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)),
        backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM))));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiServiceProvider);
      // Backend reads: to_shop_id, product_id[], quantity[product_id]
      final body = <String, dynamic>{'to_shop_id': toShopId};
      for (int i = 0; i < itemsWithQty.length; i++) {
        final item = itemsWithQty[i];
        body['product_id[$i]'] = item.productId;
        body['quantity[${item.productId}]'] = item.transferQuantity.toString();
      }
      final result = await api.postMfProductionTransfer(body);
      if (!mounted) return;
      final status = result['status']?.toString() ?? '';
      if (status == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Transfer completed successfully', style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)),
          backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM))));
        context.pop(true);
      } else {
        final msg = result['message']?.toString() ?? 'Transfer failed';
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
        // Pinned header: destination shop and search stay fixed.
        _buildStickyHeader(),
        Expanded(child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 12),
            _buildProductsHeader(), const SizedBox(height: 8),
            _buildCatalogList(),
            if (_selectedItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              TransferSummaryCard(productsSelected: _selectedItems.length, totalQuantity: _totalTransferQuantity, destinationShop: _selectedShop ?? ''),
            ],
            SizedBox(height: 24 + bottomPadding),
          ]),
        )),
        TransferBottomBar(
          onClose: () => context.pop(),
          onTransfer: (_selectedItems.isNotEmpty && _selectedShop != null && !_isSaving) ? _save : null,
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
        Text('Transfer Manufactured Products', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text('Transfer manufactured products to other shops.', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10)),
      ]),
      centerTitle: true,
      actions: [
        Padding(padding: const EdgeInsets.only(right: 12), child: Container(
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
          child: IconButton(onPressed: null, icon: Icon(Icons.swap_horiz_rounded, color: AppColors.textHint, size: 20)),
        )),
      ],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.divider)),
    );
  }

  Widget _buildStickyHeader() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        border: Border(bottom: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppConstants.paddingLG, 12, AppConstants.paddingLG, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          TransferShopDropdown(value: _selectedShop, onChanged: (v) => setState(() => _selectedShop = v)),
          const SizedBox(height: 8),
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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
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
        Text(
          _selectedItems.isEmpty ? 'Products' : 'Transfer Items',
          style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        if (_selectedItems.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusFull),
            ),
            child: Text('${_selectedItems.length}',
              style: AppTypography.captionBold.copyWith(color: AppColors.primary, fontSize: 11)),
          ),
        ],
        const Spacer(),
        Text('${products.length} available', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _buildCatalogList() {
    if (_isLoadingProducts) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    final products = _displayProducts;
    if (_allProducts.isEmpty && _searchController.text.trim().isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXXL, vertical: 60),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.inventory_2_rounded, size: 56, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('No manufactured products found', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ]),
      ));
    }
    if (products.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXXL, vertical: 60),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 120, height: 120, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), shape: BoxShape.circle),
            child: Icon(Icons.search_off_rounded, size: 56, color: AppColors.primary.withValues(alpha: 0.4))),
          const SizedBox(height: 24),
          Text('No Products Found', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Search a product to begin transferring.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
        ]),
      ));
    }
    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Column(children: products.map(_buildCatalogCard).toList()));
  }

  Widget _buildCatalogCard(Map<String, dynamic> product) {
    final name = product['name'] as String;
    final idx = _itemIndexByName(name);
    final item = idx >= 0 ? _items[idx] : null;
    final qty = item?.transferQuantity ?? 0;
    final selected = qty > 0;
    final stock = item?.availableStock ?? ((product['stock'] as num?) ?? 0).toInt();
    final remaining = stock - qty;

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
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Header: avatar + name/availability + stepper
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
                name.isNotEmpty ? name.substring(0, name.length.clamp(0, 2)).toUpperCase() : '??',
                style: AppTypography.captionBold.copyWith(color: AppColors.primary, fontSize: 11),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(
                name,
                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Available: $stock',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10),
              ),
            ]),
          ),
          const SizedBox(width: 6),
          CompactQtyStepper(
            qty: qty,
            onAdd: () => _incrementProduct(product),
            onRemove: () => _decrementProduct(name),
          ),
        ]),
        const SizedBox(height: 8),
        // Stock breakdown revealed once selected.
        if (selected && item != null)
          _buildStockInfo(stock, qty, remaining)
        else
          _buildUnselectedFooter(stock),
      ]),
    );
  }

  Widget _buildStockInfo(int stock, int qty, int remaining) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Text('Available: $stock', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10)),
        const Spacer(),
        Text('Transfer: $qty', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10)),
        const Spacer(),
        Text(
          'Remaining: $remaining',
          style: AppTypography.captionBold.copyWith(
            color: remaining < 0 ? AppColors.danger : AppColors.success,
            fontSize: 10,
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
        stock > 0
            ? 'Available: $stock units — tap + to transfer'
            : 'No stock available — cannot transfer',
        style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10),
      ),
    );
  }
}
