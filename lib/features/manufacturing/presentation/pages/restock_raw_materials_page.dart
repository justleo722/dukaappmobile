import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/stock/presentation/pages/barcode_scanner_screen.dart';
import 'package:dukaapp/features/stock/presentation/widgets/compact_qty_stepper.dart';
import 'package:dukaapp/features/stock/presentation/widgets/expiry_picker.dart';
import 'package:dukaapp/features/stock/presentation/widgets/price_input.dart';
import 'package:dukaapp/features/purchase/presentation/widgets/purchase_information_card.dart';
import 'package:dukaapp/features/purchase/presentation/widgets/purchase_summary_card.dart';
import 'package:dukaapp/features/purchase/presentation/widgets/purchase_bottom_bar.dart';

class _RestockItem {
  final String rawMaterialId;
  final String name;
  final int currentStock;
  int quantity;
  final TextEditingController unitCostController;
  DateTime? expiryDate;

  _RestockItem({
    required this.rawMaterialId,
    required this.name,
    required this.currentStock,
    double unitCostValue = 0,
  })  : quantity = 1,
        unitCostController = TextEditingController(text: unitCostValue > 0 ? unitCostValue.toStringAsFixed(0) : '');

  void dispose() {
    unitCostController.dispose();
  }
}

class RestockRawMaterialsPage extends ConsumerStatefulWidget {
  const RestockRawMaterialsPage({super.key});

  @override
  ConsumerState<RestockRawMaterialsPage> createState() => _RestockRawMaterialsPageState();
}

class _RestockRawMaterialsPageState extends ConsumerState<RestockRawMaterialsPage> {
  String? _selectedAccount;
  String? _selectedSupplier;
  DateTime _restockDate = DateTime.now();
  final List<_RestockItem> _items = [];
  // Live search over the inline raw-material catalog.
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allMaterials = [];
  List<String> _accounts = [];
  Map<String, String> _accountIdMap = {};

