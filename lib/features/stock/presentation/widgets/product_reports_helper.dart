import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';

class ProductReportsHelper {
  static String _fmt(double v) => v >= 1000000
      ? '${(v / 1000000).toStringAsFixed(1)}M'
      : v.toStringAsFixed(0);

  static String get _exportDateTime => DateFormat('dd-MM-yyyy_HH-mm').format(DateTime.now());

  static List<Map<String, dynamic>> _parseRows(dynamic raw) {
    if (raw is List) return raw.cast<Map<String, dynamic>>();
    if (raw is Map<String, dynamic>) {
      final d = raw['data'] ?? raw['rows'] ?? raw;
      if (d is List) return d.cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> _fetchHistory(
      WidgetRef ref, String productId) async {
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getProductHistory(productId: productId);
      return _parseRows(res.data);
    } catch (_) {
      return [];
    }
  }

  // ─── HISTORY PDF ──────────────────────────────────────────────────────
  // Columns: S/N, Date, Type, Qty, Balance
  static Future<void> exportHistoryPdf({
    required BuildContext context,
    required WidgetRef ref,
    required String productName,
    required String productId,
    String shopName = '',
  }) async {
    final rows = await _fetchHistory(ref, productId);
    final doc = pw.Document();
    final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final List<Map<String, dynamic>> historyData = rows.isEmpty
        ? []
        : rows.asMap().entries.map((e) => {
              'sn': e.key + 1,
              'date': e.value['datetime']?.toString() ?? e.value['record_date']?.toString() ?? '',
              'type': e.value['action_label']?.toString() ?? '',
              'qty': e.value['quantity']?.toString() ?? '0',
              'balance': e.value['available']?.toString() ?? '0',
            }).toList();

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
    required WidgetRef ref,
    required String productName,
    required String productId,
    required double buyingPrice,
    String shopName = '',
  }) async {
    final rows = await _fetchHistory(ref, productId);
    final doc = pw.Document();
    final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final List<Map<String, dynamic>> stockData = rows.map((r) {
      final bal = double.tryParse(r['available']?.toString() ?? '0') ?? 0;
      final bp = double.tryParse(r['bp']?.toString() ?? '0') ?? buyingPrice;
      return {
        'date': r['datetime']?.toString() ?? r['record_date']?.toString() ?? '',
        'action': r['action_label']?.toString() ?? '',
        'in': r['quantity_in']?.toString() ?? '0',
        'out': r['quantity_out']?.toString() ?? '0',
        'bal': bal.toStringAsFixed(0),
        'value': _fmt(bal * bp),
      };
    }).toList();

    final totalIn = rows.fold<double>(0, (s, r) => s + (double.tryParse(r['quantity_in']?.toString() ?? '0') ?? 0));
    final totalOut = rows.fold<double>(0, (s, r) => s + (double.tryParse(r['quantity_out']?.toString() ?? '0') ?? 0));
    final finalBal = stockData.isNotEmpty ? stockData.last['bal'] : '0';
    final lastBp = rows.isNotEmpty ? (double.tryParse(rows.last['bp']?.toString() ?? '0') ?? buyingPrice) : buyingPrice;
    final finalValue = _fmt((double.tryParse(finalBal.toString()) ?? 0) * lastBp);

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
                '${row['value']}',
              ]),
              ['TOTAL', '', totalIn.toStringAsFixed(0), totalOut.toStringAsFixed(0), '$finalBal', finalValue],
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
  // Columns: DATE, ACTION, IN, OUT, BAL, VALUE (sale movements only)
  static Future<void> exportSalesPdf({
    required BuildContext context,
    required WidgetRef ref,
    required String productName,
    required String productId,
    required double sellingPrice,
    String shopName = '',
  }) async {
    final rows = await _fetchHistory(ref, productId);
    // Filter to sale/return movements only
    final saleRows = rows.where((r) {
      final t = r['movement_type']?.toString() ?? '';
      return ['sale', 'outbound', 'return', 'inbound'].contains(t.toLowerCase());
    }).toList();
    final doc = pw.Document();
    final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final List<Map<String, dynamic>> salesData = saleRows.map((r) {
      final sp = double.tryParse(r['sp']?.toString() ?? '0') ?? sellingPrice;
      final qOut = double.tryParse(r['quantity_out']?.toString() ?? '0') ?? 0;
      final qIn = double.tryParse(r['quantity_in']?.toString() ?? '0') ?? 0;
      final val = qOut > 0 ? qOut * sp : -(qIn * sp);
      return {
        'date': r['datetime']?.toString() ?? r['record_date']?.toString() ?? '',
        'action': r['action_label']?.toString() ?? '',
        'in': qIn.toStringAsFixed(0),
        'out': qOut.toStringAsFixed(0),
        'bal': (double.tryParse(r['available']?.toString() ?? '0') ?? 0).toStringAsFixed(0),
        'value': _fmt(val),
        '_val': val,
        '_out': qOut,
        '_in': qIn,
      };
    }).toList();

    final totalOut = salesData.fold<double>(0, (s, r) => s + (r['_out'] as double));
    final totalReturns = salesData.fold<double>(0, (s, r) => s + (r['_in'] as double));
    final totalSalesValue = salesData.fold<double>(0, (s, r) => s + (r['_val'] as double));

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
                '${row['value']}',
              ]),
              ['TOTAL', '${totalReturns.toStringAsFixed(0)} returns', '', '${totalOut.toStringAsFixed(0)} sold', '', _fmt(totalSalesValue)],
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
