import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/stock/presentation/pages/barcode_scanner_screen.dart';
import 'package:dukaapp/features/stock/presentation/widgets/compact_qty_stepper.dart';
import 'package:dukaapp/features/stock/presentation/widgets/price_input.dart';
import 'package:dukaapp/features/stock/presentation/widgets/expiry_picker.dart';
import 'package:dukaapp/features/purchase/presentation/widgets/purchase_information_card.dart';
import 'package:dukaapp/features/stock/presentation/providers/stock_provider.dart';
import 'package:dukaapp/features/purchase/presentation/widgets/purchase_summary_card.dart';
import 'package:dukaapp/features/purchase/presentation/widgets/purchase_bottom_bar.dart';
import 'package:dukaapp/features/purchase/presentation/providers/purchase_provider.dart';
import 'package:dukaapp/core/providers.dart';

class _PurchaseItem {
  final String name;
  final dynamic productId;
  final int currentStock;
  int quantity;
  final TextEditingController buyingPrice;
  final TextEditingController sellingPrice;
  final TextEditingController wholesalePrice;
  DateTime? expiryDate;

  _PurchaseItem({
    required this.name,
    this.productId,
    required this.currentStock,
    double buyingPriceValue = 0,
    double sellingPriceValue = 0,
    double wholesalePriceValue = 0,
  })  : quantity = 1,
        buyingPrice = TextEditingController(text: buyingPriceValue > 0 ? buyingPriceValue.toStringAsFixed(0) : ''),
        sellingPrice = TextEditingController(text: sellingPriceValue > 0 ? sellingPriceValue.toStringAsFixed(0) : ''),
        wholesalePrice = TextEditingController(text: wholesalePriceValue > 0 ? wholesalePriceValue.toStringAsFixed(0) : '');

  void dispose() {
    buyingPrice.dispose();
    sellingPrice.dispose();
    wholesalePrice.dispose();
  }
}

class PurchaseStockPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialProduct;
  final bool editMode;
  final bool createMode;
  final String? poNumber;
  final String? purchaseId;
  final String? initialSupplier;
  final List<Map<String, dynamic>>? editProducts;

  const PurchaseStockPage({
    super.key,
    this.initialProduct,
    this.editMode = false,
    this.createMode = false,
    this.poNumber,
    this.purchaseId,
    this.initialSupplier,
    this.editProducts,
  });

  @override
  ConsumerState<PurchaseStockPage> createState() => _PurchaseStockPageState();
}

class _PurchaseStockPageState extends ConsumerState<PurchaseStockPage> {
  String? _selectedAccount;
  String? _selectedSupplier;
  DateTime _purchaseDate = DateTime.now();
  final List<_PurchaseItem> _items = [];
  // Live search over the inline product list.
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allProducts = [];
  bool _isLoadingProducts = true;
  List<String> _accounts = [];
  List<String> _suppliers = [];
  // id→name maps for submitting correct IDs to backend
  Map<String, String> _supplierIdMap = {}; // name → id
  Map<String, String> _accountIdMap  = {}; // name → id

  @override
  void initState() {
    super.initState();
    _loadProductList();
    _loadAccountsAndSuppliers();
    if (widget.editMode && widget.editProducts != null) {
      _selectedSupplier = widget.initialSupplier;
      for (final product in widget.editProducts!) {
        final name = product['name'] as String;
        final quantity = product['quantity'] as int? ?? 1;
        final price = (product['price'] as num?)?.toDouble() ?? 0;
        if (!_items.any((item) => item.name == name)) {
          final item = _PurchaseItem(
            name: name,
            currentStock: 0,
            buyingPriceValue: price,
            sellingPriceValue: price,
            wholesalePriceValue: price,
          );
          item.quantity = quantity;
          _items.add(item);
        }
      }
    } else if (widget.initialProduct != null) {
      _addInitialProduct(widget.initialProduct!);
    }
  }

