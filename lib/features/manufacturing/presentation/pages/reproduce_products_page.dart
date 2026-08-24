import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

class _ReproduceProduct {
  final String name;
  final String recipe;
  int quantity;
  double productionCost;
  final TextEditingController sellingPriceController;
  final TextEditingController wholesalePriceController;
  DateTime expiryDate;

  _ReproduceProduct({
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

class ReproduceProductsPage extends StatefulWidget {
  const ReproduceProductsPage({super.key});

  @override
  State<ReproduceProductsPage> createState() => _ReproduceProductsPageState();
}

class _ReproduceProductsPageState extends State<ReproduceProductsPage> {
  DateTime _productionDate = DateTime.now();
  final List<_ReproduceProduct> _items = [];

  static const List<Map<String, dynamic>> _dummyProducts = [
    {'name': 'White T-Shirt', 'recipe': 'Basic Tee', 'productionCost': 450.0, 'sellingPrice': 850.0, 'wholesalePrice': 750.0},
    {'name': 'Denim Jeans', 'recipe': 'Slim Fit Denim', 'productionCost': 1200.0, 'sellingPrice': 2500.0, 'wholesalePrice': 2200.0},
    {'name': 'Cotton Hoodie', 'recipe': 'Winter Hoodie', 'productionCost': 900.0, 'sellingPrice': 1800.0, 'wholesalePrice': 1600.0},
    {'name': 'Linen Shirt', 'recipe': 'Casual Linen', 'productionCost': 700.0, 'sellingPrice': 1400.0, 'wholesalePrice': 1200.0},
    {'name': 'Sport Shorts', 'recipe': 'Active Shorts', 'productionCost': 350.0, 'sellingPrice': 700.0, 'wholesalePrice': 600.0},
  ];

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
      _items.add(_ReproduceProduct(
        name: name,
        recipe: product['recipe'] as String,
        quantity: 1,
        productionCost: product['productionCost'] as double,
        sellingPrice: product['sellingPrice'] as double,
        wholesalePrice: product['wholesalePrice'] as double,
      ));
      addedCount++;
    }
    if (addedCount > 0) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$addedCount product${addedCount == 1 ? '' : 's'} added', style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)),
          backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM))),
      );
    }
  }

  void _showSearchSheet() {
    final searchController = TextEditingController();
    List<Map<String, dynamic>> filtered = List.from(_dummyProducts);
    final Set<int> selectedIndices = {};

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void toggleSelection(int index) {
              setSheetState(() {
                if (selectedIndices.contains(index)) { selectedIndices.remove(index); }
                else { selectedIndices.add(index); }
              });
            }

            void toggleAll() {
              setSheetState(() {
                final selectable = filtered.asMap().keys.where((i) => !_items.any((item) => item.name == filtered[i]['name'])).toSet();
                final allSelected = selectable.every((i) => selectedIndices.contains(i));
                if (allSelected) { selectedIndices.removeAll(selectable); }
                else { selectedIndices.addAll(selectable); }
              });
            }

            void addSelected() {
              final toAdd = selectedIndices.map((i) => filtered[i]).where((p) => !_items.any((item) => item.name == p['name'])).toList();
              Navigator.pop(context);
              _addProducts(toAdd);
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.7, minChildSize: 0.5, maxChildSize: 0.9,
              builder: (context, scrollController) {
                final selectableCount = filtered.where((p) => !_items.any((item) => item.name == p['name'])).length;
                final allSelected = selectableCount > 0 && filtered.asMap().keys.where((i) => !_items.any((item) => item.name == filtered[i]['name'])).every((i) => selectedIndices.contains(i));

                return Container(
                  decoration: const BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                  child: Column(children: [
                    const SizedBox(height: 12),
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 16),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
                      child: Row(children: [
                        Expanded(child: Text('Search Product', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700))),
                        if (selectedIndices.isNotEmpty) Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text('${selectedIndices.length} selected', style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 22)),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
                      child: TextField(controller: searchController, autofocus: true,
                        onChanged: (value) {
                          final query = value.toLowerCase().trim();
                          setSheetState(() {
                            selectedIndices.clear();
                            filtered = query.isEmpty ? List.from(_dummyProducts) : _dummyProducts.where((p) => (p['name'] as String).toLowerCase().contains(query)).toList();
                          });
                        },
                        style: AppTypography.bodyMedium,
                        decoration: InputDecoration(hintText: 'Search by product name', hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
                          filled: true, fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    if (filtered.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
                        child: Row(children: [
                          SizedBox(width: 24, height: 24, child: Checkbox(
                            value: allSelected, onChanged: selectableCount > 0 ? (_) => toggleAll() : null,
                            activeColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            side: BorderSide(color: allSelected ? AppColors.primary : AppColors.border, width: 1.5),
                          )),
                          const SizedBox(width: 10),
                          Text('Select All', style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Expanded(child: filtered.isEmpty
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.search_off_rounded, size: 48, color: AppColors.textHint.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text('No products found', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                        ]))
                      : ListView.separated(controller: scrollController, padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
                        itemCount: filtered.length, separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderLight),
                        itemBuilder: (context, index) {
                          final product = filtered[index];
                          final name = product['name'] as String;
                          final recipe = product['recipe'] as String;
                          final isAlreadyAdded = _items.any((item) => item.name == name);
                          final isSelected = selectedIndices.contains(index);
                          return InkWell(
                            onTap: isAlreadyAdded ? null : () => toggleSelection(index), borderRadius: BorderRadius.circular(12),
                            child: Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(children: [
                                if (!isAlreadyAdded)
                                  SizedBox(width: 24, height: 24, child: Checkbox(
                                    value: isSelected, onChanged: (_) => toggleSelection(index),
                                    activeColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border, width: 1.5),
                                  ))
                                else const SizedBox(width: 24),
                                const SizedBox(width: 12),
                                Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                  child: Center(child: Text(name.substring(0, name.length.clamp(0, 2)).toUpperCase(),
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)))),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(name, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text('Recipe: $recipe', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                                ])),
                                if (isAlreadyAdded) Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Text('Added', style: AppTypography.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
                                ),
                              ]),
                            ),
                          );
                        }),
                    ),
                    if (selectedIndices.isNotEmpty)
                      Container(
                        padding: EdgeInsets.only(left: AppConstants.paddingLG, right: AppConstants.paddingLG, top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
                        decoration: const BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.divider, width: 1))),
                        child: SizedBox(width: double.infinity, height: AppConstants.buttonHeight,
                          child: ElevatedButton.icon(
                            onPressed: addSelected, icon: const Icon(Icons.add_rounded, size: 20),
                            label: Text('Add Selected (${selectedIndices.length})', style: AppTypography.buttonLarge),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.textWhite, elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD))),
                          ),
                        ),
                      ),
                  ]),
                );
              },
            );
          },
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(backgroundColor: const Color(0xFFF5F7FB), appBar: _buildAppBar(),
      body: SafeArea(top: false, child: Column(children: [
        Expanded(child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 16), _buildDateSection(), const SizedBox(height: 12),
            _buildProductsHeader(), const SizedBox(height: 8),
            _buildAddButton(),
            if (_items.isNotEmpty) ...[
              _buildProductCards(),
              const SizedBox(height: 16),
              _buildSummaryCard(),
            ],
            if (_items.isEmpty) _buildEmptyState(),
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

  Widget _buildDateSection() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('Production Date', style: AppTypography.label.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        GestureDetector(onTap: _pickProductionDate, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), border: Border.all(color: AppColors.inputBorder)),
          child: Row(children: [
            const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text('${_productionDate.day.toString().padLeft(2, '0')}/${_productionDate.month.toString().padLeft(2, '0')}/${_productionDate.year}',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500))),
            Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint, size: 20),
          ]),
        )),
      ]),
    );
  }

  Widget _buildProductsHeader() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Row(children: [
        if (_items.isNotEmpty) ...[
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
            child: Text('${_items.length} item${_items.length == 1 ? '' : 's'}',
              style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
        ],
        Text(_items.isEmpty ? 'Products' : 'Re-Production Items', style: AppTypography.label.copyWith(color: AppColors.textPrimary)),
        const Spacer(),
        Text('${_items.length} available', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _buildProductCards() {
    return Column(children: List.generate(_items.length, (index) {
      final item = _items[index];
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.factory_rounded, color: AppColors.primary, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('Recipe: ${item.recipe}', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11)),
            ])),
            GestureDetector(
              onTap: () => setState(() { item.dispose(); _items.removeAt(index); }),
              child: Container(padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.close_rounded, size: 16, color: AppColors.danger)),
            ),
          ]),
          const Divider(height: 20),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Quantity', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 10)),
              const SizedBox(height: 4),
              TextField(keyboardType: TextInputType.number,
                style: AppTypography.bodySmall,
                controller: TextEditingController(text: '${item.quantity}'),
                onChanged: (v) { item.quantity = int.tryParse(v) ?? 1; },
                decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  filled: true, fillColor: const Color(0xFFF5F7FB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
              ),
            ])),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Cost', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 10)),
              const SizedBox(height: 4),
              Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
                child: Text('Tsh ${item.productionCost.toStringAsFixed(0)}', style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600))),
            ])),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Selling Price', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 10)),
              const SizedBox(height: 4),
              TextField(controller: item.sellingPriceController, keyboardType: TextInputType.number,
                style: AppTypography.bodySmall,
                decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  filled: true, fillColor: const Color(0xFFF5F7FB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
              ),
            ])),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Wholesale Price', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 10)),
              const SizedBox(height: 4),
              TextField(controller: item.wholesalePriceController, keyboardType: TextInputType.number,
                style: AppTypography.bodySmall,
                decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  filled: true, fillColor: const Color(0xFFF5F7FB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
              ),
            ])),
          ]),
          const SizedBox(height: 10),
          GestureDetector(onTap: () async {
            final picked = await showDatePicker(context: context, initialDate: item.expiryDate, firstDate: DateTime.now(), lastDate: DateTime(2100),
              builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: AppColors.primary, onPrimary: AppColors.textWhite, surface: AppColors.card, onSurface: AppColors.textPrimary)), child: child!));
            if (picked != null) setState(() => item.expiryDate = picked);
          },
            child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.inputBorder)),
              child: Row(children: [
                Icon(Icons.calendar_today_rounded, color: AppColors.textHint, size: 16),
                const SizedBox(width: 8),
                Text('Expiry: ${item.expiryDate.day}/${item.expiryDate.month}/${item.expiryDate.year}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary)),
              ]),
            ),
          ),
        ]),
      );
    }));
  }

  Widget _buildSummaryCard() {
    final totalCost = _items.fold(0.0, (sum, item) => sum + (item.productionCost * item.quantity));
    final totalQty = _items.fold(0, (sum, item) => sum + item.quantity);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Row(children: [
        _buildStat(label: 'Products', value: '${_items.length}', icon: Icons.inventory_2_rounded),
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

  Widget _buildAddButton() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: SizedBox(width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _showSearchSheet,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text('Add Product to Re-Produce', style: AppTypography.buttonLarge.copyWith(color: AppColors.primary)),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD))),
        ),
      ),
    );
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
          onPressed: _items.isNotEmpty ? () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Re-production saved successfully', style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)),
              backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM))));
          } : null,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.textWhite, elevation: 0, disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD))),
          child: Text('Save', style: AppTypography.buttonLarge),
        ))),
      ]),
    );
  }
}
