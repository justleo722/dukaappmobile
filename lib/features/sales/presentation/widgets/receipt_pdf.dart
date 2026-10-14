import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// PDF version of [ReceiptWidget]: same sections in the same order, on an 80mm
/// receipt roll, so a downloaded receipt looks like the on-screen one.
Future<Uint8List> buildReceiptPdf({
  required String shopName,
  String shopAddress = '',
  String shopPhone = '',
  String shopTin = '',
  required String title,
  required String receiptNumber,
  required String date,
  required String time,
  String? customerName,
  required String cashier,
  required String paymentMode,
  required List<Map<String, dynamic>> items,
  required double subtotal,
  double discount = 0,
  required double totalPaid,
  required double amountReceived,
  String message = '',
}) async {
  final fmt = NumberFormat('#,###');
  String money(double v) => 'Tsh ${fmt.format(v)}';
  const grey = PdfColor.fromInt(0xFF6B7280);
  const hint = PdfColor.fromInt(0xFF9CA3AF);
  const primary = PdfColor.fromInt(0xFF2563EB);
  const green = PdfColor.fromInt(0xFF22C55E);

  pw.Widget dashed() => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 6),
        child: pw.Divider(color: hint, borderStyle: pw.BorderStyle.dashed, height: 1),
      );

  pw.Widget infoRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: grey)),
            pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );

  pw.Widget totalRow(String label, String value, {bool bold = false, PdfColor? color}) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: pw.TextStyle(fontSize: 8.5, color: grey, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
            pw.Text(value, style: pw.TextStyle(fontSize: 8.5, color: color, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );

  final doc = pw.Document();
  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.roll80,
    margin: const pw.EdgeInsets.all(10),
    build: (ctx) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Center(child: pw.Text(shopName, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: pw.BoxDecoration(color: const PdfColor.fromInt(0x1A2563EB), borderRadius: pw.BorderRadius.circular(4)),
            child: pw.Text(title, style: pw.TextStyle(fontSize: 8, color: primary, fontWeight: pw.FontWeight.bold)),
          ),
        ),
        if (shopAddress.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Center(child: pw.Text(shopAddress, style: const pw.TextStyle(fontSize: 8, color: grey), textAlign: pw.TextAlign.center)),
        ],
        if (shopPhone.isNotEmpty || shopTin.isNotEmpty) ...[
          pw.SizedBox(height: 3),
          pw.Center(
            child: pw.Text(
              [if (shopPhone.isNotEmpty) 'Tel: $shopPhone', if (shopTin.isNotEmpty) 'TIN: $shopTin'].join('\n'),
              style: const pw.TextStyle(fontSize: 7.5, color: hint),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
        dashed(),
        infoRow('Receipt No:', receiptNumber),
        infoRow('Date:', date),
        infoRow('Time:', time),
        dashed(),
        if (customerName != null && customerName.isNotEmpty) infoRow('Customer:', customerName),
        infoRow('Cashier:', cashier),
        infoRow('Payment:', paymentMode),
        pw.SizedBox(height: 6),
        pw.Text('Items', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        ...items.map((item) {
          final name = (item['name'] ?? item['product_name'] ?? '').toString();
          final qty = (num.tryParse(item['quantity']?.toString() ?? '') ?? 0).toDouble();
          final price = (num.tryParse(item['price']?.toString() ?? '') ?? 0).toDouble();
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(name, style: const pw.TextStyle(fontSize: 8.5)),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('${fmt.format(qty)} x ${money(price)}', style: const pw.TextStyle(fontSize: 7.5, color: hint)),
                    pw.Text(money(price * qty), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Divider(color: const PdfColor.fromInt(0xFFF1F5F9), height: 1),
              ],
            ),
          );
        }),
        dashed(),
        totalRow('Subtotal:', money(subtotal)),
        if (discount > 0) totalRow('Discount:', money(discount), color: green),
        totalRow('Total Paid:', money(totalPaid)),
        pw.SizedBox(height: 3),
        totalRow('Amount Received:', money(amountReceived), bold: true, color: primary),
        if (message.trim().isNotEmpty) ...[
          dashed(),
          pw.Center(child: pw.Text(message, style: const pw.TextStyle(fontSize: 8, color: hint), textAlign: pw.TextAlign.center)),
        ],
      ],
    ),
  ));
  return doc.save();
}
