// features/suppliers/presentation/pages/suppliers_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/suppliers/data/models/supplier_model.dart';
import 'package:dukaapp/features/suppliers/presentation/providers/supplier_provider.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/shared/dialogs/app_filter_dialog.dart';
import 'package:dukaapp/features/suppliers/presentation/pages/credit_purchases_page.dart';
import 'package:dukaapp/features/suppliers/presentation/pages/cash_purchases_page.dart';

class SuppliersPage extends ConsumerStatefulWidget {
  const SuppliersPage({super.key});

  @override
  ConsumerState<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends ConsumerState<SuppliersPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Supplier> _suppliers = [];
  List<Supplier> _filteredSuppliers = [];
  final Set<String> _selectedSupplierIds = {};
  bool _isLoading = false;

  bool get _selectAll =>
      _filteredSuppliers.isNotEmpty &&
      _filteredSuppliers.every((s) => _selectedSupplierIds.contains(s.id));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSuppliers());
  }

  Future<void> _loadSuppliers() async {
    if (!mounted) return;
    // Serve cache immediately
    final cache = ref.read(localCacheProvider);
    final cached = await cache.loadList('suppliers', 'list');
    if (mounted && cached.isNotEmpty) {
      final list = cached.map(Supplier.fromJson).toList();
      setState(() { _suppliers = list; _filteredSuppliers = List.from(list); });
    } else {
      setState(() => _isLoading = true);
    }
    // Fetch fresh from API
    try {
      final repo = ref.read(supplierRepositoryProvider);
      final list = await repo.fetchSuppliers();
      if (!mounted) return;
      cache.save('suppliers', 'list', list.map((s) => s.toJson()).toList());
      setState(() {
        _suppliers = list;
        _filteredSuppliers = List.from(list);
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterSuppliers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSuppliers = List.from(_suppliers);
      } else {
        _filteredSuppliers = _suppliers
            .where((s) =>
                s.name.toLowerCase().contains(query.toLowerCase()) ||
                s.phone.contains(query))
            .toList();
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectAll) {
        for (final s in _filteredSuppliers) {
          _selectedSupplierIds.remove(s.id);
        }
      } else {
        for (final s in _filteredSuppliers) {
          _selectedSupplierIds.add(s.id);
        }
      }
    });
  }

  void _toggleSupplierSelection(String id) {
    setState(() {
      if (_selectedSupplierIds.contains(id)) {
        _selectedSupplierIds.remove(id);
      } else {
        _selectedSupplierIds.add(id);
      }
    });
  }

  Future<void> _deleteSupplier(Supplier supplier) async {
    try {
      final repo = ref.read(supplierRepositoryProvider);
      await repo.bulkDeleteSuppliers([supplier.id]);
      if (!mounted) return;
      setState(() {
        _suppliers.removeWhere((s) => s.id == supplier.id);
        _filteredSuppliers.removeWhere((s) => s.id == supplier.id);
        _selectedSupplierIds.remove(supplier.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${supplier.name} removed',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildActionButtons(),
          // On-Credit/On-Cash now open dedicated pages.
          _buildSearchBar(),
          _buildSelectAllRow(),
          Expanded(
            child: _filteredSuppliers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.only(
                      top: 4,
                      bottom: 24 + bottomPadding,
                    ),
                    itemCount: _filteredSuppliers.length,
                    itemBuilder: (context, index) {
                      final supplier = _filteredSuppliers[index];
                      return _buildSupplierCard(supplier);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
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
      title: Column(
        children: [
          Text(
            s.supplierManagement,
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _selectedSupplierIds.isEmpty
                ? '${_filteredSuppliers.length} suppliers'
                : '${_selectedSupplierIds.length} selected',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppColors.divider,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final s = ref.read(stringsProvider);
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.symmetric(
        vertical: AppConstants.paddingSM,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLG,
        ),
        child: Row(
          children: [
            _buildActionChip(
              icon: Icons.credit_card_rounded,
              label: s.onCredit,
              color: AppColors.warning,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreditPurchasesPage(),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            _buildActionChip(
              icon: Icons.payments_rounded,
              label: s.onCash,
              color: AppColors.success,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CashPurchasesPage(),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            _buildActionChip(
              icon: Icons.filter_list_rounded,
              label: 'Filter',
              color: AppColors.secondary,
              onTap: () => AppFilterDialog.show(context),
            ),
            const SizedBox(width: 8),
            _buildActionChip(
              icon: Icons.person_add_rounded,
              label: s.newSupplier,
              color: AppColors.primary,
              onTap: () => context.push('/suppliers/add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppConstants.radiusSM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingLG,
        4,
        AppConstants.paddingLG,
        AppConstants.paddingMD,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _filterSuppliers,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search supplier by name or phone...',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textHint,
                      size: 18,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _filterSuppliers('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMD,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectAllRow() {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLG,
        vertical: AppConstants.paddingSM,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _selectAll,
              onChanged: (_) => _toggleSelectAll(),
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: const BorderSide(
                color: AppColors.border,
                width: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Select All Suppliers',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (_selectedSupplierIds.isNotEmpty)
            Material(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              child: InkWell(
                onTap: _showDeleteSelectedConfirmation,
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.delete_rounded,
                        color: AppColors.danger,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Delete (${_selectedSupplierIds.length})',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSupplierCard(Supplier supplier) {
    final s = ref.read(stringsProvider);
    final isSelected = _selectedSupplierIds.contains(supplier.id);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLG,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleSupplierSelection(supplier.id),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business_rounded,
                    color: AppColors.secondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supplier.name,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        supplier.phone,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              icon: Icons.email_outlined,
              label: supplier.email ?? s.notSet,
            ),
            const SizedBox(height: 4),
            _buildInfoRow(
              icon: Icons.business_center_outlined,
              label: supplier.companyName ?? s.notSet,
            ),
            const SizedBox(height: 4),
            _buildInfoRow(
              icon: Icons.location_on_outlined,
              label: supplier.address ?? s.notSet,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton(
                  icon: Icons.visibility_rounded,
                  color: AppColors.primary,
                  onTap: () => context.push(
                    '/suppliers/${supplier.id}/dashboard',
                    extra: supplier,
                  ),
                ),
                const SizedBox(width: 6),
                _buildActionButton(
                  icon: Icons.edit_rounded,
                  color: AppColors.success,
                  onTap: () => context.push('/suppliers/add', extra: supplier),
                ),
                const SizedBox(width: 6),
                _buildActionButton(
                  icon: Icons.delete_rounded,
                  color: AppColors.danger,
                  onTap: () => _showDeleteConfirmation(supplier),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textHint, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }

  // _buildPurchasesAccordion was removed — purchases now open in dedicated pages

  // Sample purchases helper removed — purchases are shown on dedicated pages.

  

  void _showDeleteConfirmation(Supplier supplier) {
    final s = ref.read(stringsProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        ),
        title: Text(
          s.deleteSupplier,
          style: AppTypography.h6.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to remove ${supplier.name}? This action cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              s.cancel,
              style: AppTypography.buttonMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSupplier(supplier);
            },
            child: Text(
              s.delete,
              style: AppTypography.buttonMedium.copyWith(
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteSelectedConfirmation() {
    final s = ref.read(stringsProvider);
    final count = _selectedSupplierIds.length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        ),
        title: Text(
          'Delete $count Supplier${count > 1 ? 's' : ''}',
          style: AppTypography.h6.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to remove $count selected supplier${count > 1 ? 's' : ''}? This action cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              s.cancel,
              style: AppTypography.buttonMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSelectedSuppliers();
            },
            child: Text(
              s.delete,
              style: AppTypography.buttonMedium.copyWith(
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteSelectedSuppliers() {
    final count = _selectedSupplierIds.length;
    setState(() {
      _suppliers.removeWhere((s) => _selectedSupplierIds.contains(s.id));
      _filteredSuppliers.removeWhere((s) => _selectedSupplierIds.contains(s.id));
      _selectedSupplierIds.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$count supplier${count > 1 ? 's' : ''} removed',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite),
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.business_outlined,
              size: 40,
              color: AppColors.secondary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No suppliers found',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different search or add a new supplier',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
