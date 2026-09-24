// features/stock/presentation/pages/manage_stock_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/stock/data/models/stock_models.dart';
import 'package:dukaapp/features/stock/presentation/providers/stock_provider.dart';
import 'package:dukaapp/features/stock/presentation/widgets/stock_status_chip.dart';
import 'package:dukaapp/features/stock/presentation/widgets/stock_summary_card.dart';
import 'package:dukaapp/features/stock/presentation/widgets/stock_action_button.dart';
import 'package:dukaapp/features/stock/presentation/widgets/stock_search_field.dart';
import 'package:dukaapp/features/stock/presentation/widgets/stock_category_switch.dart';
import 'package:dukaapp/features/stock/presentation/widgets/stock_select_bar.dart';
import 'package:dukaapp/features/stock/presentation/widgets/stock_product_card.dart';
import 'package:dukaapp/features/stock/presentation/widgets/stock_categories_grid.dart';
import 'package:dukaapp/features/stock/presentation/pages/import_stock_page.dart';
import 'package:dukaapp/features/stock/presentation/widgets/product_reports_helper.dart';
import 'package:dukaapp/shared/dialogs/app_filter_dialog.dart';
import 'package:dukaapp/shared/providers/filter_provider.dart';
import 'package:dukaapp/core/providers.dart';

class ManageStockPage extends ConsumerStatefulWidget {
  const ManageStockPage({super.key});

  @override
  ConsumerState<ManageStockPage> createState() => _ManageStockPageState();
}

class _ManageStockPageState extends ConsumerState<ManageStockPage> {
  bool _categoryMode = false;
  final TextEditingController _searchController = TextEditingController();
  final Set<dynamic> _selectedIds = {};
  dynamic _expandedProductId;

  /// Active filter pill: 'all' | 'out_of_stock' | 'to_expire' | 'expired' | 'low_stock'
  String _activeFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Filtering ────────────────────────────────────────────────────────────

