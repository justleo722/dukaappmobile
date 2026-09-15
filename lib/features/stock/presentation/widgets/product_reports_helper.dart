import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

class ProductReportsHelper {
  static String _fmt(double v) => v >= 1000000
      ? '${(v / 1000000).toStringAsFixed(1)}M'
      : v.toStringAsFixed(0);

  static String get _exportDateTime => DateFormat('dd-MM-yyyy_HH-mm').format(DateTime.now());

  // ─── HISTORY PDF ──────────────────────────────────────────────────────
  // Columns: S/N, Date, Type (IN/OUT), Qty, Balance
  static Future<void> exportHistoryPdf({
    required BuildContext context,
    required String productName,
    String shopName = '',
  }) async {
    final doc = pw.Document();
    final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    // Sample data - in real app this would come from a database
    final List<Map<String, dynamic>> historyData = [
      {'sn': 1, 'date': '2026-07-03', 'type': 'IN', 'qty': 20, 'balance': 20},
      {'sn': 2, 'date': '2026-07-05', 'type': 'OUT', 'qty': 5, 'balance': 15},
      {'sn': 3, 'date': '2026-07-10', 'type': 'IN', 'qty': 10, 'balance': 25},
      {'sn': 4, 'date': '2026-07-12', 'type': 'OUT', 'qty': 3, 'balance': 22},
      {'sn': 5, 'date': '2026-07-15', 'type': 'OUT', 'qty': 7, 'balance': 15},
      {'sn': 6, 'date': '2026-07-20', 'type': 'IN', 'qty': 15, 'balance': 30},
      {'sn': 7, 'date': '2026-07-25', 'type': 'OUT', 'qty': 10, 'balance': 20},
      {'sn': 8, 'date': '2026-07-28', 'type': 'IN', 'qty': 5, 'balance': 25},
    ];

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.portrait,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Product History Report', style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 16)),
            pw.SizedBox(height: 4),
            pw.Text('Product: $productName', style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 12)),
            pw.SizedBox(height: 2),
            pw.Text('$shopName  •  $now',
                style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9, color: PdfColors.grey600)),
            pw.SizedBox(height: 4),
            pw.Divider(),
            pw.SizedBox(height: 4),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 8, color: PdfColors.white),
            cellStyle: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 8),
            headerAlignment: pw.Alignment.center,
            cellAlignment: pw.Alignment.center,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey400),
            headers: ['S/N', 'Date', 'Type', 'Qty', 'Balance'],
            data: historyData.map((row) => [
              '${row['sn']}',
              '${row['date']}',
              '${row['type']}',
              '${row['qty']}',
              '${row['balance']}',
            ]).toList(),
          ),
        ],
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 7, color: PdfColors.grey500),
          ),
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${productName}_History_${_exportDateTime}.pdf');
    await file.writeAsBytes(await doc.save(), flush: true);
    await OpenFile.open(file.path);
  }

  // ─── STOCK PDF ────────────────────────────────────────────────────────
  // Columns: DATE, ACTION, IN, OUT, BAL, VALUE
  static Future<void> exportStockPdf({
    required BuildContext context,
    required String productName,
    required double buyingPrice,
    String shopName = '',
  }) async {
    final doc = pw.Document();
    final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    // Sample data - in real app this would come from a database
    final List<Map<String, dynamic>> stockData = [
      {'date': '2026-07-03', 'action': 'Purchase', 'in': 20, 'out': 0, 'bal': 20, 'value': 20 * buyingPrice},
      {'date': '2026-07-05', 'action': 'Sale', 'in': 0, 'out': 5, 'bal': 15, 'value': 15 * buyingPrice},
      {'date': '2026-07-10', 'action': 'Purchase', 'in': 10, 'out': 0, 'bal': 25, 'value': 25 * buyingPrice},
      {'date': '2026-07-12', 'action': 'Sale', 'in': 0, 'out': 3, 'bal': 22, 'value': 22 * buyingPrice},
      {'date': '2026-07-15', 'action': 'Sale', 'in': 0, 'out': 7, 'bal': 15, 'value': 15 * buyingPrice},
      {'date': '2026-07-20', 'action': 'Purchase', 'in': 15, 'out': 0, 'bal': 30, 'value': 30 * buyingPrice},
      {'date': '2026-07-25', 'action': 'Sale', 'in': 0, 'out': 10, 'bal': 20, 'value': 20 * buyingPrice},
      {'date': '2026-07-28', 'action': 'Purchase', 'in': 5, 'out': 0, 'bal': 25, 'value': 25 * buyingPrice},
    ];

    final totalIn = stockData.fold<int>(0, (sum, row) => sum + (row['in'] as int));
    final totalOut = stockData.fold<int>(0, (sum, row) => sum + (row['out'] as int));
    final finalBal = stockData.last['bal'] as int;
    final finalValue = stockData.last['value'] as double;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Stock Report', style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 16)),
            pw.SizedBox(height: 4),
            pw.Text('Product: $productName', style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 12)),
            pw.SizedBox(height: 2),
            pw.Text('$shopName  •  $now',
                style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9, color: PdfColors.grey600)),
            pw.SizedBox(height: 4),
            pw.Divider(),
            pw.SizedBox(height: 4),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 8, color: PdfColors.white),
            cellStyle: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 8),
            headerAlignment: pw.Alignment.center,
            cellAlignment: pw.Alignment.center,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey400),
            headers: ['DATE', 'ACTION', 'IN', 'OUT', 'BAL', 'VALUE'],
            data: [
              ...stockData.map((row) => [
                '${row['date']}',
                '${row['action']}',
                '${row['in']}',
                '${row['out']}',
                '${row['bal']}',
                _fmt(row['value'] as double),
              ]),
              ['TOTAL', '', '$totalIn', '$totalOut', '$finalBal', _fmt(finalValue)],
            ],
          ),
        ],
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 7, color: PdfColors.grey500),
          ),
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${productName}_Stock_${_exportDateTime}.pdf');
    await file.writeAsBytes(await doc.save(), flush: true);
    await OpenFile.open(file.path);
  }

  // ─── SALES PDF ────────────────────────────────────────────────────────
  // Columns: DATE, ACTION, IN, OUT, BAL, VALUE (showing how product is sold)
  static Future<void> exportSalesPdf({
    required BuildContext context,
    required String productName,
    required double sellingPrice,
    String shopName = '',
  }) async {
    final doc = pw.Document();
    final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    // Sample data - in real app this would come from a database
    final List<Map<String, dynamic>> salesData = [
      {'date': '2026-07-05', 'action': 'Sale', 'in': 0, 'out': 5, 'bal': 15, 'value': 5 * sellingPrice},
      {'date': '2026-07-12', 'action': 'Sale', 'in': 0, 'out': 3, 'bal': 12, 'value': 3 * sellingPrice},
      {'date': '2026-07-15', 'action': 'Sale', 'in': 0, 'out': 7, 'bal': 5, 'value': 7 * sellingPrice},
      {'date': '2026-07-18', 'action': 'Return', 'in': 2, 'out': 0, 'bal': 7, 'value': -2 * sellingPrice},
      {'date': '2026-07-22', 'action': 'Sale', 'in': 0, 'out': 4, 'bal': 3, 'value': 4 * sellingPrice},
      {'date': '2026-07-25', 'action': 'Sale', 'in': 0, 'out': 10, 'bal': -7, 'value': 10 * sellingPrice},
      {'date': '2026-07-28', 'action': 'Sale', 'in': 0, 'out': 2, 'bal': -9, 'value': 2 * sellingPrice},
    ];

    final totalOut = salesData.where((row) => (row['out'] as int) > 0).fold<int>(0, (sum, row) => sum + (row['out'] as int));
    final totalReturns = salesData.where((row) => (row['in'] as int) > 0).fold<int>(0, (sum, row) => sum + (row['in'] as int));
    final totalSalesValue = salesData.fold<double>(0, (sum, row) => sum + (row['value'] as double));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Sales Report', style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 16)),
            pw.SizedBox(height: 4),
            pw.Text('Product: $productName', style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 12)),
            pw.SizedBox(height: 2),
            pw.Text('$shopName  •  $now',
                style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9, color: PdfColors.grey600)),
            pw.SizedBox(height: 4),
            pw.Divider(),
            pw.SizedBox(height: 4),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 8, color: PdfColors.white),
            cellStyle: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 8),
            headerAlignment: pw.Alignment.center,
            cellAlignment: pw.Alignment.center,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey400),
            headers: ['DATE', 'ACTION', 'IN', 'OUT', 'BAL', 'VALUE'],
            data: [
              ...salesData.map((row) => [
                '${row['date']}',
                '${row['action']}',
                '${row['in']}',
                '${row['out']}',
                '${row['bal']}',
                _fmt(row['value'] as double),
              ]),
              ['TOTAL', '$totalReturns returns', '', '$totalOut sold', '', _fmt(totalSalesValue)],
            ],
          ),
        ],
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 7, color: PdfColors.grey500),
          ),
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${productName}_Sales_${_exportDateTime}.pdf');
    await file.writeAsBytes(await doc.save(), flush: true);
    await OpenFile.open(file.path);
  }

  // ─── PHOTOS DIALOG ───────────────────────────────────────────────────
  static void showPhotosDialog({
    required BuildContext context,
    required String productName,
  }) {
    // Sample photos - in real app these would come from the product's photo list
    final List<String> samplePhotos = [
      'https://via.placeholder.com/400x400/007AFF/FFFFFF?text=${Uri.encodeComponent(productName)}+1',
      'https://via.placeholder.com/400x400/34C759/FFFFFF?text=${Uri.encodeComponent(productName)}+2',
      'https://via.placeholder.com/400x400/FF9500/FFFFFF?text=${Uri.encodeComponent(productName)}+3',
    ];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMD),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product Photos',
                            style: AppTypography.h6.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            productName,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 22),
                    ),
                  ],
                ),
              ),
              // Photos grid
              Flexible(
                child: samplePhotos.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.photo_library_outlined,
                                size: 48,
                                color: AppColors.textHint.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No photos available',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(AppConstants.paddingMD),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: samplePhotos.length,
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              samplePhotos[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_rounded,
                                      size: 32,
                                      color: AppColors.primary.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Photo ${index + 1}',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
