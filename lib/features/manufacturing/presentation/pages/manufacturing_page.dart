import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/services/api_service.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/core/services/local_cache_service.dart';
import 'package:dukaapp/shared/dialogs/app_filter_dialog.dart';
import 'package:dukaapp/shared/providers/filter_provider.dart';
import 'package:dukaapp/features/auth/presentation/controllers/auth_controller.dart';

class ManufacturingPage extends ConsumerStatefulWidget {
  const ManufacturingPage({super.key});

  @override
  ConsumerState<ManufacturingPage> createState() => _ManufacturingPageState();
}

class _ManufacturingPageState extends ConsumerState<ManufacturingPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];
  int _recipeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({String? from, String? to}) async {
    // Serve cache immediately
    final cache = ref.read(localCacheProvider);
    final cached = await cache.loadList('manufacturing', 'products');
    if (mounted && cached.isNotEmpty) {
      setState(() { _products = cached; _isLoading = false; });
    } else {
      setState(() => _isLoading = true);
    }
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getMfManufacturedProducts(from: from, to: to);
      final body = res.data;
      List<Map<String, dynamic>> products = [];
      List<dynamic> rawList = [];
      if (body is List) {
        rawList = body;
      } else if (body is Map) {
        final data = body['data'] ?? body['products'] ?? body;
        if (data is List) rawList = data;
      }
      products = rawList.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

      // Also fetch recipe count
      try {
        final recipeRes = await api.getMfRecipes();
        final rb = recipeRes.data;
        List<dynamic> rl = [];
        if (rb is List) rl = rb;
        else if (rb is Map) { final d = rb['data'] ?? rb['recipes'] ?? rb; if (d is List) rl = d; }
        _recipeCount = rl.length;
      } catch (_) {}
      if (products.isNotEmpty) cache.save('manufacturing', 'products', products);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _totalRawMaterialValue => _products.fold(0.0, (sum, p) {
    final cost = (p['unit_cost'] ?? p['buying_price'] ?? p['cost_price'] ?? 0);
    final qty = (p['quantity'] ?? p['stock'] ?? 0);
    return sum + ((cost as num).toDouble() * (qty as num).toDouble());
  });

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider.select((s) => s.activeShop?.id), (prev, next) {
      if (prev != next && next != null) _loadData();
    });
    ref.listen<FilterState>(filterProvider, (_, f) => _loadData(from: f.from, to: f.to));
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(context),
      body: Column(children: [
        _buildSummaryCards(),
        const SizedBox(height: 12),
        _buildActionButtons(context),
        const SizedBox(height: 12),
        Expanded(child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _products.isEmpty ? _buildEmptyState() : _buildProductList()),
      ]),
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
      title: Text('Manage Manufactured Products', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      centerTitle: true,
      actions: [
        Padding(padding: const EdgeInsets.only(right: 8), child: IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 20),
          onPressed: _loadData,
        )),
      ],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.divider)),
    );
  }

  Widget _buildSummaryCards() {
    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 8),
        itemCount: 3,
        separatorBuilder: (_, index) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          switch (i) {
            case 0: return _summaryCard('Total Cost Value', _fmt(_totalRawMaterialValue), AppColors.textSecondary, const Color(0xFFF1F5F9), Icons.inventory_2_rounded);
            case 1: return _summaryCard('Manufactured Products', _products.length.toString(), AppColors.primary, const Color(0xFFEBF2FF), Icons.factory_rounded);
            case 2: return _summaryCard('Total Recipes', _recipeCount.toString(), AppColors.success, AppColors.successLight, Icons.receipt_long_rounded);
            default: return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color, Color bgColor, IconData icon) {
    return SizedBox(
      width: 165,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))]),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18)),
          const SizedBox(height: 8),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10)),
          const SizedBox(height: 4),
          SizedBox(height: 18, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
            child: Text(value, style: AppTypography.bodyMedium.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1))),
        ]),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final buttons = <Map<String, dynamic>>[
      {'icon': Icons.layers_rounded, 'label': 'Raw Material', 'color': AppColors.primary, 'onTap': () => context.push('/manufacturing/raw-materials')},
      {'icon': Icons.receipt_long_rounded, 'label': 'Recipe', 'color': AppColors.primary, 'onTap': () => context.push('/manufacturing/recipes')},
      {'icon': Icons.swap_horiz_rounded, 'label': 'Transfer', 'color': AppColors.primary, 'onTap': () => context.push('/manufacturing/transfer')},
      {'icon': Icons.refresh_rounded, 'label': 'Re‑Produce', 'color': AppColors.primary, 'onTap': () => context.push('/manufacturing/reproduce')},
      {'icon': Icons.tune_rounded, 'label': 'Adjust', 'color': AppColors.primary, 'onTap': () => context.push('/manufacturing/adjust')},
      {'icon': Icons.filter_list_rounded, 'label': 'Filter', 'color': AppColors.primary, 'onTap': () => AppFilterDialog.show(context)},
      {'icon': Icons.download_rounded, 'label': 'Download', 'color': AppColors.primary, 'onTap': () => context.push('/manufacturing/reports')},
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
        itemCount: buttons.length + 1,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == buttons.length) return _addProductBtn();
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

  Widget _addProductBtn() {
    return GestureDetector(
      onTap: () => context.push('/manufacturing/add-product'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.add_rounded, size: 14, color: AppColors.textWhite), const SizedBox(width: 6),
          Text('Add Product', style: AppTypography.bodySmall.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w600, fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _buildProductList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      itemCount: _products.length,
      itemBuilder: (ctx, i) => _buildProductCard(_products[i]),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> p) {
    final name = p['product_name'] ?? p['name'] ?? 'Unknown';
    final recipe = p['recipe_name'] ?? p['recipe'] ?? '—';
    final qty = (p['quantity'] ?? p['stock'] ?? 0) as num;
    final unitCost = (p['unit_cost'] ?? p['buying_price'] ?? p['cost_price'] ?? 0) as num;
    final sellingPrice = (p['selling_price'] ?? p['price'] ?? 0) as num;
    final totalValue = unitCost.toDouble() * qty.toDouble();
    final rawStatus = (p['status'] ?? 'In Stock').toString();
    final status = rawStatus.isEmpty ? 'In Stock' : rawStatus;
    final statusColor = _statusColor(status);
    final statusBg = _statusBg(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.factory_rounded, color: AppColors.primary, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name.toString(), style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('Recipe: $recipe', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
            child: Text(status, style: AppTypography.caption.copyWith(color: statusColor, fontWeight: FontWeight.w600, fontSize: 10)),
          ),
        ]),
        const Divider(height: 20),
        Row(children: [
          _infoChip('Qty', qty.toString()),
          const SizedBox(width: 8),
          _infoChip('Unit Cost', _fmt(unitCost.toDouble())),
          const SizedBox(width: 8),
          _infoChip('Selling', _fmt(sellingPrice.toDouble())),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/manufacturing/edit-product', extra: {
              'name': name, 'recipe': recipe, 'quantity': qty.toInt(),
              'unitCost': unitCost.toDouble(), 'sellingPrice': sellingPrice.toDouble(),
              'wholesalePrice': sellingPrice.toDouble() * 0.85, 'alertLevel': 10,
              ...p,
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.edit_rounded, size: 14, color: AppColors.primary), const SizedBox(width: 4),
                Text('Edit', style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 11)),
              ]),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _showDeleteConfirmation(name.toString(), p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.delete_rounded, size: 14, color: AppColors.danger), const SizedBox(width: 4),
                Text('Delete', style: AppTypography.caption.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 11)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Text('Total Value:', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          Text(_fmt(totalValue), style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(6)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.textHint, fontSize: 9)),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXXL, vertical: 60), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 100, height: 100, decoration: BoxDecoration(color: const Color(0xFFEEF2FF), shape: BoxShape.circle),
        child: Icon(Icons.factory_rounded, size: 48, color: AppColors.primary.withValues(alpha: 0.4))),
      const SizedBox(height: 20),
      Text('No Manufactured Products', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text('Tap "Add Product" to get started.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
    ])));
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('low') || s.contains('alert')) return const Color(0xFFF59E0B);
    if (s.contains('expired') || s.contains('out')) return AppColors.danger;
    return AppColors.success;
  }

  Color _statusBg(String status) {
    final s = status.toLowerCase();
    if (s.contains('low') || s.contains('alert')) return const Color(0xFFFEF3C7);
    if (s.contains('expired') || s.contains('out')) return AppColors.dangerLight;
    return AppColors.successLight;
  }

  String _fmt(double v) {
    return 'TZS ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  void _showDeleteConfirmation(String productName, Map<String, dynamic> p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.delete_rounded, color: AppColors.danger, size: 18)),
          const SizedBox(width: 10),
          Text('Delete Product', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
        ]),
        content: Text('Are you sure you want to delete "$productName"? This action cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final api = ref.read(apiServiceProvider);
                await api.postMfProductionDelete({'product_id': p['id'] ?? p['product_id'] ?? ''});
                _loadData();
              } catch (_) {}
            },
            style: TextButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: AppColors.textWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: Text('Delete', style: AppTypography.bodySmall.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
