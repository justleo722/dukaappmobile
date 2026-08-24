import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/sales/presentation/widgets/sales_summary_card.dart';
import 'package:dukaapp/features/sales/presentation/widgets/sales_action_button.dart';
import 'package:dukaapp/features/sales/presentation/widgets/sales_search_field.dart';
import 'package:dukaapp/features/sales/presentation/widgets/sale_accordion_card.dart';
import 'package:dukaapp/features/sales/presentation/widgets/sales_list_item.dart';
import 'package:dukaapp/features/sales/presentation/widgets/payment_badge.dart';
import 'package:dukaapp/features/sales/presentation/widgets/receipt_widget.dart';
import 'package:dukaapp/shared/dialogs/app_filter_dialog.dart';

class ManageSalesPage extends StatefulWidget {
  const ManageSalesPage({super.key});

  @override
  State<ManageSalesPage> createState() => _ManageSalesPageState();
}

class _ManageSalesPageState extends State<ManageSalesPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _viewList = false;
  int? _expandedSaleIndex;
  final Set<int> _selectedSales = {};

  final List<Map<String, dynamic>> _sales = [
    {
      'date': 'Jul 31, 2026 14:29',
      'paymentStatus': 'Paid',
      'soldBy': 'SON',
      'total': 'Tsh 132,000',
      'totalRaw': 132000.0,
      'products': [
        {
          'name': 'AIR',
          'quantity': 1,
          'price': 125000.0,
          'total': 125000.0,
        },
        {
          'name': 'AIR FRESH',
          'quantity': 1,
          'price': 7000.0,
          'total': 7000.0,
        },
      ],
      'paymentMethod': 'Cash',
      'paid': 132000.0,
      'discount': 0.0,
      'balance': 0.0,
      'customer': 'Walk-in',
      'paymentType': PaymentType.cash,
    },
    {
      'date': 'Jul 30, 2026 11:15',
      'paymentStatus': 'Paid',
      'soldBy': 'MKE',
      'total': 'Tsh 45,000',
      'totalRaw': 45000.0,
      'products': [
        {
          'name': 'BEAUTY CREAM',
          'quantity': 1,
          'price': 18000.0,
          'total': 18000.0,
        },
        {
          'name': 'FACE MASK',
          'quantity': 2,
          'price': 9000.0,
          'total': 18000.0,
        },
        {
          'name': 'DISH SOAP',
          'quantity': 1,
          'price': 3500.0,
          'total': 3500.0,
        },
      ],
      'paymentMethod': 'Cash',
      'paid': 45000.0,
      'discount': 0.0,
      'balance': 0.0,
      'customer': 'Amina',
      'paymentType': PaymentType.cash,
    },
    {
      'date': 'Jul 29, 2026 09:45',
      'paymentStatus': 'Credit',
      'soldBy': 'JUM',
      'total': 'Tsh 68,000',
      'totalRaw': 68000.0,
      'products': [
        {
          'name': 'CAR PHONE HOLDER',
          'quantity': 2,
          'price': 15000.0,
          'total': 30000.0,
        },
        {
          'name': 'CHARGER CABLE',
          'quantity': 3,
          'price': 6000.0,
          'total': 18000.0,
        },
        {
          'name': 'DISH SOAP',
          'quantity': 2,
          'price': 3500.0,
          'total': 7000.0,
        },
        {
          'name': 'AIR FRESH',
          'quantity': 1,
          'price': 7000.0,
          'total': 7000.0,
        },
      ],
      'paymentMethod': 'Credit',
      'paid': 50000.0,
      'discount': 0.0,
      'balance': 18000.0,
      'customer': 'Hassan',
      'paymentType': PaymentType.credit,
    },
    {
      'date': 'Jul 28, 2026 16:00',
      'paymentStatus': 'Pending',
      'soldBy': 'SON',
      'total': 'Tsh 25,000',
      'totalRaw': 25000.0,
      'products': [
        {
          'name': 'BEAUTY CREAM',
          'quantity': 1,
          'price': 18000.0,
          'total': 18000.0,
        },
        {
          'name': 'FACE MASK',
          'quantity': 1,
          'price': 7000.0,
          'total': 7000.0,
        },
      ],
      'paymentMethod': 'Pending',
      'paid': 0.0,
      'discount': 0.0,
      'balance': 25000.0,
      'customer': 'Fatima',
      'paymentType': PaymentType.pending,
    },
  ];

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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Sales',
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
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final sorted = _selectedSales.toList()..sort((a, b) => b.compareTo(a));
              setState(() {
                for (final i in sorted) {
                  _sales.removeAt(i);
                }
                _selectedSales.clear();
                _expandedSaleIndex = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sales deleted')),
              );
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

  void _deleteSale(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Sale',
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
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _sales.removeAt(index);
                _expandedSaleIndex = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sale deleted')),
              );
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
                    const SalesSummaryCard(
                      totalSales: 'Tsh 132,000',
                      totalCredits: 'Tsh 0',
                      totalOrders: 0,
                      profit: 'Tsh 46,432.2',
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
        'Manage Sales',
        style: AppTypography.h6.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
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
            onTap: () => context.push('/sales/orders'),
          ),
          const SizedBox(width: 10),
          SalesActionButton(
            icon: Icons.receipt_rounded,
            label: 'Purchase',
            onTap: () => context.push('/sales/purchases'),
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
            label: 'Download',
            onTap: () => context.push('/sales/reports'),
          ),
          const SizedBox(width: 10),
          SalesActionButton(
            icon: Icons.add_rounded,
            label: 'Add Sale',
            isHighlighted: true,
            onTap: () => context.push('/sales/add'),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'View List',
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
            onDownload: () {},
            onBackdate: () => _showBackdateDialog(index),
            onPrint: () => _showReceiptPreview(sale),
            onPreview: () => _showReceiptPreview(sale),
            onEdit: () async {
              await context.push('/sales/add', extra: sale);
              if (mounted) {
                setState(() {
                  _expandedSaleIndex = null;
                });
              }
            },
            onDelete: () => _deleteSale(index),
          );
        }),
      ],
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
                date: sale['date'].split(' ').take(2).join(' '),
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

  void _showBackdateDialog(int orderIndex) async {
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
            'Backdate Sale',
            style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select a new date for this sale',
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
                      'Cancel',
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
                      'Backdate',
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
      final formatted = DateFormat('MMM dd, yyyy HH:mm').format(
        DateTime(picked.year, picked.month, picked.day, parsedDate.hour, parsedDate.minute),
      );
      setState(() {
        _sales[orderIndex]['date'] = formatted;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale date updated')),
        );
      }
    }
  }

  void _showReceiptPreview(Map<String, dynamic> sale) {
    final products = List<Map<String, dynamic>>.from(sale['products']);
    final totalAmount = products.fold<double>(
      0,
      (sum, p) => sum + (p['price'] as double) * (p['quantity'] as int),
    );

    ReceiptWidget.show(
      context,
      title: 'Sales Receipt',
      receiptNumber: 'RCP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      date: sale['date'].split(' ').take(2).join(' '),
      time: sale['date'].split(' ').last,
      cashier: sale['soldBy'],
      paymentMode: sale['paymentMethod'],
      items: products,
      subtotal: totalAmount,
      totalPaid: sale['paid'],
      amountReceived: sale['paid'],
    );
  }
}
