// features/suppliers/presentation/pages/credit_purchases_page.dart
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

class CreditPurchasesPage extends StatefulWidget {
  const CreditPurchasesPage({super.key});

  @override
  State<CreditPurchasesPage> createState() => _CreditPurchasesPageState();
}

class _CreditPurchasesPageState extends State<CreditPurchasesPage> {
  final List<Supplier> _suppliers = Supplier.sampleSuppliers();
  final Map<String, bool> _expanded = {};

  List<Map<String, dynamic>> _purchasesFor(Supplier s) {
    if (s.creditBalance == 0) return [];
    return [
      {
        'purchaseNumber': '#P${s.id}C',
        'date': '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
        'status': 'Unpaid',
        'total': s.creditBalance,
        'paid': 0.0,
        'balance': s.creditBalance,
        'products': [
          {'name': 'Item A', 'quantity': 2, 'unitCost': 25000.0, 'amount': 50000.0},
          {'name': 'Item B', 'quantity': 1, 'unitCost': 15000.0, 'amount': 15000.0},
        ],
      }
    ];
  }

  
  

  


  @override
  Widget build(BuildContext context) {
    final suppliersWithCredit = _suppliers.where((s) => s.creditBalance > 0).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Credit Purchases', style: AppTypography.h6.copyWith(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.card,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _exportAllPurchasesPdf(suppliersWithCredit),
            icon: const Icon(Icons.file_download_rounded, color: AppColors.textPrimary),
            tooltip: 'Download PDF',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLG),
        child: suppliersWithCredit.isEmpty
            ? Center(child: Text('No credit purchases found', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)))
            : ListView(
                children: suppliersWithCredit.map((s) {
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
                          onClearCredit: () => _showClearCreditDialog(s),
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
            pw.Header(level: 0, child: pw.Text('Credit Purchases', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
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
      final file = File('${dir.path}/CreditPurchases_${DateFormat('dd-MM-yyyy_HH-mm').format(DateTime.now())}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exporting PDF: $e')));
    }
  }

  Future<void> _showClearCreditDialog(Supplier s) async {
    final balance = s.creditBalance;
    final amountController = TextEditingController(text: balance.toStringAsFixed(0));
    final dateController = TextEditingController(text: DateFormat('MM/dd/yyyy').format(DateTime.now()));
    DateTime selectedDate = DateTime.now();
    String? selectedAccount;
    final accounts = ['Cash', 'Bank - Main', 'Mobile Wallet'];

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Clear Supplier Credit', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
          content: StatefulBuilder(builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Supplier', style: AppTypography.labelSmall),
                  const SizedBox(height: 6),
                  TextFormField(initialValue: s.name, readOnly: true, decoration: InputDecoration(border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 12),
                  Text('Purchase Balance', style: AppTypography.labelSmall),
                  const SizedBox(height: 6),
                  TextFormField(initialValue: 'Tsh ${balance.toStringAsFixed(0)}', readOnly: true, decoration: InputDecoration(border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 12),
                  Text('Date', style: AppTypography.labelSmall),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final d = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (d != null) {
                        setState(() {
                          selectedDate = d;
                          dateController.text = DateFormat('MM/dd/yyyy').format(d);
                        });
                      }
                    },
                    child: IgnorePointer(
                      child: TextFormField(controller: dateController, decoration: InputDecoration(suffixIcon: const Icon(Icons.calendar_today), border: OutlineInputBorder(), isDense: true)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Amount to Pay', style: AppTypography.labelSmall),
                  const SizedBox(height: 6),
                  TextFormField(controller: amountController, keyboardType: TextInputType.number, decoration: InputDecoration(border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 12),
                  Text('Pay From Account', style: AppTypography.labelSmall),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedAccount,
                    items: accounts.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                    onChanged: (v) => setState(() => selectedAccount = v),
                    decoration: InputDecoration(border: OutlineInputBorder(), isDense: true),
                  ),
                ],
              ),
            );
          }),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), minimumSize: const Size(64, 36)),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: AppTypography.bodyMedium),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), minimumSize: const Size(64, 36)),
                  onPressed: () {
                    final amt = double.tryParse(amountController.text.replaceAll(',', '')) ?? 0.0;
                    if (amt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
                      return;
                    }
                    setState(() {
                      final idx = _suppliers.indexWhere((e) => e.id == s.id);
                      if (idx != -1) {
                        final remaining = (s.creditBalance - amt).clamp(0, double.infinity).toDouble();
                        _suppliers[idx] = _suppliers[idx].copyWith(creditBalance: remaining);
                      }
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment recorded for ${s.name}', style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)), backgroundColor: AppColors.success));
                  },
                  child: const Text('Submit'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
