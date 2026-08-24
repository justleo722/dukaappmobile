// features/purchase/presentation/pages/purchase_reports/purchase_report_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xls;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/shared/dialogs/app_filter_dialog.dart';
import 'package:go_router/go_router.dart';

class PurchaseReportPage extends StatefulWidget {
  final String reportKey;
  final String title;

  const PurchaseReportPage({required this.reportKey, required this.title, super.key});

  @override
  State<PurchaseReportPage> createState() => _PurchaseReportPageState();
}

class _PurchaseReportPageState extends State<PurchaseReportPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalController = ScrollController();

  String get _currentDateTime {
    final now = DateTime.now();
    final date = DateFormat('dd MMM yyyy').format(now);
    final time = DateFormat('hh:mm a').format(now);
    return '$date • $time';
  }

  String get _exportDateTime => DateFormat('dd-MM-yyyy_HH-mm').format(DateTime.now());

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  String _parseNumeric(String s) => s.replaceAll(RegExp(r'[^0-9.]'), '');

  bool _isNumericColumn(String header) {
    final h = header.toLowerCase();
    return h == 'total' || h == 'paid' || h == 'balance' || h == 'qty' || h == 'items' || h == 'wallet';
  }

  List<List<String>> get _filteredRows {
    final map = _reportData();
    final rows = List<List<String>>.from(map['rows'] as List);
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return rows;
    return rows.where((row) {
      return row.any((cell) => cell.toLowerCase().contains(query));
    }).toList();
  }

  List<String> get _headers => List<String>.from((_reportData()['headers'] as List));

  List<String> _computeTotals(List<List<String>> rows, List<String> headers) {
    final totals = List<String>.filled(headers.length, '');
    for (int col = 0; col < headers.length; col++) {
      if (_isNumericColumn(headers[col])) {
        double sum = 0;
        for (final row in rows) {
          if (col < row.length) {
            sum += double.tryParse(_parseNumeric(row[col])) ?? 0;
          }
        }
        final fmt = NumberFormat('#,###');
        totals[col] = fmt.format(sum);
      }
    }
    return totals;
  }

  // ─── PDF ─────────────────────────────────────────────────────────────
  Future<void> _exportPdf() async {
    final rows = _filteredRows;
    final headers = _headers;
    if (rows.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }

    final doc = pw.Document();
    final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final totals = _computeTotals(rows, headers);
    final hasTotals = totals.any((t) => t.isNotEmpty);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(widget.title, style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 16)),
            pw.SizedBox(height: 2),
            pw.Text('SON COLLECTION  •  $now',
                style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9, color: PdfColors.grey600)),
            pw.SizedBox(height: 4),
            pw.Divider(),
            pw.SizedBox(height: 4),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 7, color: PdfColors.white),
            cellStyle: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 7),
            headerAlignment: pw.Alignment.center,
            cellAlignment: pw.Alignment.center,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey400),
            headers: headers,
            data: [
              ...rows.map((r) => r),
              if (hasTotals)
                totals.asMap().entries.map((e) {
                  if (e.key == 0) return 'TOTAL';
                  return e.value;
                }).toList(),
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
    final file = File('${dir.path}/${widget.reportKey}_$_exportDateTime.pdf');
    await file.writeAsBytes(await doc.save(), flush: true);
    await OpenFile.open(file.path);
  }

  // ─── EXCEL ───────────────────────────────────────────────────────────
  Future<void> _exportExcel() async {
    final rows = _filteredRows;
    final headers = _headers;
    if (rows.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }

    final excel = xls.Excel.createExcel();
    excel.rename(excel.getDefaultSheet()!, widget.title);
    final sheet = excel[widget.title];

    sheet.appendRow(headers.map((h) => xls.TextCellValue(h)).toList());

    for (final r in rows) {
      sheet.appendRow(r.asMap().entries.map((e) {
        if (_isNumericColumn(headers[e.key])) {
          return xls.DoubleCellValue(double.tryParse(_parseNumeric(e.value)) ?? 0);
        }
        return xls.TextCellValue(e.value);
      }).toList());
    }

    final totals = _computeTotals(rows, headers);
    final hasTotals = totals.any((t) => t.isNotEmpty);
    if (hasTotals) {
      sheet.appendRow(totals.asMap().entries.map((e) {
        if (e.key == 0) return xls.TextCellValue('TOTAL');
        if (e.value.isEmpty) return xls.TextCellValue('');
        return xls.DoubleCellValue(double.tryParse(_parseNumeric(e.value)) ?? 0);
      }).toList());
    }

    final bytes = excel.save();
    if (bytes == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${widget.reportKey}_$_exportDateTime.xlsx');
    await file.writeAsBytes(bytes, flush: true);
    await OpenFile.open(file.path);
  }

  // ─── DATA ────────────────────────────────────────────────────────────
  Map<String, dynamic> _reportData() {
    switch (widget.reportKey) {
      case 'purchase_history':
        return {
          'headers': ['S/N', 'Date', 'Products', 'Total', 'Paid', 'Balance'],
          'rows': [
            ['1', '01 Jul 2026', 'AIR x20', '90,000', '90,000', '0'],
            ['2', '02 Jul 2026', 'CREAM x15', '180,000', '180,000', '0'],
          ]
        };
      case 'total_purchase':
        return {
          'headers': ['S/N', 'Purchases', 'Items', 'Total', 'Paid', 'Balance'],
          'rows': [
            ['1', 'PUR-001', '25', '270,000', '200,000', '70,000'],
          ]
        };
      case 'orders':
        return {
          'headers': ['S/N', 'Purchases', 'Items', 'Total', 'Paid', 'Balance'],
          'rows': [
            ['1', 'ORD-001', '50', '450,000', '450,000', '0'],
          ]
        };
      case 'suppliers':
        return {
          'headers': ['S/N', 'Supplier', 'Phone', 'Wallet'],
          'rows': [
            ['1', 'JUMA SUPPLIERS', '0712 345678', 'MPESA: 12345'],
          ]
        };
      case 'cash_purchase':
        return {
          'headers': ['S/N', 'Supplier', 'Total', 'Paid', 'Balance'],
          'rows': [
            ['1', 'AMINA TRADERS', '120,000', '120,000', '0'],
          ]
        };
      case 'credit_purchase':
        return {
          'headers': ['S/N', 'Date', 'Supplier', 'Total', 'Paid', 'Balance', 'Status'],
          'rows': [
            ['1', '03 Jul 2026', 'HASSAN WHOLESALE', '240,000', '200,000', '40,000', 'PENDING'],
          ]
        };
      case 'by_category':
        return {
          'headers': ['S/N', 'Category', 'Qty', 'Total'],
          'rows': [
            ['1', 'Beverages', '120', '450,000'],
          ]
        };
      case 'by_products':
        return {
          'headers': ['S/N', 'Product', 'Category', 'Qty', 'Total'],
          'rows': [
            ['1', 'AIR', 'Cleaning', '30', '135,000'],
          ]
        };
      case 'by_supplier':
        return {
          'headers': ['S/N', 'Supplier', 'Total', 'Paid', 'Balance'],
          'rows': [
            ['1', 'FATIMA ENTERPRISES', '287,500', '0', '287,500'],
          ]
        };
      case 'stock_returned':
        return {
          'headers': ['S/N', 'Date', 'Supplier', 'Qty', 'Total'],
          'rows': [
            ['1', '05 Jul 2026', 'JUMA SUPPLIERS', '10', '50,000'],
          ]
        };
      default:
        return {'headers': <String>[], 'rows': <List<String>>[]};
    }
  }

  double _columnWidth(String header) {
    switch (header) {
      case 'S/N':
        return 40;
      case 'Date':
        return 100;
      case 'Products':
      case 'Product':
        return 120;
      case 'Category':
        return 90;
      case 'Purchases':
      case 'Purchase':
        return 90;
      case 'Supplier':
        return 140;
      case 'Items':
      case 'Qty':
        return 50;
      case 'Status':
        return 70;
      case 'Phone':
        return 100;
      case 'Wallet':
        return 100;
      default:
        return 80;
    }
  }

  // ─── UI ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final rows = _filteredRows;
    final headers = _headers;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              _buildShopHeader(),
              _buildActionButtons(context),
              const SizedBox(height: 12),
              _buildSearchField(),
              const SizedBox(height: 12),
              rows.isEmpty ? _buildEmptyState() : _buildTable(rows, headers),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomCloseButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
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
            widget.title,
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'SON COLLECTION',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppColors.divider,
        ),
      ),
    );
  }

  Widget _buildShopHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 12),
      color: AppColors.card,
      child: Row(
        children: [
          Icon(Icons.storefront_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SON COLLECTION',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentDateTime,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 10),
      color: AppColors.card,
      child: Row(
        children: [
          _buildActionButton(
            icon: Icons.picture_as_pdf_rounded,
            label: 'PDF',
            color: AppColors.danger,
            onTap: _exportPdf,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.table_chart_rounded,
            label: 'Excel',
            color: AppColors.success,
            onTap: _exportExcel,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.filter_list_rounded,
            label: 'Filter',
            color: AppColors.primary,
            onTap: () => AppFilterDialog.show(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: AppTypography.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search purchases...',
          hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.close_rounded, color: AppColors.textHint, size: 18),
                )
              : null,
          filled: true,
          fillColor: AppColors.card,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
            borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildTable(List<List<String>> rows, List<String> headers) {
    final totals = _computeTotals(rows, headers);
    final hasTotals = totals.any((t) => t.isNotEmpty);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _horizontalController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTableHeader(headers),
              ...rows.asMap().entries.map(
                  (entry) => _buildTableRow(entry.value, entry.key, headers)),
              if (hasTotals) _buildTotalsRow(totals, headers),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader(List<String> headers) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: const BoxDecoration(color: AppColors.primary),
      child: Row(
        children: headers.map((h) => _headerCell(h, _columnWidth(h))).toList(),
      ),
    );
  }

  Widget _headerCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: AppColors.textWhite,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableRow(List<String> row, int index, List<String> headers) {
    final isEven = index % 2 == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isEven ? AppColors.card : AppColors.background,
      ),
      child: Row(
        children: row.asMap().entries.map((e) {
          final header = headers[e.key];
          if (header == 'Status') {
            return _statusCell(e.value, _columnWidth(header));
          }
          return _dataCell(e.value, _columnWidth(header));
        }).toList(),
      ),
    );
  }

  Widget _dataCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: AppColors.textPrimary,
          fontSize: 10,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _statusCell(String text, double width) {
    Color color;
    switch (text.toUpperCase()) {
      case 'PAID':
        color = AppColors.success;
        break;
      case 'PENDING':
        color = AppColors.warning;
        break;
      case 'PARTIAL':
        color = AppColors.primary;
        break;
      default:
        color = AppColors.textPrimary;
    }

    return SizedBox(
      width: width,
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTotalsRow(List<String> totals, List<String> headers) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        border: Border(
          top: BorderSide(color: AppColors.primary.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: Row(
        children: totals.asMap().entries.map((e) {
          if (e.key == 0) {
            return _totalLabelCell('TOTAL', _columnWidth(headers[e.key]));
          }
          return _totalCell(e.value, _columnWidth(headers[e.key]));
        }).toList(),
      ),
    );
  }

  Widget _totalCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _totalLabelCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingXXL,
          vertical: 60,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Purchases Found',
              style: AppTypography.h6.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different search term.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCloseButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppConstants.paddingLG,
        right: AppConstants.paddingLG,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: const Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: AppConstants.buttonHeight,
        child: OutlinedButton(
          onPressed: () => context.pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            ),
          ),
          child: Text(
            'Close',
            style: AppTypography.buttonLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
