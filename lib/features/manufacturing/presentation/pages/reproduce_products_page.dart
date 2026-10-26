import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/features/stock/presentation/providers/stock_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/stock/presentation/pages/barcode_scanner_screen.dart';
import 'package:dukaapp/features/stock/presentation/widgets/compact_qty_stepper.dart';
import 'package:dukaapp/features/stock/presentation/widgets/expiry_picker.dart';
import 'package:dukaapp/features/stock/presentation/widgets/price_input.dart';

class _ReproduceProduct {
  final String productId;
  final String recipeId;
  final String name;
  final String recipe;
  int quantity;
  double productionCost;
  final TextEditingController sellingPriceController;
  final TextEditingController wholesalePriceController;
  DateTime expiryDate;

  _ReproduceProduct({
    required this.productId,
    required this.recipeId,
    required this.name,
    required this.recipe,
    required this.quantity,
    required this.productionCost,
    double sellingPrice = 0,
    double wholesalePrice = 0,
    DateTime? expiryDate,
  })  : sellingPriceController = TextEditingController(text: sellingPrice > 0 ? sellingPrice.toStringAsFixed(0) : ''),
        wholesalePriceController = TextEditingController(text: wholesalePrice > 0 ? wholesalePrice.toStringAsFixed(0) : ''),
        expiryDate = expiryDate ?? DateTime.now().add(const Duration(days: 365));

  void dispose() {
    sellingPriceController.dispose();
    wholesalePriceController.dispose();
  }
}

class ReproduceProductsPage extends ConsumerStatefulWidget {
  const ReproduceProductsPage({super.key});

  @override
  ConsumerState<ReproduceProductsPage> createState() => _ReproduceProductsPageState();
}

