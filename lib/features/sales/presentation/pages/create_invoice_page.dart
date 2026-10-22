import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dukaapp/app/colors.dart' show AppColors;
import 'package:dukaapp/features/sales/presentation/providers/sales_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dukaapp/app/app.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/sales/presentation/widgets/sale_product_catalog.dart';
import 'package:dukaapp/features/stock/presentation/pages/barcode_scanner_screen.dart';
import 'package:dukaapp/features/customers/presentation/pages/add_customer_page.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/stock/presentation/providers/stock_provider.dart';

class CreateInvoicePage extends ConsumerStatefulWidget {
  /// Invoice map from InvoicesPage when editing; null when creating.
  final Map<String, dynamic>? existingInvoice;

  const CreateInvoicePage({super.key, this.existingInvoice});

  @override
  ConsumerState<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends ConsumerState<CreateInvoicePage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));
  String? _selectedCustomerId;   // actual ID sent to backend
  String? _selectedCustomerName; // display value shown in dropdown
  String _selectedPaymentType = 'Credit';

  static const String _addNewCustomerValue = '__add_new_customer__';
  static const String _addNewPaymentValue = '__add_new_payment__';

  // Each entry: {'id': String?, 'name': String}
  final List<Map<String, String?>> _customers = [];

  final List<String> _paymentTypes = [
    'Cash',
    'Mobile Money',
    'Bank Transfer',
    'Credit',
  ];

  final List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _prefillFromExisting();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomers();
      _loadProducts();
    });
  }

  bool get _isEditing => widget.existingInvoice != null;

  void _prefillFromExisting() {
    final inv = widget.existingInvoice;
    if (inv == null) return;
    double d(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0.0;
    final products = (inv['products'] as List?) ?? const [];
    for (final p in products.whereType<Map>()) {
      final qty = (num.tryParse(p['quantity']?.toString() ?? '') ?? 1).toInt();
      _items.add({
        'product_id': p['product_id'],
        'stock_id': p['stock_id'],
        'name': (p['name'] ?? '').toString(),
        'sellingPrice': d(p['price']),
        'quantity': qty,
        // Invoices don't deduct stock; allow at least the invoiced quantity.
        'stock': qty + 9999,
        'discount': d(p['discount']),
      });
    }
    final customerId = (inv['customer_id'] ?? '').toString();
    final customerName = (inv['customer'] ?? '').toString();
    if (customerId.isNotEmpty) {
      _selectedCustomerId = customerId;
      _selectedCustomerName = customerName;
    }
    final due = DateTime.tryParse((inv['dueDate'] ?? '').toString());
    if (due != null) _dueDate = due;
  }

  List<Map<String, dynamic>> _allProducts = [];

  // Real stock (same source as Add Order); product_id/stock_id are required by Sales::add.
  Future<void> _loadProducts() async {
    try {
      final products = await ref.read(stockRemoteDatasourceProvider).fetchStock();
      if (!mounted) return;
      setState(() {
        _allProducts = products.map((p) => <String, dynamic>{
          'product_id': p.productId,
          'stock_id': p.stockId,
          'name': p.name,
          'sellingPrice': p.sellingPrice,
          'stock': p.isService ? 9999 : p.available.toInt(),
          'type': p.type ?? 'product',
          'unit': p.unit ?? '',
          'barcode': p.barcode ?? '',
        }).toList();
      });
    } catch (e) {
      debugPrint('[CreateInvoice] load products failed: $e');
    }
  }

  Future<void> _loadCustomers() async {
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getCustomers();
      final raw = res.data;
      final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? raw['customers'] ?? []) : []);
      if (!mounted) return;
      setState(() {
        _customers.clear();
        _customers.add({'id': null, 'name': 'Walk-in'});
        for (final c in list) {
          if (c is Map) {
            final id = (c['customer_id'] ?? c['id'] ?? '').toString();
            final name = (c['customer_name'] ?? c['name'] ?? '').toString();
            if (name.isNotEmpty) {
              _customers.add({'id': id.isEmpty ? null : id, 'name': name});
            }
          }
        }
        // Editing: show the invoice's customer by the name the list uses.
        if (_selectedCustomerId != null) {
          final match = _customers.where((c) => c['id'] == _selectedCustomerId).firstOrNull;
          if (match != null) _selectedCustomerName = match['name'];
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  double get _totalAmount {
    double total = 0;
    for (final item in _items) {
      final price = item['sellingPrice'] as double;
      final qty = item['quantity'] as int;
      final disc = item['discount'] as double;
      total += (price * qty) - disc;
    }
    return total;
  }

  int get _totalQuantity {
    int qty = 0;
    for (final item in _items) {
      qty += item['quantity'] as int;
    }
    return qty;
  }

  double get _totalItemDiscount {
    double total = 0;
    for (final item in _items) {
      total += item['discount'] as double;
    }
    return total;
  }

  double get _globalDiscount {
    final value = double.tryParse(_discountController.text) ?? 0;
    return value.clamp(0, _totalAmount);
  }

  double get _finalAmount => _totalAmount - _globalDiscount;

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###');
    return 'Tsh ${formatter.format(amount)}';
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
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

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
      setState(() => _dueDate = picked);
    }
  }

  // Scanned products, newest last; they are listed first so they're visible.
  final List<String> _pinnedIds = [];

  /// Scan: an exact barcode match adds one of that product (or one more) and
  /// moves it to the top; anything else becomes the search text.
  Future<void> _openBarcodeScanner() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const BarcodeScannerScreen()),
    );
    final code = result?.trim() ?? '';
    if (code.isEmpty || !mounted) return;
    final product = catalogFindByBarcode(_allProducts, code);
    if (product == null) {
      setState(() => _searchController.text = code);
      return;
    }
    final added = catalogAddToCart(_items, product, limitToStock: false);
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
    if (query.isEmpty) return _allProducts;
    return _allProducts.where((p) {
      final name = (p['name']?.toString() ?? '').toLowerCase();
      final barcode = (p['barcode']?.toString() ?? '').toLowerCase();
      return name.contains(query) || barcode.contains(query);
    }).toList();
  }

  void _showAddNewCustomerSheet() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const AddCustomerPage(),
      ),
    );
    if (result == true && mounted) {
      await _loadCustomers();
    }
  }

  void _showAddNewPaymentSheet() {
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
                  'Add New Payment Mode',
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
                    hintText: 'Enter payment mode name',
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
                          'Add Payment Mode',
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

  Future<void> _saveInvoice() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }
    // Sales::add requires a real customer for invoices (saleTypeRequiresCustomer).
    if (_selectedCustomerName == null || _selectedCustomerId == null || _selectedCustomerId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final itemStrings = _items.map((item) {
        final productId = item['product_id'] ?? 0;
        final stockId = item['stock_id'] ?? '';
        final qty = item['quantity'] ?? 1;
        final price = item['sellingPrice'] ?? item['price'] ?? 0.0;
        final discount = item['discount'] ?? 0.0;
        // Same as add_sale_page: subtotal is gross; the server subtracts discount.
        final subtotal = price * qty;
        final net = subtotal - discount;
        return '$productId|$stockId|$qty|$price|$discount|$subtotal|0|$net';
      }).toList();

      final total = _items.fold<double>(0, (s, i) {
        final price = ((i['sellingPrice'] ?? i['price'] ?? 0.0) as num).toDouble();
        final qty = ((i['quantity'] ?? 1) as num).toDouble();
        final discount = ((i['discount'] ?? 0.0) as num).toDouble();
        return s + price * qty - discount;
      });

      // Bracket notation so PHP reads items[] as a proper array.
      final body = <String, dynamic>{
        for (int i = 0; i < itemStrings.length; i++) 'items[$i]': itemStrings[i],
        'payment_mode': 'invoice',
        'customer_id': _selectedCustomerId ?? '',
        'total_amount': total,
        'paid_amount': 0,
        'discount': 0.0,
        'sale_type': 'invoice',
        // Sales::add switches to update() when sale_id is posted.
        if (_isEditing) 'sale_id': (widget.existingInvoice!['sale_id'] ?? '').toString(),
      };

      final repo = ref.read(salesRepositoryProvider);
      final res = await repo.addSale(body);
      final ok = res['status']?.toString() == '1' || res['status'] == true || res['status']?.toString() == 'success';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? (_isEditing ? 'Invoice updated successfully' : 'Invoice created successfully') : (res['message']?.toString() ?? 'Failed')),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
      ));
      if (ok) context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildDateFields(),
                    const SizedBox(height: 8),
                    _buildCustomerDropdown(),
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
                              // Invoices don't deduct stock.
                              limitToStock: false,
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
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(AppConstants.paddingLG, 6, AppConstants.paddingLG, 6 + bottomPadding),
              decoration: const BoxDecoration(
                color: AppColors.card,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(flex: 3, child: _buildPaymentTypeDropdown()),
                      const SizedBox(width: 10),
                      Expanded(flex: 2, child: _buildDiscountField()),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_totalItemDiscount > 0)
                    _buildSummaryRow('Item Discounts', _formatCurrency(_totalItemDiscount),
                        valueColor: AppColors.danger),
                  _buildSummaryRow(
                    'Total (${_items.length} items, $_totalQuantity qty)',
                    _formatCurrency(_finalAmount),
                    isBold: true,
                    valueColor: AppColors.primary,
                  ),
                  const SizedBox(height: 6),
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
            'Create Invoice',
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
    );
  }

  Widget _buildDateFields() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invoice Date',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textHint,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          _formatDate(_selectedDate),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _pickDueDate,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMD,
                vertical: 14,
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
                    Icons.event_rounded,
                    color: AppColors.danger,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Due Date',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textHint,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          _formatDate(_dueDate),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Select Customer',
          style: AppTypography.label.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        DropdownButtonHideUnderline(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: DropdownButton<String>(
              value: _selectedCustomerName,
              isExpanded: true,
              hint: Text(
                'Select Customer',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint),
              style: AppTypography.bodyMedium,
              items: [
                ..._customers.map((c) => DropdownMenuItem<String>(
                      value: c['name'],
                      child: Text(c['name'] ?? ''),
                    )),
                DropdownMenuItem<String>(
                  value: _addNewCustomerValue,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Add New Customer',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == _addNewCustomerValue) {
                  _showAddNewCustomerSheet();
                } else {
                  final match = _customers.firstWhere(
                    (c) => c['name'] == value,
                    orElse: () => {'id': null, 'name': value},
                  );
                  setState(() {
                    _selectedCustomerName = value;
                    _selectedCustomerId = match['id'];
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
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
                hintText: 'Search Items / Scan Barcode',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textHint,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
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
            '${_items.length} selected',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10),
          ),
      ],
    );
  }

  Widget _buildPaymentTypeDropdown() {
    final allOptions = [..._paymentTypes, _addNewPaymentValue];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Payment Type',
          style: AppTypography.label.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedPaymentType,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textHint,
          ),
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
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
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.textFieldRadius,
              ),
              borderSide: const BorderSide(color: AppColors.inputBorder),
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
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Add New Payment Mode',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }
            return DropdownMenuItem(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            if (value == _addNewPaymentValue) {
              _showAddNewPaymentSheet();
            } else {
              setState(() => _selectedPaymentType = value ?? 'Credit');
            }
          },
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Discount', style: AppTypography.label.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: _discountController,
          keyboardType: TextInputType.number,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: '0',
            prefixText: 'Tsh ',
            filled: true,
            fillColor: AppColors.card,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
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
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              'CANCEL',
              style: AppTypography.buttonMedium.copyWith(
                color: AppColors.danger,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveInvoice,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              'CREATE INVOICE',
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
