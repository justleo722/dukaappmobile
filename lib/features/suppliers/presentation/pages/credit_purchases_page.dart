// features/suppliers/presentation/pages/credit_purchases_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/suppliers/presentation/widgets/supplier_purchase_accordion_card.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class CreditPurchasesPage extends ConsumerStatefulWidget {
  const CreditPurchasesPage({super.key});

  @override
  ConsumerState<CreditPurchasesPage> createState() => _CreditPurchasesPageState();
}

class _CreditPurchasesPageState extends ConsumerState<CreditPurchasesPage> {
  List<Map<String, dynamic>> _suppliers = [];
  bool _isLoading = false;
  final Map<String, bool> _expanded = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getOncreditSuppliers();
      final raw = res.data;
      final list = raw is List
          ? raw
          : (raw is Map ? (raw['data'] ?? raw['suppliers'] ?? []) : []);
      if (!mounted) return;
      setState(() {
        _suppliers = (list as List).whereType<Map<String, dynamic>>().toList();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _purchasesFor(Map<String, dynamic> s) {
    final raw = s['purchases'];
    if (raw == null) return [];
    final list = raw is List ? raw : (raw is Map ? raw.values.toList() : []);
    return list.whereType<Map<String, dynamic>>().toList();
  }

  List<Map<String, dynamic>> _itemsFor(Map<String, dynamic> purchase) {
    final raw = purchase['items'];
    if (raw == null) return [];
    final list = raw is List ? raw : (raw is Map ? raw.values.toList() : []);
    return list.whereType<Map<String, dynamic>>().map((i) => {
      'name': (i['product_name'] ?? i['name'] ?? '').toString(),
      'quantity': (double.tryParse(i['quantity']?.toString() ?? '') ?? 0).toInt(),
      'unitCost': double.tryParse(i['bp']?.toString() ?? '') ?? 0.0,
      'amount': (double.tryParse(i['quantity']?.toString() ?? '') ?? 0) *
          (double.tryParse(i['bp']?.toString() ?? '') ?? 0),
    }).toList();
  }

  Future<void> _exportSupplierStatement(Map<String, dynamic> s) async {
    final purchases = _purchasesFor(s);
    if (purchases.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No purchases for this supplier')));
      return;
    }
    try {
      final doc = pw.Document();
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (ctx) => [
          pw.Header(level: 0, child: pw.Text('Supplier Statement - ${s['name'] ?? ''}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Purchase', 'Date', 'Status', 'Total', 'Paid', 'Balance'],
            data: purchases.map((p) => [
              p['invoice_no']?.toString().isNotEmpty == true ? p['invoice_no'].toString() : '#${p['purchase_id'] ?? ''}',
              (p['purchase_date'] ?? '').toString(),
              (p['payment_status'] ?? '').toString(),
              (double.tryParse(p['total_amount']?.toString() ?? '') ?? 0).toStringAsFixed(0),
              (double.tryParse(p['paid_amount']?.toString() ?? '') ?? 0).toStringAsFixed(0),
              (double.tryParse(p['balance']?.toString() ?? '') ?? 0).toStringAsFixed(0),
            ]).toList(),
          ),
        ],
      ));
      final bytes = await doc.save();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/SupplierStatement_${s['supplier_id'] ?? ''}_${DateFormat('dd-MM-yyyy_HH-mm').format(DateTime.now())}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _showClearCreditDialog(Map<String, dynamic> s) async {
    final balance = double.tryParse(s['balance']?.toString() ?? '') ?? 0.0;
    final amountController = TextEditingController(text: balance.toStringAsFixed(0));
    final dateController = TextEditingController(text: DateFormat('MM/dd/yyyy').format(DateTime.now()));
    DateTime selectedDate = DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Clear Supplier Credit', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
          content: StatefulBuilder(builder: (ctx2, setS) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Supplier', style: AppTypography.labelSmall),
                  const SizedBox(height: 6),
                  TextFormField(initialValue: s['name']?.toString() ?? '', readOnly: true, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 12),
                  Text('Purchase Balance', style: AppTypography.labelSmall),
                  const SizedBox(height: 6),
                  TextFormField(initialValue: 'Tsh ${balance.toStringAsFixed(0)}', readOnly: true, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 12),
                  Text('Date', style: AppTypography.labelSmall),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final d = await showDatePicker(context: ctx, initialDate: selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (d != null) setS(() { selectedDate = d; dateController.text = DateFormat('MM/dd/yyyy').format(d); });
                    },
                    child: IgnorePointer(child: TextFormField(controller: dateController, decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today), border: OutlineInputBorder(), isDense: true))),
                  ),
                  const SizedBox(height: 12),
                  Text('Amount to Pay', style: AppTypography.labelSmall),
                  const SizedBox(height: 6),
                  TextFormField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)),
                ],
              ),
            );
          }),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Cancel', style: AppTypography.bodyMedium)),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amountController.text.replaceAll(',', '')) ?? 0.0;
                if (amt <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
                  return;
                }
                Navigator.of(ctx).pop();
                try {
                  final api = ref.read(apiServiceProvider);
                  await api.postSupplierClearCreditBalance({
                    'supplier_id': s['supplier_id']?.toString() ?? '',
                    'amount': amt,
                    'date': DateFormat('yyyy-MM-dd').format(selectedDate),
                  });
                  if (!mounted) return;
                  await _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Payment recorded for ${s['name'] ?? ''}', style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)),
                    backgroundColor: AppColors.success,
                  ));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger));
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Credit Purchases', style: AppTypography.h6.copyWith(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.card,
        elevation: 0,
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary), tooltip: 'Refresh'),
        ],
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _suppliers.isEmpty
              ? Center(child: Text('No credit purchases found', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)))
              : Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLG),
                  child: ListView(
                    children: _suppliers.map((s) {
                      final purchases = _purchasesFor(s);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['name']?.toString() ?? '', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          ...purchases.map((p) {
                            final id = (p['purchase_id'] ?? '').toString();
                            final isExp = _expanded[id] ?? false;
                            final total = double.tryParse(p['total_amount']?.toString() ?? '') ?? 0.0;
                            final paid = double.tryParse(p['paid_amount']?.toString() ?? '') ?? 0.0;
                            final balance = double.tryParse(p['balance']?.toString() ?? '') ?? 0.0;
                            return SupplierPurchaseAccordionCard(
                              purchaseNumber: p['invoice_no']?.toString().isNotEmpty == true
                                  ? p['invoice_no'].toString()
                                  : '#$id',
                              date: (p['purchase_date'] ?? p['record_date'] ?? '').toString(),
                              status: (p['payment_status'] ?? 'Unpaid').toString(),
                              total: total,
                              paid: paid,
                              balance: balance,
                              products: _itemsFor(p),
                              isExpanded: isExp,
                              onExpandToggle: () => setState(() => _expanded[id] = !isExp),
                              onDownloadPdf: () => _exportSupplierStatement(s),
                              onClearCredit: balance > 0 ? () => _showClearCreditDialog(s) : null,
                            );
                          }).toList(),
                          const SizedBox(height: 16),
                        ],
                      );
                    }).toList(),
                  ),
                ),
    );
  }
}
