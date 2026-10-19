import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dukaapp/features/sales/presentation/providers/sales_provider.dart';
import 'package:dukaapp/features/stock/presentation/providers/stock_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/core/models/shop_config.dart';
import 'package:dukaapp/features/stock/presentation/pages/barcode_scanner_screen.dart';
import 'package:dukaapp/features/customers/presentation/pages/add_customer_page.dart';

class AddSalePage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existingSale;

  const AddSalePage({super.key, this.existingSale});

  @override
  ConsumerState<AddSalePage> createState() => _AddSalePageState();
}

class _AddSalePageState extends ConsumerState<AddSalePage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  // Manual override of the total amount (e.g. haggled price). When null the
  // total is auto-calculated from items minus global discount.
  final TextEditingController _totalController = TextEditingController();
  bool _isManualTotal = false;
  double? _lastAutoTotal;
  // Persistent per-product text controllers so edits survive rebuilds.
  final Map<dynamic, TextEditingController> _priceControllers = {};
  final Map<dynamic, TextEditingController> _qtyControllers = {};
  DateTime _selectedDate = DateTime.now();
  String _selectedPaymentType = 'Cash';
  bool _isWholesale = false; // initialized in initState from shopConfig
  bool get _isEditing => widget.existingSale != null;

  static const String _addNewCustomerValue = '__add_new_customer__';
  static const String _addNewPaymentValue = '__add_new_payment__';

  // Customers loaded from backend: [{id, name}]; null id = Walk-in
  List<Map<String, dynamic>> _customers = [
    {'id': null, 'name': 'Walk-in'},
  ];
  // The selected customer_id (null = Walk-in)
  String? _selectedCustomerId;

  final List<String> _paymentTypes = [
    'Cash',
    'Mobile Money',
    'Bank Transfer',
    'Credit',
  ];
  // name → account_id from the shop's real payment accounts (same list as web).
  final Map<String, String> _paymentIds = {};

  Future<void> _loadPaymentModes() async {
    try {
      final res = await ref.read(apiServiceProvider).getPaymentMode();
      final body = res.data;
      final list = body is List ? body : (body is Map ? (body['data'] ?? []) : []);
      final names = <String>[];
      final ids = <String, String>{};
      for (final e in (list as List).whereType<Map>()) {
        final name = (e['name'] ?? e['account_name'] ?? '').toString();
        final id = (e['account_id'] ?? '').toString();
        if (name.isEmpty || id.isEmpty || ids.containsKey(name)) continue;
        names.add(name);
        ids[name] = id;
      }
      if (!mounted || names.isEmpty) return;
      setState(() {
        _paymentTypes
          ..clear()
          ..addAll(names);
        _paymentIds
          ..clear()
          ..addAll(ids);
        if (!_paymentTypes.contains(_selectedPaymentType)) {
          _selectedPaymentType = _paymentTypes.firstWhere(
            (n) => n.toLowerCase() == 'cash',
            orElse: () => _paymentTypes.first,
          );
        }
      });
    } catch (e) {
      debugPrint('[AddSale] payment modes failed: $e');
    }
  }

  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    _items = [];
    _isWholesale = ref.read(shopConfigProvider).valueOrNull?.useWholesalePrice ?? false;
    if (_isEditing) {
      _loadExistingSale();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure stock is loaded so the product picker has data even when the
      // user navigates to AddSalePage without visiting the stock page first.
      ref.read(stockProvider);
      _loadCustomers();
      _loadPaymentModes();
    });
  }

  Future<void> _loadCustomers() async {
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getCustomers();
      final raw = res.data;
      final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? raw['customers'] ?? []) : []);
      if (!mounted) return;
      setState(() {
        _customers = [{'id': null, 'name': 'Walk-in'}];
        for (final c in list) {
          if (c is Map) {
            final id = (c['customer_id'] ?? c['id'])?.toString();
            final name = (c['customer_name'] ?? c['name'] ?? '').toString();
            if (id != null && name.isNotEmpty) {
              _customers.add({'id': id, 'name': name});
            }
          }
        }
      });
    } catch (_) {}
  }

  void _loadExistingSale() {
    final sale = widget.existingSale!;
    final dateStr = sale['date'] as String;
    final parts = dateStr.split(' ');
    try {
      _selectedDate = DateFormat('MMM dd, yyyy').parse(
        '${parts[0]} ${parts[1]} ${parts[2]}',
      );
    } catch (_) {
      _selectedDate = DateTime.now();
    }
    // customer name from existing sale — we don't have the ID, leave as walk-in
    // customer will be re-selectable when editing
    final paymentMethod = sale['paymentMethod'] as String? ?? 'Cash';
    if (_paymentTypes.contains(paymentMethod)) {
      _selectedPaymentType = paymentMethod;
    }
    final discount = sale['discount'] as double? ?? 0.0;
    if (discount > 0) {
      _discountController.text = discount.toStringAsFixed(0);
    }
    final products = List<Map<String, dynamic>>.from(sale['products'] ?? []);
    _items = products.map((p) {
      return {
        'name': p['name'],
        'sellingPrice': double.tryParse(p['price']?.toString() ?? '') ?? 0.0,
        'quantity': (num.tryParse(p['quantity']?.toString() ?? '') ?? 1).toInt(),
        'stock': (num.tryParse(p['quantity']?.toString() ?? '') ?? 1).toInt() + 10,
        // Was `(x ?? 0.0) is double ? x : …`, which returned null when discount was missing.
        'discount': double.tryParse(p['discount']?.toString() ?? '') ?? 0.0,
        'product_id': p['product_id'] ?? 0,
        'stock_id': p['stock_id'] ?? '',
      };
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    _totalController.dispose();
    for (final c in _priceControllers.values) {
      c.dispose();
    }
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  ShopConfig get _cfg => ref.read(shopConfigProvider).valueOrNull ?? ShopConfig.defaults;

  double get _totalAmount {
    double total = 0;
    for (final item in _items) {
      total += _lineTotal(item) - _lineDiscount(item);
    }
    return total < 0 ? 0 : total;
  }

  int get _totalQuantity {
    int qty = 0;
    for (final item in _items) {
      qty += item['quantity'] as int;
    }
    return qty;
  }

  /// Total of all discounts on this sale: global footer discount + each
  /// product's own discount.
  double get _totalDiscount {
    double total = _globalDiscount;
    for (final item in _items) {
      total += _lineDiscount(item);
    }
    return total;
  }

  double get _globalDiscount {
    final value = double.tryParse(
      _discountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    ) ?? 0;
    return _clamp(value, 0, _totalAmount);
  }

  double get _finalAmount => _totalAmount - _globalDiscount;

  /// Amount actually charged: manual override when the user edited the total
  /// field, otherwise the auto-calculated total.
  double get _effectiveTotal {
    if (_isManualTotal) {
      final parsed = double.tryParse(
        _totalController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      );
      if (parsed != null) return parsed < 0 ? 0 : parsed;
    }
    return _finalAmount;
  }

  /// Products matching the current search query (name or barcode).
  List<Map<String, dynamic>> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _cachedAllProducts;
    return _cachedAllProducts.where((p) {
      final name = (p['name']?.toString() ?? '').toLowerCase();
      final barcode = (p['barcode']?.toString() ?? '').toLowerCase();
      return name.contains(query) || barcode.contains(query);
    }).toList();
  }

  String _formatCurrency(double amount) {
    return 'Tsh ${_formatAmount(amount)}';
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,###').format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // ---------------------------------------------------------------------------
  // Pricing / discount helpers
  // ---------------------------------------------------------------------------

  double _clamp(double value, double min, double max) =>
      value < min ? min : (value > max ? max : value);

  int _cartIndex(dynamic productId) =>
      _items.indexWhere((item) => item['product_id'] == productId);

  /// Unit price of a cart item under the current retail/wholesale mode.
  double _itemPrice(Map<String, dynamic> item) {
    if (_isWholesale) {
      return (item['wholesalePrice'] as double?) ??
          (item['sellingPrice'] as double?) ??
          0;
    }
    return item['sellingPrice'] as double? ?? 0;
  }

  double _lineTotal(Map<String, dynamic> item) =>
      _itemPrice(item) * (((item['quantity'] as num?) ?? 1).toInt());

  /// A product's own discount, never allowed to exceed its line total.
  double _lineDiscount(Map<String, dynamic> item) => _clamp(
        ((item['discount'] as num?)?.toDouble()) ?? 0,
        0,
        _lineTotal(item),
      );

  void _clampItemDiscount(int index) {
    if (index < 0 || index >= _items.length) return;
    final lineTotal = _lineTotal(_items[index]);
    final discount = ((_items[index]['discount'] as num?)?.toDouble()) ?? 0;
    _items[index]['discount'] = _clamp(discount, 0, lineTotal);
  }

  /// Price shown in a product's price field: the cart price when the product
  /// is in the cart, otherwise the catalog default for the active mode.
  double? _displayPrice(Map<String, dynamic> product) {
    final idx = _cartIndex(product['product_id']);
    if (idx >= 0) return _itemPrice(_items[idx]);
    if (_isWholesale) {
      return (product['wholesalePrice'] as double?) ??
          (product['sellingPrice'] as double?);
    }
    return product['sellingPrice'] as double?;
  }

  TextEditingController _priceControllerFor(Map<String, dynamic> product) {
    final id = product['product_id'];
    final existing = _priceControllers[id];
    if (existing != null) return existing;
    final controller = TextEditingController(
      text: _displayPrice(product)?.toStringAsFixed(0) ?? '0',
    );
    _priceControllers[id] = controller;
    return controller;
  }

  TextEditingController _qtyControllerFor(Map<String, dynamic> product) {
    final id = product['product_id'];
    final existing = _qtyControllers[id];
    if (existing != null) return existing;
    final idx = _cartIndex(id);
    final controller = TextEditingController(
      text: idx >= 0 ? '${_items[idx]['quantity']}' : '0',
    );
    _qtyControllers[id] = controller;
    return controller;
  }

  /// Keep the qty field in sync when the cart changes via +/- buttons.
  void _syncQtyController(dynamic productId) {
    final controller = _qtyControllers[productId];
    if (controller == null) return;
    final idx = _cartIndex(productId);
    final text = idx >= 0 ? '${_items[idx]['quantity']}' : '0';
    if (controller.text != text) controller.text = text;
  }

  /// Re-point every price field at the right price after the wholesale
  /// toggle flips (cart price if in cart, catalog default otherwise).
  void _syncPriceControllersWithMode() {
    for (final entry in _priceControllers.entries) {
      double? price;
      final idx = _cartIndex(entry.key);
      if (idx >= 0) {
        price = _itemPrice(_items[idx]);
      } else {
        for (final p in _cachedAllProducts) {
          if (p['product_id'] == entry.key) {
            price = _isWholesale
                ? ((p['wholesalePrice'] as double?) ??
                    (p['sellingPrice'] as double?))
                : (p['sellingPrice'] as double?);
            break;
          }
        }
      }
      if (price != null) {
        final text = price.toStringAsFixed(0);
        if (entry.value.text != text) entry.value.text = text;
      }
    }
  }

  /// Apply an edited unit price to the product under the active mode,
  /// adding the product to the cart first if needed.
  void _setUnitPrice(Map<String, dynamic> product, double price) {
    var idx = _cartIndex(product['product_id']);
    if (idx < 0) {
      _addToCart(product);
      idx = _cartIndex(product['product_id']);
    }
    if (idx >= 0) {
      if (_isWholesale) {
        _items[idx]['wholesalePrice'] = price;
      } else {
        _items[idx]['sellingPrice'] = price;
      }
      _clampItemDiscount(idx);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textWhite,
              surface: AppColors.card,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _openBarcodeScanner() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const BarcodeScannerScreen(),
      ),
    );
    if (result == null || result.isEmpty || !mounted) return;
    final code = result.trim();
    // Exact barcode match → add straight to the cart; otherwise fall back to
    // using the scanned code as a search query.
    final matches = _cachedAllProducts.where(
      (p) => (p['barcode']?.toString() ?? '').trim() == code,
    );
    if (matches.isNotEmpty) {
      final product = matches.first;
      final stock = (product['stock'] as num?)?.toInt() ?? 0;
      if (stock <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${product['name']} is out of stock'),
          backgroundColor: AppColors.danger,
        ));
        return;
      }
      _addToCart(product);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Added ${product['name']}'),
        backgroundColor: AppColors.success,
      ));
    } else {
      setState(() => _searchController.text = code);
    }
  }

  void _addToCart(Map<String, dynamic> product, {double? price}) {
    final existingIndex = _cartIndex(product['product_id']);
    if (existingIndex >= 0) {
      final currentQty = (_items[existingIndex]['quantity'] as num?)?.toInt() ?? 0;
      final maxStock = (_items[existingIndex]['stock'] as num?)?.toInt() ?? 0;
      if (currentQty < maxStock) {
        setState(() {
          _items[existingIndex]['quantity'] = currentQty + 1;
          _clampItemDiscount(existingIndex);
        });
      }
    } else {
      final catalogSelling = (product['sellingPrice'] as num?)?.toDouble() ?? 0;
      final catalogWholesale =
          (product['wholesalePrice'] as num?)?.toDouble() ?? catalogSelling;
      setState(() {
        _items.add({
          'product_id': product['product_id'],
          'stock_id': product['stock_id'],
          'name': product['name'],
          // `price` (when given) applies to the mode the user is editing in.
          'sellingPrice':
              (!_isWholesale && price != null) ? price : catalogSelling,
          'wholesalePrice':
              (_isWholesale && price != null) ? price : catalogWholesale,
          'quantity': 1,
          'stock': product['stock'],
          'discount': 0.0,
        });
      });
    }
    _syncQtyController(product['product_id']);
  }

  void _removeFromCart(Map<String, dynamic> product) {
    final existingIndex = _cartIndex(product['product_id']);
    if (existingIndex >= 0) {
      final currentQty = (_items[existingIndex]['quantity'] as num?)?.toInt() ?? 1;
      if (currentQty <= 1) {
        setState(() {
          _items.removeAt(existingIndex);
        });
      } else {
        setState(() {
          _items[existingIndex]['quantity'] = currentQty - 1;
          _clampItemDiscount(existingIndex);
        });
      }
    }
    _syncQtyController(product['product_id']);
  }

  void _showAddNewCustomerSheet() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const AddCustomerPage(),
      ),
    );
    if (result != null && mounted) {
      // Reload customers to get the newly added one with its real ID
      await _loadCustomers();
    }
  }

  void _showAddNewPaymentSheet() {
    final s = ref.read(stringsProvider);
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.paddingLG),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  s.addNewPaymentMode,
                  style: AppTypography.h6.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: AppTypography.bodyMedium,
                  cursorColor: AppColors.primary,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: s.enterPaymentModeName,
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textHint,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.textFieldRadius,
                      ),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.textFieldRadius,
                      ),
                      borderSide: const BorderSide(
                        color: AppColors.inputFocusBorder,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusMD,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final name = controller.text.trim();
                          if (name.isNotEmpty) {
                            setState(() {
                              _paymentTypes.add(name);
                              _selectedPaymentType = name;
                            });
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textWhite,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusMD,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          s.addPaymentMode,
                          style: AppTypography.buttonMedium.copyWith(
                            color: AppColors.textWhite,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isSaving = false;

  Future<void> _saveSale() async {
    final s = ref.read(stringsProvider);
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      // Build items in pipe format: product_id|stock_id|qty|price|discount|subtotal|vat|total
      // subtotal = gross (price * qty), NOT net. PHP's configuredVatTotals subtracts
      // discount from subtotal itself — sending net here would cause double deduction.
      final itemStrings = _items.map((item) {
        final productId = item['product_id'] ?? 0;
        final stockId = item['stock_id'] ?? '';
        final qty = item['quantity'] ?? 1;
        final price = _itemPrice(item);           // respects retail/wholesale toggle
        final discount = _lineDiscount(item);     // clamped to the line total
        final subtotal = price * qty;             // gross, before discount
        final net = subtotal - discount;          // net, after discount
        return '$productId|$stockId|$qty|$price|$discount|$subtotal|0|$net';
      }).toList();

      // Use explicit bracket notation so PHP reads items[] as an array.
      // Dio's default form-urlencoded encoding of a List may not produce
      // the PHP-compatible items[0]=...&items[1]=... format.
      final body = <String, dynamic>{
        for (int i = 0; i < itemStrings.length; i++) 'items[$i]': itemStrings[i],
        'payment_mode': _paymentIds[_selectedPaymentType] ?? _selectedPaymentType,
        'customer_id': _selectedCustomerId ?? '',
        // total_amount = amount shown to user (items net - global discount,
        // or the manually edited total when overridden).
        'total_amount': _effectiveTotal,
        'paid_amount': _selectedPaymentType.toLowerCase() == 'credit' ? 0 : _effectiveTotal,
        'discount': _globalDiscount,
        'date': _selectedDate.toIso8601String().split('T')[0],
        'sale_type': _selectedPaymentType.toLowerCase() == 'credit' ? 'sale' : 'cashsale',
      };

      if (_isEditing) {
        body['sale_id'] = widget.existingSale!['sale_id'] ?? '';
      }

      final repo = ref.read(salesRepositoryProvider);
      final res = _isEditing ? await repo.updateSale(body) : await repo.addSale(body);
      final ok = res['status']?.toString() == '1' ||
          res['status'] == true ||
          res['status']?.toString() == 'success';

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? (_isEditing ? s.saleUpdatedSuccessfully : s.saleSavedSuccessfully)
            : (res['message']?.toString() ?? s.failedToSaveSale)),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
      ));
      if (ok) {
        // Refresh sales list and stock so real-time data shows immediately
        ref.read(salesProvider.notifier).refresh();
        ref.read(stockProvider.notifier).refresh();
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Resolved product list cached in build() so the picker always has fresh data.
  List<Map<String, dynamic>> _cachedAllProducts = [];

  @override
  Widget build(BuildContext context) {
    // Watch strings so this page rebuilds when localized strings change
    // (sub-builders read them via ref.read).
    ref.watch(stringsProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Watch stockProvider in the proper build context so Riverpod can rebuild
    // this widget when data arrives, and the picker never sees an empty list.
    _cachedAllProducts = ref.watch(stockProvider).maybeWhen(
          data: (state) => state.products
              .map((p) => {
                    'product_id': p.productId,
                    'stock_id': p.stockId,
                    'name': p.name,
                    'sellingPrice': p.sellingPrice,
                    'wholesalePrice': p.wholesalePrice,
                    // Services have available=0 in DB but are always sellable.
                    'stock': p.type == 'service' ? 9999 : p.available.toInt(),
                    'type': p.type ?? 'product',
                    'barcode': p.barcode ?? '',
                    'unit': p.unit ?? '',
                  })
              .toList(),
          orElse: () => _cachedAllProducts, // keep previous list while reloading
        );

    // Keep the total field in sync with the cart. When items/discount change
    // the auto total changes too, which clears any manual override.
    final autoTotal = _finalAmount;
    if (_lastAutoTotal != autoTotal) {
      _lastAutoTotal = autoTotal;
      _isManualTotal = false;
      _totalController.text = _formatAmount(autoTotal);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Date', style: AppTypography.caption.copyWith(fontSize: 10)),
                              const SizedBox(height: 2),
                              _buildDateField(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Customer', style: AppTypography.caption.copyWith(fontSize: 10)),
                              const SizedBox(height: 2),
                              _buildCustomerDropdown(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    _buildItemsHeader(),
                    const SizedBox(height: 6),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildItemsList(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(AppConstants.paddingLG, 6, AppConstants.paddingLG, 6 + bottomPadding),
              decoration: const BoxDecoration(
                color: AppColors.card,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Payment Type', style: AppTypography.caption.copyWith(fontSize: 10)),
                            const SizedBox(height: 2),
                            _buildPaymentTypeDropdown(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Discount', style: AppTypography.caption.copyWith(fontSize: 10)),
                            const SizedBox(height: 2),
                            _buildDiscountField(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTotalSection(),
                  const SizedBox(height: 8),
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final s = ref.read(stringsProvider);
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
            _isEditing ? s.editSale : s.addSale,
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            ref.watch(authProvider).activeShop?.shopName ?? 'My Shop',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.wholesale,
                style: AppTypography.caption.copyWith(
                  color: _isWholesale
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 4),
              Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: _isWholesale,
                  onChanged: (value) {
                    setState(() {
                      _isWholesale = value;
                      // Prices are stored per mode, so re-point every price
                      // field (and keep the totals) once the mode flips.
                      _syncPriceControllersWithMode();
                    });
                  },
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                  activeThumbColor: AppColors.primary,
                  inactiveTrackColor: AppColors.border,
                  inactiveThumbColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
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
            const Icon(
              Icons.calendar_today_rounded,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _formatDate(_selectedDate),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDropdown() {
    // Value is customer_id string (null = Walk-in, sentinel = add new)
    final dropdownValue = _selectedCustomerId; // null = Walk-in selected
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: dropdownValue,
          isExpanded: true,
          hint: Text(
            'Walk-in',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textHint, size: 20),
          style: AppTypography.bodyMedium,
          items: [
            ..._customers.map((c) => DropdownMenuItem<String>(
                  value: c['id'] as String?,
                  child: Text(
                    c['name'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
            DropdownMenuItem<String>(
              value: _addNewCustomerValue,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Flexible(
                    child: Text(
                  'Add Customer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w600),
                )),
              ]),
            ),
          ],
          onChanged: (value) {
            if (value == _addNewCustomerValue) {
              _showAddNewCustomerSheet();
            } else {
              setState(() => _selectedCustomerId = value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final s = ref.read(stringsProvider);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
        vertical: 4,
      ),
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
          const Icon(
            Icons.search_rounded,
            color: AppColors.textHint,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: AppTypography.bodyMedium,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: s.searchItemsScanBarcode,
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textHint,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() => _searchController.clear()),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.textHint,
                  size: 18,
                ),
              ),
            ),
          const SizedBox(width: 6),
          if (_cfg.enableBarcodeScanner)
            GestureDetector(
              onTap: _openBarcodeScanner,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemsHeader() {
    final query = _searchController.text.trim();
    return Row(
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
            '${_filteredProducts.length}',
            style: AppTypography.captionBold.copyWith(
              color: AppColors.primary,
              fontSize: 11,
            ),
          ),
        ),
        if (query.isNotEmpty && _filteredProducts.length != _cachedAllProducts.length)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              'of ${_cachedAllProducts.length}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textHint,
                fontSize: 10,
              ),
            ),
          ),
        const Spacer(),
        if (query.isNotEmpty)
          Text(
            'Search: "$query"',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildStockBadge(Map<String, dynamic> product) {
    final isService = product['type'] == 'service';
    final stock = (product['stock'] as num?)?.toInt() ?? 0;
    final unit = product['unit']?.toString() ?? '';

    Color color;
    String text;
    if (isService) {
      color = AppColors.primary;
      text = 'Service';
    } else if (stock <= 0) {
      color = AppColors.danger;
      text = 'Out of stock';
    } else {
      color = AppColors.success;
      text = 'Qty: $stock${unit.isNotEmpty ? ' $unit' : ''}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: AppTypography.captionBold.copyWith(fontSize: 10, color: color),
      ),
    );
  }

  Widget _buildItemsList() {
    final products = _filteredProducts;
    if (products.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 32, color: AppColors.textHint),
            const SizedBox(height: 8),
            Text(
              'No products match your search',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return Column(
      children: List.generate(products.length, (index) {
        final product = products[index];
        final existing = _items.firstWhere(
          (it) => it['product_id'] == product['product_id'],
          orElse: () => <String, dynamic>{},
        );
        final qty = existing.isEmpty ? 0 : ((existing['quantity'] as num?)?.toInt() ?? 0);
        final stock = (product['stock'] as num?)?.toInt() ?? 0;
        final outOfStock = stock <= 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product['name']?.toString() ?? '',
                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStockBadge(product),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _isWholesale ? 'WP: ' : 'SP: ',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      height: 24,
                      child: TextField(
                        controller: _priceControllerFor(product),
                        textAlign: TextAlign.left,
                        keyboardType: TextInputType.number,
                        style: AppTypography.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          final parsed = double.tryParse(
                            value.replaceAll(RegExp(r'[^0-9.]'), ''),
                          );
                          if (parsed == null) return;
                          setState(() => _setUnitPrice(product, parsed));
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Line total for the current qty, so the effect of price
                    // and discount edits is immediately visible.
                    if (qty > 0)
                      Text(
                        _formatCurrency(
                          _lineTotal(existing) - _lineDiscount(existing),
                        ),
                        style: AppTypography.captionBold.copyWith(
                          fontSize: 10,
                          color: AppColors.textPrimary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: qty > 0 ? () => _removeFromCart(product) : null,
                    ),
                    SizedBox(
                      width: 48,
                      height: 32,
                      child: TextField(
                        controller: _qtyControllerFor(product),
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: AppTypography.bodyMedium,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          final parsed = int.tryParse(
                            value.replaceAll(RegExp(r'[^0-9]'), ''),
                          );
                          var idx = _cartIndex(product['product_id']);
                          if (parsed == null || parsed <= 0) {
                            // Cleared / zero → take it out of the cart.
                            if (idx >= 0) {
                              setState(() => _items.removeAt(idx));
                            }
                          } else {
                            // Clamp to available stock.
                            final q = parsed > stock ? stock : parsed;
                            if (idx < 0) {
                              _addToCart(product);
                              idx = _cartIndex(product['product_id']);
                            }
                            if (idx >= 0) {
                              setState(() {
                                _items[idx]['quantity'] = q;
                                _clampItemDiscount(idx);
                              });
                            }
                          }
                          _syncQtyController(product['product_id']);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                      onPressed: outOfStock ? null : () => _addToCart(product),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        // Discounting implies selling: add to the cart first
                        // when the product isn't in it yet.
                        var idx = _cartIndex(product['product_id']);
                        if (idx < 0) {
                          _addToCart(product);
                          idx = _cartIndex(product['product_id']);
                        }
                        if (idx >= 0) _showDiscountDialog(idx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (existing.isNotEmpty ? _lineDiscount(existing) : 0) > 0
                              ? AppColors.dangerLight.withValues(alpha: 0.5)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: (existing.isNotEmpty ? _lineDiscount(existing) : 0) > 0
                                ? AppColors.danger.withValues(alpha: 0.3)
                                : AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.discount_rounded,
                              size: 12,
                              color: (existing.isNotEmpty ? _lineDiscount(existing) : 0) > 0
                                  ? AppColors.danger
                                  : AppColors.textHint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (existing.isNotEmpty ? _lineDiscount(existing) : 0) > 0
                                  ? '-${_formatAmount(_lineDiscount(existing))}'
                                  : 'Discount',
                              style: AppTypography.caption.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: (existing.isNotEmpty ? _lineDiscount(existing) : 0) > 0
                                    ? AppColors.danger
                                    : AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _showDiscountDialog(int index) {
    final item = _items[index];
    final lineTotal = _lineTotal(item);
    final current = _lineDiscount(item);
    final controller = TextEditingController(
      text: current > 0 ? current.toStringAsFixed(0) : '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Discount — ${item['name'] ?? 'Product'}',
          style: AppTypography.bodyMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Amount',
                prefixText: 'Tsh ',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Line total: ${_formatCurrency(lineTotal)}. '
              'Discount cannot exceed it (0 removes the discount).',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final v = double.tryParse(
                    controller.text.replaceAll(RegExp(r'[^0-9]'), ''),
                  ) ??
                  0;
              setState(() {
                // Clamp so a line can never go negative, e.g. after the
                // quantity or price was reduced below the discount.
                _items[index]['discount'] = _clamp(v, 0, lineTotal);
              });
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeDropdown() {
    final s = ref.read(stringsProvider);
    final allOptions = [..._paymentTypes, _addNewPaymentValue];
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          // initialValue is read once; rebuild the field when the list loads.
          key: ValueKey('payment-${_paymentTypes.join('|')}'),
          value: _selectedPaymentType,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textHint,
            size: 20,
          ),
          style: AppTypography.bodyMedium,
          items: allOptions.map((type) {
            if (type == _addNewPaymentValue) {
              return DropdownMenuItem(
                value: type,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        s.addNewPaymentMode,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }
            return DropdownMenuItem(
              value: type,
              child: Text(
                type,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == _addNewPaymentValue) {
              _showAddNewPaymentSheet();
            } else {
              setState(() => _selectedPaymentType = value ?? 'Cash');
            }
          },
        ),
      ),
    );
  }

  /// Big, prominent and editable total amount. Editing it overrides the
  /// auto-calculated total (useful for haggled prices); any change to the
  /// cart or discount resets it back to auto.
  Widget _buildTotalSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TOTAL AMOUNT',
                  style: AppTypography.captionBold.copyWith(
                    color: AppColors.primary,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
                TextField(
                  controller: _totalController,
                  keyboardType: TextInputType.number,
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontSize: 26,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 2),
                    prefixText: 'Tsh ',
                    prefixStyle: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontSize: 20,
                    ),
                  ),
                  onChanged: (_) {
                    _isManualTotal = true;
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_items.length} items • $_totalQuantity qty',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
              if (_totalDiscount > 0)
                Text(
                  'Discount: -${_formatCurrency(_totalDiscount)}',
                  style: AppTypography.captionBold.copyWith(
                    color: AppColors.danger,
                    fontSize: 10,
                  ),
                ),
              if (_isManualTotal)
                GestureDetector(
                  onTap: () => setState(() {
                    _isManualTotal = false;
                    _totalController.text = _formatAmount(_finalAmount);
                  }),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.refresh_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Auto: ${_formatCurrency(_finalAmount)}',
                        style: AppTypography.captionBold.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountField() {
    return TextField(
      controller: _discountController,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.left,
      style: AppTypography.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Tsh 0',
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
        prefixText: 'Tsh ',
        prefixStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
          borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.danger, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              'CANCEL',
              style: AppTypography.buttonMedium.copyWith(
                color: AppColors.danger,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveSale,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textWhite,
                    ),
                  )
                : Text(
                    _isEditing ? 'UPDATE' : 'SAVE',
                    style: AppTypography.buttonMedium.copyWith(
                      color: AppColors.textWhite,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