class _ReproduceProductsPageState extends ConsumerState<ReproduceProductsPage> {
  DateTime _productionDate = DateTime.now();
  final List<_ReproduceProduct> _items = [];
  // Live search over the inline product catalog.
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allProducts = [];
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
          'recipe_id': (m['recipe_id'] ?? '').toString(),
          'name': (m['product_name'] ?? m['name'] ?? '').toString(),
          'recipe': (m['recipe_name'] ?? m['recipe'] ?? '').toString(),
          'productionCost': num.tryParse((m['unit_cost'] ?? m['cost_price'] ?? 0).toString()) ?? 0,
          'sellingPrice': num.tryParse((m['selling_price'] ?? m['price'] ?? 0).toString()) ?? 0,
          'wholesalePrice': num.tryParse((m['wholesale_price'] ?? 0).toString()) ?? 0,
        };
      }).toList();
      setState(() => _allProducts = products);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final itemsWithQty = _items.where((i) => i.quantity > 0 && i.productId.isNotEmpty).toList();
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
      // Backend reads: product_id[], quantity[product_id], recipe_id[product_id],
      // selling_price[product_id], expiry_date[product_id], production_date
      final body = <String, dynamic>{
        'production_date': _productionDate.toIso8601String().substring(0, 10),
      };
      for (int i = 0; i < itemsWithQty.length; i++) {
        final item = itemsWithQty[i];
        final pid = item.productId;
        body['product_id[$i]'] = pid;
        body['quantity[$pid]'] = item.quantity.toString();
        if (item.recipeId.isNotEmpty) body['recipe_id[$pid]'] = item.recipeId;
        body['selling_price[$pid]'] = item.sellingPriceController.text.trim().isEmpty ? '0' : item.sellingPriceController.text.trim();
        body['wholesale_price[$pid]'] = item.wholesalePriceController.text.trim().isEmpty ? '0' : item.wholesalePriceController.text.trim();
        body['expiry_date[$pid]'] = item.expiryDate.toIso8601String().substring(0, 10);
      }
      final result = await api.postMfProductionReproduce(body);
      if (!mounted) return;
      final status = result['status']?.toString() ?? '';
      if (status == 'success') {
        // Finished goods' stock changed: reload the cached Stock list.
        ref.invalidate(stockProvider);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Re-production saved successfully', style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)),
          backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM))));
        context.pop(true);
      } else {
        final msg = result['message']?.toString() ?? 'Failed to save';
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

  Future<void> _pickProductionDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _productionDate, firstDate: DateTime(2020), lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: AppColors.primary, onPrimary: AppColors.textWhite, surface: AppColors.card, onSurface: AppColors.textPrimary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _productionDate = picked);
  }

  // ---------------------------------------------------------------------------
  // Premium inline catalog helpers
  // ---------------------------------------------------------------------------

  /// Items currently part of the re-production (quantity >= 1).
  List<_ReproduceProduct> get _selectedItems =>
      _items.where((item) => item.quantity > 0).toList();

  /// Products matching the current search query (name or barcode).
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
      if (item.quantity > 0 && !names.contains(item.name)) {
        list.add({
          'product_id': item.productId,
          'recipe_id': item.recipeId,
          'name': item.name,
          'recipe': item.recipe,
          'productionCost': item.productionCost,
          'sellingPrice': 0,
          'wholesalePrice': 0,
        });
      }
    }
    return list;
  }

  int _itemIndexByName(String name) => _items.indexWhere((item) => item.name == name);

  int _qtyFor(String name) {
    final i = _itemIndexByName(name);
    return i < 0 ? 0 : _items[i].quantity;
  }

  /// Select a product (quantity 1) or bump its quantity.
  void _incrementProduct(Map<String, dynamic> product) {
    final name = product['name'] as String;
    final i = _itemIndexByName(name);
    setState(() {
      if (i < 0) {
        _items.add(_ReproduceProduct(
          productId: (product['product_id'] ?? '').toString(),
          recipeId: (product['recipe_id'] ?? '').toString(),
          name: name,
          recipe: (product['recipe'] ?? '').toString(),
          quantity: 1,
          productionCost: ((product['productionCost'] as num?) ?? 0).toDouble(),
          sellingPrice: ((product['sellingPrice'] as num?) ?? 0).toDouble(),
          wholesalePrice: ((product['wholesalePrice'] as num?) ?? 0).toDouble(),
        ));
      } else {
        _items[i].quantity += 1;
      }
    });
  }

  /// Deselect at quantity 1 — the item (and its controllers) is kept.
  void _decrementProduct(String name) {
    final i = _itemIndexByName(name);
    if (i < 0) return;
    setState(() {
      if (_items[i].quantity <= 1) {
        _items[i].quantity = 0;
      } else {
        _items[i].quantity -= 1;
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
        '$name added to re-production',
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite),
      ),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(backgroundColor: const Color(0xFFF5F7FB), appBar: _buildAppBar(),
      body: SafeArea(top: false, child: Column(children: [
        // Pinned header: production date and search stay fixed.
        _buildStickyHeader(),
        Expanded(child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 12),
            _buildProductsHeader(), const SizedBox(height: 8),
            _buildCatalogList(),
            if (_selectedItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSummaryCard(),
            ],
            SizedBox(height: 24 + bottomPadding),
          ]),
        )),
        _buildBottomBar(),
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
        Text('Re-Produce Manufacture Products', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text('Re-produce existing manufactured products.', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10)),
      ]),
      centerTitle: true,
      actions: [
        Padding(padding: const EdgeInsets.only(right: 12), child: Container(
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
          child: IconButton(onPressed: null, icon: Icon(Icons.refresh_rounded, color: AppColors.textHint, size: 20)),
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
          Text('Production Date', style: AppTypography.label.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          _buildDateField(),
          const SizedBox(height: 8),
          _buildSearchBar(),
        ]),
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _pickProductionDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), border: Border.all(color: AppColors.inputBorder)),
        child: Row(children: [
          const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(
            '${_productionDate.day.toString().padLeft(2, '0')}/${_productionDate.month.toString().padLeft(2, '0')}/${_productionDate.year}',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          )),
          Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint, size: 18),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Row(children: [
        Text(
          _selectedItems.isEmpty ? 'Products' : 'Re-Production Items',
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
            child: Text(
              '${_selectedItems.length}',
              style: AppTypography.captionBold.copyWith(color: AppColors.primary, fontSize: 11),
            ),
          ),
        ],
        const Spacer(),
        Text('${products.length} available', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _buildCatalogList() {
    final products = _displayProducts;
    if (products.isEmpty) {
      if (_searchController.text.trim().isEmpty) return _buildEmptyState();
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
            const Icon(Icons.search_off_rounded, size: 32, color: AppColors.textHint),
            const SizedBox(height: 8),
            Text('No products match your search', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
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
    final idx = _itemIndexByName(name);
    final item = idx >= 0 ? _items[idx] : null;
    final qty = item?.quantity ?? 0;
    final selected = qty > 0;
    final recipe = item?.recipe ?? (product['recipe']?.toString() ?? '');
    final productionCost = item?.productionCost ?? (((product['productionCost'] as num?) ?? 0).toDouble());

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
        // Header: avatar + name/recipe + stepper
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
                'Recipe: $recipe',
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
        // Details revealed once selected.
        if (selected && item != null) ...[
          _buildCompactDetails(item),
          const SizedBox(height: 8),
          ExpiryPicker(
            label: 'Expiry Date',
            selectedDate: item.expiryDate,
            onDateSelected: (d) {
              if (d != null) setState(() => item.expiryDate = d);
            },
          ),
        ] else
          _buildUnselectedFooter(productionCost),
      ]),
    );
  }

  Widget _buildCompactDetails(_ReproduceProduct item) {
    return Row(children: [
      Expanded(child: _buildCostTile(item.productionCost)),
      const SizedBox(width: 8),
      Expanded(
        child: PriceInput(label: 'Sell', controller: item.sellingPriceController, hintText: '0'),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: PriceInput(label: 'Whole', controller: item.wholesalePriceController, hintText: '0'),
      ),
    ]);
  }

  Widget _buildCostTile(double productionCost) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text('Cost', style: AppTypography.captionBold.copyWith(color: AppColors.textSecondary, fontSize: 11)),
      const SizedBox(height: 6),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
        ),
        child: Text(
          'Tsh ${productionCost.toStringAsFixed(0)}',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
        ),
      ),
    ]);
  }

  Widget _buildUnselectedFooter(double productionCost) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        productionCost > 0
            ? 'Production cost: Tsh ${productionCost.toStringAsFixed(0)} — tap + to re-produce'
            : 'Tap + to add this product to re-production',
        style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final selected = _selectedItems;
    final totalCost = selected.fold(0.0, (sum, item) => sum + (item.productionCost * item.quantity));
    final totalQty = selected.fold(0, (sum, item) => sum + item.quantity);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Row(children: [
        _buildStat(label: 'Products', value: '${selected.length}', icon: Icons.inventory_2_rounded),
        _buildDivider(),
        _buildStat(label: 'Total Qty', value: '$totalQty', icon: Icons.shopping_cart_rounded),
        _buildDivider(),
        _buildStat(label: 'Total Cost', value: 'Tsh ${totalCost.toStringAsFixed(0)}', icon: Icons.attach_money_rounded, isWide: true),
      ]),
    );
  }

  Widget _buildStat({required String label, required String value, required IconData icon, bool isWide = false}) {
    return Expanded(flex: isWide ? 2 : 1, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: AppColors.primary), const SizedBox(height: 4),
      Text(value, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
      const SizedBox(height: 2),
      Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10), textAlign: TextAlign.center),
    ]));
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 32, margin: const EdgeInsets.symmetric(horizontal: 8), color: AppColors.divider);
  }

  Widget _buildEmptyState() {
    return Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXXL, vertical: 60),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 100, height: 100, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), shape: BoxShape.circle),
          child: Icon(Icons.refresh_rounded, size: 48, color: AppColors.primary.withValues(alpha: 0.4))),
        const SizedBox(height: 20),
        Text('No Products Available', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('No products available for re-production. Add products first.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
      ]),
    ));
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(left: AppConstants.paddingLG, right: AppConstants.paddingLG, top: 16, bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(color: AppColors.card, border: const Border(top: BorderSide(color: AppColors.divider, width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 12, offset: const Offset(0, -4))]),
      child: Row(children: [
        Expanded(child: SizedBox(height: AppConstants.buttonHeight, child: OutlinedButton(
          onPressed: () => context.pop(),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary, side: const BorderSide(color: AppColors.border, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD))),
          child: Text('Close', style: AppTypography.buttonLarge.copyWith(color: AppColors.textSecondary)),
        ))),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: SizedBox(height: AppConstants.buttonHeight, child: ElevatedButton(
          onPressed: (_selectedItems.isNotEmpty && !_isSaving) ? _save : null,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.textWhite, elevation: 0, disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD))),
          child: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Save', style: AppTypography.buttonLarge),
        ))),
      ]),
    );
  }
}
