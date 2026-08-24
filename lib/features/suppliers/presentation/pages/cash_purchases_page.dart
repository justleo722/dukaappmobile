// features/suppliers/presentation/pages/cash_purchases_page.dart
import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/suppliers/data/models/supplier_model.dart';
import 'package:dukaapp/features/suppliers/presentation/widgets/supplier_purchase_accordion_card.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
// receipt preview not used here; supplier statement export used instead

class CashPurchasesPage extends StatefulWidget {
  const CashPurchasesPage({super.key});

  @override
  State<CashPurchasesPage> createState() => _CashPurchasesPageState();
}

class _CashPurchasesPageState extends State<CashPurchasesPage> {
  final List<Supplier> _suppliers = Supplier.sampleSuppliers();
  final Map<String, bool> _expanded = {};

  List<Map<String, dynamic>> _purchasesFor(Supplier s) {
    if (s.totalPurchases == 0) return [];
    return [
      {
        'purchaseNumber': '#P${s.id}H',
        'date': '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
        'status': 'Paid',
        'total': s.totalPurchases * 0.2,
        'paid': s.totalPurchases * 0.2,
        'balance': 0.0,
        'products': [
          {'name': 'Item X', 'quantity': 3, 'unitCost': 20000.0, 'amount': 60000.0},
        ],
      }
    ];
  }

  Future<void> _exportSupplierStatement(Supplier s) async {
    final purchases = _purchasesFor(s);
    if (purchases.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No purchases for this supplier')));
      return;
    }

    try {
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            pw.Header(level: 0, child: pw.Text('Supplier Statement - ${s.name}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Purchase', 'Date', 'Status', 'Total', 'Paid', 'Balance'],
              data: purchases.map((p) => [p['purchaseNumber'] ?? '', p['date'] ?? '', p['status'] ?? '', (p['total'] as double).toStringAsFixed(0), (p['paid'] as double).toStringAsFixed(0), (p['balance'] as double).toStringAsFixed(0)]).toList(),
            ),
          ],
        ),
      );

      final bytes = await doc.save();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/SupplierStatement_${s.id}_${DateFormat('dd-MM-yyyy_HH-mm').format(DateTime.now())}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exporting supplier statement: $e')));
    }
  }

  
  

  

  @override
  Widget build(BuildContext context) {
    final suppliersWithCash = _suppliers.where((s) => s.totalPurchases > 0).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Cash Purchases', style: AppTypography.h6.copyWith(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.card,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _exportAllPurchasesPdf(suppliersWithCash),
            icon: const Icon(Icons.file_download_rounded, color: AppColors.textPrimary),
            tooltip: 'Download PDF',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLG),
        child: suppliersWithCash.isEmpty
            ? Center(child: Text('No cash purchases found', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)))
            : ListView(
                children: suppliersWithCash.map((s) {
                  final purchases = _purchasesFor(s);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      ...purchases.map((p) {
                        final id = p['purchaseNumber'] as String;
                        final isExp = _expanded[id] ?? false;
                        return SupplierPurchaseAccordionCard(
                          purchaseNumber: p['purchaseNumber'],
                          date: p['date'],
                          status: p['status'],
                          total: p['total'],
                          paid: p['paid'],
                          balance: p['balance'],
                          products: p['products'],
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

  Future<void> _exportAllPurchasesPdf(List<Supplier> suppliers) async {
    final allPurchases = <List<String>>[];
    for (final s in suppliers) {
      final purchases = _purchasesFor(s);
      for (final p in purchases) {
        allPurchases.add([
          s.name,
          p['purchaseNumber'] ?? '',
          p['date'] ?? '',
          p['status'] ?? '',
          (p['total'] as double).toStringAsFixed(0),
        ]);
      }
    }

    if (allPurchases.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No purchases to export')));
      return;
    }

    try {
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            pw.Header(level: 0, child: pw.Text('Cash Purchases', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Supplier', 'Purchase', 'Date', 'Status', 'Total'],
              data: allPurchases,
            ),
          ],
        ),
      );

      final bytes = await doc.save();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/CashPurchases_${DateFormat('dd-MM-yyyy_HH-mm').format(DateTime.now())}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exporting PDF: $e')));
    }
  }
}
