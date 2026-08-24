import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/shared/dialogs/app_filter_dialog.dart';
import 'package:dukaapp/features/manufacturing/presentation/dialogs/sort_raw_materials_dialog.dart';

class _RawMaterial {
  final String name;
  final String unit;
  final int currentStock;
  final double unitCost;
  final String status;

  const _RawMaterial({
    required this.name,
    required this.unit,
    required this.currentStock,
    required this.unitCost,
    required this.status,
  });

  double get totalValue => unitCost * currentStock;
}

class RawMaterialsPage extends StatefulWidget {
  const RawMaterialsPage({super.key});

  @override
  State<RawMaterialsPage> createState() => _RawMaterialsPageState();
}

class _RawMaterialsPageState extends State<RawMaterialsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SortField _sortField = SortField.status;
  SortOrder _sortOrder = SortOrder.asc;
  String _selectedStatusLabel = 'All';

  final List<_RawMaterial> _materials = [
    _RawMaterial(name: 'Cotton Fabric (White)', unit: 'kg', currentStock: 250, unitCost: 3500, status: 'In Stock'),
    _RawMaterial(name: 'Polyester Thread', unit: 'roll', currentStock: 120, unitCost: 1200, status: 'In Stock'),
    _RawMaterial(name: 'Denim Fabric', unit: 'kg', currentStock: 15, unitCost: 5500, status: 'Running Low'),
    _RawMaterial(name: 'Zipper (Metal)', unit: 'item', currentStock: 500, unitCost: 200, status: 'In Stock'),
    _RawMaterial(name: 'Button (Plastic)', unit: 'item', currentStock: 800, unitCost: 50, status: 'In Stock'),
    _RawMaterial(name: 'Elastic Band', unit: 'mtr', currentStock: 3, unitCost: 150, status: 'Running Low'),
    _RawMaterial(name: 'Fabric Dye (Blue)', unit: 'ltr', currentStock: 0, unitCost: 4500, status: 'Expired'),
    _RawMaterial(name: 'Bleach Solution', unit: 'ltr', currentStock: 8, unitCost: 2200, status: 'In Stock'),
    _RawMaterial(name: 'Interfacing Cloth', unit: 'kg', currentStock: 40, unitCost: 1800, status: 'In Stock'),
    _RawMaterial(name: 'Sewing Needles', unit: 'pack', currentStock: 25, unitCost: 300, status: 'In Stock'),
    _RawMaterial(name: 'Linen Fabric', unit: 'kg', currentStock: 0, unitCost: 6000, status: 'Expired'),
    _RawMaterial(name: 'Silk Thread', unit: 'roll', currentStock: 60, unitCost: 2500, status: 'In Stock'),
  ];

  double get _totalValue => _materials.fold(0.0, (sum, m) => sum + m.totalValue);
  int get _totalCount => _materials.length;

  List<_RawMaterial> get _filteredMaterials {
    List<_RawMaterial> list = _materials;
    if (_searchQuery.isNotEmpty) {
      list = list.where((m) => m.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    if (_selectedStatusLabel != 'All') {
      if (_selectedStatusLabel == 'Out of Stock') {
        list = list.where((m) => m.currentStock == 0).toList();
      } else {
        list = list.where((m) => m.status == _selectedStatusLabel).toList();
      }
    }
    list.sort((a, b) {
      int cmp;
      switch (_sortField) {
        case SortField.name: cmp = a.name.compareTo(b.name); break;
        case SortField.stock: cmp = a.currentStock.compareTo(b.currentStock); break;
        case SortField.unitCost: cmp = a.unitCost.compareTo(b.unitCost); break;
        case SortField.totalValue: cmp = a.totalValue.compareTo(b.totalValue); break;
        case SortField.status:
          const order = {'In Stock': 0, 'Running Low': 1, 'Expired': 2};
          cmp = (order[a.status] ?? 3).compareTo(order[b.status] ?? 3);
          break;
      }
      return _sortOrder == SortOrder.desc ? -cmp : cmp;
    });
    return list;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildSummarySection(),
                    const SizedBox(height: 14),
                    _buildActionButtons(context),
                    const SizedBox(height: 14),
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    _filteredMaterials.isEmpty ? _buildEmptyState() : _buildMaterialsList(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.card, elevation: 0,
      leading: Padding(padding: const EdgeInsets.all(8.0), child: Container(
        decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
        child: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20)),
      )),
      leadingWidth: 56,
      title: Text('Manage Raw Materials', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      centerTitle: true,
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.divider)),
    );
  }

  Widget _buildSummarySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Row(
        children: [
          _buildSummaryCard(
            label: 'All Raw Materials',
            amount: _totalCount.toString(),
            color: AppColors.primary,
            bgColor: const Color(0xFFEBF2FF),
            icon: Icons.inventory_2_rounded,
          ),
          const SizedBox(width: 12),
          _buildSummaryCard(
            label: 'Total Value',
            amount: _fmt(_totalValue),
            color: AppColors.success,
            bgColor: AppColors.successLight,
            icon: Icons.attach_money_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String amount,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18)),
            const SizedBox(height: 8),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10)),
            const SizedBox(height: 4),
            SizedBox(height: 18, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
              child: Text(amount, style: AppTypography.bodyMedium.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1))),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final buttons = <Map<String, dynamic>>[
      {'icon': Icons.sort_rounded, 'label': 'Sort', 'color': AppColors.primary, 'onTap': () => _showSortDialog()},
      {'icon': Icons.tune_rounded, 'label': 'Adjust', 'color': AppColors.primary, 'onTap': () => context.push('/adjust')},
      {'icon': Icons.refresh_rounded, 'label': 'Restock', 'color': AppColors.primary, 'onTap': () => context.push('/manufacturing/raw-materials/restock')},
      {'icon': Icons.filter_list_rounded, 'label': 'Filter', 'color': AppColors.primary, 'onTap': () => AppFilterDialog.show(context)},
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
        itemCount: buttons.length + 1,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == buttons.length) return _addNewBtn();
          final b = buttons[i];
          return _actionBtn(b['icon'] as IconData, b['label'] as String, b['color'] as Color, b['onTap'] as VoidCallback);
        },
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(border: Border.all(color: color, width: 1.5), borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color), const SizedBox(width: 6),
          Text(label, style: AppTypography.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _addNewBtn() {
    return GestureDetector(
      onTap: () => context.push('/manufacturing/raw-materials/add'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.add_rounded, size: 14, color: AppColors.textWhite), const SizedBox(width: 6),
          Text('Add New Raw Material', style: AppTypography.bodySmall.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w600, fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
          border: Border.all(color: AppColors.inputBorder),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.textHint, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController, style: AppTypography.bodyMedium,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search raw materials by name...',
                  hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                child: const Icon(Icons.close_rounded, color: AppColors.textHint, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialsList() {
    return ListView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      itemCount: _filteredMaterials.length,
      itemBuilder: (ctx, i) => _buildMaterialCard(_filteredMaterials[i]),
    );
  }

  Widget _buildMaterialCard(_RawMaterial material) {
    final statusColor = _statusColor(material.status);
    final statusBg = _statusBg(material.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(material.name, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('Unit: ${material.unit}', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                child: Text(material.status, style: AppTypography.caption.copyWith(color: statusColor, fontWeight: FontWeight.w600, fontSize: 10)),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              _infoChip('Stock', material.currentStock.toString()),
              const SizedBox(width: 8),
              _infoChip('Unit Cost', _fmt(material.unitCost)),
              const SizedBox(width: 8),
              _infoChip('Total Value', _fmt(material.totalValue)),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/manufacturing/raw-materials/edit', extra: {
                  'name': material.name, 'unit': material.unit,
                  'unitCost': material.unitCost, 'status': material.status,
                }),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.edit_rounded, size: 14, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _showDeleteConfirmation(material.name),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.delete_rounded, size: 14, color: AppColors.danger),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(6)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTypography.caption.copyWith(color: AppColors.textHint, fontSize: 9)),
          const SizedBox(height: 2),
          Text(value, style: AppTypography.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXXL, vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 100, height: 100,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), shape: BoxShape.circle),
              child: Icon(Icons.inventory_2_rounded, size: 48, color: AppColors.primary.withValues(alpha: 0.4))),
            const SizedBox(height: 20),
            Text('No Raw Materials Found', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Tap "Add New Raw Material" to get started.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  void _showSortDialog() {
    SortRawMaterialsDialog.show(
      context,
      selectedField: _sortField,
      selectedOrder: _sortOrder,
      selectedStatusLabel: _selectedStatusLabel,
      onFieldChanged: (f) => setState(() => _sortField = f),
      onOrderChanged: (o) => setState(() => _sortOrder = o),
      onStatusChanged: (s) => setState(() => _selectedStatusLabel = s),
      onApply: () => setState(() {}),
    );
  }

  void _showDeleteConfirmation(String materialName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.delete_rounded, color: AppColors.danger, size: 18)),
          const SizedBox(width: 10),
          Text('Delete Material', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
        ]),
        content: Text('Are you sure you want to delete "$materialName"? This action cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
          TextButton(onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: AppColors.textWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: Text('Delete', style: AppTypography.bodySmall.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'In Stock': return AppColors.success;
      case 'Running Low': return const Color(0xFFF59E0B);
      case 'Expired': return AppColors.danger;
      default: return AppColors.textSecondary;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'In Stock': return AppColors.successLight;
      case 'Running Low': return const Color(0xFFFEF3C7);
      case 'Expired': return AppColors.dangerLight;
      default: return const Color(0xFFF1F5F9);
    }
  }

  String _fmt(double v) {
    return 'TZS ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }
}
