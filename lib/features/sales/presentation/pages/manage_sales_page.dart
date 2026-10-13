import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dukaapp/features/sales/presentation/widgets/receipt_pdf.dart';
import 'package:dukaapp/features/sales/presentation/widgets/payment_accounts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:dukaapp/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/sales/data/models/sales_models.dart';
import 'package:dukaapp/features/sales/presentation/providers/sales_provider.dart';
import 'package:dukaapp/features/sales/presentation/widgets/sales_summary_card.dart';
import 'package:dukaapp/features/sales/presentation/widgets/sales_action_button.dart';
import 'package:dukaapp/features/sales/presentation/widgets/sales_search_field.dart';
import 'package:dukaapp/features/sales/presentation/widgets/sale_accordion_card.dart';
import 'package:dukaapp/features/sales/presentation/widgets/sales_list_item.dart';
import 'package:dukaapp/features/sales/presentation/widgets/payment_badge.dart';
import 'package:dukaapp/features/sales/presentation/widgets/receipt_widget.dart';
import 'package:dukaapp/shared/dialogs/app_filter_dialog.dart';
import 'package:dukaapp/shared/providers/filter_provider.dart';
import 'package:dukaapp/core/providers.dart';

class ManageSalesPage extends ConsumerStatefulWidget {
  const ManageSalesPage({super.key});

  @override
  ConsumerState<ManageSalesPage> createState() => _ManageSalesPageState();
}

