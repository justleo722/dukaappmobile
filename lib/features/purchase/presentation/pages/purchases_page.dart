// features/purchase/presentation/pages/purchases_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/sales/presentation/widgets/sales_action_button.dart';
import 'package:dukaapp/features/sales/presentation/widgets/sale_product_tile.dart';
import 'package:dukaapp/features/sales/presentation/widgets/payment_summary_card.dart';
import 'package:dukaapp/features/sales/presentation/widgets/receipt_widget.dart';
import 'package:dukaapp/shared/dialogs/app_filter_dialog.dart';
import 'package:dukaapp/shared/providers/filter_provider.dart';
import 'package:dukaapp/features/purchase/presentation/providers/purchase_provider.dart';

class PurchasesPage extends ConsumerStatefulWidget {
  const PurchasesPage({super.key});

  @override
  ConsumerState<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchasesPageState extends ConsumerState<PurchasesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _expandedIndex;
  final Set<int> _selectedPurchases = {};
  bool _isLoading = false;

  List<Map<String, dynamic>> _purchases = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPurchases());
  }

  Future<void> _loadPurchases({String? from, String? to}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(purchaseRepositoryProvider);
      final list = await repo.fetchPurchases(from: from, to: to);
      if (!mounted) return;
      setState(() {
        _purchases = list.map((p) => {
          'purchase_id': p.purchaseId,
          'date': p.date,
          'status': p.paymentStatus.toUpperCase() == 'PAID' ? 'PAID' : 'PENDING',
          'createdBy': p.createdBy,
          'supplier': p.supplier,
          'products': p.items,
          'discount': 0.0,
          'paid': p.paidAmount,
          'balance': p.balance,
          'paymentMode': p.purchaseType == 'credit' ? 'Credit' : 'Cash',
        }).toList();
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

  double get _totalPurchases {
    double total = 0;
    for (final purchase in _purchases) {
      final products = List<Map<String, dynamic>>.from(purchase['products']);
      total += products.fold<double>(
        0,
        (sum, p) => sum + (p['price'] as double) * (p['quantity'] as int),
      );
    }
    return total;
  }

  double get _totalToPay {
    double total = 0;
    for (final purchase in _purchases) {
      total += purchase['balance'] as double;
    }
    return total;
  }

  double get _totalCredit {
    double total = 0;
    for (final purchase in _purchases) {
      if (purchase['paymentMode'] == 'Credit') {
        total += purchase['balance'] as double;
      }
    }
    return total;
  }

  double get _totalCash {
    double total = 0;
    for (final purchase in _purchases) {
      if (purchase['paymentMode'] == 'Cash') {
        total += purchase['paid'] as double;
      }
    }
    return total;
  }

  List<Map<String, dynamic>> get _filteredPurchases {
    if (_searchQuery.isEmpty) return _purchases;
    return _purchases.where((purchase) {
      final supplier = (purchase['supplier'] as String).toLowerCase();
      final products = (purchase['products'] as List)
          .map((p) => (p['name'] as String).toLowerCase())
          .join(' ');
      final query = _searchQuery.toLowerCase();
      return supplier.contains(query) || products.contains(query);
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
      if (_selectedPurchases.contains(index)) {
        _selectedPurchases.remove(index);
      } else {
        _selectedPurchases.add(index);
      }
    });
  }

  void _deletePurchase(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        ),
        title: Text(
          'Delete Purchase',
          style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete this purchase?',
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
              final purchaseId = _purchases[index]['purchase_id']?.toString() ?? '';
              try {
                final repo = ref.read(purchaseRepositoryProvider);
                if (purchaseId.isNotEmpty) await repo.bulkDelete({'purchase_ids': [purchaseId]});
                if (!mounted) return;
                setState(() {
                  _purchases.removeAt(index);
                  _expandedIndex = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Purchase deleted')),
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
          'Delete Purchases',
          style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete ${_selectedPurchases.length} purchase(s)?',
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
              final sorted = _selectedPurchases.toList()..sort((a, b) => b.compareTo(a));
              final ids = sorted.map((i) => _purchases[i]['purchase_id']?.toString() ?? '').where((id) => id.isNotEmpty).toList();
              try {
                final repo = ref.read(purchaseRepositoryProvider);
                if (ids.isNotEmpty) await repo.bulkDelete({'purchase_ids': ids});
                if (!mounted) return;
                setState(() {
                  for (final i in sorted) { _purchases.removeAt(i); }
                  _selectedPurchases.clear();
                  _expandedIndex = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Purchases deleted')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
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

  void _showPayDialog(int index) {
    final purchase = _purchases[index];
    final balance = purchase['balance'] as double;
    final supplier = purchase['supplier'] as String;
    final amountController = TextEditingController(text: balance.toStringAsFixed(0));
    DateTime selectedDate = DateTime.now();
    String? selectedAccount;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.payment_rounded,
                          color: AppColors.success,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Clear Supplier Credit',
                          style: AppTypography.h6.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDialogField(
                    label: 'Supplier',
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: Text(
                        supplier,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildDialogField(
                    label: 'Purchase Balance',
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: Text(
                        _formatCurrency(balance),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                              size: 18,
                            ),
                            const SizedBox(width: 10),
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
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildDialogField(
                    label: 'Amount to Pay',
                    child: TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: AppTypography.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Enter amount',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textHint,
                        ),
                        prefixText: 'Tsh ',
                        prefixStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                          borderSide: BorderSide(color: AppColors.inputBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                          borderSide: BorderSide(color: AppColors.inputBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildDialogField(
                    label: 'Pay From Account',
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedAccount,
                          hint: Text(
                            'Select Account',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textHint,
                            ),
                          ),
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textHint,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                            DropdownMenuItem(value: 'Bank', child: Text('Bank')),
                            DropdownMenuItem(value: 'Mobile Money', child: Text('Mobile Money')),
                          ],
                          onChanged: (value) {
                            setDialogState(() => selectedAccount = value);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            final amount = double.tryParse(amountController.text) ?? 0;
                            if (amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a valid amount')),
                              );
                              return;
                            }
                            final purchaseId = _purchases[index]['purchase_id']?.toString() ?? '';
                            Navigator.pop(context);
                            try {
                              final repo = ref.read(purchaseRepositoryProvider);
                              await repo.addPayment({
                                'purchase_id': purchaseId,
                                'amount': amount,
                                'date': DateFormat('yyyy-MM-dd').format(selectedDate),
                                if (selectedAccount != null) 'account': selectedAccount,
                              });
                              if (!mounted) return;
                              setState(() {
                                final newPaid = amount.clamp(0, balance);
                                _purchases[index]['paid'] = (_purchases[index]['paid'] as double) + newPaid;
                                _purchases[index]['balance'] = balance - newPaid;
                                if (_purchases[index]['balance'] <= 0) _purchases[index]['status'] = 'PAID';
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Payment recorded')),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          child: Text(
                            'Submit',
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  void _showReturnDialog(int index) {
    final purchase = _purchases[index];
    final products = List<Map<String, dynamic>>.from(purchase['products']);
    final totalAmount = products.fold<double>(
      0,
      (sum, p) => sum + (p['price'] as double) * (p['quantity'] as int),
    );
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.reply_rounded,
                          color: AppColors.warning,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Return Purchase',
                          style: AppTypography.h6.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Are you sure you want to return all products from this purchase?',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total: ${_formatCurrency(totalAmount)}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDialogField(
                    label: 'Return Date',
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                              size: 18,
                            ),
                            const SizedBox(width: 10),
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
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              _purchases.removeAt(index);
                              _expandedIndex = null;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Purchase returned')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          child: Text(
                            'Confirm Return',
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBackdateDialog(int index) async {
    final purchase = _purchases[index];
    final dateStr = purchase['date'] as String;
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
            'Backdate Purchase',
            style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select a new date for this purchase',
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
      final formatted = DateFormat('MMM dd, yyyy HH:mm').format(
        DateTime(picked.year, picked.month, picked.day, parsedDate.hour, parsedDate.minute),
      );
      setState(() {
        _purchases[index]['date'] = formatted;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase date updated')),
        );
      }
    }
  }

  void _showReceiptPreview(Map<String, dynamic> purchase) {
    final products = List<Map<String, dynamic>>.from(purchase['products']);
    final totalAmount = products.fold<double>(
      0,
      (sum, p) => sum + (p['price'] as double) * (p['quantity'] as int),
    );

    ReceiptWidget.show(
      context,
      title: 'Purchase Receipt',
      receiptNumber: 'PUR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      date: purchase['date'].split(' ').take(2).join(' '),
      time: purchase['date'].split(' ').last,
      cashier: purchase['createdBy'],
      paymentMode: purchase['paymentMode'],
      items: products,
      subtotal: totalAmount,
      totalPaid: purchase['paid'],
      amountReceived: purchase['paid'],
    );
  }

  Future<void> _downloadReceiptPdf(Map<String, dynamic> purchase) async {
    final doc = pw.Document();
    final products = List<Map<String, dynamic>>.from(purchase['products']);
    final totalAmount = products.fold<double>(
      0,
      (sum, p) => sum + (p['price'] as double) * (p['quantity'] as int),
    );
    final dateTime = purchase['date'] as String;
    final receiptNumber = 'PUR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'SON COLLECTION',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Dar Es Salaam',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.Text(
              'Tel: +255 123 456 789 | TIN: 123-456-789',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'PURCHASE RECEIPT',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue700,
                ),
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Divider(color: PdfColors.grey300, thickness: 1),
          ],
        ),
        build: (context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPdfInfoRow('Receipt No:', receiptNumber),
              pw.SizedBox(height: 3),
              _buildPdfInfoRow('Date:', dateTime),
              pw.SizedBox(height: 3),
              _buildPdfInfoRow('Supplier:', purchase['supplier']),
              pw.SizedBox(height: 3),
              _buildPdfInfoRow('Payment Mode:', purchase['paymentMode']),
              pw.SizedBox(height: 3),
              _buildPdfInfoRow('Created By:', purchase['createdBy']),
              pw.SizedBox(height: 12),
              pw.Divider(color: PdfColors.grey300, thickness: 1),
              pw.SizedBox(height: 10),
              pw.Text(
                'ITEMS',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 9, color: PdfColors.white),
                cellStyle: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9),
                headerAlignment: pw.Alignment.center,
                cellAlignment: pw.Alignment.center,
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
                oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                border: pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
                headerPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                headers: ['PRODUCT', 'QTY', 'PRICE', 'TOTAL'],
                data: products.map((p) => [
                  p['name'].toString(),
                  p['quantity'].toString(),
                  _formatCurrencyPdf((p['price'] as num).toDouble()),
                  _formatCurrencyPdf((p['total'] as num).toDouble()),
                ]).toList(),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey300, thickness: 1),
              pw.SizedBox(height: 8),
              _buildPdfTotalRow('Subtotal:', _formatCurrencyPdf(totalAmount)),
              pw.SizedBox(height: 4),
              _buildPdfTotalRow('Discount:', _formatCurrencyPdf(purchase['discount'] as double)),
              pw.SizedBox(height: 4),
              _buildPdfTotalRow('Amount Paid:', _formatCurrencyPdf(purchase['paid'] as double)),
              pw.SizedBox(height: 4),
              _buildPdfTotalRow(
                'Balance:',
                _formatCurrencyPdf(purchase['balance'] as double),
                isBold: true,
                color: (purchase['balance'] as double) > 0 ? PdfColors.red700 : PdfColors.green700,
              ),
            ],
          ),
        ],
        footer: (context) => pw.Center(
          child: pw.Text(
            'LIPA VODA 12345',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final fileName = '${receiptNumber}_${DateFormat('dd-MM-yyyy_HH-mm').format(DateTime.now())}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await doc.save(), flush: true);
    await OpenFile.open(file.path);
  }

  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _buildPdfTotalRow(String label, String value, {bool isBold = false, PdfColor? color}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: color ?? PdfColors.black,
          ),
        ),
      ],
    );
  }

  String _formatCurrencyPdf(double amount) {
    final formatter = NumberFormat('#,###');
    return 'Tsh ${formatter.format(amount)}';
  }

  void _editPurchase(int index) {
    final purchase = _purchases[index];
    final products = List<Map<String, dynamic>>.from(purchase['products']);

    context.push('/purchase', extra: {
      'editMode': true,
      'poNumber': 'PUR-${index + 1}',
      'supplier': purchase['supplier'],
      'products': products,
    });
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildSummarySection(),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                    const SizedBox(height: 16),
                    _buildCreditCashRow(),
                    const SizedBox(height: 12),
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    if (_selectedPurchases.isNotEmpty) _buildBulkActionsBar(),
                    _buildPurchasesList(),
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
            'Manage Purchases',
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'SON COLLECTION',
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

  Widget _buildSummarySection() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final cards = [
            {
              'label': 'Total Purchases',
              'amount': _formatCurrency(_totalPurchases),
              'color': AppColors.textPrimary,
              'bgColor': AppColors.background,
              'icon': Icons.shopping_cart_rounded,
            },
            {
              'label': 'To Pay',
              'amount': _formatCurrency(_totalToPay),
              'color': _totalToPay > 0 ? AppColors.danger : AppColors.success,
              'bgColor': _totalToPay > 0 ? AppColors.dangerLight : AppColors.successLight,
              'icon': Icons.payment_rounded,
            },
            {
              'label': 'Total Purchase Orders',
              'amount': '${_purchases.length}',
              'color': AppColors.textPrimary,
              'bgColor': AppColors.background,
              'icon': Icons.receipt_long_rounded,
            },
          ];
          final card = cards[index];
          return SizedBox(
            width: MediaQuery.of(context).size.width * 0.42,
            child: _buildSummaryCard(
              label: card['label'] as String,
              amount: card['amount'] as String,
              color: card['color'] as Color,
              bgColor: card['bgColor'] as Color,
              icon: card['icon'] as IconData,
            ),
          );
        },
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: AppTypography.bodyMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
        children: [
          SalesActionButton(
            icon: Icons.shopping_cart_rounded,
            label: 'Order',
            onTap: () => context.push('/purchases/orders'),
          ),
          const SizedBox(width: 10),
          SalesActionButton(
            icon: Icons.people_rounded,
            label: 'Supplier',
            onTap: () => context.push('/suppliers'),
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
            label: 'Download',
            onTap: () => context.push('/purchases/reports'),
          ),
          const SizedBox(width: 10),
          SalesActionButton(
            icon: Icons.refresh_rounded,
            label: 'Re-stock',
            onTap: () => context.push('/purchase'),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCashRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.credit_card_rounded,
                color: AppColors.danger,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Credit: ${_formatCurrency(_totalCredit)}',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(
                Icons.attach_money_rounded,
                color: AppColors.success,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Cash: ${_formatCurrency(_totalCash)}',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
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
                  hintText: 'Search purchase by supplier or product...',
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

  Widget _buildBulkActionsBar() {
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
            '${_selectedPurchases.length} Selected',
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

  Widget _buildPurchasesList() {
    if (_filteredPurchases.isEmpty) {
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
              Icons.shopping_cart_outlined,
              size: 40,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No purchases found',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(_filteredPurchases.length, (index) {
        final purchase = _filteredPurchases[index];
        return _buildPurchaseAccordion(purchase, index);
      }),
    );
  }

  Widget _buildPurchaseAccordion(Map<String, dynamic> purchase, int index) {
    final products = List<Map<String, dynamic>>.from(purchase['products']);
    final isPaid = purchase['status'] == 'PAID';
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
        color: _selectedPurchases.contains(index)
            ? AppColors.primary.withValues(alpha: 0.04)
            : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _selectedPurchases.contains(index)
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
                        color: isPaid ? AppColors.success : AppColors.warning,
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
                            Expanded(child: _buildPurchaseInfo(purchase)),
                            _buildTotalAndChevron(purchase, totalAmount, index),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildExpandedContent(purchase, index, products, totalAmount),
        ],
      ),
    );
  }

  Widget _buildCheckbox(int index) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Checkbox(
        value: _selectedPurchases.contains(index),
        onChanged: (_) => _toggleSelection(index),
        activeColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: BorderSide(
          color: _selectedPurchases.contains(index)
              ? AppColors.primary
              : AppColors.border,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildPurchaseInfo(Map<String, dynamic> purchase) {
    final isPaid = purchase['status'] == 'PAID';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          purchase['date'],
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
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                purchase['status'],
                style: AppTypography.caption.copyWith(
                  color: isPaid ? AppColors.success : AppColors.warning,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${purchase['paymentMode']} BY ${purchase['createdBy']}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'From: ${purchase['supplier']}',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalAndChevron(Map<String, dynamic> purchase, double totalAmount, int purchaseIndex) {
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
          turns: _expandedIndex == purchaseIndex ? 0.5 : 0,
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
    Map<String, dynamic> purchase,
    int purchaseIndex,
    List<Map<String, dynamic>> products,
    double totalAmount,
  ) {
    final isExpanded = _expandedIndex == purchaseIndex;
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
                    paymentMethod: purchase['paymentMode'],
                    paid: purchase['paid'],
                    discount: purchase['discount'],
                    balance: purchase['balance'],
                  ),
                  const SizedBox(height: 12),
                  _buildPurchaseActions(purchaseIndex, purchase),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildPurchaseActions(int purchaseIndex, Map<String, dynamic> purchase) {
    final isPending = purchase['status'] == 'PENDING';
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (isPending) ...[
            _buildOutlinedAction(
              icon: Icons.payment_rounded,
              label: 'Pay',
              onTap: () => _showPayDialog(purchaseIndex),
            ),
            const SizedBox(width: 8),
          ],
          _buildOutlinedAction(
            icon: Icons.download_rounded,
            label: 'Download',
            onTap: () => _downloadReceiptPdf(_purchases[purchaseIndex]),
          ),
          const SizedBox(width: 8),
          _buildOutlinedAction(
            icon: Icons.date_range_rounded,
            label: 'Backdate',
            onTap: () => _showBackdateDialog(purchaseIndex),
          ),
          const SizedBox(width: 8),
          _buildOutlinedAction(
            icon: Icons.print_rounded,
            label: 'Print',
            onTap: () => _showReceiptPreview(_purchases[purchaseIndex]),
          ),
          const SizedBox(width: 8),
          _buildOutlinedAction(
            icon: Icons.visibility_rounded,
            label: 'Preview',
            onTap: () => _showReceiptPreview(_purchases[purchaseIndex]),
          ),
          const SizedBox(width: 8),
          _buildOutlinedAction(
            icon: Icons.edit_rounded,
            label: 'Edit',
            onTap: () => _editPurchase(purchaseIndex),
          ),
          const SizedBox(width: 8),
          _buildOutlinedAction(
            icon: Icons.reply_rounded,
            label: 'Return All',
            onTap: () => _showReturnDialog(purchaseIndex),
          ),
          const SizedBox(width: 8),
          _buildDangerAction(
            icon: Icons.delete_rounded,
            label: 'Delete',
            onTap: () => _deletePurchase(purchaseIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildOutlinedAction({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerAction({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.danger.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.danger, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
