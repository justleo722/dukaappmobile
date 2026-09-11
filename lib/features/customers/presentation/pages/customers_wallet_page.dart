import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/customers/data/models/customer_model.dart';
import 'package:dukaapp/features/customers/presentation/providers/customer_provider.dart';
import 'package:dukaapp/features/customers/presentation/widgets/add_cash_dialog.dart';
import 'package:dukaapp/features/customers/presentation/widgets/clear_wallet_dialog.dart';

class _CustomerWallet {
  final Customer customer;
  final double walletBalance;

  const _CustomerWallet({
    required this.customer,
    required this.walletBalance,
  });
}

class CustomersWalletPage extends ConsumerStatefulWidget {
  const CustomersWalletPage({super.key});

  @override
  ConsumerState<CustomersWalletPage> createState() => _CustomersWalletPageState();
}

class _CustomersWalletPageState extends ConsumerState<CustomersWalletPage> {
  final TextEditingController _searchController = TextEditingController();
  List<_CustomerWallet> _wallets = [];
  List<_CustomerWallet> _filteredWallets = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWallets());
  }

  Future<void> _loadWallets() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(customerRepositoryProvider);
      final customers = await repo.fetchCustomers();
      if (!mounted) return;
      final wallets = customers
          .where((c) => c.creditBalance > 0 || c.totalSpent > 0)
          .map((c) => _CustomerWallet(customer: c, walletBalance: c.creditBalance))
          .toList();
      setState(() {
        _wallets = wallets;
        _filteredWallets = List.from(wallets);
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

  double get _totalWalletBalance {
    return _wallets.fold(0, (sum, w) => sum + w.walletBalance);
  }

  int get _customersWithBalance {
    return _wallets.where((w) => w.walletBalance > 0).length;
  }

  void _filterWallets(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredWallets = List.from(_wallets);
      } else {
        _filteredWallets = _wallets
            .where((w) =>
                w.customer.name.toLowerCase().contains(query.toLowerCase()) ||
                w.customer.phone.contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildSummarySection(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredWallets.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.only(
                      top: 4,
                      bottom: 24 + bottomPadding,
                    ),
                    itemCount: _filteredWallets.length,
                    itemBuilder: (context, index) {
                      final wallet = _filteredWallets[index];
                      return _buildWalletCard(wallet);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
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
        'Customers Wallet',
        style: AppTypography.h6.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
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
          onChanged: _filterWallets,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search name or phone...',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.textHint,
                      size: 18,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _filterWallets('');
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

  Widget _buildSummarySection() {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingLG,
        0,
        AppConstants.paddingLG,
        AppConstants.paddingMD,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Wallet Balance',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textWhite.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'TZS ${_totalWalletBalance.toStringAsFixed(0)}',
                    style: AppTypography.h5.copyWith(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: AppColors.textWhite.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Customers with balance',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textWhite.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_customersWithBalance / ${_wallets.length}',
                  style: AppTypography.h5.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard(_CustomerWallet wallet) {
    final hasBalance = wallet.walletBalance > 0;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLG,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
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
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hasBalance
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.textHint.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: hasBalance ? AppColors.success : AppColors.textHint,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wallet.customer.name,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        wallet.customer.phone,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'TZS ${wallet.walletBalance.toStringAsFixed(0)}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: hasBalance ? AppColors.success : AppColors.textHint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildActionButton(
                  icon: Icons.visibility_rounded,
                  label: 'View',
                  color: AppColors.primary,
                  onTap: () => context.push(
                    '/customers/${wallet.customer.id}/dashboard',
                    extra: wallet.customer,
                  ),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.receipt_long_rounded,
                  label: 'Statement',
                  color: AppColors.secondary,
                  onTap: () => _showComingSoon('Statement'),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Add Cash',
                  color: AppColors.success,
                  onTap: () => _showAddCashDialog(wallet.customer),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.clear_all_rounded,
                  label: 'Clear',
                  color: AppColors.danger,
                  onTap: () => _showClearWalletDialog(wallet),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 9,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
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
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 40,
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No customers found',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different search',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature coming soon',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
        ),
      ),
    );
  }

  void _showAddCashDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AddCashDialog(customer: customer),
    );
  }

  void _showClearWalletDialog(_CustomerWallet wallet) {
    showDialog(
      context: context,
      builder: (context) => ClearWalletDialog(
        customer: wallet.customer,
        walletBalance: wallet.walletBalance,
      ),
    );
  }
}
