import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// A4 invoice PDF with the same content as the invoice preview.
Future<Uint8List> buildInvoicePdf({
  required String shopName,
  String shopAddress = '',
  String shopPhone = '',
  String shopTin = '',
  required String invoiceNo,
  required String date,
  String dueDate = '',
  required String customer,
  String createdBy = '',
  required List<Map<String, dynamic>> items,
  double discount = 0,
  required double total,
  double paid = 0,
  double balance = 0,
  String message = '',
}) async {
  final fmt = NumberFormat('#,###');
  String money(num v) => 'Tsh ${fmt.format(v)}';
  const grey = PdfColor.fromInt(0xFF6B7280);
  const primary = PdfColor.fromInt(0xFF2563EB);

  double d(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
  final subtotal = items.fold<double>(0, (s, i) => s + d(i['price']) * d(i['quantity']));

  pw.Widget info(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(children: [
          pw.SizedBox(width: 80, child: pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: grey))),
          pw.Expanded(child: pw.Text(value.isEmpty ? '-' : value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
        ]),
      );

  pw.Widget totalRow(String label, String value, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ]),
      );

  final doc = pw.Document();
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(32),
    build: (ctx) => [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(shopName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            if (shopAddress.isNotEmpty) pw.Text(shopAddress, style: const pw.TextStyle(fontSize: 9, color: grey)),
            if (shopPhone.isNotEmpty) pw.Text('Tel: $shopPhone', style: const pw.TextStyle(fontSize: 9, color: grey)),
            if (shopTin.isNotEmpty) pw.Text('TIN: $shopTin', style: const pw.TextStyle(fontSize: 9, color: grey)),
          ]),
          pw.Text('INVOICE', style: pw.TextStyle(fontSize: 22, color: primary, fontWeight: pw.FontWeight.bold)),
        ],
      ),
      pw.SizedBox(height: 16),
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Bill To', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(customer, style: const pw.TextStyle(fontSize: 10)),
        ])),
        pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          info('Invoice No:', invoiceNo),
          info('Date Issued:', date),
          info('Due Date:', dueDate),
          if (createdBy.isNotEmpty) info('Created By:', createdBy),
        ])),
      ]),
      pw.SizedBox(height: 16),
      pw.TableHelper.fromTextArray(
        headers: ['#', 'Item', 'Qty', 'Price', 'Total'],
        headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: primary),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellAlignments: {0: pw.Alignment.centerLeft, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight, 4: pw.Alignment.centerRight},
        data: [
          for (var i = 0; i < items.length; i++)
            [
              '${i + 1}',
              (items[i]['name'] ?? '').toString(),
              fmt.format(d(items[i]['quantity'])),
              money(d(items[i]['price'])),
              money(d(items[i]['price']) * d(items[i]['quantity'])),
            ],
        ],
      ),
      pw.SizedBox(height: 12),
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.SizedBox(
          width: 220,
          child: pw.Column(children: [
            totalRow('Subtotal', money(subtotal)),
            if (discount > 0) totalRow('Discount', money(discount)),
            totalRow('Total', money(total), bold: true),
            totalRow('Paid', money(paid)),
            totalRow('Balance', money(balance), bold: true),
          ]),
        ),
      ),
      if (message.trim().isNotEmpty) ...[
        pw.SizedBox(height: 20),
        pw.Center(child: pw.Text(message, style: pw.TextStyle(fontSize: 10, color: primary, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
      ],
    ],
  ));
  return doc.save();
}