class _ManageSalesPageState extends ConsumerState<ManageSalesPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _viewList = false;
  int? _expandedSaleIndex;
  final Set<int> _selectedSales = {};
  bool _isDeleting = false;

  // Live data loaded from salesProvider
  List<Map<String, dynamic>> _sales = [];
  SalesSummary _summary = SalesSummary.empty;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSales());
  }

  int _ordersCount = 0;
  double _profit = 0;

  Future<void> _loadSales({String? from, String? to}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      debugPrint('[Sales] _loadSales called from=$from to=$to');
      final repo = ref.read(salesRepositoryProvider);

      final sales = await repo.fetchSales(from: from, to: to);
      debugPrint('[Sales] fetchSales returned ${sales.length} records');

      final summary = await repo.fetchSalesSummary(from: from, to: to);
      debugPrint('[Sales] summary: total=${summary.total}');
      final orders = await repo.fetchOrders(from: from, to: to).catchError((_) => <SaleRecord>[]);

      if (!mounted) return;
      setState(() {
        _summary = summary;
        _ordersCount = orders.length;
        _profit = sales.fold<double>(0, (s, r) => s + r.profit);
        _sales = sales.map(_saleRecordToMap).toList();
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('[Sales] _loadSales ERROR: $e\n$st');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Convert [SaleRecord] to the map shape the existing UI expects.
  Map<String, dynamic> _saleRecordToMap(SaleRecord r) {
    PaymentType paymentType;
    switch (r.paymentStatus.toLowerCase()) {
      case 'credit':
        paymentType = PaymentType.credit;
        break;
      case 'pending':
        paymentType = PaymentType.pending;
        break;
      default:
        paymentType = PaymentType.cash;
    }
    return {
      'sale_id': r.saleId,
      'date': r.date,
      'paymentStatus': r.paymentStatus,
      'soldBy': r.soldBy,
      'total': r.total,
      'totalRaw': r.totalRaw,
      'products': r.products
          .map((p) => {
                'name': p.name,
                'quantity': p.quantity,
                'price': p.price,
                'total': p.total,
                'discount': p.discount,
                'product_id': p.productId,
                'stock_id': p.stockId,
              })
          .toList(),
      'paymentMethod': r.paymentMethod,
      'paid': r.paid,
      'discount': r.discount,
      'balance': r.balance,
      'customer': r.customer,
      'paymentType': paymentType,
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSaleExpansion(int index) {
    setState(() {
      _expandedSaleIndex = _expandedSaleIndex == index ? null : index;
    });
  }

  void _toggleSaleSelection(int index) {
    setState(() {
      if (_selectedSales.contains(index)) {
        _selectedSales.remove(index);
      } else {
        _selectedSales.add(index);
      }
    });
  }

  void _deleteSelected() {
    final s = ref.read(stringsProvider);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.deleteSales,
          style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete ${_selectedSales.length} sale(s)?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              s.cancel,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (_isDeleting) return;
              final ids = _selectedSales
                  .where((i) => i < _sales.length)
                  .map((i) => _sales[i]['sale_id'])
                  .where((id) => id != null && id.toString().isNotEmpty)
                  .toList();
              if (ids.isEmpty) {
                setState(() => _selectedSales.clear());
                return;
              }
              setState(() => _isDeleting = true);
              try {
                final repo = ref.read(salesRepositoryProvider);
                // Sales::bulkdelete reads sale_ids as a comma-separated string.
                final res = await repo.bulkDelete({'sale_ids': ids.join(',')});
                final ok = res['status']?.toString() == '1' ||
                    res['status'] == true ||
                    res['status']?.toString() == 'success';
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? s.salesDeleted : (res['message']?.toString() ?? s.deleteFailed)),
                    backgroundColor: ok ? AppColors.success : AppColors.danger,
                  ),
                );
                if (ok) {
                  setState(() => _selectedSales.clear());
                  await _loadSales();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
                  );
                }
              } finally {
                if (mounted) setState(() => _isDeleting = false);
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

  void _deleteSale(int index) {
    final s = ref.read(stringsProvider);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.deleteSale,
          style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete this sale?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              s.cancel,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final saleId = index < _sales.length ? _sales[index]['sale_id']?.toString() : null;
              if (saleId == null || saleId.isEmpty) {
                setState(() => _expandedSaleIndex = null);
                return;
              }
              try {
                final repo = ref.read(salesRepositoryProvider);
                final res = await repo.deleteRecord({'sale_id': saleId});
                final ok = res['status']?.toString() == '1' ||
                    res['status'] == true ||
                    res['status']?.toString() == 'success';
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? s.saleDeleted : (res['message']?.toString() ?? s.deleteFailed)),
                    backgroundColor: ok ? AppColors.success : AppColors.danger,
                  ),
                );
                if (ok) {
                  setState(() => _expandedSaleIndex = null);
                  await _loadSales();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
                  );
                }
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

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    ref.listen<FilterState>(filterProvider, (_, f) => _loadSales(from: f.from, to: f.to));
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
                    const SizedBox(height: 12),
                    SalesSummaryCard(
                      // Same cards as the web Manage Sales page.
                      totalSales: _isLoading ? '...' : '${_summary.currency} ${_fmt(_summary.total)}',
                      totalCredits: _isLoading ? '...' : '${_summary.currency} ${_fmt(_summary.unpaid)}',
                      totalOrders: _isLoading ? 0 : _ordersCount,
                      profit: _isLoading ? '...' : '${_summary.currency} ${_fmt(_profit)}',
                    ),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                    const SizedBox(height: 16),
                    SalesSearchField(
                      controller: _searchController,
                      onChanged: (value) => setState(() {}),
                      onClear: () => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    _buildViewToggle(),
                    const SizedBox(height: 12),
                    if (_viewList)
                      _buildListView()
                    else
                      _buildAccordionView(),
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
            onPressed: () => Navigator.pop(context),
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
        s.manageSales,
        style: AppTypography.h6.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildActionButtons() {
    final s = ref.read(stringsProvider);
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
        children: [
          SalesActionButton(
            icon: Icons.shopping_cart_rounded,
            label: 'Order',
            onTap: () => context.push('/sales/orders'),
          ),
          const SizedBox(width: 10),
          SalesActionButton(
            icon: Icons.people_rounded,
            label: 'Customer',
            onTap: () => context.push('/customers'),
          ),
          const SizedBox(width: 10),
          SalesActionButton(
            icon: Icons.receipt_long_rounded,
            label: 'Invoice',
            onTap: () => context.push('/sales/invoices'),
          ),
          const SizedBox(width: 10),
          SalesActionButton(
            icon: Icons.filter_list_rounded,
            label: 'Filter',
            onTap: () => AppFilterDialog.show(context),
          ),
          const SizedBox(width: 10),
          SalesActionButton(
            icon: Icons.file_download_done_rounded,
            label: s.download,
            onTap: () => context.push('/sales/reports'),
          ),
          const SizedBox(width: 10),
          SalesActionButton(
            icon: Icons.add_rounded,
            label: s.addSale,
            isHighlighted: true,
            onTap: () async {
              await context.push('/sales/add');
              if (mounted) await _loadSales();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    final s = ref.read(stringsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            s.viewList,
            style: AppTypography.caption.copyWith(
              color: _viewList
                  ? AppColors.primary
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 4),
          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: _viewList,
              onChanged: (value) {
                setState(() {
                  _viewList = value;
                  _expandedSaleIndex = null;
                });
              },
              activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
              activeThumbColor: AppColors.primary,
              inactiveTrackColor: AppColors.border,
              inactiveThumbColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccordionView() {
    if (_isLoading) return _buildSkeleton();
    return Column(
      children: [
        if (_selectedSales.isNotEmpty) _buildDeleteBar(),
        ...List.generate(_sales.length, (index) {
          final sale = _sales[index];
          return SaleAccordionCard(
            date: sale['date'],
            paymentStatus: sale['paymentStatus'],
            soldBy: sale['soldBy'],
            total: sale['total'],
            isSelected: _selectedSales.contains(index),
            onSelectionChanged: (_) => _toggleSaleSelection(index),
            isExpanded: _expandedSaleIndex == index,
            onExpandToggle: () => _toggleSaleExpansion(index),
            products: List<Map<String, dynamic>>.from(sale['products']),
            paymentMethod: sale['paymentMethod'],
            paid: sale['paid'],
            discount: sale['discount'],
            balance: sale['balance'],
            onDownload: () => _downloadReceiptPdf(sale),
            onBackdate: () => _showBackdateDialog(index),
            onPrint: () => _showReceiptPreview(sale),
            onPreview: () => _showReceiptPreview(sale),
            onEdit: () async {
              await context.push('/sales/add', extra: sale);
              if (mounted) {
                setState(() => _expandedSaleIndex = null);
                await _loadSales();
              }
            },
            onDelete: () => _deleteSale(index),
            // Show Pay button only for unpaid/credit sales
            onPay: _toD(sale['balance']) > 0.01
                ? () => _showPayDialog(index)
                : null,
          );
        }),
      ],
    );
  }

  /// Payment dialog for credit / unpaid sales.
  Future<void> _showPayDialog(int index) async {
    final accounts = await loadPaymentAccounts(ref);
    if (!mounted) return;
    final s = ref.read(stringsProvider);
    final sale = _sales[index];
    final balance = _toD(sale['balance']);
    final saleId = sale['sale_id']?.toString() ?? '';
    final amountController = TextEditingController(text: balance.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();
    // Real shop accounts (same as selling); the account_id is what the server books.
    String? selectedPaymentMode = defaultPaymentAccountId(accounts);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Pay Credit Balance',
            style: AppTypography.h6.copyWith(color: AppColors.textPrimary)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Balance: TZS ${balance.toStringAsFixed(0)}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: s.amountPaid,
                  prefixText: 'TZS ',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final d = double.tryParse(v ?? '');
                  if (d == null || d <= 0) return 'Enter valid amount';
                  if (d > balance) return s.exceedsBalance;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedPaymentMode,
                decoration: const InputDecoration(
                  labelText: 'Payment Mode',
                  border: OutlineInputBorder(),
                ),
                items: accounts
                    .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedPaymentMode = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              try {
                final repo = ref.read(salesRepositoryProvider);
                final res = await repo.addPayment({
                  'sale_id': saleId,
                  'amount': amountController.text.trim(),
                  if (selectedPaymentMode != null) 'payment_mode': selectedPaymentMode,
                });
                final ok = res['status']?.toString() == '1' ||
                    res['status'] == true ||
                    res['status']?.toString() == 'success';
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'Payment recorded' : (res['message']?.toString() ?? 'Payment failed')),
                  backgroundColor: ok ? AppColors.success : AppColors.danger,
                ));
                if (ok) await _loadSales();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger));
                }
              }
            },
            child: Text(s.pay, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildDeleteBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedSales.length} Selected',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _deleteSelected,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3),
                  width: 1,
                ),
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
                    'Delete',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    if (_isLoading) return _buildSkeleton();
    return Column(
      children: [
        ...List.generate(_sales.length, (index) {
          final sale = _sales[index];
          final products = List<Map<String, dynamic>>.from(sale['products']);
          final firstProduct = products.isNotEmpty ? products.first : {};
          return Column(
            children: [
              SalesListItem(
                productName: firstProduct['name'] ?? 'Sale',
                quantity: products.fold<int>(
                  0,
                  (sum, p) => sum + (p['quantity'] as int),
                ),
                price: sale['totalRaw'],
                customer: sale['customer'],
                paymentType: sale['paymentType'],
                soldBy: sale['soldBy'],
                date: _receiptDate(sale['date']),
                total: sale['total'],
              ),
              if (index < _sales.length - 1)
                Divider(
                  height: 1,
                  indent: 44,
                  endIndent: 20,
                  color: AppColors.divider,
                ),
            ],
          );
        }),
      ],
    );
  }

  /// Skeleton loading cards shown while sales are being fetched.
  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Column(
        children: List.generate(6, (i) => _SkeletonCard(key: ValueKey(i))),
      ),
    );
  }

  void _showBackdateDialog(int orderIndex) async {
    final s = ref.read(stringsProvider);
    final sale = _sales[orderIndex];
    final dateStr = sale['date'] as String;
    final parts = dateStr.split(' ');
    DateTime parsedDate;
    try {
      parsedDate = DateFormat('MMM dd, yyyy').parse('${parts[0]} ${parts[1]} ${parts[2]}');
    } catch (_) {
      parsedDate = DateTime.now();
    }

    DateTime selectedDate = parsedDate;

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          ),
          title: Text(
            s.backdateSale,
            style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.selectNewDateForSale,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
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
                  if (date != null) {
                    setDialogState(() => selectedDate = date);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
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
                      Text(
                        DateFormat('MMM dd, yyyy').format(selectedDate),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
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
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      s.cancel,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, selectedDate),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      s.backdate,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (picked != null && mounted) {
      final saleId = orderIndex < _sales.length
          ? _sales[orderIndex]['sale_id']?.toString()
          : null;
      if (saleId != null && saleId.isNotEmpty) {
        try {
          final repo = ref.read(salesRepositoryProvider);
          final res = await repo.backdate({
            'sale_id': saleId,
            'date': DateFormat('yyyy-MM-dd').format(picked),
          });
          final ok = res['status']?.toString() == '1' || res['status'] == true;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(ok ? s.saleDateUpdated : (res['message']?.toString() ?? 'Backdate failed')),
              backgroundColor: ok ? AppColors.success : AppColors.danger,
            ));
            if (ok) await _loadSales();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
            );
          }
        }
      }
    }
  }

  /// Safely parse any value (double, int, String) to double.
  double _toD(dynamic v) => v is double ? v : double.tryParse(v?.toString() ?? '') ?? 0.0;

  String _fmt(double v) => v == v.roundToDouble()
      ? v.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')
      : v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');

  Future<void> _downloadReceiptPdf(Map<String, dynamic> sale) async {
    try {
      final shopName = ref.read(authProvider).activeShop?.shopName ?? 'My Shop';
      final products = List<Map<String, dynamic>>.from(sale['products']);
      final receiptNo = _receiptNo(sale);
      final cfg = ref.read(shopConfigProvider).valueOrNull;
      final totalAmount = _toD(sale['totalRaw'] ?? sale['total']);
      final dateParts = (sale['date'] ?? '').toString().split(' ');
      // Same layout as the on-screen ReceiptWidget.
      final bytes = await buildReceiptPdf(
        shopName: shopName,
        shopAddress: cfg?.shopAddress ?? '',
        shopPhone: cfg?.shopPhone ?? '',
        shopTin: cfg?.shopTin ?? '',
        title: 'Sales Receipt',
        receiptNumber: receiptNo,
        date: _receiptDate(sale['date']),
        time: dateParts.isNotEmpty ? dateParts.last : '',
        customerName: sale['customer']?.toString(),
        cashier: (sale['soldBy'] ?? '').toString(),
        paymentMode: (sale['paymentMethod'] ?? '').toString(),
        items: products,
        subtotal: totalAmount + _toD(sale['discount']),
        discount: _toD(sale['discount']),
        totalPaid: _toD(sale['paid']),
        amountReceived: _toD(sale['paid']),
        message: cfg?.receiptMessage ?? '',
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/receipt_$receiptNo.pdf');
      await file.writeAsBytes(bytes);
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  // Real sale id instead of a random timestamp number.
  String _receiptNo(Map<String, dynamic> sale) {
    final id = (sale['invoice_no'] ?? sale['sale_id'] ?? '').toString();
    return id.isEmpty ? 'RCP' : 'RCP-$id';
  }

  // Backend date is "Oct 11, 2026 14:30": keep month, day and year.
  String _receiptDate(dynamic date) {
    final parts = (date ?? '').toString().split(' ');
    return parts.length > 3 ? parts.take(3).join(' ') : parts.join(' ');
  }

  void _showReceiptPreview(Map<String, dynamic> sale) {
    final products = List<Map<String, dynamic>>.from(sale['products']);
    final totalAmount = _toD(sale['totalRaw'] ?? sale['total']);

    ReceiptWidget.show(
      context,
      title: 'Sales Receipt',
      receiptNumber: _receiptNo(sale),
      date: _receiptDate(sale['date']),
      time: sale['date'].split(' ').last,
      cashier: sale['soldBy'],
      paymentMode: sale['paymentMethod'],
      items: products,
      // Subtotal is before discount; totalAmount (sales.total_amount) is after it.
      subtotal: totalAmount + _toD(sale['discount']),
      totalPaid: _toD(sale['paid']),
      amountReceived: _toD(sale['paid']),
      discount: _toD(sale['discount']),
      customerName: sale['customer']?.toString(),
    );
  }
}

// ── Skeleton card ─────────────────────────────────────────────────────────────

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard({super.key});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _child) {
        final base = Color.lerp(
          const Color(0xFFE0E0E0),
          const Color(0xFFF5F5F5),
          _anim.value,
        )!;
        final highlight = Color.lerp(
          const Color(0xFFEEEEEE),
          const Color(0xFFFAFAFA),
          _anim.value,
        )!;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Row(
            children: [
              // Left colour stripe
              Container(
                width: 4,
                height: 52,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bone(highlight, width: 120, height: 13),
                    const SizedBox(height: 8),
                    _bone(highlight, width: 80, height: 10),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _bone(highlight, width: 70, height: 13),
                  const SizedBox(height: 8),
                  _bone(highlight, width: 50, height: 10),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bone(Color color, {required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
