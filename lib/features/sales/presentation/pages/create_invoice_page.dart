import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dukaapp/app/colors.dart' show AppColors;
import 'package:dukaapp/features/sales/presentation/providers/sales_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/sales/presentation/widgets/add_sale_item_tile.dart';
import 'package:dukaapp/features/stock/presentation/pages/barcode_scanner_screen.dart';
import 'package:dukaapp/features/customers/presentation/pages/add_customer_page.dart';
import 'package:dukaapp/core/providers.dart';

class CreateInvoicePage extends ConsumerStatefulWidget {
  const CreateInvoicePage({super.key});

  @override
  ConsumerState<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends ConsumerState<CreateInvoicePage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));
  String? _selectedCustomer;
  String _selectedPaymentType = 'Credit';

  static const String _addNewCustomerValue = '__add_new_customer__';
  static const String _addNewPaymentValue = '__add_new_payment__';

  final List<String> _customers = [
    'HASSAN ALI',
    'AMINA HASSAN',
    'FATIMA OSMAN',
    'JUMA JUMA',
    'NEEMA KIMARO',
  ];

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCustomers());
  }

  Future<void> _loadCustomers() async {
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getCustomers();
      final raw = res.data;
      final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? raw['customers'] ?? []) : []);
      if (!mounted) return;
      setState(() {
        _customers
          ..clear()
          ..add('Walk-in');
        for (final c in list) {
          if (c is Map) {
            final name = (c['customer_name'] ?? c['name'] ?? '').toString();
            if (name.isNotEmpty) _customers.add(name);
          }
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

  Future<void> _openBarcodeScanner() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const BarcodeScannerScreen(),
      ),
    );
    if (result != null && result.isNotEmpty) {
      _searchController.text = result;
      setState(() {});
    }
  }

  void _addItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return _buildItemPickerSheet(scrollController);
          },
        );
      },
    );
  }

  void _addSelectedItem(Map<String, dynamic> product) {
    final existingIndex = _items.indexWhere(
      (item) => item['name'] == product['name'],
    );
    if (existingIndex >= 0) {
      final currentQty = _items[existingIndex]['quantity'] as int;
      final maxStock = _items[existingIndex]['stock'] as int;
      if (currentQty < maxStock) {
        setState(() {
          _items[existingIndex]['quantity'] = currentQty + 1;
        });
      }
    } else {
      setState(() {
        _items.add({
          'name': product['name'],
          'sellingPrice': product['sellingPrice'],
          'quantity': 1,
          'stock': product['stock'],
          'discount': 0.0,
        });
      });
    }
    Navigator.pop(context);
  }

  void _updateItemQuantity(int index, int delta) {
    setState(() {
      final currentQty = _items[index]['quantity'] as int;
      final maxStock = _items[index]['stock'] as int;
      final newQty = currentQty + delta;
      if (newQty > 0 && newQty <= maxStock) {
        _items[index]['quantity'] = newQty;
      }
    });
  }

  void _updateItemDiscount(int index, double value) {
    setState(() {
      _items[index]['discount'] = value;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
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
    if (_selectedCustomer == null) {
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
        final subtotal = (price * qty) - discount;
        return '\$productId|\$stockId|\$qty|\$price|\$discount|\$subtotal|0|\$subtotal';
      }).toList();

      final total = _items.fold<double>(0, (s, i) {
        final price = ((i['sellingPrice'] ?? i['price'] ?? 0.0) as num).toDouble();
        final qty = (i['quantity'] ?? 1) as int;
        final discount = ((i['discount'] ?? 0.0) as num).toDouble();
        return s + price * qty - discount;
      });

      // Bracket notation so PHP reads items[] as a proper array.
      final body = <String, dynamic>{
        for (int i = 0; i < itemStrings.length; i++) 'items[$i]': itemStrings[i],
        'payment_mode': 'invoice',
        'customer_id': _selectedCustomer ?? '',
        'total_amount': total,
        'paid_amount': 0,
        'discount': 0.0,
        'sale_type': 'invoice',
      };

      final repo = ref.read(salesRepositoryProvider);
      final res = await repo.addSale(body);
      final ok = res['status']?.toString() == '1' || res['status'] == true || res['status']?.toString() == 'success';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Invoice created successfully' : (res['message']?.toString() ?? 'Failed')),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
      ));
      if (ok) context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: \$e'), backgroundColor: AppColors.danger),
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingLG,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildDateFields(),
                    const SizedBox(height: 16),
                    _buildCustomerDropdown(),
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    _buildItemsHeader(),
                    const SizedBox(height: 8),
                    _buildItemsList(),
                    const SizedBox(height: 16),
                    _buildPaymentTypeDropdown(),
                    const SizedBox(height: 16),
                    _buildSummarySection(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                    SizedBox(height: 24 + bottomPadding),
                  ],
                ),
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
    final allOptions = [..._customers, _addNewCustomerValue];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Select Customer',
          style: AppTypography.label.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedCustomer,
          isExpanded: true,
          hint: Text(
            'Select Customer',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
          ),
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
          items: allOptions.map((customer) {
            if (customer == _addNewCustomerValue) {
              return DropdownMenuItem(
                value: customer,
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
              );
            }
            return DropdownMenuItem(
              value: customer,
              child: Text(customer),
            );
          }).toList(),
          onChanged: (value) {
            if (value == _addNewCustomerValue) {
              _showAddNewCustomerSheet();
            } else {
              setState(() => _selectedCustomer = value);
            }
          },
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
          'Items',
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
            '${_items.length}',
            style: AppTypography.captionBold.copyWith(
              color: AppColors.primary,
              fontSize: 11,
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _addItem,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Add Item',
                  style: AppTypography.buttonSmall.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList() {
    if (_items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          border: Border.all(
            color: AppColors.border,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 40,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No items added yet',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap "Add Item" to start adding products',
              style: AppTypography.caption.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(_items.length, (index) {
        final item = _items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AddSaleItemTile(
            name: item['name'],
            sellingPrice: item['sellingPrice'],
            quantity: item['quantity'],
            stock: item['stock'],
            discount: item['discount'],
            isWholesale: false,
            onQuantityChanged: (delta) => _updateItemQuantity(index, delta),
            onRemove: () => _removeItem(index),
            onDiscountChanged: (value) => _updateItemDiscount(index, value),
          ),
        );
      }),
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

  Widget _buildSummarySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: AppTypography.label.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Entries', '${_items.length}'),
          _buildSummaryRow('Total Quantity', '$_totalQuantity'),
          _buildSummaryRow('Total Amount', _formatCurrency(_totalAmount)),
          if (_totalItemDiscount > 0) ...[
            _buildSummaryRow(
              'Item Discounts',
              '- ${_formatCurrency(_totalItemDiscount)}',
              valueColor: AppColors.danger,
            ),
          ],
          const Divider(height: 20, color: AppColors.border),
          _buildDiscountField(),
          const Divider(height: 20, color: AppColors.border),
          _buildSummaryRow(
            'Final Amount',
            _formatCurrency(_finalAmount),
            isBold: true,
            valueColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Discount',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(
          width: 120,
          child: TextField(
            controller: _discountController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Tsh 0',
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
              prefixText: 'Tsh ',
              prefixStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.inputFocusBorder,
                  width: 1.5,
                ),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
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

  Widget _buildItemPickerSheet(ScrollController scrollController) {
    final List<Map<String, dynamic>> allProducts = [
      {'name': 'AIR', 'sellingPrice': 125000.0, 'stock': 5},
      {'name': 'AIR FRESH', 'sellingPrice': 7000.0, 'stock': 15},
      {'name': 'BEAUTY CREAM', 'sellingPrice': 18000.0, 'stock': 8},
      {'name': 'FACE MASK', 'sellingPrice': 9000.0, 'stock': 12},
      {'name': 'DISH SOAP', 'sellingPrice': 3500.0, 'stock': 20},
      {'name': 'CAR PHONE HOLDER', 'sellingPrice': 15000.0, 'stock': 6},
      {'name': 'CHARGER CABLE', 'sellingPrice': 6000.0, 'stock': 10},
    ];

    return _ItemPickerContent(
      allProducts: allProducts,
      formatCurrency: _formatCurrency,
      onAddItem: _addSelectedItem,
      onScanBarcode: _openBarcodeScanner,
    );
  }
}

class _ItemPickerContent extends StatefulWidget {
  final List<Map<String, dynamic>> allProducts;
  final String Function(double) formatCurrency;
  final void Function(Map<String, dynamic>) onAddItem;
  final VoidCallback onScanBarcode;

  const _ItemPickerContent({
    required this.allProducts,
    required this.formatCurrency,
    required this.onAddItem,
    required this.onScanBarcode,
  });

  @override
  State<_ItemPickerContent> createState() => _ItemPickerContentState();
}

class _ItemPickerContentState extends State<_ItemPickerContent> {
  final TextEditingController _sheetSearchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _sheetSearchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_searchQuery.isEmpty) return widget.allProducts;
    return widget.allProducts
        .where(
          (p) => p['name'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingLG,
              16,
              AppConstants.paddingLG,
              12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Product',
                    style: AppTypography.h6.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    widget.onScanBarcode();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Scan',
                          style: AppTypography.captionBold.copyWith(
                            color: AppColors.primary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingLG,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _sheetSearchController,
                      style: AppTypography.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textHint,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _sheetSearchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textHint,
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 40,
                          color: AppColors.textHint.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No products found',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingLG,
                      vertical: AppConstants.paddingSM,
                    ),
                    itemCount: _filteredProducts.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      color: AppColors.borderLight,
                    ),
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 4,
                        ),
                        title: Text(
                          product['name'],
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${widget.formatCurrency(product['sellingPrice'])} - ${product['stock']} in stock',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        onTap: () => widget.onAddItem(product),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