  Future<void> _loadProductList() async {
    if (mounted) setState(() => _isLoadingProducts = true);
    try {
      // Try stockProvider first (already loaded → no extra API call)
      final stockState = ref.read(stockProvider);
      final stockProducts = stockState.maybeWhen(
        data: (s) => s.products,
        orElse: () => null,
      );
      if (stockProducts != null && stockProducts.isNotEmpty) {
        final products = stockProducts.map((p) => {
          'name': p.name,
          'product_id': p.productId?.toString() ?? '',
          'barcode': p.barcode ?? '',
          'stock': p.type == 'service' ? 9999.0 : p.available,
          'buyingPrice': p.buyingPrice,
          'sellingPrice': p.sellingPrice,
          'wholesalePrice': p.wholesalePrice,
        }).where((p) => (p['name'] as String).isNotEmpty).toList();
        if (mounted) setState(() { _allProducts = products; _isLoadingProducts = false; });
        return;
      }
      // Fallback: fetch stock directly from API (same endpoint as stockProvider)
      final api = ref.read(apiServiceProvider);
      final res = await api.getStock();
      final body = res.data;
      List raw = [];
      if (body is List) {
        raw = body;
      } else if (body is Map) {
        final data = body['data'] ?? body['stock'] ?? body['products'] ?? body;
        if (data is List) raw = data;
      }
      double toD(dynamic v) => num.tryParse(v?.toString() ?? '')?.toDouble() ?? 0.0;
      final products = raw.whereType<Map>().map((e) {
        final m = Map<String, dynamic>.from(e);
        return {
          'name': (m['product_name'] ?? m['name'] ?? '').toString(),
          'product_id': (m['product_id'] ?? m['id'])?.toString() ?? '',
          'barcode': (m['barcode'] ?? m['bar_code'] ?? '').toString(),
          'stock': toD(m['available'] ?? m['quantity'] ?? m['stock'] ?? 0),
          'buyingPrice': toD(m['bp'] ?? m['buying_price'] ?? m['actual_bp'] ?? m['cost_price']),
          'sellingPrice': toD(m['sp'] ?? m['selling_price'] ?? m['unit_price'] ?? m['price']),
          'wholesalePrice': toD(m['wp'] ?? m['wholesale_price']),
        };
      }).where((p) => (p['name'] as String).isNotEmpty).toList();
      if (mounted) setState(() { _allProducts = products; _isLoadingProducts = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProducts = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load products: $e')),
        );
      }
    }
  }

