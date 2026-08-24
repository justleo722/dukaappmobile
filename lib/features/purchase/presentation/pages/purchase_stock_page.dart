import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/stock/presentation/pages/barcode_scanner_screen.dart';
import 'package:dukaapp/features/purchase/presentation/widgets/purchase_information_card.dart';
import 'package:dukaapp/features/purchase/presentation/widgets/purchase_product_card.dart';
import 'package:dukaapp/features/purchase/presentation/widgets/purchase_summary_card.dart';
import 'package:dukaapp/features/purchase/presentation/widgets/purchase_bottom_bar.dart';

class _PurchaseItem {
  final String name;
  final int currentStock;
  int quantity;
  final TextEditingController buyingPrice;
  final TextEditingController sellingPrice;
  final TextEditingController wholesalePrice;
  DateTime? expiryDate;

  _PurchaseItem({
    required this.name,
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

class PurchaseStockPage extends StatefulWidget {
  final Map<String, dynamic>? initialProduct;
  final bool editMode;
  final bool createMode;
  final String? poNumber;
  final String? initialSupplier;
  final List<Map<String, dynamic>>? editProducts;

  const PurchaseStockPage({
    super.key,
    this.initialProduct,
    this.editMode = false,
    this.createMode = false,
    this.poNumber,
    this.initialSupplier,
    this.editProducts,
  });

  @override
  State<PurchaseStockPage> createState() => _PurchaseStockPageState();
}

class _PurchaseStockPageState extends State<PurchaseStockPage> {
  String? _selectedAccount;
  String? _selectedSupplier;
  DateTime _purchaseDate = DateTime.now();
  final List<_PurchaseItem> _items = [];

  static const List<Map<String, dynamic>> _dummyProducts = [
    {'name': 'AIR', 'stock': 15, 'buyingPrice': 4500.0, 'sellingPrice': 7000.0, 'wholesalePrice': 6500.0},
    {'name': 'AIR FRESH', 'stock': 8, 'buyingPrice': 3500.0, 'sellingPrice': 5500.0, 'wholesalePrice': 5000.0},
    {'name': 'APPLE JUICE', 'stock': 20, 'buyingPrice': 1200.0, 'sellingPrice': 2000.0, 'wholesalePrice': 1800.0},
    {'name': 'COCA COLA 600ML', 'stock': 3, 'buyingPrice': 800.0, 'sellingPrice': 1000.0, 'wholesalePrice': 1000.0},
    {'name': 'COKE', 'stock': 12, 'buyingPrice': 800.0, 'sellingPrice': 1000.0, 'wholesalePrice': 950.0},
  ];

  @override
  void initState() {
    super.initState();
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

  void _addInitialProduct(Map<String, dynamic> product) {
    final name = product['name'] as String;
    if (!_items.any((item) => item.name == name)) {
      _items.add(_PurchaseItem(
        name: name,
        currentStock: product['stock'] as int? ?? 0,
        buyingPriceValue: product['buyingPrice'] as double? ?? 0,
        sellingPriceValue: product['sellingPrice'] as double? ?? 0,
        wholesalePriceValue: product['wholesalePrice'] as double? ?? 0,
      ));
    }
  }

  int get _totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  String get _estimatedValue {
    double total = 0;
    for (final item in _items) {
      final price = double.tryParse(item.buyingPrice.text) ?? 0;
      total += price * item.quantity;
    }
    return 'Tsh ${total.toStringAsFixed(0)}';
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addProducts(List<Map<String, dynamic>> products) {
    int addedCount = 0;
    for (final product in products) {
      final name = product['name'] as String;
      if (_items.any((item) => item.name == name)) continue;
      _items.add(_PurchaseItem(
        name: name,
        currentStock: product['stock'] as int,
        buyingPriceValue: product['buyingPrice'] as double,
        sellingPriceValue: product['sellingPrice'] as double,
        wholesalePriceValue: product['wholesalePrice'] as double,
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

  void _removeProduct(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  void _showSearchSheet() {
    final searchController = TextEditingController();
    List<Map<String, dynamic>> filtered = List.from(_dummyProducts);
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
                            final query = value.toLowerCase().trim();
                            setSheetState(() {
                              selectedIndices.clear();
                              filtered = query.isEmpty
                                  ? List.from(_dummyProducts)
                                  : _dummyProducts.where((p) {
                                      final name = (p['name'] as String).toLowerCase();
                                      return name.contains(query);
                                    }).toList();
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
                                    final query = result.toLowerCase().trim();
                                    setSheetState(() {
                                      selectedIndices.clear();
                                      filtered = query.isEmpty
                                          ? List.from(_dummyProducts)
                                          : _dummyProducts.where((p) {
                                              final name = (p['name'] as String).toLowerCase();
                                              return name.contains(query);
                                            }).toList();
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
                                  final stock = product['stock'] as int;
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
                                                  'Stock: $stock',
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    PurchaseInformationCard(
                      onSearchTap: _showSearchSheet,
                      selectedAccount: _selectedAccount,
                      onAccountChanged: (v) => setState(() => _selectedAccount = v),
                      selectedSupplier: _selectedSupplier,
                      onSupplierChanged: (v) => setState(() => _selectedSupplier = v),
                    ),
                    const SizedBox(height: 14),
                    _buildDateSection(),
                    const SizedBox(height: 16),
                    _buildItemsHeader(),
                    const SizedBox(height: 8),
                    if (_items.isNotEmpty) ...[
                      _buildProductList(),
                      const SizedBox(height: 8),
                    ],
                    _buildAddButton(),
                    if (_items.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      PurchaseSummaryCard(
                        numberOfProducts: _items.length,
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
              onSave: _items.isNotEmpty
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.editMode
                                ? 'Purchase order updated successfully'
                                : 'Purchase saved successfully',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite),
                          ),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                          ),
                        ),
                      );
                      if (widget.editMode) {
                        context.pop();
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
                    : 'Purchase Stock',
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
                    : 'Add purchased products into inventory.',
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

  Widget _buildDateSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Purchase Date',
            style: AppTypography.label.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          GestureDetector(
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${_purchaseDate.day.toString().padLeft(2, '0')}/${_purchaseDate.month.toString().padLeft(2, '0')}/${_purchaseDate.year}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_items.length} item${_items.length == 1 ? '' : 's'}',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Purchase Items',
            style: AppTypography.label.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return Column(
      children: List.generate(_items.length, (index) {
        final item = _items[index];
        return PurchaseProductCard(
          productName: item.name,
          quantity: item.quantity,
          onQuantityChanged: (v) => setState(() => item.quantity = v),
          buyingPriceController: item.buyingPrice,
          sellingPriceController: item.sellingPrice,
          wholesalePriceController: item.wholesalePrice,
          expiryDate: item.expiryDate,
          onExpiryChanged: (v) => setState(() => item.expiryDate = v),
          currentStock: item.currentStock,
          onDelete: () => _removeProduct(index),
        );
      }),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _showSearchSheet,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(
            'Add Another Product',
            style: AppTypography.buttonLarge.copyWith(
              color: AppColors.primary,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            ),
          ),
        ),
      ),
    );
  }
}
