import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

class _CategoryStock {
  final int sn;
  final String category;
  final int quantity;
  final double stockValue;
  final double sales;
  final double profit;

  const _CategoryStock({
    required this.sn,
    required this.category,
    required this.quantity,
    required this.stockValue,
    required this.sales,
    required this.profit,
  });

  double get total => stockValue + sales + profit;
}

class StockByCategoryReportPage extends StatefulWidget {
  const StockByCategoryReportPage({super.key});

  @override
  State<StockByCategoryReportPage> createState() =>
      _StockByCategoryReportPageState();
}

class _StockByCategoryReportPageState extends State<StockByCategoryReportPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalController = ScrollController();

  static const List<_CategoryStock> _allCategories = [
    _CategoryStock(sn: 1, category: 'Beverages', quantity: 450, stockValue: 2800000, sales: 1500000, profit: 650000),
    _CategoryStock(sn: 2, category: 'Snacks & Confectionery', quantity: 320, stockValue: 1200000, sales: 850000, profit: 320000),
    _CategoryStock(sn: 3, category: 'Household Cleaning', quantity: 180, stockValue: 950000, sales: 600000, profit: 210000),
    _CategoryStock(sn: 4, category: 'Personal Care', quantity: 210, stockValue: 1100000, sales: 720000, profit: 280000),
    _CategoryStock(sn: 5, category: 'Groceries & Staples', quantity: 380, stockValue: 2400000, sales: 1300000, profit: 480000),
    _CategoryStock(sn: 6, category: 'Dairy & Eggs', quantity: 150, stockValue: 800000, sales: 520000, profit: 180000),
    _CategoryStock(sn: 7, category: 'Frozen Foods', quantity: 120, stockValue: 650000, sales: 400000, profit: 140000),
    _CategoryStock(sn: 8, category: 'Bakery', quantity: 90, stockValue: 400000, sales: 300000, profit: 110000),
    _CategoryStock(sn: 9, category: 'Alcohol & Spirits', quantity: 200, stockValue: 5200000, sales: 2800000, profit: 1200000),
    _CategoryStock(sn: 10, category: 'Stationery & Office', quantity: 160, stockValue: 550000, sales: 350000, profit: 125000),
    _CategoryStock(sn: 11, category: 'Baby Products', quantity: 140, stockValue: 780000, sales: 480000, profit: 175000),
    _CategoryStock(sn: 12, category: 'Electronics & Accessories', quantity: 80, stockValue: 3200000, sales: 1600000, profit: 750000),
  ];

  List<_CategoryStock> get _filteredItems {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return _allCategories;
    return _allCategories
        .where((c) => c.category.toLowerCase().contains(query))
        .toList();
  }

  int get _totalQuantity => _filteredItems.fold(0, (s, i) => s + i.quantity);
  double get _totalStockValue => _filteredItems.fold(0, (s, i) => s + i.stockValue);
  double get _totalSales => _filteredItems.fold(0, (s, i) => s + i.sales);
  double get _totalProfit => _filteredItems.fold(0, (s, i) => s + i.profit);
  double get _grandTotal => _filteredItems.fold(0, (s, i) => s + i.total);

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

  // ─── PDF ─────────────────────────────────────────────────────────────
  Future<void> _exportPdf() async {
    final items = _filteredItems;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    final doc = pw.Document();
    final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Stock by Category Report',
                style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 16)),
            pw.SizedBox(height: 2),
            pw.Text('DukaApp Main Shop  •  $now',
                style: pw.TextStyle(
                    font: pw.Font.helvetica(), fontSize: 9, color: PdfColors.grey600)),
            pw.SizedBox(height: 4),
            pw.Divider(),
            pw.SizedBox(height: 4),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
                font: pw.Font.helveticaBold(), fontSize: 7, color: PdfColors.white),
            cellStyle: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 7),
            headerAlignment: pw.Alignment.center,
            cellAlignment: pw.Alignment.center,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey400),
            headers: ['S/N', 'Category', 'Quantity', 'Stock Value', 'Sales', 'Profit', 'Total'],
            data: [
              ...items.map((i) => [
                '${i.sn}', i.category, '${i.quantity}', _fmt(i.stockValue),
                _fmt(i.sales), _fmt(i.profit), _fmt(i.total),
              ]),
              ['', 'TOTAL', '$_totalQuantity', _fmt(_totalStockValue), _fmt(_totalSales), _fmt(_totalProfit), _fmt(_grandTotal)],
            ],
          ),
        ],
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(
                font: pw.Font.helvetica(), fontSize: 7, color: PdfColors.grey500),
          ),
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/StockByCategory_$_exportDateTime.pdf');
    await file.writeAsBytes(await doc.save(), flush: true);
    await OpenFile.open(file.path);
  }

  // ─── EXCEL ───────────────────────────────────────────────────────────
  Future<void> _exportExcel() async {
    final items = _filteredItems;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    final excel = xls.Excel.createExcel();
    excel.rename(excel.getDefaultSheet()!, 'Stock by Category');

    final sheet = excel['Stock by Category'];

    final headers = ['S/N', 'Category', 'Quantity', 'Stock Value', 'Sales', 'Profit', 'Total'];
    sheet.appendRow(headers.map((h) => xls.TextCellValue(h)).toList());

    for (final item in items) {
      sheet.appendRow([
        xls.DoubleCellValue(item.sn.toDouble()),
        xls.TextCellValue(item.category),
        xls.DoubleCellValue(item.quantity.toDouble()),
        xls.DoubleCellValue(item.stockValue),
        xls.DoubleCellValue(item.sales),
        xls.DoubleCellValue(item.profit),
        xls.DoubleCellValue(item.total),
      ]);
    }

    sheet.appendRow([
      xls.TextCellValue(''),
      xls.TextCellValue('TOTAL'),
      xls.DoubleCellValue(_totalQuantity.toDouble()),
      xls.DoubleCellValue(_totalStockValue),
      xls.DoubleCellValue(_totalSales),
      xls.DoubleCellValue(_totalProfit),
      xls.DoubleCellValue(_grandTotal),
    ]);

    final fileBytes = excel.save();
    if (fileBytes == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/StockByCategory_$_exportDateTime.xlsx');
    await file.writeAsBytes(fileBytes, flush: true);
    await OpenFile.open(file.path);
  }

  String _fmt(double v) => v >= 1000000
      ? '${(v / 1000000).toStringAsFixed(1)}M'
      : v.toStringAsFixed(0);

  // ─── UI ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;

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
              items.isEmpty
                  ? _buildEmptyState()
                  : _buildTable(items),
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
      title: Text(
        'Stock by Category',
        style: AppTypography.h6.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.divider),
      ),
    );
  }

  Widget _buildShopHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLG, vertical: 12),
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
                  'DukaApp Main Shop',
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
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLG, vertical: 10),
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
      padding:
          const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: AppTypography.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search categories...',
          hintStyle:
              AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textHint, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textHint, size: 18),
                )
              : null,
          filled: true,
          fillColor: AppColors.card,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(AppConstants.textFieldRadius),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(AppConstants.textFieldRadius),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(AppConstants.textFieldRadius),
            borderSide: const BorderSide(
                color: AppColors.inputFocusBorder, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildTable(List<_CategoryStock> items) {
    return Container(
      margin:
          const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
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
              _buildTableHeader(),
              ...items.asMap().entries.map(
                  (entry) => _buildTableRow(entry.value, entry.key)),
              _buildTotalsRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(color: AppColors.primary),
      child: Row(
        children: [
          _headerCell('S/N', 36),
          _headerCell('Category', 160),
          _headerCell('Quantity', 70),
          _headerCell('Stock Value', 80),
          _headerCell('Sales', 80),
          _headerCell('Profit', 80),
          _headerCell('Total', 80),
        ],
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

  Widget _buildTableRow(_CategoryStock item, int index) {
    final isEven = index % 2 == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isEven ? AppColors.card : AppColors.background,
      ),
      child: Row(
        children: [
          _dataCell('${item.sn}', 36),
          _nameCell(item.category, 160),
          _dataCell('${item.quantity}', 70),
          _moneyCell(item.stockValue, 80),
          _moneyCell(item.sales, 80),
          _profitCell(item.profit, 80),
          _totalCell(item.total, 80),
        ],
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

  Widget _nameCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _moneyCell(double value, double width) {
    return SizedBox(
      width: width,
      child: Text(
        _fmt(value),
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

  Widget _profitCell(double value, double width) {
    final isPositive = value >= 0;
    return SizedBox(
      width: width,
      child: Text(
        _fmt(value),
        style: AppTypography.caption.copyWith(
          color: isPositive ? AppColors.success : AppColors.danger,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _totalCell(double value, double width) {
    return SizedBox(
      width: width,
      child: Text(
        _fmt(value),
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

  Widget _buildTotalsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        border: Border(
          top: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          _totalCellW('', 36),
          _totalLabelCell('TOTAL', 160),
          _totalCellW('$_totalQuantity', 70),
          _totalCellW(_fmt(_totalStockValue), 80),
          _totalCellW(_fmt(_totalSales), 80),
          _totalProfitCell(_totalProfit, 80),
          _totalValueCell(_grandTotal, 80),
        ],
      ),
    );
  }

  Widget _totalCellW(String text, double width) {
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

  Widget _totalProfitCell(double value, double width) {
    final isPositive = value >= 0;
    return SizedBox(
      width: width,
      child: Text(
        _fmt(value),
        style: AppTypography.caption.copyWith(
          color: isPositive ? AppColors.success : AppColors.danger,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _totalValueCell(double value, double width) {
    return SizedBox(
      width: width,
      child: Text(
        _fmt(value),
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
                Icons.category_outlined,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Categories Found',
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