  List<StockProduct> _filtered(List<StockProduct> products) {
    // 1. Apply status-pill filter first.
    List<StockProduct> result;
    switch (_activeFilter) {
      case 'out_of_stock':
        result = products.where((p) => p.isOutOfStock).toList();
        break;
      case 'low_stock':
        result =
            products.where((p) => p.isLowStock && !p.isOutOfStock).toList();
        break;
      // 'to_expire' and 'expired' require expiry data from the API.
      // For now return an empty list so the pill clearly shows 0.
      case 'to_expire':
      case 'expired':
        result = [];
        break;
      default: // 'all'
        result = products;
    }

    // 2. Then apply the search query on top.
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return result;
    return result
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            (p.category?.toLowerCase().contains(q) ?? false) ||
            (p.barcode?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  // ── Selection ────────────────────────────────────────────────────────────

  bool _allSelected(List<StockProduct> products) =>
      products.isNotEmpty && _selectedIds.length == products.length;

  void _toggleSelection(dynamic id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleAllSelection(List<StockProduct> products) {
    setState(() {
      if (_allSelected(products)) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(products.map((p) => p.productId));
      }
    });
  }

  void _toggleExpansion(dynamic id) {
    setState(() {
      _expandedProductId = _expandedProductId == id ? null : id;
    });
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  void _deleteSelected(List<StockProduct> products) {
    final s = ref.read(stringsProvider);
    final count = _selectedIds.length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.deleteProducts,
          style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete $count product(s)?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              s.cancel,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final ids = _selectedIds.toList();
              try {
                final repo = ref.read(stockRepositoryProvider);
                await repo.bulkDeleteProducts(ids);
                if (!mounted) return;
                setState(() => _selectedIds.clear());
                ref.read(stockProvider.notifier).refresh();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Products deleted')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete failed: $e')),
                );
              }
            },
            child: Text(
              s.delete,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(StockProduct product) {
    final s = ref.read(stringsProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        ),
        title: Text(
          'Delete Product',
          style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${product.name}"?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              s.cancel,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final repo = ref.read(stockRepositoryProvider);
                await repo.bulkDeleteProducts([product.productId]);
                if (!mounted) return;
                ref.read(stockProvider.notifier).refresh();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${product.name} deleted')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete failed: $e')),
                );
              }
            },
            child: Text(
              s.delete,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCategory(String categoryName, List<StockProduct> products) {
    context.push(
      '/stock/manage/category',
      extra: {
        'categoryName': categoryName,
        'products': products
            .where((p) => p.category == categoryName)
            .map((p) => {
                  'name': p.name,
                  'category': p.category,
                  'buyingPrice': p.buyingPrice,
                  'sellingPrice': p.sellingPrice,
                  'stock': p.available,
                  'product_id': p.productId,
                  'imageUrl': p.imageUrl,
                  'type': p.type,
                })
            .toList(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    // Reload stock when global date filter changes
    ref.listen<FilterState>(filterProvider, (_, __) {
      ref.read(stockProvider.notifier).refresh();
    });
    final stockAsync = ref.watch(stockProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(stockAsync.isLoading),
      body: SafeArea(
        top: false,
        child: stockAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _buildError(e),
          data: (stock) {
            final products = _filtered(stock.products);
            return Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => ref.read(stockProvider.notifier).refresh(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          _buildStatusChips(stock),
                          const SizedBox(height: 16),
                          _buildSummaryCard(stock),
                          const SizedBox(height: 16),
                          _buildActionButtons(),
                          const SizedBox(height: 16),
                          StockSearchField(
                            controller: _searchController,
                            onChanged: (value) => setState(() {}),
                            onClear: () => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          StockCategorySwitch(
                            value: _categoryMode,
                            onChanged: (value) {
                              setState(() {
                                _categoryMode = value;
                                _selectedIds.clear();
                                _expandedProductId = null;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          if (!_categoryMode) ...[
                            StockSelectBar(
                              isAllSelected: _allSelected(products),
                              onToggleAll: (_) =>
                                  _toggleAllSelection(products),
                              selectedCount: _selectedIds.length,
                              onDeleteAll: () =>
                                  _deleteSelected(products),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (_categoryMode)
                            StockCategoriesGrid(
                              products: products
                                  .map((p) => {
                                        'name': p.name,
                                        'category': p.category ?? '',
                                        'buyingPrice': p.buyingPrice,
                                        'sellingPrice': p.sellingPrice,
                                        'stock': p.available,
                                      })
                                  .toList(),
                              onCategoryTap: (cat) =>
                                  _navigateToCategory(cat, stock.products),
                            )
                          else
                            _buildProductList(products),
                          SizedBox(height: 24 + bottomPadding),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Builders ─────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(bool isLoading) {
    final s = ref.read(stringsProvider);
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
      title: Text(
        s.manageStock,
        style: AppTypography.h6.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      actions: [
        if (isLoading)
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusChips(StockState stock) {
    final s = ref.read(stringsProvider);
    final all = stock.products.length;
    final outOfStock =
        stock.products.where((p) => p.isOutOfStock).length;
    final lowStock =
        stock.products.where((p) => p.isLowStock && !p.isOutOfStock).length;

    void select(String filter) => setState(() {
          _activeFilter = filter;
          _selectedIds.clear();
          _expandedProductId = null;
        });

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
        children: [
          StockStatusChip(
            icon: Icons.inventory_2_rounded,
            count: all,
            label: s.all,
            color: AppColors.textSecondary,
            backgroundColor: AppColors.background,
            isSelected: _activeFilter == 'all',
            onTap: () => select('all'),
          ),
          const SizedBox(width: 8),
          StockStatusChip(
            icon: Icons.remove_shopping_cart_rounded,
            count: outOfStock,
            label: s.outOfStock,
            color: AppColors.danger,
            backgroundColor: AppColors.dangerLight,
            isSelected: _activeFilter == 'out_of_stock',
            onTap: () => select('out_of_stock'),
          ),
          const SizedBox(width: 8),
          StockStatusChip(
            icon: Icons.schedule_rounded,
            count: 0,
            label: s.toExpire,
            color: const Color(0xFFFF9800),
            backgroundColor: const Color(0xFFFFF3E0),
            isSelected: _activeFilter == 'to_expire',
            onTap: () => select('to_expire'),
          ),
          const SizedBox(width: 8),
          StockStatusChip(
            icon: Icons.event_busy_rounded,
            count: 0,
            label: 'Expired',
            color: const Color(0xFFE64A19),
            backgroundColor: const Color(0xFFFBE9E7),
            isSelected: _activeFilter == 'expired',
            onTap: () => select('expired'),
          ),
          const SizedBox(width: 8),
          StockStatusChip(
            icon: Icons.trending_down_rounded,
            count: lowStock,
            label: s.runningLow,
            color: AppColors.primary,
            backgroundColor: const Color(0xFFE3F2FD),
            isSelected: _activeFilter == 'low_stock',
            onTap: () => select('low_stock'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(StockState stock) {
    final s = stock.summary;
    final currency = s.currency;
    final stockValue =
        '$currency ${_fmt(s.stockValue)}';

    // Estimate profit from individual product margins
    double profitEstimate = 0;
    for (final p in stock.products) {
      final margin = p.sellingPrice - p.buyingPrice;
      if (margin > 0) profitEstimate += margin * p.available;
    }
    final profitStr = '$currency ${_fmt(profitEstimate)}';

    return StockSummaryCard(
      totalStockValue: stockValue,
      profitEstimate: profitStr,
      allProducts: s.itemsCount > 0 ? s.itemsCount : stock.products.length,
    );
  }

  Widget _buildActionButtons() {
    final s = ref.read(stringsProvider);
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
        children: [
          StockActionButton(
            icon: Icons.file_download_rounded,
            label: s.importStock,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => const ImportStockPage(),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          StockActionButton(
            icon: Icons.transfer_within_a_station_rounded,
            label: s.importFromShop,
            onTap: () => context.push('/stock/manage/import-from-shop'),
          ),
          const SizedBox(width: 10),
          StockActionButton(
            icon: Icons.shopping_cart_rounded,
            label: 'Purchase',
            onTap: () => context.push('/stock/manage/purchase'),
          ),
          const SizedBox(width: 10),
          StockActionButton(
            icon: Icons.swap_horiz_rounded,
            label: 'Transfer',
            onTap: () => context.push('/transfer'),
          ),
          const SizedBox(width: 10),
          StockActionButton(
            icon: Icons.tune_rounded,
            label: 'Adjust',
            onTap: () => context.push('/adjust'),
          ),
          const SizedBox(width: 10),
          StockActionButton(
            icon: Icons.filter_list_rounded,
            label: 'Filter',
            onTap: () => AppFilterDialog.show(context),
          ),
          const SizedBox(width: 10),
          StockActionButton(
            icon: Icons.file_download_done_rounded,
            label: 'Download',
            onTap: () => context.push('/stock-reports'),
          ),
          const SizedBox(width: 10),
          StockActionButton(
            icon: Icons.add_rounded,
            label: 'Add Product',
            isHighlighted: true,
            onTap: () => context.push('/stock/manage/add'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List<StockProduct> products) {
    return Column(
      children: products.map((product) {
        final id = product.productId;
        return StockProductCard(
          productName: product.name,
          category: product.category ?? '',
          buyingPrice: product.buyingPrice,
          sellingPrice: product.sellingPrice,
          currentStock: product.available.toInt(),
          type: product.type,
          imageUrl: product.imageUrl,
          isSelected: _selectedIds.contains(id),
          onSelectionChanged: (_) => _toggleSelection(id),
          isExpanded: _expandedProductId == id,
          onExpandToggle: () => _toggleExpansion(id),
          onEdit: () => context.push('/stock/manage/add', extra: {
            'product_id': product.productId,
            'stock_id': product.stockId,
            'name': product.name,
            'category': product.category,
            'buyingPrice': product.buyingPrice,
            'sellingPrice': product.sellingPrice,
            'wholesalePrice': product.wholesalePrice,
            'stock': product.available,
            'reorderLevel': product.reorderLevel,
            'barcode': product.barcode,
            'unit': product.unit,
            'imageUrl': product.imageUrl,
            'type': product.type,
          }),
          onHistory: () => ProductReportsHelper.exportHistoryPdf(
            context: context,
            ref: ref,
            productName: product.name,
            productId: product.productId?.toString() ?? '',
          ),
          onStockPdf: () => ProductReportsHelper.exportStockPdf(
            context: context,
            ref: ref,
            productName: product.name,
            productId: product.productId?.toString() ?? '',
            buyingPrice: product.buyingPrice,
          ),
          onSalesPdf: () => ProductReportsHelper.exportSalesPdf(
            context: context,
            ref: ref,
            productName: product.name,
            productId: product.productId?.toString() ?? '',
            sellingPrice: product.sellingPrice,
          ),
          onPhotos: () => ProductReportsHelper.showPhotosDialog(
            context: context,
            productName: product.name,
          ),
          onRestock: () =>
              context.push('/stock/manage/purchase', extra: {
                'initialProduct': {
                  'name': product.name,
                  'product_id': product.productId,
                  'category': product.category,
                  'buyingPrice': product.buyingPrice,
                  'sellingPrice': product.sellingPrice,
                  'wholesalePrice': product.wholesalePrice,
                  'stock': product.available,
                },
              }),
          onAdjust: () => context.push('/adjust'),
          onDelete: () => _deleteProduct(product),
        );
      }).toList(),
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Imeshindwa kupakia stock',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.read(stockProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Jaribu tena'),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}
