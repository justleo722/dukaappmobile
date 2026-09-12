import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/features/sales/data/models/sales_models.dart';
import 'package:dukaapp/features/sales/presentation/providers/sales_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/sales/presentation/widgets/sales_action_button.dart';
import 'package:dukaapp/features/sales/presentation/widgets/sale_product_tile.dart';
import 'package:dukaapp/features/sales/presentation/widgets/payment_summary_card.dart';
import 'package:dukaapp/features/sales/presentation/widgets/sales_bottom_actions.dart';
import 'package:dukaapp/shared/dialogs/app_filter_dialog.dart';
import 'package:dukaapp/shared/providers/filter_provider.dart';
import 'package:dukaapp/features/auth/presentation/controllers/auth_controller.dart';

class InvoicesPage extends ConsumerStatefulWidget {
  const InvoicesPage({super.key});

  @override
  ConsumerState<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends ConsumerState<InvoicesPage> {

  String get _shopName =>
      ref.read(authProvider).activeShop?.shopName ?? 'My Shop';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _expandedIndex;
  final Set<int> _selectedInvoices = {};

  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = false;
  InvoiceSummary _invoiceSummary = InvoiceSummary.empty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInvoices());
  }

  Future<void> _loadInvoices({String? from, String? to}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(salesRepositoryProvider);
      final results = await Future.wait([
        repo.fetchInvoices(from: from, to: to),
        repo.fetchInvoiceSummary(from: from, to: to),
      ]);
      if (!mounted) return;
      final records = results[0] as List<SaleRecord>;
      setState(() {
        _invoiceSummary = results[1] as InvoiceSummary;
        _invoices = records.map((r) => {
          'sale_id': r.saleId,
          'date': r.date,
          'customer': r.customer,
          'invoiceNo': r.invoiceNo ?? '',
          'paymentMethod': r.paymentMethod,
          'paid': r.paid,
          'balance': r.balance,
          'total': r.totalRaw,
          'status': r.balance > 0.01 ? 'UNPAID' : 'PAID',
          'soldBy': r.soldBy,
          'products': r.products.map((p) => {
            'name': p.name,
            'quantity': p.quantity,
            'price': p.price,
            'total': p.total,
          }).toList(),
        }).toList();
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

  double get _paidTotal {
    double total = 0;
    for (final inv in _invoices) {
      if (inv['status'] == 'PAID') {
        total += (inv['paid'] as double);
      }
    }
    return total;
  }

  double get _unpaidTotal {
    double total = 0;
    for (final inv in _invoices) {
      total += inv['balance'] as double;
    }
    return total;
  }

  List<Map<String, dynamic>> get _filteredInvoices {
    if (_searchQuery.isEmpty) return _invoices;
    return _invoices.where((inv) {
      final customer = (inv['customer'] as String).toLowerCase();
      final products = (inv['products'] as List)
          .map((p) => (p['name'] as String).toLowerCase())
          .join(' ');
      final query = _searchQuery.toLowerCase();
      return customer.contains(query) || products.contains(query);
    }).toList();
  }

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < formatted.length; i++) {
      if (i > 0 && (formatted.length - i) % 3 == 0) buffer.write(',');
      buffer.write(formatted[i]);
    }
    return 'Tsh ${buffer.toString()}';
  }

  void _toggleExpansion(int index) {
    setState(() {
      _expandedIndex = _expandedIndex == index ? null : index;
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedInvoices.contains(index)) {
        _selectedInvoices.remove(index);
      } else {
        _selectedInvoices.add(index);
      }
    });
  }

  void _deleteInvoice(int index) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        ),
        title: Text(
          'Delete Invoice',
          style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete this invoice?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              final saleId = _invoices[index]['sale_id']?.toString() ?? '';
              try {
                final repo = ref.read(salesRepositoryProvider);
                await repo.deleteRecord({'sale_id': saleId});
                if (!mounted) return;
                setState(() {
                  _invoices.removeAt(index);
                  _expandedIndex = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invoice deleted')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete failed: $e')),
                );
              }
            },
            child: Text(
              'Delete',
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

  void _deleteSelected() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Invoices',
          style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete ${_selectedInvoices.length} invoice(s)?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final sorted = _selectedInvoices.toList()
                ..sort((a, b) => b.compareTo(a));
              final ids = sorted.map((i) => _invoices[i]['sale_id']?.toString() ?? '').where((id) => id.isNotEmpty).toList();
              try {
                final repo = ref.read(salesRepositoryProvider);
                if (ids.isNotEmpty) await repo.bulkDelete({'sale_ids': ids});
                if (!mounted) return;
                setState(() {
                  for (final i in sorted) {
                    _invoices.removeAt(i);
                  }
                  _selectedInvoices.clear();
                  _expandedIndex = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invoices deleted')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete failed: $e')),
                );
              }
            },
            child: Text(
              'Delete',
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

  void _showPayDialog(int invoiceIndex) {
    final invoice = _invoices[invoiceIndex];
    final balance = invoice['balance'] as double;
    final amountController = TextEditingController(text: balance.toStringAsFixed(0));
    DateTime selectedDate = DateTime.now();
    String selectedAccount = 'Cash';

    final accounts = ['Cash', 'Bank Account', 'Mobile Money', 'Savings'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          ),
          title: Text(
            'Add Payment',
            style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDialogField(
                  label: 'Balance',
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                    ),
                    child: Text(
                      'Tsh ${balance.toStringAsFixed(0)}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDialogField(
                  label: 'Date',
                  child: GestureDetector(
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('MMM dd, yyyy').format(selectedDate),
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                          ),
                          const Spacer(),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDialogField(
                  label: 'Amount to Collect',
                  child: TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: AppTypography.bodyMedium,
                    cursorColor: AppColors.primary,
                    decoration: InputDecoration(
                      hintText: 'Enter amount',
                      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
                      prefixText: 'Tsh ',
                      prefixStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                        borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDialogField(
                  label: 'Select Account',
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedAccount,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint),
                    style: AppTypography.bodyMedium,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                        borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5),
                      ),
                    ),
                    items: accounts.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                    onChanged: (v) => setDialogState(() => selectedAccount = v ?? 'Cash'),
                  ),
                ),
              ],
            ),
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
                      'Cancel',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final amount = double.tryParse(amountController.text) ?? 0;
                      if (amount > 0) {
                        final saleId = _invoices[invoiceIndex]['sale_id']?.toString() ?? '';
                        final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
                        Navigator.pop(context);
                        try {
                          final repo = ref.read(salesRepositoryProvider);
                          await repo.addPayment({
                            'sale_id': saleId,
                            'amount': amount,
                            'date': dateStr,
                            'account': selectedAccount,
                          });
                          if (!mounted) return;
                          setState(() {
                            _invoices[invoiceIndex]['paid'] = (_invoices[invoiceIndex]['paid'] as double) + amount;
                            _invoices[invoiceIndex]['balance'] = balance - amount;
                            if ((_invoices[invoiceIndex]['balance'] as double) <= 0) {
                              _invoices[invoiceIndex]['status'] = 'PAID';
                              _invoices[invoiceIndex]['balance'] = 0.0;
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Payment recorded successfully')),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Payment failed: $e')),
                          );
                        }
                      }
                    },
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
                      'Submit',
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
  }

  Widget _buildDialogField({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.label.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  void _showBackdateDialog(int invoiceIndex) async {
    final invoice = _invoices[invoiceIndex];
    final dateStr = invoice['date'] as String;
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
            'Backdate Invoice',
            style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select a new date for this invoice',
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selectedDate),
              child: Text(
                'Backdate',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (picked != null && mounted) {
      final newDate = DateTime(picked.year, picked.month, picked.day, parsedDate.hour, parsedDate.minute);
      final formatted = DateFormat('MMM dd, yyyy HH:mm').format(newDate);
      final saleId = _invoices[invoiceIndex]['sale_id']?.toString() ?? '';
      try {
        final repo = ref.read(salesRepositoryProvider);
        await repo.backdate({
          'sale_id': saleId,
          'date': DateFormat('yyyy-MM-dd HH:mm:ss').format(newDate),
        });
        if (!mounted) return;
        setState(() {
          _invoices[invoiceIndex]['date'] = formatted;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice date updated')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backdate failed: $e')),
        );
      }
    }
  }

  void _showInvoicePreview(Map<String, dynamic> invoice) {
    final products = List<Map<String, dynamic>>.from(invoice['products']);
    final totalAmount = products.fold<double>(
      0,
      (sum, p) => sum + (p['price'] as double) * (p['quantity'] as int),
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.92,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: _buildInvoicePreviewContent(invoice, products, totalAmount),
        ),
      ),
    );
  }

  Widget _buildInvoicePreviewContent(
    Map<String, dynamic> invoice,
    List<Map<String, dynamic>> products,
    double totalAmount,
  ) {
    final isPaid = invoice['status'] == 'PAID';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPreviewHeader(),
                const SizedBox(height: 20),
                _buildPreviewInvoiceDetails(invoice),
                const SizedBox(height: 20),
                _buildPreviewItemsTable(products),
                const SizedBox(height: 20),
                _buildPreviewTotals(invoice, totalAmount, isPaid),
                const SizedBox(height: 16),
                _buildPreviewFooter(),
              ],
            ),
          ),
        ),
        _buildPreviewActions(),
      ],
    );
  }

  Widget _buildPreviewHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _shopName,
                  style: AppTypography.h5.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tel: +255 123 456 789',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Address: Dar es Salaam, Tanzania',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'TIN: 123-456-789',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: AppColors.success,
                size: 24,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.3),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewInvoiceDetails(Map<String, dynamic> invoice) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
      ),
      child: Column(
        children: [
          Text(
            'INVOICE',
            style: AppTypography.h5.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Invoice No:', invoice['invoice']),
          const SizedBox(height: 6),
          _buildDetailRow('Date Issued:', invoice['date']),
          const SizedBox(height: 6),
          _buildDetailRow('Due Date:', invoice['dueDate']),
          const SizedBox(height: 6),
          _buildDetailRow('Customer:', invoice['customer']),
          const SizedBox(height: 6),
          _buildDetailRow('Created By:', invoice['createdBy']),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewItemsTable(List<Map<String, dynamic>> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items',
          style: AppTypography.label.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppConstants.radiusMD),
                    topRight: Radius.circular(AppConstants.radiusMD),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Item',
                        style: AppTypography.captionBold.copyWith(
                          color: AppColors.primary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Qty',
                        style: AppTypography.captionBold.copyWith(
                          color: AppColors.primary,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Price',
                        style: AppTypography.captionBold.copyWith(
                          color: AppColors.primary,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Total',
                        style: AppTypography.captionBold.copyWith(
                          color: AppColors.primary,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              ...products.map((product) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        product['name'],
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${product['quantity']}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatCurrency(product['price']),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatCurrency(product['total']),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewTotals(
    Map<String, dynamic> invoice,
    double totalAmount,
    bool isPaid,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
      ),
      child: Column(
        children: [
          _buildTotalRow('Subtotal', _formatCurrency(totalAmount)),
          const SizedBox(height: 8),
          _buildTotalRow('Discount', '- ${_formatCurrency(invoice['discount'] as double)}'),
          const SizedBox(height: 8),
          _buildTotalRow('Paid Amount', _formatCurrency(invoice['paid'] as double)),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Balance Due',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _formatCurrency(invoice['balance'] as double),
                  style: AppTypography.bodyMedium.copyWith(
                    color: isPaid ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTotalRow('Payment Mode', invoice['paymentMode'] as String),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
      ),
      child: Text(
        'LIPA VODA 12345',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPreviewActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Close',
                style: AppTypography.buttonMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Print functionality coming soon')),
                );
              },
              icon: const Icon(Icons.print_rounded, color: Colors.white, size: 18),
              label: Text(
                'Print Invoice',
                style: AppTypography.buttonMedium.copyWith(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FilterState>(filterProvider, (_, f) => _loadInvoices(from: f.from, to: f.to));
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
                    _buildSummaryCards(),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    if (_selectedInvoices.isNotEmpty) _buildDeleteBar(),
                    _buildInvoicesList(),
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
            'Invoices',
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            _shopName,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              label: 'Paid Total',
              amount: _formatCurrency(_paidTotal),
              color: AppColors.success,
              bgColor: AppColors.successLight,
              icon: Icons.check_circle_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              label: 'Unpaid Total',
              amount: _formatCurrency(_unpaidTotal),
              color: AppColors.danger,
              bgColor: AppColors.dangerLight,
              icon: Icons.cancel_rounded,
            ),
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
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: AppTypography.bodyMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      height: 90,
      child: Center(
        child: ListView(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          padding:
              const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
          children: [
            SalesActionButton(
              icon: Icons.filter_list_rounded,
              label: 'Filter',
              onTap: () => AppFilterDialog.show(context),
            ),
            const SizedBox(width: 10),
            SalesActionButton(
              icon: Icons.receipt_long_rounded,
              label: 'Generate Invoice',
              isHighlighted: true,
              onTap: () => context.push('/sales/create-invoice'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMD,
          vertical: 4,
        ),
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
            const Icon(
              Icons.search_rounded,
              color: AppColors.textHint,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search invoice by customer or product...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textHint,
                  size: 18,
                ),
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
            '${_selectedInvoices.length} Selected',
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

  Widget _buildInvoicesList() {
    if (_isLoading) return _buildSkeleton();
    if (_filteredInvoices.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          border: Border.all(
            color: AppColors.border,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No invoices found',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(_filteredInvoices.length, (index) {
        final invoice = _filteredInvoices[index];
        return _buildInvoiceAccordion(invoice, index);
      }),
    );
  }

  Widget _buildInvoiceAccordion(Map<String, dynamic> invoice, int index) {
    final products = List<Map<String, dynamic>>.from(invoice['products']);
    final isPaid = invoice['status'] == 'PAID';
    final totalAmount = products.fold<double>(
      0,
      (sum, p) => sum + (p['price'] as double) * (p['quantity'] as int),
    );

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLG,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: _selectedInvoices.contains(index)
            ? AppColors.primary.withValues(alpha: 0.04)
            : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _selectedInvoices.contains(index)
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => _toggleExpansion(index),
              borderRadius: BorderRadius.circular(14),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: isPaid ? AppColors.success : AppColors.danger,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          bottomLeft: Radius.circular(14),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            _buildCheckbox(index),
                            const SizedBox(width: 10),
                            Expanded(child: _buildInvoiceInfo(invoice)),
                            _buildTotalAndChevron(invoice, totalAmount, index),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildExpandedContent(invoice, index, products, totalAmount),
        ],
      ),
    );
  }

  Widget _buildCheckbox(int index) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Checkbox(
        value: _selectedInvoices.contains(index),
        onChanged: (_) => _toggleSelection(index),
        activeColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: BorderSide(
          color: _selectedInvoices.contains(index)
              ? AppColors.primary
              : AppColors.border,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildInvoiceInfo(Map<String, dynamic> invoice) {
    final isPaid = invoice['status'] == 'PAID';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${invoice['invoice']} - ${invoice['date']}',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isPaid
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                invoice['status'],
                style: AppTypography.caption.copyWith(
                  color: isPaid ? AppColors.success : AppColors.danger,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'BY ${invoice['createdBy']}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'To: ${invoice['customer']}',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalAndChevron(Map<String, dynamic> invoice, double totalAmount, int invoiceIndex) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Total',
              style: AppTypography.caption.copyWith(
                color: AppColors.textHint,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatCurrency(totalAmount),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(width: 6),
        AnimatedRotation(
          turns: _expandedIndex == invoiceIndex ? 0.5 : 0,
          duration: const Duration(milliseconds: 250),
          child: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textHint,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent(
    Map<String, dynamic> invoice,
    int invoiceIndex,
    List<Map<String, dynamic>> products,
    double totalAmount,
  ) {
    final isExpanded = _expandedIndex == invoiceIndex;
    final isUnpaid = invoice['status'] == 'UNPAID';
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: isExpanded
          ? Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 1,
                    color: AppColors.border,
                  ),
                  if (isUnpaid) ...[
                    const SizedBox(height: 12),
                    _buildPayButton(invoiceIndex),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Purchased Products',
                    style: AppTypography.captionBold.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...products.map(
                    (product) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SaleProductTile(
                        productName: product['name'] ?? '',
                        quantity: product['quantity'] ?? 0,
                        price: (product['price'] ?? 0).toDouble(),
                        total: (product['total'] ?? 0).toDouble(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PaymentSummaryCard(
                    paymentMethod: invoice['paymentMode'],
                    paid: invoice['paid'],
                    discount: invoice['discount'],
                    balance: invoice['balance'],
                  ),
                  const SizedBox(height: 12),
                  SalesBottomActions(
                    onDownload: () {},
                    onBackdate: () => _showBackdateDialog(invoiceIndex),
                    onPrint: () => _showInvoicePreview(invoice),
                    onPreview: () => _showInvoicePreview(invoice),
                    onEdit: () => context.push('/sales/create-invoice', extra: invoice),
                    onDelete: () => _deleteInvoice(invoiceIndex),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildPayButton(int invoiceIndex) {
    return GestureDetector(
      onTap: () => _showPayDialog(invoiceIndex),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.payment_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Pay',
              style: AppTypography.buttonMedium.copyWith(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Column(
        children: List.generate(6, (i) => _InvoiceSkeletonCard(key: ValueKey(i))),
      ),
    );
  }

}

class _InvoiceSkeletonCard extends StatefulWidget {
  const _InvoiceSkeletonCard({super.key});
  @override
  State<_InvoiceSkeletonCard> createState() => _InvoiceSkeletonCardState();
}

class _InvoiceSkeletonCardState extends State<_InvoiceSkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _c) {
        final c = Color.lerp(const Color(0xFFE0E0E0), const Color(0xFFF5F5F5), _anim.value)!;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEEEEEE))),
          child: Row(children: [
            Container(width: 4, height: 52, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 130, height: 13, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 8),
              Container(width: 90, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6))),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(width: 70, height: 13, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 8),
              Container(width: 50, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6))),
            ]),
          ]),
        );
      },
    );
  }
}