  Future<void> _loadAccountsAndSuppliers() async {
    try {
      final api = ref.read(apiServiceProvider);
      // Load accounts — API may return a raw List or a Map wrapping a List
      final acctRes = await api.getCashbookAccounts();
      final acctBody = acctRes.data;
      List<String> accounts = [];
      Map<String, String> accountIdMap = {};
      List<dynamic> acctList = [];
      if (acctBody is List) {
        acctList = acctBody;
      } else if (acctBody is Map) {
        final data = acctBody['data'] ?? acctBody['accounts'] ?? acctBody;
        if (data is List) acctList = data;
      }
      for (final e in acctList) {
        final name = (e['account_name'] ?? e['name'] ?? '').toString();
        final id   = (e['account_id'] ?? e['id'] ?? '').toString();
        if (name.isNotEmpty && !accountIdMap.containsKey(name)) {
          accounts.add(name);
          accountIdMap[name] = id;
        }
      }
      // Mirrors the web UI (footer.php fillSelectOptions): a synthetic
      // "Supplier Credit" option with account_id 11, which the backend's
      // isCreditPurchaseAccount() treats as a credit (unpaid) purchase.
      const creditLabel = 'Supplier Credit';
      if (!accountIdMap.containsKey(creditLabel)) {
        accounts.insert(0, creditLabel);
        accountIdMap[creditLabel] = '11';
      }

      // Load suppliers — same shape flexibility
      final suppRes = await api.getSuppliers();
      final suppBody = suppRes.data;
      List<String> suppliers = [];
      Map<String, String> supplierIdMap = {};
      List<dynamic> suppList = [];
      if (suppBody is List) {
        suppList = suppBody;
      } else if (suppBody is Map) {
        final data = suppBody['data'] ?? suppBody['suppliers'] ?? suppBody;
        if (data is List) suppList = data;
      }
      for (final e in suppList) {
        final name = (e['supplier_name'] ?? e['name'] ?? '').toString();
        final id   = (e['supplier_id'] ?? e['id'] ?? '').toString();
        if (name.isNotEmpty && !supplierIdMap.containsKey(name)) {
          suppliers.add(name);
          supplierIdMap[name] = id;
        }
      }

      if (mounted) setState(() {
        _accounts = accounts;
        _suppliers = suppliers;
        _accountIdMap  = accountIdMap;
        _supplierIdMap = supplierIdMap;
        // Default to Cash account; fall back to first account if Cash not found
        if (_selectedAccount == null && accounts.isNotEmpty) {
          _selectedAccount = accounts.firstWhere(
            (a) => a.toLowerCase() == 'cash',
            orElse: () => accounts.first,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load accounts: $e')),
        );
      }
    }
  }

  void _addInitialProduct(Map<String, dynamic> product) {
    final name = product['name'] as String;
    if (!_items.any((item) => item.name == name)) {
      _items.add(_PurchaseItem(
        name: name,
        productId: product['product_id'],
        currentStock: (product['stock'] as num?)?.toInt() ?? 0,
        buyingPriceValue: (product['buyingPrice'] as num?)?.toDouble() ?? 0.0,
        sellingPriceValue: (product['sellingPrice'] as num?)?.toDouble() ?? 0.0,
        wholesalePriceValue: (product['wholesalePrice'] as num?)?.toDouble() ?? 0.0,
      ));
    }
  }

  /// Items currently part of the purchase (quantity >= 1).
  List<_PurchaseItem> get _selectedItems =>
      _items.where((item) => item.quantity > 0).toList();

  int get _totalQuantity =>
      _items.fold(0, (sum, item) => sum + (item.quantity > 0 ? item.quantity : 0));

  String get _estimatedValue {
    double total = 0;
    for (final item in _items) {
      if (item.quantity <= 0) continue;
      final price = double.tryParse(item.buyingPrice.text) ?? 0;
      total += price * item.quantity;
    }
    return 'Tsh ${total.toStringAsFixed(0)}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

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

  /// Filter a free-text query against product name OR barcode.
  List<Map<String, dynamic>> filterProducts(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return List.from(_allProducts);
    return _allProducts.where((p) {
      final name = (p['name'] as String).toLowerCase();
      final barcode = (p['barcode']?.toString() ?? '').toLowerCase();
      return name.contains(q) || barcode.contains(q);
    }).toList();
  }

  /// Products to render: the filtered catalog, plus any already-selected
  /// items whose product isn't in the catalog (e.g. edit-mode extras).
  List<Map<String, dynamic>> get _displayProducts {
    final list = List<Map<String, dynamic>>.from(_filteredProducts);
    final names = list.map((p) => p['name'] as String).toSet();
    for (final item in _items) {
      if (item.quantity > 0 && !names.contains(item.name)) {
        list.add({
          'name': item.name,
          'product_id': item.productId,
          'barcode': '',
          'stock': item.currentStock,
          'buyingPrice': 0,
          'sellingPrice': 0,
          'wholesalePrice': 0,
        });
      }
    }
    return list;
  }

  /// Open the camera and scan a barcode. An exact match is added straight to
  /// the purchase list; otherwise the code becomes the search query.
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
      if (_items.any((item) => item.name == name)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$name is already in this purchase'),
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

  /// Add a single product straight to the purchase list (one tap).


  int _itemIndexByName(String name) =>
      _items.indexWhere((item) => item.name == name);

  int _qtyFor(String name) {
    final i = _itemIndexByName(name);
    return i < 0 ? 0 : _items[i].quantity;
  }

  void _incrementProduct(Map<String, dynamic> product) {
    final name = product['name'] as String;
    final i = _itemIndexByName(name);
    setState(() {
      if (i < 0) {
        _items.add(_PurchaseItem(
          name: name,
          productId: product['product_id'],
          currentStock: (product['stock'] as num?)?.toInt() ?? 0,
          buyingPriceValue: (product['buyingPrice'] as num?)?.toDouble() ?? 0.0,
          sellingPriceValue: (product['sellingPrice'] as num?)?.toDouble() ?? 0.0,
          wholesalePriceValue: (product['wholesalePrice'] as num?)?.toDouble() ?? 0.0,
        ));
      } else {
        _items[i].quantity += 1;
      }
    });
  }

  void _decrementProduct(String name) {
    final i = _itemIndexByName(name);
    if (i < 0) return;
    setState(() {
      if (_items[i].quantity <= 1) {
        // Deselect: keep the item (and its controllers) but drop it out of
        // the active purchase by setting quantity to 0.
        _items[i].quantity = 0;
      } else {
        _items[i].quantity -= 1;
      }
    });
  }

  void _showAddedSnack(String name) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        '$name added to purchase',
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite),
      ),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
      ),
    ));
  }

  void _addProducts(List<Map<String, dynamic>> products) {
    int addedCount = 0;
    for (final product in products) {
      final name = product['name'] as String;
      if (_items.any((item) => item.name == name)) continue;
      _items.add(_PurchaseItem(
        name: name,
        productId: product['product_id'],
        currentStock: (product['stock'] as num?)?.toInt() ?? 0,
        buyingPriceValue: (product['buyingPrice'] as num?)?.toDouble() ?? 0.0,
        sellingPriceValue: (product['sellingPrice'] as num?)?.toDouble() ?? 0.0,
        wholesalePriceValue: (product['wholesalePrice'] as num?)?.toDouble() ?? 0.0,
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



  void _showSearchSheet() {
    if (_isLoadingProducts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading products, please wait...')),
      );
      return;
    }
    if (_allProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Products not loaded. Tap to retry.'),
          action: SnackBarAction(label: 'Retry', onPressed: () {
            setState(() => _isLoadingProducts = true);
            _loadProductList();
          }),
        ),
      );
      return;
    }
    final searchController = TextEditingController();
    List<Map<String, dynamic>> filtered = List.from(_allProducts);
    final Set<int> selectedIndices = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void toggleSelection(int index) {
              setSheetState(() {
                if (selectedIndices.contains(index)) {
                  selectedIndices.remove(index);
                } else {
                  selectedIndices.add(index);
                }
              });
            }

            void toggleAll() {
              setSheetState(() {
                final selectableIndices = filtered
                    .asMap()
                    .keys
                    .where((i) => !_items.any((item) => item.name == filtered[i]['name']))
                    .toSet();
                final allSelected = selectableIndices.every((i) => selectedIndices.contains(i));
                if (allSelected) {
                  selectedIndices.removeAll(selectableIndices);
                } else {
                  selectedIndices.addAll(selectableIndices);
                }
              });
            }

            void addSelected() {
              final toAdd = selectedIndices
                  .map((i) => filtered[i])
                  .where((p) => !_items.any((item) => item.name == p['name']))
                  .toList();
              Navigator.pop(context);
              _addProducts(toAdd);
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                final selectableCount = filtered
                    .where((p) => !_items.any((item) => item.name == p['name']))
                    .length;
                final allSelected = selectableCount > 0 &&
                    filtered.asMap().keys
                        .where((i) => !_items.any((item) => item.name == filtered[i]['name']))
                        .every((i) => selectedIndices.contains(i));

                return Container(
                  decoration: const BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Search Product',
                                style: AppTypography.h6.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (selectedIndices.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${selectedIndices.length} selected',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded, size: 22),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
                        child: TextField(
                          controller: searchController,
                          autofocus: true,
                          onChanged: (value) {
                            setSheetState(() {
                              selectedIndices.clear();
                              filtered = filterProducts(value);
                            });
                          },
                          style: AppTypography.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Search by product name',
                            hintStyle: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textHint,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.textHint,
                              size: 20,
                            ),
                            suffixIcon: Container(
                              margin: const EdgeInsets.all(6),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: InkWell(
                                onTap: () async {
                                  final result = await Navigator.of(context).push<String>(
                                    MaterialPageRoute(
                                      fullscreenDialog: true,
                                      builder: (_) => const BarcodeScannerScreen(),
                                    ),
                                  );
                                  if (result != null && result.isNotEmpty) {
                                    searchController.text = result;
                                    setSheetState(() {
                                      selectedIndices.clear();
                                      filtered = filterProducts(result);
                                      // Auto-select an exact barcode match so the
                                      // user can add it with one tap.
                                      final code = result.trim();
                                      final exactIndex = filtered.indexWhere(
                                        (p) => (p['barcode']?.toString() ?? '').trim() == code,
                                      );
                                      if (exactIndex >= 0) {
                                        final name = filtered[exactIndex]['name'] as String;
                                        if (!_items.any((item) => item.name == name)) {
                                          selectedIndices.add(exactIndex);
                                        }
                                      }
                                    });
                                  }
                                },
                                child: const Icon(
                                  Icons.barcode_reader,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      if (filtered.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: allSelected,
                                  onChanged: selectableCount > 0 ? (_) => toggleAll() : null,
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
                      ],
                      const SizedBox(height: 4),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 48,
                                      color: AppColors.textHint.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No products found',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppConstants.paddingLG,
                                ),
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) => const Divider(
                                  height: 1,
                                  color: AppColors.borderLight,
                                ),
                                itemBuilder: (context, index) {
                                  final product = filtered[index];
                                  final name = product['name'] as String;
                                  final stock = (product['stock'] as num?)?.toInt() ?? 0;
                                  final barcode = (product['barcode']?.toString() ?? '').trim();
                                  final isAlreadyAdded = _items.any((item) => item.name == name);
                                  final isSelected = selectedIndices.contains(index);

                                  return InkWell(
                                    onTap: isAlreadyAdded
                                        ? null
                                        : () => toggleSelection(index),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        children: [
                                          if (!isAlreadyAdded)
                                            SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: Checkbox(
                                                value: isSelected,
                                                onChanged: (_) => toggleSelection(index),
                                                activeColor: AppColors.primary,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                side: BorderSide(
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : AppColors.border,
                                                  width: 1.5,
                                                ),
                                              ),
                                            )
                                          else
                                            const SizedBox(width: 24),
                                          const SizedBox(width: 12),
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(10),
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
                                                  barcode.isNotEmpty
                                                      ? 'Stock: $stock  •  Barcode: $barcode'
                                                      : 'Stock: $stock',
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
                                  );
                                },
                              ),
                      ),
                      if (selectedIndices.isNotEmpty)
                        Container(
                          padding: EdgeInsets.only(
                            left: AppConstants.paddingLG,
                            right: AppConstants.paddingLG,
                            top: 12,
                            bottom: MediaQuery.of(context).padding.bottom + 12,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.card,
                            border: Border(
                              top: BorderSide(color: AppColors.divider, width: 1),
                            ),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: AppConstants.buttonHeight,
                            child: ElevatedButton.icon(
                              onPressed: addSelected,
                              icon: const Icon(Icons.add_rounded, size: 20),
                              label: Text(
                                'Add Selected (${selectedIndices.length})',
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
                  ),
                );
              },
            );
          },
        );
      },
    );
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
            // Pinned header: account, supplier, date and search stay fixed.
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
                      PurchaseSummaryCard(
                        numberOfProducts: _selectedItems.length,
                        totalQuantity: _totalQuantity,
                        estimatedValue: _estimatedValue,
                      ),
                    ],
                    SizedBox(height: 24 + bottomPadding),
                  ],
                ),
              ),
            ),
            PurchaseBottomBar(
              onClose: () => context.pop(),
              saveLabel: widget.editMode
                  ? 'Update Order'
                  : widget.createMode
                      ? 'Create Order'
                      : null,
              onSave: _selectedItems.isNotEmpty
                  ? () async {
                      try {
                        final repo = ref.read(purchaseRepositoryProvider);
                        final items = _selectedItems;
                        // Backend expects parallel arrays: product_id[], quantity[], bp[], sp[], wp[], expiry_date[]
                        // PHP reads: product_id[i]=pid, quantity[pid]=qty, bp[pid]=val ...
                        // so quantity/bp/sp/wp/expiry must be keyed by product_id, not by index.
                        final Map<String, dynamic> purchaseBody = {};
                        for (int i = 0; i < items.length; i++) {
                          final item = items[i];
                          final pid = item.productId?.toString() ?? i.toString();
                          purchaseBody['product_id[$i]'] = pid;
                          purchaseBody['quantity[$pid]'] = item.quantity.toString();
                          purchaseBody['bp[$pid]'] = (double.tryParse(item.buyingPrice.text) ?? 0).toString();
                          purchaseBody['sp[$pid]'] = (double.tryParse(item.sellingPrice.text) ?? 0).toString();
                          purchaseBody['wp[$pid]'] = (double.tryParse(item.wholesalePrice.text) ?? 0).toString();
                          purchaseBody['expiry_date[$pid]'] = item.expiryDate != null
                              ? DateFormat('yyyy-MM-dd').format(item.expiryDate!)
                              : '';
                        }
                        purchaseBody['supplier_id']  = _supplierIdMap[_selectedSupplier ?? ''] ?? '';
                        purchaseBody['payment_mode'] = _accountIdMap[_selectedAccount ?? ''] ?? (_selectedAccount ?? '');
                        purchaseBody['record_date']  = DateFormat('yyyy-MM-dd').format(_purchaseDate);
                        // Web posts type=purchase; createGroupedRestock only applies the
                        // credit (Supplier Credit / account 11) logic for 'purchase'.
                        purchaseBody['type']         = widget.createMode ? 'order' : 'purchase';
                        if (widget.editMode && widget.purchaseId != null && widget.purchaseId!.isNotEmpty) {
                          purchaseBody['purchase_id'] = widget.purchaseId;
                        }
                        final res = await repo.createPurchase(purchaseBody);
                        if (!mounted) return;
                        final ok = res['status']?.toString() == 'success' ||
                            res['status']?.toString() == '1' ||
                            res['status'] == true;
                        if (!ok) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(res['message']?.toString() ?? 'Failed to save purchase', style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)),
                            backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
                          ));
                          return;
                        }
                        // Invalidate stock cache so balance reflects the restock
                        ref.read(stockProvider.notifier).refresh();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            widget.editMode ? 'Purchase order updated successfully' : 'Purchase saved successfully',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite),
                          ),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
                        ));
                        context.pop();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e'), backgroundColor: AppColors.danger));
                      }
                    }
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
            widget.createMode
                ? 'Create Purchase Order'
                : widget.editMode
                    ? 'Edit Purchase Order'
                    : 'Restock Products',
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.createMode
                ? 'Create a new purchase order.'
                : widget.editMode
                    ? 'Editing ${widget.poNumber ?? "purchase order"}'
                    : 'Pick products below and record the purchase.',
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
                Icons.receipt_long_rounded,
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
            // Account + Supplier in one row
            PurchaseInformationCard(
              showSearch: false,
              inlineRow: true,
              selectedAccount: _selectedAccount,
              onAccountChanged: (v) => setState(() => _selectedAccount = v),
              selectedSupplier: _selectedSupplier,
              onSupplierChanged: (v) => setState(() => _selectedSupplier = v),
              accounts: _accounts,
              suppliers: _suppliers,
            ),
            const SizedBox(height: 8),
            // Date
            _buildDateField(),
            const SizedBox(height: 8),
            // Search bar
            _buildSearchBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _purchaseDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => _purchaseDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${_purchaseDate.day.toString().padLeft(2, '0')}/${_purchaseDate.month.toString().padLeft(2, '0')}/${_purchaseDate.year}',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textHint,
              size: 18,
            ),
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
    final products = _displayProducts;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Row(
        children: [
          Text(
            'Products',
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusFull),
            ),
            child: Text(
              '${products.length}',
              style: AppTypography.captionBold.copyWith(
                color: AppColors.primary,
                fontSize: 11,
              ),
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _showSearchSheet,
            icon: const Icon(Icons.checklist_rounded, size: 18, color: AppColors.primary),
            label: Text(
              'Select multiple',
              style: AppTypography.captionBold.copyWith(
                color: AppColors.primary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogList() {
    if (_isLoadingProducts) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    final products = _displayProducts;
    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLG,
          vertical: 8,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 32,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 8),
              Text(
                'No products match your search',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
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
    final buyingPrice = (product['buyingPrice'] as num?)?.toDouble() ?? 0;
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
          // Prices + expiry. Editable only once selected.
          if (selected && item != null) ...[
            _buildCompactPriceRow(item),
            const SizedBox(height: 8),
            ExpiryPicker(
              label: 'Expiry Date',
              selectedDate: item.expiryDate,
              onDateSelected: (d) => setState(() => item.expiryDate = d),
            ),
          ] else
            _buildUnselectedFooter(buyingPrice),
        ],
      ),
    );
  }

  Widget _buildCompactPriceRow(_PurchaseItem item) {
    return Row(
      children: [
        Expanded(
          child: PriceInput(
            label: 'Buy',
            controller: item.buyingPrice,
            hintText: '0',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PriceInput(
            label: 'Sell',
            controller: item.sellingPrice,
            hintText: '0',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PriceInput(
            label: 'Whole',
            controller: item.wholesalePrice,
            hintText: '0',
          ),
        ),
      ],
    );
  }

  Widget _buildUnselectedFooter(double buyingPrice) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        buyingPrice > 0
            ? 'Buying price: Tsh ${buyingPrice.toStringAsFixed(0)} — tap + to restock'
            : 'Tap + to add this product to the purchase',
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
          fontSize: 10,
        ),
      ),
    );
  }
}