  @override
  void initState() {
    super.initState();
    _loadMaterials();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getCashbookAccounts();
      final body = res.data;
      List rawList = [];
      if (body is List) {
        rawList = body;
      } else if (body is Map) {
        final data = body['data'] ?? body['accounts'] ?? body;
        if (data is List) rawList = data;
      }
      final names = <String>[];
      final idMap = <String, String>{};
      for (final e in rawList) {
        if (e is! Map) continue;
        final name = (e['account_name'] ?? e['name'] ?? '').toString();
        final id = (e['account_id'] ?? e['id'] ?? '').toString();
        if (name.isNotEmpty && id.isNotEmpty && !idMap.containsKey(name)) {
          names.add(name);
          idMap[name] = id;
        }
      }
      if (!mounted) return;
      setState(() {
        _accounts = names;
        _accountIdMap = idMap;
        if (_selectedAccount == null && names.isNotEmpty) {
          _selectedAccount = names.firstWhere(
            (a) => a.toLowerCase() == 'cash',
            orElse: () => names.first,
          );
        }
      });
    } catch (_) {}
  }

  Future<void> _loadMaterials() async {
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getMfRawMaterials();
      final body = res.data;
      List<Map<String, dynamic>> materials = [];
      List rawList = [];
      if (body is List) {
        rawList = body;
      } else if (body is Map) {
        final data = body['data'] ?? body['materials'] ?? [];
        if (data is List) rawList = data;
      }
      materials = rawList.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return {
          'raw_material_id': (m['raw_material_id'] ?? m['id'] ?? '').toString(),
          'name': (m['material_name'] ?? m['name'] ?? '').toString(),
          'stock': num.tryParse((m['current_stock'] ?? m['quantity'] ?? m['stock'] ?? 0).toString()) ?? 0,
          'unitCost': num.tryParse((m['unit_cost'] ?? m['cost'] ?? 0).toString()) ?? 0,
        };
      }).toList();
      setState(() => _allMaterials = materials);
    } catch (_) {}
  }

  int get _totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  String get _estimatedValue {
    double total = 0;
    for (final item in _items) {
      final price = double.tryParse(item.unitCostController.text) ?? 0;
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

  // ---------------------------------------------------------------------------
  // Premium inline catalog helpers
  // ---------------------------------------------------------------------------

  /// Materials currently part of the restock (quantity >= 1).
  List<_RestockItem> get _selectedItems =>
      _items.where((item) => item.quantity > 0).toList();

  /// Materials matching the current search query (name or barcode).
  List<Map<String, dynamic>> get _filteredMaterials {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _allMaterials;
    return _allMaterials.where((p) {
      final name = (p['name'] as String).toLowerCase();
      final barcode = (p['barcode']?.toString() ?? '').toLowerCase();
      return name.contains(query) || barcode.contains(query);
    }).toList();
  }

  /// Materials to render: the filtered catalog, plus any already-selected
  /// items whose material isn't in the catalog.
  List<Map<String, dynamic>> get _displayProducts {
    final list = List<Map<String, dynamic>>.from(_filteredMaterials);
    final names = list.map((p) => p['name'] as String).toSet();
    for (final item in _items) {
      if (item.quantity > 0 && !names.contains(item.name)) {
        list.add({
          'raw_material_id': item.rawMaterialId,
          'name': item.name,
          'stock': item.currentStock,
          'unitCost': double.tryParse(item.unitCostController.text) ?? 0,
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

  /// Select a material (quantity 1) or bump its quantity.
  void _incrementProduct(Map<String, dynamic> material) {
    final name = material['name'] as String;
    final i = _itemIndexByName(name);
    setState(() {
      if (i < 0) {
        _items.add(_RestockItem(
          rawMaterialId: (material['raw_material_id'] ?? '').toString(),
          name: name,
          currentStock: ((material['stock'] as num?) ?? 0).toInt(),
          unitCostValue: ((material['unitCost'] as num?) ?? 0).toDouble(),
        ));
      } else {
        _items[i].quantity += 1;
      }
    });
  }

  /// Deselect at quantity 1 — the item (and its controller) is kept.
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

    final matches = _allMaterials.where(
      (p) => (p['barcode']?.toString() ?? '').trim() == code,
    );

    if (matches.isNotEmpty) {
      final material = matches.first;
      final name = material['name'] as String;
      if (_qtyFor(name) > 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$name is already selected'),
          backgroundColor: AppColors.warning,
        ));
        return;
      }
      _incrementProduct(material);
      _showAddedSnack(name);
    } else {
      setState(() => _searchController.text = code);
    }
  }

  void _showAddedSnack(String name) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        '$name added to restock',
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
                    _buildItemsHeader(),
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
              saveLabel: 'Save Restock',
              onSave: _selectedItems.isNotEmpty
                  ? () async {
                      try {
                        final api = ref.read(apiServiceProvider);
                        final selectedItems = _selectedItems;
                        final body = <String, dynamic>{
                          'record_date': '${_restockDate.year}-${_restockDate.month.toString().padLeft(2,'0')}-${_restockDate.day.toString().padLeft(2,'0')}',
                          if (_selectedAccount != null && _accountIdMap[_selectedAccount] != null)
                            'account_id': _accountIdMap[_selectedAccount]!,
                        };
                        for (int i = 0; i < selectedItems.length; i++) {
                          final item = selectedItems[i];
                          final id = item.rawMaterialId;
                          body['raw_material_id[$i]'] = id;
                          body['quantity[$id]'] = item.quantity.toString();
                          body['unit_cost[$id]'] = item.unitCostController.text.trim().isEmpty ? '0' : item.unitCostController.text.trim();
                          if (item.expiryDate != null) {
                            body['expiry_date[$id]'] = '${item.expiryDate!.year}-${item.expiryDate!.month.toString().padLeft(2,'0')}-${item.expiryDate!.day.toString().padLeft(2,'0')}';
                          }
                        }
                        final result = await api.postMfRawMaterialRestock(body);
                        if (!mounted) return;
                        final status = result['status']?.toString() ?? '';
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(status == 'success' ? 'Restock saved successfully' : (result['message']?.toString() ?? 'Failed'),
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)),
                          backgroundColor: status == 'success' ? AppColors.success : AppColors.danger,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
                        ));
                        if (status == 'success') context.pop(true);
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger));
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
      backgroundColor: AppColors.card, elevation: 0,
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
          Text('Restock Raw Materials',
            style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('Add raw materials into inventory.',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10)),
        ],
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
            child: IconButton(
              onPressed: null,
              icon: Icon(Icons.receipt_long_rounded, color: AppColors.textHint, size: 20),
            ),
          ),
        ),
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
          // Account + Supplier in one row.
          PurchaseInformationCard(
            showSearch: false,
            inlineRow: true,
            accounts: _accounts,
            selectedAccount: _selectedAccount,
            onAccountChanged: (v) => setState(() => _selectedAccount = v),
            selectedSupplier: _selectedSupplier,
            onSupplierChanged: (v) => setState(() => _selectedSupplier = v),
          ),
          const SizedBox(height: 8),
          // Date
          Text('Restock Date', style: AppTypography.label.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          _buildDateField(),
          const SizedBox(height: 8),
          // Search bar
          _buildSearchBar(),
        ]),
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context, initialDate: _restockDate,
          firstDate: DateTime(2020), lastDate: DateTime.now(),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primary)),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _restockDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${_restockDate.day.toString().padLeft(2, '0')}/${_restockDate.month.toString().padLeft(2, '0')}/${_restockDate.year}',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint, size: 18),
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
                hintText: 'Search material or scan barcode',
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

  Widget _buildItemsHeader() {
    final materials = _displayProducts;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Row(
        children: [
          Text('Restock Items', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppConstants.radiusFull)),
            child: Text('${_selectedItems.length}', style: AppTypography.captionBold.copyWith(color: AppColors.primary, fontSize: 11)),
          ),
          const Spacer(),
          Text('${materials.length} available', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildCatalogList() {
    final materials = _displayProducts;
    if (materials.isEmpty) {
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
          child: Column(
            children: [
              const Icon(Icons.inventory_2_rounded, size: 32, color: AppColors.textHint),
              const SizedBox(height: 8),
              Text(
                (_allMaterials.isEmpty && _searchController.text.trim().isEmpty)
                    ? 'No raw materials available'
                    : 'No materials match your search',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Column(children: materials.map(_buildCatalogCard).toList()),
    );
  }

  Widget _buildCatalogCard(Map<String, dynamic> material) {
    final name = material['name'] as String;
    final idx = _itemIndexByName(name);
    final item = idx >= 0 ? _items[idx] : null;
    final qty = item?.quantity ?? 0;
    final selected = qty > 0;
    final stock = item?.currentStock ?? ((material['stock'] as num?) ?? 0).toInt();
    final unitCost = item != null
        ? (double.tryParse(item.unitCostController.text) ?? 0)
        : (((material['unitCost'] as num?) ?? 0).toDouble());

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
                    name.isNotEmpty ? name.substring(0, name.length.clamp(0, 2)).toUpperCase() : '??',
                    style: AppTypography.captionBold.copyWith(color: AppColors.primary, fontSize: 11),
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
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Stock: $stock',
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              CompactQtyStepper(
                qty: qty,
                onAdd: () => _incrementProduct(material),
                onRemove: () => _decrementProduct(name),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Unit cost + expiry revealed once selected.
          if (selected && item != null)
            Row(
              children: [
                Expanded(
                  child: PriceInput(label: 'Unit Cost', controller: item.unitCostController, hintText: '0'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ExpiryPicker(
                    label: 'Expiry Date',
                    selectedDate: item.expiryDate,
                    onDateSelected: (d) => setState(() => item.expiryDate = d),
                  ),
                ),
              ],
            )
          else
            _buildUnselectedFooter(unitCost),
        ],
      ),
    );
  }

  Widget _buildUnselectedFooter(double unitCost) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        unitCost > 0
            ? 'Unit cost: Tsh ${unitCost.toStringAsFixed(0)} — tap + to restock'
            : 'Tap + to add this material to the restock',
        style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10),
      ),
    );
  }
}
