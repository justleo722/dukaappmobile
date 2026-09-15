import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:dukaapp/features/stock/presentation/providers/stock_provider.dart';
import 'package:dukaapp/shared/dialogs/app_filter_dialog.dart';
import 'package:dukaapp/shared/providers/filter_provider.dart';
import 'package:dukaapp/core/providers.dart';

class _StockItem {
  final int sn;
  final String name;
  final double bp;
  final double sp;
  final int inStock;
  final int sold;
  final int bad;
  final int lost;
  final int expired;

  const _StockItem({
    required this.sn,
    required this.name,
    required this.bp,
    required this.sp,
    required this.inStock,
    required this.sold,
    required this.bad,
    required this.lost,
    required this.expired,
  });

  int get balance => inStock - sold - bad - lost - expired;
  double get stockValue => bp * balance;
  double get sales => sp * sold;
  double get profitEstimate => sales - (bp * sold);
}

class AllStockReportPage extends ConsumerStatefulWidget {
  const AllStockReportPage({super.key});

  @override
  ConsumerState<AllStockReportPage> createState() => _AllStockReportPageState();
}

class _AllStockReportPageState extends ConsumerState<AllStockReportPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalController = ScrollController();

  List<_StockItem> _allItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadItems());
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final filter = ref.read(filterProvider);
      final api = ref.read(apiServiceProvider);
      final resp = await api.getStock(from: filter.from, to: filter.to);
      final raw = resp.data;
      List<dynamic> rows = [];
      if (raw is Map) {
        rows = (raw['data'] ?? raw['stock'] ?? raw['products'] ?? []) as List;
      } else if (raw is List) {
        rows = raw;
      }
      final items = rows.asMap().entries.map((e) {
        final j = e.value as Map<String, dynamic>;
        double _d(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
        return _StockItem(
          sn: e.key + 1,
          name: (j['product_name'] ?? j['name'] ?? '').toString(),
          bp: _d(j['bp'] ?? j['buying_price']),
          sp: _d(j['sp'] ?? j['selling_price']),
          inStock: _d(j['available'] ?? j['quantity'] ?? j['qty']).toInt(),
          sold: _d(j['sold']).toInt(),
          bad: _d(j['bad']).toInt(),
          lost: _d(j['lost']).toInt(),
          expired: _d(j['expired']).toInt(),
        );
      }).toList();
      if (mounted) setState(() => _allItems = items);
    } catch (_) {
      if (mounted) setState(() => _allItems = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_StockItem> get _filteredItems {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return _allItems;
    return _allItems.where((item) => item.name.toLowerCase().contains(query)).toList();
  }

  int get _totalIn => _filteredItems.fold(0, (s, i) => s + i.inStock);
  int get _totalSold => _filteredItems.fold(0, (s, i) => s + i.sold);
  int get _totalBad => _filteredItems.fold(0, (s, i) => s + i.bad);
  int get _totalLost => _filteredItems.fold(0, (s, i) => s + i.lost);
  int get _totalExpired => _filteredItems.fold(0, (s, i) => s + i.expired);
  int get _totalBalance => _filteredItems.fold(0, (s, i) => s + i.balance);
  double get _totalStockValue => _filteredItems.fold(0, (s, i) => s + i.stockValue);
  double get _totalSales => _filteredItems.fold(0, (s, i) => s + i.sales);
  double get _totalProfit => _filteredItems.fold(0, (s, i) => s + i.profitEstimate);

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
            pw.Text('All Stock Report', style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 16)),
            pw.SizedBox(height: 2),
            pw.Text('${ref.read(shopNameProvider).valueOrNull ?? 'My Shop'}  •  $now',
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
            headers: ['S/N', 'Item Name', 'BP', 'SP', 'In', 'Sold', 'Bad', 'Lost', 'Exp', 'Bal', 'Stock Val', 'Sales', 'Profit'],
            data: [
              ...items.map((i) => [
                '${i.sn}', i.name, _fmt(i.bp), _fmt(i.sp),
                '${i.inStock}', '${i.sold}', '${i.bad}', '${i.lost}', '${i.expired}',
                '${i.balance}', _fmt(i.stockValue), _fmt(i.sales), _fmt(i.profitEstimate),
              ]),
              ['', 'TOTAL', '', '', '$_totalIn', '$_totalSold', '$_totalBad', '$_totalLost', '$_totalExpired', '$_totalBalance', _fmt(_totalStockValue), _fmt(_totalSales), _fmt(_totalProfit)],
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
    final file = File('${dir.path}/AllStockReport_$_exportDateTime.pdf');
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
    excel.rename(excel.getDefaultSheet()!, 'All Stock Report');

    final sheet = excel['All Stock Report'];

    final headers = ['S/N', 'Item Name', 'BP', 'SP', 'In', 'Sold', 'Bad', 'Lost', 'Exp', 'Bal', 'Stock Val', 'Sales', 'Profit'];
    sheet.appendRow(headers.map((h) => xls.TextCellValue(h)).toList());

    for (final item in items) {
      sheet.appendRow([
        xls.DoubleCellValue(item.sn.toDouble()),
        xls.TextCellValue(item.name),
        xls.DoubleCellValue(item.bp),
        xls.DoubleCellValue(item.sp),
        xls.DoubleCellValue(item.inStock.toDouble()),
        xls.DoubleCellValue(item.sold.toDouble()),
        xls.DoubleCellValue(item.bad.toDouble()),
        xls.DoubleCellValue(item.lost.toDouble()),
        xls.DoubleCellValue(item.expired.toDouble()),
        xls.DoubleCellValue(item.balance.toDouble()),
        xls.DoubleCellValue(item.stockValue),
        xls.DoubleCellValue(item.sales),
        xls.DoubleCellValue(item.profitEstimate),
      ]);
    }

    sheet.appendRow([
      xls.TextCellValue(''),
      xls.TextCellValue('TOTAL'),
      xls.TextCellValue(''),
      xls.TextCellValue(''),
      xls.DoubleCellValue(_totalIn.toDouble()),
      xls.DoubleCellValue(_totalSold.toDouble()),
      xls.DoubleCellValue(_totalBad.toDouble()),
      xls.DoubleCellValue(_totalLost.toDouble()),
      xls.DoubleCellValue(_totalExpired.toDouble()),
      xls.DoubleCellValue(_totalBalance.toDouble()),
      xls.DoubleCellValue(_totalStockValue),
      xls.DoubleCellValue(_totalSales),
      xls.DoubleCellValue(_totalProfit),
    ]);

    final fileBytes = excel.save();
    if (fileBytes == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/AllStockReport_$_exportDateTime.xlsx');
    await file.writeAsBytes(fileBytes, flush: true);
    await OpenFile.open(file.path);
  }

  String _fmt(double v) => v >= 1000000
      ? '${(v / 1000000).toStringAsFixed(1)}M'
      : v.toStringAsFixed(0);

  // ─── UI ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    ref.listen<FilterState>(filterProvider, (_, __) => _loadItems());
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
              _isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                  : items.isEmpty
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
        'All Stock Report',
        style: AppTypography.h6.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
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
                  ref.read(shopNameProvider).valueOrNull ?? 'My Shop',
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
          hintText: 'Search products...',
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

  Widget _buildTable(List<_StockItem> items) {
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
              _buildTableHeader(),
              ...items.asMap().entries.map((entry) =>
                  _buildTableRow(entry.value, entry.key)),
              _buildTotalsRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.primary,
      ),
      child: Row(
        children: [
          _headerCell('S/N', 32),
          _headerCell('Item Name', 100),
          _headerCell('BP', 60),
          _headerCell('SP', 60),
          _headerCell('In', 45),
          _headerCell('Sold', 48),
          _headerCell('Bad', 42),
          _headerCell('Lost', 42),
          _headerCell('Exp', 42),
          _headerCell('Bal', 45),
          _headerCell('Stock Val', 75),
          _headerCell('Sales', 70),
          _headerCell('Profit', 70),
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

  Widget _buildTableRow(_StockItem item, int index) {
    final isEven = index % 2 == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isEven ? AppColors.card : AppColors.background,
      ),
      child: Row(
        children: [
          _dataCell('${item.sn}', 32),
          _nameCell(item.name, 100),
          _dataCell(_fmt(item.bp), 60),
          _dataCell(_fmt(item.sp), 60),
          _dataCell('${item.inStock}', 45),
          _dataCell('${item.sold}', 48),
          _dataCell('${item.bad}', 42),
          _dataCell('${item.lost}', 42),
          _dataCell('${item.expired}', 42),
          _dataCell('${item.balance}', 45),
          _dataCell(_fmt(item.stockValue), 75),
          _dataCell(_fmt(item.sales), 70),
          _profitCell(item.profitEstimate, 70),
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

  Widget _buildTotalsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        border: Border(
          top: BorderSide(color: AppColors.primary.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          _totalCell('', 32),
          _totalLabelCell('TOTAL', 100),
          _totalCell('', 60),
          _totalCell('', 60),
          _totalCell('$_totalIn', 45),
          _totalCell('$_totalSold', 48),
          _totalCell('$_totalBad', 42),
          _totalCell('$_totalLost', 42),
          _totalCell('$_totalExpired', 42),
          _totalCell('$_totalBalance', 45),
          _totalCell(_fmt(_totalStockValue), 75),
          _totalCell(_fmt(_totalSales), 70),
          _totalProfitCell(_totalProfit, 70),
        ],
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
                Icons.inventory_2_outlined,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Products Found',
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
