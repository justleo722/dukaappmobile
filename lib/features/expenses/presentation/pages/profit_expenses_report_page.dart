import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xls;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/shared/dialogs/app_filter_dialog.dart';

class ProfitExpensesReportPage extends StatefulWidget {
  final String reportKey;
  final String title;

  const ProfitExpensesReportPage({required this.reportKey, required this.title, super.key});

  @override
  State<ProfitExpensesReportPage> createState() => _ProfitExpensesReportPageState();
}

class _ProfitExpensesReportPageState extends State<ProfitExpensesReportPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalController = ScrollController();

  String get _exportDateTime => DateFormat('dd-MM-yyyy_HH-mm').format(DateTime.now());

  String get _currentDateTime {
    final now = DateTime.now();
    final date = DateFormat('dd MMM yyyy').format(now);
    final time = DateFormat('hh:mm a').format(now);
    return '$date • $time';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  String _parseNumeric(String s) => s.replaceAll(RegExp(r'[^0-9.]'), '');

  bool _isNumericColumn(String header) {
    final h = header.toLowerCase();
    return h == 'total sales' || h == 'gross profit' || h == 'bad/lost/expired stock' ||
        h == 'expenses' || h == 'net profit' || h == 'cash in hand' ||
        h == 'amount' || h == 'sold' || h == 'sales' || h == 'profit' ||
        h == 'bad' || h == 'lost' || h == 'expired' || h == 'loss';
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
            pw.Text('SON COLLECTION  \u2022  $now',
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
      case 'daily-profit':
        return {
          'headers': ['S/N', 'Date', 'Total Sales', 'Gross Profit', 'Bad/Lost/Expired Stock', 'Expenses', 'Net Profit', 'Cash In Hand'],
          'rows': [
            ['1', '13 Aug 2026', '350,000', '98,000', '5,000', '65,000', '28,000', '380,000'],
            ['2', '12 Aug 2026', '285,000', '76,500', '3,000', '40,000', '33,500', '352,000'],
            ['3', '11 Aug 2026', '412,000', '115,000', '8,000', '55,000', '52,000', '318,500'],
            ['4', '10 Aug 2026', '198,000', '52,000', '2,500', '45,000', '4,500', '266,500'],
            ['5', '09 Aug 2026', '520,000', '145,000', '12,000', '70,000', '63,000', '262,000'],
          ]
        };
      case 'all-expenses':
        return {
          'headers': ['S/N', 'Date', 'Title', 'Category', 'Amount', 'Status'],
          'rows': [
            ['1', '13 Aug 2026', 'Rent Payment', 'Utilities', '500,000', 'Paid'],
            ['2', '13 Aug 2026', 'Electricity Bill', 'Utilities', '85,000', 'Paid'],
            ['3', '12 Aug 2026', 'Staff Lunch', 'Food', '25,000', 'Paid'],
            ['4', '12 Aug 2026', 'Transport Fare', 'Transport', '15,000', 'Pending'],
            ['5', '11 Aug 2026', 'Cleaning Supplies', 'Maintenance', '12,000', 'Paid'],
            ['6', '10 Aug 2026', 'Internet Subscription', 'Utilities', '45,000', 'Paid'],
            ['7', '09 Aug 2026', 'Packaging Materials', 'Operations', '30,000', 'Paid'],
            ['8', '08 Aug 2026', 'Water Bill', 'Utilities', '18,000', 'Pending'],
          ]
        };
      case 'profits':
        return {
          'headers': ['S/N', 'Item Name', 'Sold', 'Sales', 'Profit'],
          'rows': [
            ['1', 'Coca Cola 600ML', '24', '24,000', '4,300'],
            ['2', 'Fanta Orange', '18', '18,000', '3,600'],
            ['3', 'Pepsi 500ML', '12', '12,000', '3,000'],
            ['4', 'Minute Maid', '10', '18,000', '6,000'],
            ['5', 'Mango Juice', '15', '22,500', '7,500'],
            ['6', 'Energy Drink', '8', '20,000', '8,000'],
            ['7', 'Chips', '30', '15,000', '6,000'],
            ['8', 'Biscuits', '40', '14,000', '5,500'],
          ]
        };
      case 'loss':
        return {
          'headers': ['S/N', 'Item Name', 'Bad', 'Lost', 'Expired', 'Loss'],
          'rows': [
            ['1', 'Coca Cola 600ML', '2', '0', '3', '5,000'],
            ['2', 'Fanta Orange', '1', '1', '0', '2,000'],
            ['3', 'Pepsi 500ML', '0', '2', '1', '3,000'],
            ['4', 'Minute Maid', '1', '0', '2', '5,400'],
            ['5', 'Energy Drink', '0', '1', '1', '4,000'],
            ['6', 'Biscuits', '3', '0', '4', '2,100'],
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
      case 'Item Name':
      case 'Title':
        return 120;
      case 'Category':
        return 90;
      case 'Status':
        return 70;
      default:
        return 85;
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
          hintText: 'Search report\u2026',
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
              'No Data Found',
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
}
