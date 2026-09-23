import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/stock/presentation/widgets/adjust_product_card.dart';
import 'package:dukaapp/features/stock/presentation/widgets/adjustment_status_dropdown.dart';
import 'package:dukaapp/features/stock/presentation/widgets/adjustment_summary_card.dart';
import 'package:dukaapp/features/stock/presentation/widgets/adjust_bottom_bar.dart';

class _AdjustItem {
  final String rawMaterialId;
  final String name;
  final int currentStock;
  int adjustQuantity;
  AdjustmentStatus status;

  _AdjustItem({required this.rawMaterialId, required this.name, required this.currentStock})
      : adjustQuantity = 0,
        status = AdjustmentStatus.none;
}

class AdjustRawMaterialsPage extends ConsumerStatefulWidget {
  const AdjustRawMaterialsPage({super.key});

  @override
  ConsumerState<AdjustRawMaterialsPage> createState() => _AdjustRawMaterialsPageState();
}

class _AdjustRawMaterialsPageState extends ConsumerState<AdjustRawMaterialsPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<_AdjustItem> _items = [];
  final Set<int> _selectedMaterials = {};
  List<Map<String, dynamic>> _allMaterials = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
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
          'stock': (m['current_stock'] ?? m['quantity'] ?? m['stock'] ?? 0) as num,
        };
      }).toList();
      setState(() => _allMaterials = materials);
    } catch (_) {}
  }

  List<Map<String, dynamic>> get _filteredMaterials {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return _allMaterials;
    return _allMaterials.where((m) => (m['name'] as String).toLowerCase().contains(query)).toList();
  }

  int get _totalAdjustedQuantity => _items.fold(0, (sum, item) => sum + item.adjustQuantity);
  int get _adjustmentTypeCount => _items.where((item) => item.status != AdjustmentStatus.none).length;

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  void _addSelectedMaterials() {
    final materials = _filteredMaterials;
    int addedCount = 0;
    for (final index in _selectedMaterials) {
      if (index >= materials.length) continue;
      final m = materials[index];
      final name = m['name'] as String;
      if (_items.any((item) => item.name == name)) continue;
      _items.add(_AdjustItem(
        rawMaterialId: (m['raw_material_id'] ?? '').toString(),
        name: name,
        currentStock: (m['stock'] as num).toInt(),
      ));
      addedCount++;
    }
    setState(() => _selectedMaterials.clear());
    if (addedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$addedCount material${addedCount == 1 ? '' : 's'} added', style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)),
        backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM))));
    }
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedMaterials.contains(index)) { _selectedMaterials.remove(index); }
      else { _selectedMaterials.add(index); }
    });
  }

  void _toggleAll() {
    final materials = _filteredMaterials;
    final selectableIndices = materials.asMap().keys.where((i) => !_items.any((item) => item.name == materials[i]['name'])).toSet();
    final allSelected = selectableIndices.every((i) => _selectedMaterials.contains(i));
    setState(() {
      if (allSelected) { _selectedMaterials.removeAll(selectableIndices); }
      else { _selectedMaterials.addAll(selectableIndices); }
    });
  }

  Future<void> _save() async {
    final validItems = _items.where((i) => i.adjustQuantity > 0 && i.status != AdjustmentStatus.none && i.rawMaterialId.isNotEmpty).toList();
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Set quantity and reason for at least one material.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)),
        backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM))));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiServiceProvider);
      // Backend: raw_material_id[], quantity[id], reason[id]
      final body = <String, dynamic>{};
      for (int i = 0; i < validItems.length; i++) {
        final item = validItems[i];
        final id = item.rawMaterialId;
        body['raw_material_id[$i]'] = id;
        body['quantity[$id]'] = item.adjustQuantity.toString();
        body['reason[$id]'] = item.status.name; // 'balancing','bad','expired','lost'
      }
      final result = await api.postMfRawMaterialAdjust(body);
      if (!mounted) return;
      final status = result['status']?.toString() ?? '';
      if (status == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Adjustments saved successfully', style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)),
          backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM))));
        context.pop(true);
      } else {
        final msg = result['message']?.toString() ?? 'Failed to save adjustments';
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

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(backgroundColor: const Color(0xFFF5F7FB), appBar: _buildAppBar(),
      body: SafeArea(top: false, child: Column(children: [
        Expanded(child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 16), _buildSearchSection(), const SizedBox(height: 12),
            _buildMaterialsHeader(), const SizedBox(height: 8),
            if (_items.isNotEmpty) ...[
              _buildAdjustmentCards(), const SizedBox(height: 16),
              AdjustmentSummaryCard(productsSelected: _items.length, adjustedQuantity: _totalAdjustedQuantity, adjustmentTypeCount: _adjustmentTypeCount),
            ],
            if (_items.isEmpty) _buildMaterialList(),
            SizedBox(height: 24 + bottomPadding),
          ]),
        )),
        AdjustBottomBar(
          onClose: () => context.pop(),
          onSave: (_items.isNotEmpty && !_isSaving) ? _save : null,
        ),
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
        Text('Adjust Raw Materials', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text('Adjust quantities and record adjustment reasons.', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10)),
      ]),
      centerTitle: true, bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.divider)),
    );
  }

  Widget _buildSearchSection() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))]),
        child: TextField(controller: _searchController, onChanged: (_) => setState(() {}), style: AppTypography.bodyMedium,
          decoration: InputDecoration(hintText: 'Search raw material name', hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(onPressed: () { _searchController.clear(); setState(() {}); }, icon: const Icon(Icons.close_rounded, color: AppColors.textHint, size: 18))
              : null,
            filled: true, fillColor: AppColors.card, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
        ),
      ),
    );
  }

  Widget _buildMaterialsHeader() {
    final materials = _filteredMaterials;
    final selectableIndices = materials.asMap().keys.where((i) => !_items.any((item) => item.name == materials[i]['name'])).toSet();
    final allSelected = selectableIndices.isNotEmpty && selectableIndices.every((i) => _selectedMaterials.contains(i));

    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Row(children: [
        if (_items.isNotEmpty) ...[
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
            child: Text('${_items.length} item${_items.length == 1 ? '' : 's'}', style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
        ],
        Text(_items.isEmpty ? 'Raw Materials' : 'Adjustment Items', style: AppTypography.label.copyWith(color: AppColors.textPrimary)),
        const Spacer(),
        if (_items.isEmpty && materials.isNotEmpty) ...[
          SizedBox(width: 24, height: 24, child: Checkbox(
            value: allSelected, onChanged: selectableIndices.isNotEmpty ? (_) => _toggleAll() : null,
            activeColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            side: BorderSide(color: allSelected ? AppColors.primary : AppColors.border, width: 1.5))),
          const SizedBox(width: 6),
          Text('Select All', style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
        ],
      ]),
    );
  }

  Widget _buildAdjustmentCards() {
    return Column(children: List.generate(_items.length, (index) {
      final item = _items[index];
      return AdjustProductCard(
        productName: item.name, currentStock: item.currentStock,
        adjustQuantity: item.adjustQuantity, onQuantityChanged: (v) => setState(() => item.adjustQuantity = v),
        status: item.status, onStatusChanged: (v) => setState(() => item.status = v ?? AdjustmentStatus.none),
      );
    }));
  }

  Widget _buildMaterialList() {
    final materials = _filteredMaterials;
    if (_searchController.text.isNotEmpty && materials.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXXL, vertical: 60),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 120, height: 120, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), shape: BoxShape.circle),
            child: Icon(Icons.search_off_rounded, size: 56, color: AppColors.primary.withValues(alpha: 0.4))),
          const SizedBox(height: 24),
          Text('No Materials Found', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Search a material to begin adjusting stock.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
        ]),
      ));
    }

    return Column(children: [
      ...materials.asMap().entries.map((entry) {
        final index = entry.key;
        final material = entry.value;
        final name = material['name'] as String;
        final stock = (material['stock'] as num).toInt();
        final isAlreadyAdded = _items.any((item) => item.name == name);
        final isSelected = _selectedMaterials.contains(index);

        return Container(margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 4),
          decoration: BoxDecoration(color: isSelected ? AppColors.primary.withValues(alpha: 0.04) : AppColors.card,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(14),
            child: InkWell(onTap: isAlreadyAdded ? null : () => _toggleSelection(index), borderRadius: BorderRadius.circular(14),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  if (!isAlreadyAdded) SizedBox(width: 24, height: 24, child: Checkbox(
                    value: isSelected, onChanged: (_) => _toggleSelection(index),
                    activeColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border, width: 1.5)))
                  else const SizedBox(width: 24),
                  const SizedBox(width: 12),
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text(name.substring(0, name.length.clamp(0, 2)).toUpperCase(),
                      style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('Stock: $stock', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                  ])),
                  if (isAlreadyAdded) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('Added', style: AppTypography.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w600))),
                ]),
              ),
            ),
          ),
        );
      }),
      if (_selectedMaterials.isNotEmpty) ...[
        const SizedBox(height: 12),
        Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
          child: SizedBox(width: double.infinity, height: AppConstants.buttonHeight,
            child: ElevatedButton.icon(onPressed: _addSelectedMaterials, icon: const Icon(Icons.add_rounded, size: 20),
              label: Text('Add Selected (${_selectedMaterials.length})', style: AppTypography.buttonLarge),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.textWhite, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)))))),
      ],
    ]);
  }
}
