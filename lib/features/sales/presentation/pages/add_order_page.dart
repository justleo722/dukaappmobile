import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dukaapp/app/app.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dukaapp/features/customers/presentation/pages/add_customer_page.dart';
import 'package:dukaapp/features/sales/presentation/providers/sales_provider.dart';
import 'package:dukaapp/features/sales/presentation/widgets/sale_product_catalog.dart';
import 'package:dukaapp/features/stock/presentation/pages/barcode_scanner_screen.dart';
import 'package:dukaapp/features/stock/presentation/providers/stock_provider.dart';

class AddOrderPage extends ConsumerStatefulWidget {
  const AddOrderPage({super.key});

  @override
  ConsumerState<AddOrderPage> createState() => _AddOrderPageState();
}

class _AddOrderPageState extends ConsumerState<AddOrderPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedCustomerId;
  bool _isWholesale = false;
  bool _isSaving = false;

  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _cachedAllProducts = [];

  static const String _addNewCustomerValue = '__add_new_customer__';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomers();
      _loadProducts();
    });
  }

  Future<void> _loadProducts() async {
    try {
      final ds = ref.read(stockRemoteDatasourceProvider);
      // Always fetch unfiltered — ignore any active date range so all products appear.
      final products = await ds.fetchStock();
      if (!mounted) return;
      setState(() {
        _cachedAllProducts = products
            .map(
              (p) => {
                'product_id': p.productId,
                'stock_id': p.stockId,
                'name': p.name,
                'sellingPrice': p.sellingPrice,
                'wholesalePrice': p.wholesalePrice,
                'stock': p.type == 'service' ? 9999 : p.available.toInt(),
                'type': p.type ?? 'product',
                'unit': p.unit ?? '',
                'barcode': p.barcode ?? '',
              },
            )
            .toList();
      });
    } catch (_) {
      // Fallback: use whatever stockProvider already has
      final current = ref.read(stockProvider);
      if (current is AsyncData && mounted) {
        setState(() {
          _cachedAllProducts = current.value!.products
              .map(
                (p) => {
                  'product_id': p.productId,
                  'stock_id': p.stockId,
                  'name': p.name,
                  'sellingPrice': p.sellingPrice,
                  'wholesalePrice': p.wholesalePrice,
                  'stock': p.type == 'service' ? 9999 : p.available.toInt(),
                  'type': p.type ?? 'product',
                },
              )
              .toList();
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getCustomers();
      final raw = res.data;
      final list = raw is List
          ? raw
          : (raw is Map ? (raw['data'] ?? raw['result'] ?? []) : []);
      if (!mounted) return;
      setState(() {
        _customers = [
          {'id': null, 'name': 'Walk-in'},
          ...list.map<Map<String, dynamic>>((c) {
            final id =
                c['customer_id']?.toString() ??
                c['id']?.toString() ??
                c['customerId']?.toString();
            final name =
                c['customer_name']?.toString() ??
                c['name']?.toString() ??
                c['fullname']?.toString() ??
                'Unknown';
            return {'id': id, 'name': name};
          }),
        ];
      });
    } catch (_) {
      if (mounted)
        setState(
          () => _customers = [
            {'id': null, 'name': 'Walk-in'},
          ],
        );
    }
  }

  double get _globalDiscount {
    final v = double.tryParse(_discountController.text) ?? 0;
    return v < 0 ? 0 : v;
  }

  double get _totalAmount => _items.fold(0.0, (sum, item) {
    final price = _isWholesale
        ? (item['wholesalePrice'] as double? ??
              item['sellingPrice'] as double? ??
              0.0)
        : (item['sellingPrice'] as double? ?? 0.0);
    final qty = (item['quantity'] as num?)?.toInt() ?? 1;
    final disc = item['discount'] as double? ?? 0.0;
    return sum + (price * qty) - disc;
  });

  double get _finalAmount => _totalAmount - _globalDiscount;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // Scanned products, newest last; they are listed first so they're visible.
  final List<String> _pinnedIds = [];

  /// Scan: an exact barcode match adds one of that product (or one more) and
  /// moves it to the top; anything else becomes the search text.
  Future<void> _scanBarcode() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const BarcodeScannerScreen()),
    );
    final code = result?.trim() ?? '';
    if (code.isEmpty || !mounted) return;
    final product = catalogFindByBarcode(_cachedAllProducts, code);
    if (product == null) {
      setState(() => _searchController.text = code);
      return;
    }
    final added = catalogAddToCart(_items, product, limitToStock: true);
    final id = catalogProductId(product);
    setState(() {
      _searchController.clear();
      _pinnedIds
        ..remove(id)
        ..add(id);
    });
    showAppToast(
      added ? 'Added ${product['name']}' : '${product['name']} is out of stock',
      isError: !added,
    );
  }

  /// Products matching the search (name or barcode).
  List<Map<String, dynamic>> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _cachedAllProducts;
    return _cachedAllProducts.where((p) {
      final name = (p['name']?.toString() ?? '').toLowerCase();
      final barcode = (p['barcode']?.toString() ?? '').toLowerCase();
      return name.contains(query) || barcode.contains(query);
    }).toList();
  }

  Future<void> _saveOrder() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add at least one item')));
      return;
    }
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final itemStrings = _items.map((item) {
        final productId = item['product_id'] ?? 0;
        final stockId = item['stock_id'] ?? '';
        final qty = item['quantity'] ?? 1;
        final price = _isWholesale
            ? (item['wholesalePrice'] as double? ??
                  item['sellingPrice'] as double? ??
                  0.0)
            : (item['sellingPrice'] as double? ?? 0.0);
        final discount = item['discount'] ?? 0.0;
        final subtotal = price * qty;
        final net = subtotal - discount;
        return '$productId|$stockId|$qty|$price|$discount|$subtotal|0|$net';
      }).toList();

      final body = <String, dynamic>{
        for (int i = 0; i < itemStrings.length; i++)
          'items[$i]': itemStrings[i],
        'payment_mode': 'credit',
        'customer_id': _selectedCustomerId ?? '',
        'total_amount': _finalAmount,
        'paid_amount': 0,
        'discount': _globalDiscount,
        'date': _selectedDate.toIso8601String().split('T')[0],
        'sale_type': 'order',
      };

      final repo = ref.read(salesRepositoryProvider);
      final res = await repo.addSale(body);
      final ok =
          res['status']?.toString() == '1' ||
          res['status'] == true ||
          res['status']?.toString() == 'success';

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Order saved successfully'
                : (res['message']?.toString() ?? 'Failed to save order'),
          ),
          backgroundColor: ok ? AppColors.success : AppColors.danger,
        ),
      );
      if (ok) {
        ref.read(salesProvider.notifier).refresh();
        ref.read(stockProvider.notifier).refresh();
        context.pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // _loadProducts() fetches the full unfiltered list; only fall back to the
    // (possibly date-filtered) stockProvider while that is still empty.
    if (_cachedAllProducts.isEmpty) {
      _cachedAllProducts = ref
          .watch(stockProvider)
          .maybeWhen(
            data: (state) => state.products
                .map(
                  (p) => {
                    'product_id': p.productId,
                    'stock_id': p.stockId,
                    'name': p.name,
                    'sellingPrice': p.sellingPrice,
                    'wholesalePrice': p.wholesalePrice,
                    'stock': p.type == 'service' ? 9999 : p.available.toInt(),
                    'type': p.type ?? 'product',
                    'unit': p.unit ?? '',
                    'barcode': p.barcode ?? '',
                  },
                )
                .toList(),
            orElse: () => _cachedAllProducts,
          );
    }

    // Same layout as Add Sale: products listed inline, totals pinned below.
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingLG,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildDateField()),
                        const SizedBox(width: 10),
                        Expanded(child: _buildCustomerDropdown()),
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
                          children: [
                            SaleProductCatalog(
                              products: catalogPinFirst(_filteredProducts, _pinnedIds),
                              items: _items,
                              isWholesale: _isWholesale,
                              onChanged: () => setState(() {}),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomBar(bottomPadding),
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
            'New Order',
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            ref.watch(authProvider).activeShop?.shopName ?? 'My Shop',
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Wholesale',
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
                  onChanged: (v) => setState(() => _isWholesale = v),
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMD,
          vertical: 14,
        ),
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
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                DateFormat('MMM dd, yyyy').format(_selectedDate),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
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
    final dropdownValue = _selectedCustomerId;
    final validValue = _customers.any((c) => c['id'] == dropdownValue)
        ? dropdownValue
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validValue,
          isExpanded: true,
          hint: Text(
            'Select Customer (required)',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
          ),
          items: [
            ..._customers.map(
              (c) => DropdownMenuItem<String>(
                value: c['id']?.toString(),
                child: Text(
                  c['name'] as String,
                  style: AppTypography.bodyMedium,
                ),
              ),
            ),
            DropdownMenuItem<String>(
              value: _addNewCustomerValue,
              child: Row(
                children: [
                  const Icon(
                    Icons.add_circle_outline_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add New Customer',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (value) async {
            if (value == _addNewCustomerValue) {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddCustomerPage()),
              );
              await _loadCustomers();
              return;
            }
            setState(() => _selectedCustomerId = value);
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: AppTypography.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Search product or scan barcode',
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
                      onTap: _scanBarcode,
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
                borderRadius: BorderRadius.circular(
                  AppConstants.textFieldRadius,
                ),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsHeader() {
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
        const Spacer(),
        if (_items.isNotEmpty)
          Text(
            '${_items.length} item${_items.length == 1 ? '' : 's'} selected',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: bold ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: bold ? AppColors.primary : AppColors.textPrimary,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(double bottomPadding) {
    final fmt = NumberFormat('#,###');
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppConstants.paddingLG,
        8,
        AppConstants.paddingLG,
        8 + bottomPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Discount',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  onChanged: (_) => setState(() {}),
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    isDense: true,
                    prefixText: 'Tsh ',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _summaryRow(
            'Total (${_items.length} items)',
            'Tsh ${fmt.format(_finalAmount)}',
            bold: true,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusLG,
                      ),
                    ),
                    minimumSize: Size(
                      double.infinity,
                      AppConstants.buttonHeight,
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: AppTypography.buttonLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: (_items.isNotEmpty && !_isSaving)
                      ? _saveOrder
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.5,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusLG,
                      ),
                    ),
                    minimumSize: Size(
                      double.infinity,
                      AppConstants.buttonHeight,
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Save Order', style: AppTypography.buttonLarge),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
