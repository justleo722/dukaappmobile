import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/stock/presentation/pages/barcode_scanner_screen.dart';
import 'package:dukaapp/features/stock/presentation/providers/stock_provider.dart';
import 'package:dukaapp/features/stock/presentation/widgets/transfer_shop_dropdown.dart';
import 'package:dukaapp/features/stock/presentation/widgets/transfer_summary_card.dart';
import 'package:dukaapp/features/stock/presentation/widgets/transfer_bottom_bar.dart';
import 'package:dukaapp/features/stock/presentation/widgets/compact_qty_stepper.dart';

class _TransferItem {
  final String name;
  final int availableStock;
  final dynamic productId;
  int transferQuantity;

  _TransferItem({
    required this.name,
    required this.availableStock,
    this.productId,
    int? transferQuantity,
  }) : transferQuantity = transferQuantity ?? 1;
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

  /// Full unfiltered catalog (name, stock, product_id, barcode).
  List<Map<String, dynamic>> _getAllProducts() {
    final stockState = ref.read(stockProvider);
    return stockState.whenOrNull(
          data: (s) => s.products
              .map((p) => {
                    'name': p.name,
                    'stock': p.available.toInt(),
                    'product_id': p.productId,
                    'barcode': p.barcode ?? '',
                  })
              .toList(),
        ) ??
        [];
  }

  /// Products matching the current search query (name or barcode).
  List<Map<String, dynamic>> _getFilteredProducts() {
    final allProducts = _getAllProducts();
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return allProducts;
    return allProducts.where((p) {
      final name = (p['name'] as String).toLowerCase();
      final barcode = (p['barcode']?.toString() ?? '').toLowerCase();
      return name.contains(query) || barcode.contains(query);
    }).toList();
  }

  /// Extract shop_id from label "Shop Name (shop_id)"
  String? _extractShopId(String? label) {
    if (label == null) return null;
    final match = RegExp(r'\(([^)]+)\)$').firstMatch(label);
    return match?.group(1);
  }

  /// Items currently part of the transfer (quantity >= 1).
  List<_TransferItem> get _selectedItems =>
      _items.where((item) => item.transferQuantity > 0).toList();

  int get _totalTransferQuantity =>
      _selectedItems.fold(0, (sum, item) => sum + item.transferQuantity);

  int _itemIndexByName(String name) =>
      _items.indexWhere((item) => item.name == name);

  int _qtyFor(String name) {
    final i = _itemIndexByName(name);
    return i < 0 ? 0 : _items[i].transferQuantity;
  }

  /// Select (or bump) a product straight from the catalog / barcode scan.
  void _incrementProduct(Map<String, dynamic> product) {
    final name = product['name'] as String;
    final i = _itemIndexByName(name);
    setState(() {
      if (i < 0) {
        _items.add(_TransferItem(
          name: name,
          availableStock: (product['stock'] as num?)?.toInt() ?? 0,
          productId: product['product_id'],
          transferQuantity: 1,
        ));
      } else {
        _items[i].transferQuantity += 1;
      }
    });
  }

  void _decrementProduct(String name) {
    final i = _itemIndexByName(name);
    if (i < 0) return;
    setState(() {
      if (_items[i].transferQuantity <= 1) {
        // Deselect: keep the item (and its state) but drop it out of the
        // active transfer by setting quantity to 0.
        _items[i].transferQuantity = 0;
      } else {
        _items[i].transferQuantity -= 1;
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

    final matches = _getAllProducts().where(
      (p) => (p['barcode']?.toString() ?? '').trim() == code,
    );

    if (matches.isNotEmpty) {
      _incrementProduct(matches.first);
    } else {
      setState(() => _searchController.text = code);
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
            // Pinned header: destination shop and search stay fixed.
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
                      TransferSummaryCard(
                        productsSelected: _selectedItems.length,
                        totalQuantity: _totalTransferQuantity,
                        destinationShop: _selectedShop ?? '',
                      ),
                    ],
                    SizedBox(height: 24 + bottomPadding),
                  ],
                ),
              ),
            ),
            TransferBottomBar(
              onClose: () => context.pop(),
              onTransfer: (_selectedShop != null &&
                      !_isSaving &&
                      _selectedItems.isNotEmpty)
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
            // Destination shop picker stays pinned at the top.
            TransferShopDropdown(
              value: _selectedShop,
              onChanged: (v) => setState(() => _selectedShop = v),
            ),
            const SizedBox(height: 8),
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
    final products = _getFilteredProducts();
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
            selectedCount > 0 ? 'Transfer Items' : 'Products',
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
                      'Available: $stock',
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
          // Available / transfer / remaining breakdown once selected.
          if (selected && item != null)
            _buildTransferInfoRow(item)
          else
            _buildUnselectedFooter(stock),
        ],
      ),
    );
  }

  Widget _buildTransferInfoRow(_TransferItem item) {
    final remaining = item.availableStock - item.transferQuantity;
    return Row(
      children: [
        _buildInfoChip('Available', '${item.availableStock}', AppColors.primary),
        const SizedBox(width: 8),
        _buildInfoChip('Transfer', '${item.transferQuantity}', AppColors.secondary),
        const SizedBox(width: 8),
        _buildInfoChip(
          'Remaining',
          '$remaining',
          remaining < 0 ? AppColors.danger : AppColors.success,
        ),
      ],
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: color,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnselectedFooter(int available) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Available: $available units — tap + to transfer',
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
          fontSize: 10,
        ),
      ),
    );
  }
}
