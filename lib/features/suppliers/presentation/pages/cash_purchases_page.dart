// features/suppliers/presentation/pages/cash_purchases_page.dart
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

class CashPurchasesPage extends ConsumerStatefulWidget {
  const CashPurchasesPage({super.key});

  @override
  ConsumerState<CashPurchasesPage> createState() => _CashPurchasesPageState();
}

class _CashPurchasesPageState extends ConsumerState<CashPurchasesPage> {
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
      final res = await api.getOncashSuppliers();
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
    final list = raw is List
        ? raw
        : (raw is Map ? raw.values.toList() : []);
    return list.whereType<Map<String, dynamic>>().toList();
  }

  List<Map<String, dynamic>> _itemsFor(Map<String, dynamic> purchase) {
    final raw = purchase['items'];
    if (raw == null) return [];
    final list = raw is List
        ? raw
        : (raw is Map ? raw.values.toList() : []);
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
              p['invoice_no'] ?? '#${p['purchase_id'] ?? ''}',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cash Purchases', style: AppTypography.h6.copyWith(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.card,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _suppliers.isEmpty
              ? Center(child: Text('No cash purchases found', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)))
              : Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLG),
                  child: ListView(
                    children: _suppliers.map((s) {
                      final purchases = _purchasesFor(s);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['name'] ?? '', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
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
                                  : '#${id}',
                              date: (p['purchase_date'] ?? p['record_date'] ?? '').toString(),
                              status: (p['payment_status'] ?? 'Paid').toString(),
                              total: total,
                              paid: paid,
                              balance: balance,
                              products: _itemsFor(p),
                              isExpanded: isExp,
                              onExpandToggle: () => setState(() => _expanded[id] = !isExp),
                              onDownloadPdf: () => _exportSupplierStatement(s),
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
