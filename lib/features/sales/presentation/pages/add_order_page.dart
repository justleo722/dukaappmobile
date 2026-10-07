import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dukaapp/features/customers/presentation/pages/add_customer_page.dart';
import 'package:dukaapp/features/sales/data/repositories/sales_repository.dart';
import 'package:dukaapp/features/sales/presentation/providers/sales_provider.dart';
import 'package:dukaapp/features/sales/presentation/widgets/add_sale_item_tile.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCustomers());
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
            final id = c['customer_id']?.toString() ??
                c['id']?.toString() ??
                c['customerId']?.toString();
            final name = c['customer_name']?.toString() ??
                c['name']?.toString() ??
                c['fullname']?.toString() ??
                'Unknown';
            return {'id': id, 'name': name};
          }),
        ];
      });
    } catch (_) {
      if (mounted) setState(() => _customers = [{'id': null, 'name': 'Walk-in'}]);
    }
  }

  double get _globalDiscount {
    final v = double.tryParse(_discountController.text) ?? 0;
    return v < 0 ? 0 : v;
  }

  double get _totalAmount => _items.fold(0.0, (sum, item) {
    final price = _isWholesale
        ? (item['wholesalePrice'] as double? ?? item['sellingPrice'] as double? ?? 0.0)
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

  void _addProduct(Map<String, dynamic> product) {
    final existing = _items.indexWhere(
      (i) => i['product_id'].toString() == product['product_id'].toString(),
    );
    if (existing >= 0) {
      setState(() {
        final qty = (_items[existing]['quantity'] as num?)?.toInt() ?? 1;
        _items[existing]['quantity'] = qty + 1;
      });
    } else {
      setState(() {
        _items.add({
          'product_id': product['product_id'],
          'stock_id': product['stock_id'],
          'name': product['name'],
          'sellingPrice': product['sellingPrice'],
          'wholesalePrice': product['wholesalePrice'],
          'quantity': 1,
          'stock': product['stock'],
          'discount': 0.0,
          'type': product['type'] ?? 'product',
        });
      });
    }
    _searchController.clear();
  }

  Future<void> _saveOrder() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item')),
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
        final price = _isWholesale
            ? (item['wholesalePrice'] as double? ?? item['sellingPrice'] as double? ?? 0.0)
            : (item['sellingPrice'] as double? ?? 0.0);
        final discount = item['discount'] ?? 0.0;
        final subtotal = price * qty;
        final net = subtotal - discount;
        return '$productId|$stockId|$qty|$price|$discount|$subtotal|0|$net';
      }).toList();

      final body = <String, dynamic>{
        for (int i = 0; i < itemStrings.length; i++) 'items[$i]': itemStrings[i],
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
      final ok = res['status']?.toString() == '1' ||
          res['status'] == true ||
          res['status']?.toString() == 'success';

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Order saved successfully'
            : (res['message']?.toString() ?? 'Failed to save order')),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
      ));
      if (ok) {
        ref.read(salesProvider.notifier).refresh();
        ref.read(stockProvider.notifier).refresh();
        context.pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppColors.danger,
      ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    _cachedAllProducts = ref.watch(stockProvider).maybeWhen(
          data: (state) => state.products
              .map((p) => {
                    'product_id': p.productId,
                    'stock_id': p.stockId,
                    'name': p.name,
                    'sellingPrice': p.sellingPrice,
                    'wholesalePrice': p.wholesalePrice,
                    'stock': p.type == 'service' ? 9999 : p.available.toInt(),
                    'type': p.type ?? 'product',
                  })
              .toList(),
          orElse: () => _cachedAllProducts,
        );

    final query = _searchController.text.toLowerCase().trim();
    final filtered = query.isEmpty
        ? <Map<String, dynamic>>[]
        : _cachedAllProducts
            .where((p) => p['name'].toString().toLowerCase().contains(query))
            .take(10)
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingLG,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildDateField(),
                    const SizedBox(height: 16),
                    _buildCustomerDropdown(),
                    const SizedBox(height: 16),
                    _buildSearchBar(filtered),
                    const SizedBox(height: 16),
                    if (_items.isNotEmpty) ...[
                      _buildItemsHeader(),
                      const SizedBox(height: 8),
                      _buildItemsList(),
                      const SizedBox(height: 16),
                      _buildSummarySection(),
                      const SizedBox(height: 24),
                    ],
                    SizedBox(height: 24 + bottomPadding),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
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
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
          ),
        ),
      ),
      leadingWidth: 56,
      title: Column(
        children: [
          Text(
            'New Order',
            style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          ),
          Text(
            ref.watch(authProvider).activeShop?.shopName ?? 'My Shop',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10),
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
                  color: _isWholesale ? AppColors.primary : AppColors.textSecondary,
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
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              DateFormat('EEE, dd MMM yyyy').format(_selectedDate),
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
            ),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDropdown() {
    final dropdownValue = _selectedCustomerId;
    final validValue = _customers.any((c) => c['id'] == dropdownValue) ? dropdownValue : null;

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
          hint: Text('Select Customer (required)', style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint)),
          items: [
            ..._customers.map((c) => DropdownMenuItem<String>(
                  value: c['id']?.toString(),
                  child: Text(c['name'] as String, style: AppTypography.bodyMedium),
                )),
            DropdownMenuItem<String>(
              value: _addNewCustomerValue,
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('Add New Customer',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
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

  Widget _buildSearchBar(List<Map<String, dynamic>> filtered) {
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
              hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () { _searchController.clear(); setState(() {}); },
                      icon: const Icon(Icons.close_rounded, color: AppColors.textHint, size: 18),
                    )
                  : InkWell(
                      onTap: () async {
                        final result = await Navigator.of(context).push<String>(
                          MaterialPageRoute(fullscreenDialog: true, builder: (_) => const BarcodeScannerScreen()),
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
                        child: const Icon(Icons.barcode_reader, color: AppColors.primary, size: 18),
                      ),
                    ),
              filled: true,
              fillColor: AppColors.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (filtered.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: filtered.map((p) {
                final stock = p['stock'] as int;
                return ListTile(
                  dense: true,
                  title: Text(p['name'] as String, style: AppTypography.bodyMedium),
                  subtitle: Text('Stock: $stock', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                  trailing: Text(
                    NumberFormat('#,###').format(p['sellingPrice']),
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                  onTap: stock > 0 || p['type'] == 'service' ? () => _addProduct(p) : null,
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildItemsHeader() {
    return Row(
      children: [
        Text('Order Items', style: AppTypography.label.copyWith(color: AppColors.textPrimary)),
        const Spacer(),
        Text('${_items.length} item${_items.length == 1 ? '' : 's'}',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildItemsList() {
    return Column(
      children: _items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final price = _isWholesale
            ? (item['wholesalePrice'] as double? ?? item['sellingPrice'] as double? ?? 0.0)
            : (item['sellingPrice'] as double? ?? 0.0);
        return AddSaleItemTile(
          name: item['name'] as String,
          price: price,
          quantity: (item['quantity'] as num?)?.toInt() ?? 1,
          maxStock: (item['stock'] as num?)?.toInt() ?? 9999,
          discount: item['discount'] as double? ?? 0.0,
          isService: item['type'] == 'service',
          onQuantityChanged: (v) => setState(() => _items[index]['quantity'] = v),
          onDiscountChanged: (v) => setState(() => _items[index]['discount'] = v),
          onRemove: () => setState(() => _items.removeAt(index)),
        );
      }).toList(),
    );
  }

  Widget _buildSummarySection() {
    final fmt = NumberFormat('#,###');
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal', fmt.format(_totalAmount)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Discount', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
              const Spacer(),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  onChanged: (_) => setState(() {}),
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          _summaryRow('Total', fmt.format(_finalAmount), bold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Row(
      children: [
        Text(label,
            style: AppTypography.bodyMedium.copyWith(
              color: bold ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
            )),
        const Spacer(),
        Text(value,
            style: AppTypography.bodyMedium.copyWith(
              color: bold ? AppColors.primary : AppColors.textPrimary,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            )),
      ],
    );
  }

  Widget _buildBottomBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(AppConstants.paddingLG, 12, AppConstants.paddingLG, 12 + bottomPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusLG)),
                minimumSize: Size(double.infinity, AppConstants.buttonHeight),
              ),
              child: Text('Cancel', style: AppTypography.buttonLarge.copyWith(color: AppColors.textSecondary)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: (_items.isNotEmpty && !_isSaving) ? _saveOrder : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusLG)),
                minimumSize: Size(double.infinity, AppConstants.buttonHeight),
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Save Order', style: AppTypography.buttonLarge),
            ),
          ),
        ],
      ),
    );
  }
}
