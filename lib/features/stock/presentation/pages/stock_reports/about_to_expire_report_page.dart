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
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/stock/presentation/providers/stock_provider.dart';
import 'package:dukaapp/shared/dialogs/app_filter_dialog.dart';
import 'package:dukaapp/shared/providers/filter_provider.dart';

class _ExpiryItem {
  final int sn;
  final String name;
  final int quantity;
  final double stockValue;

  const _ExpiryItem({required this.sn, required this.name, required this.quantity, required this.stockValue});
}

class AboutToExpireReportPage extends ConsumerStatefulWidget {
  const AboutToExpireReportPage({super.key});

  @override
  ConsumerState<AboutToExpireReportPage> createState() => _AboutToExpireReportPageState();
}

class _AboutToExpireReportPageState extends ConsumerState<AboutToExpireReportPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalController = ScrollController();

  List<_ExpiryItem> _allItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadItems());
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(stockRepositoryProvider);
      final products = await repo.fetchExpiredStock();
      final items = products.asMap().entries.map((e) {
        final p = e.value;
        return _ExpiryItem(sn: e.key + 1, name: p.name, quantity: p.available.toInt(), stockValue: p.buyingPrice * p.available);
      }).toList();
      if (mounted) setState(() => _allItems = items);
    } catch (_) {
      if (mounted) setState(() => _allItems = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_ExpiryItem> get _filteredItems {
    final q = _searchController.text.toLowerCase().trim();
    return q.isEmpty ? _allItems : _allItems.where((i) => i.name.toLowerCase().contains(q)).toList();
  }

  int get _totalQty => _filteredItems.fold(0, (s, i) => s + i.quantity);
  double get _totalValue => _filteredItems.fold(0, (s, i) => s + i.stockValue);

  String get _currentDateTime => '${DateFormat('dd MMM yyyy').format(DateTime.now())} • ${DateFormat('hh:mm a').format(DateTime.now())}';
  String get _exportDateTime => DateFormat('dd-MM-yyyy_HH-mm').format(DateTime.now());

  @override
  void dispose() { _searchController.dispose(); _horizontalController.dispose(); super.dispose(); }

  Future<void> _exportPdf() async {
    final items = _filteredItems;
    if (items.isEmpty) return;
    final doc = pw.Document();
    final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    doc.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4.landscape, margin: const pw.EdgeInsets.all(20),
      header: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('About to Expire Report', style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 16)),
        pw.SizedBox(height: 2), pw.Text('${ref.read(shopNameProvider).valueOrNull ?? 'My Shop'}  •  $now', style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 4), pw.Divider(), pw.SizedBox(height: 4)]),
      build: (_) => [pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 7, color: PdfColors.white),
        cellStyle: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 7),
        headerAlignment: pw.Alignment.center, cellAlignment: pw.Alignment.center,
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
        oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
        border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey400),
        headers: ['S/N', 'Item Name', 'Quantity', 'Stock Value'],
        data: [...items.map((i) => ['${i.sn}', i.name, '${i.quantity}', _fmt(i.stockValue)]), ['', 'TOTAL', '$_totalQty', _fmt(_totalValue)]])],
    ));
    final dir = await getApplicationDocumentsDirectory();
    await File('${dir.path}/AboutToExpire_$_exportDateTime.pdf').writeAsBytes(await doc.save(), flush: true);
    await OpenFile.open('${dir.path}/AboutToExpire_$_exportDateTime.pdf');
  }

  Future<void> _exportExcel() async {
    final items = _filteredItems;
    if (items.isEmpty) return;
    final excel = xls.Excel.createExcel();
    excel.rename(excel.getDefaultSheet()!, 'About to Expire');
    final sheet = excel['About to Expire'];
    sheet.appendRow(['S/N', 'Item Name', 'Quantity', 'Stock Value'].map((h) => xls.TextCellValue(h)).toList());
    for (final i in items) { sheet.appendRow([xls.DoubleCellValue(i.sn.toDouble()), xls.TextCellValue(i.name), xls.DoubleCellValue(i.quantity.toDouble()), xls.DoubleCellValue(i.stockValue)]); }
    sheet.appendRow([xls.TextCellValue(''), xls.TextCellValue('TOTAL'), xls.DoubleCellValue(_totalQty.toDouble()), xls.DoubleCellValue(_totalValue)]);
    final bytes = excel.save(); if (bytes == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/AboutToExpire_$_exportDateTime.xlsx');
    await file.writeAsBytes(bytes, flush: true); await OpenFile.open(file.path);
  }

  String _fmt(double v) => v >= 1000000 ? '${(v / 1000000).toStringAsFixed(1)}M' : v.toStringAsFixed(0);

  @override
  Widget build(BuildContext context) {
    ref.listen<FilterState>(filterProvider, (_, __) => _loadItems());
    final items = _filteredItems;
    return Scaffold(backgroundColor: const Color(0xFFF5F7FB), appBar: _buildAppBar(context),
      body: SafeArea(top: false, child: SingleChildScrollView(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(children: [_buildShopHeader(), _buildActionButtons(context), const SizedBox(height: 12), _buildSearchField(), const SizedBox(height: 12),
          _isLoading
              ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
              : items.isEmpty ? _buildEmptyState() : _buildTable(items),
          const SizedBox(height: 24)]))));
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(backgroundColor: AppColors.card, elevation: 0,
      leading: Padding(padding: const EdgeInsets.all(8.0), child: Container(decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
        child: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20)))),
      leadingWidth: 56, title: Text('About to Expire', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      centerTitle: true, bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.divider)));
  }

  Widget _buildShopHeader() {
    return Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 12), color: AppColors.card,
      child: Row(children: [Icon(Icons.storefront_rounded, size: 18, color: AppColors.primary), const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ref.read(shopNameProvider).valueOrNull ?? 'My Shop', style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2), Text(_currentDateTime, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10))]))]));
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 10), color: AppColors.card,
      child: Row(children: [
        _buildActionButton(icon: Icons.picture_as_pdf_rounded, label: 'PDF', color: AppColors.danger, onTap: _exportPdf), const SizedBox(width: 8),
        _buildActionButton(icon: Icons.table_chart_rounded, label: 'Excel', color: AppColors.success, onTap: _exportExcel), const SizedBox(width: 8),
        _buildActionButton(icon: Icons.filter_list_rounded, label: 'Filter', color: AppColors.primary, onTap: () => AppFilterDialog.show(context))]));
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Expanded(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: Container(padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 16, color: color), const SizedBox(width: 6),
        Text(label, style: AppTypography.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 12))]))));
  }

  Widget _buildSearchField() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG), child: TextField(controller: _searchController, onChanged: (_) => setState(() {}),
      style: AppTypography.bodyMedium, decoration: InputDecoration(hintText: 'Search products...', hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
        suffixIcon: _searchController.text.isNotEmpty ? IconButton(onPressed: () { _searchController.clear(); setState(() {}); }, icon: const Icon(Icons.close_rounded, color: AppColors.textHint, size: 18)) : null,
        filled: true, fillColor: AppColors.card, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5)))));
  }

  Widget _buildTable(List<_ExpiryItem> items) {
    return Container(margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))]),
      child: ClipRRect(borderRadius: BorderRadius.circular(14), child: SingleChildScrollView(scrollDirection: Axis.horizontal, controller: _horizontalController,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildTableHeader(), ...items.asMap().entries.map((e) => _buildTableRow(e.value, e.key)), _buildTotalsRow()]))));
  }

  Widget _buildTableHeader() {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: const BoxDecoration(color: AppColors.primary),
      child: Row(children: [_headerCell('S/N', 50), _headerCell('Item Name', 180), _headerCell('Quantity', 80), _headerCell('Stock Value', 100)]));
  }

  Widget _headerCell(String text, double width) {
    return SizedBox(width: width, child: Text(text, style: AppTypography.caption.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w700, fontSize: 11), textAlign: TextAlign.center));
  }

  Widget _buildTableRow(_ExpiryItem item, int index) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: index % 2 == 0 ? AppColors.card : AppColors.background),
      child: Row(children: [_dataCell('${item.sn}', 50), _nameCell(item.name, 180), _dataCell('${item.quantity}', 80), _valueCell(item.stockValue, 100)]));
  }

  Widget _dataCell(String t, double w) => SizedBox(width: w, child: Text(t, style: AppTypography.caption.copyWith(color: AppColors.textPrimary, fontSize: 11), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis));
  Widget _nameCell(String t, double w) => SizedBox(width: w, child: Text(t, style: AppTypography.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis));
  Widget _valueCell(double v, double w) => SizedBox(width: w, child: Text(_fmt(v), style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 11), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis));

  Widget _buildTotalsRow() {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06),
      border: Border(top: BorderSide(color: AppColors.primary.withValues(alpha: 0.2), width: 1))),
      child: Row(children: [_totalW('', 50), _totalLabelW('TOTAL', 180), _totalW('$_totalQty', 80), _totalW(_fmt(_totalValue), 100)]));
  }

  Widget _totalW(String t, double w) => SizedBox(width: w, child: Text(t, style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis));
  Widget _totalLabelW(String t, double w) => SizedBox(width: w, child: Text(t, style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis));

  Widget _buildEmptyState() {
    return Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXXL, vertical: 60), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 100, height: 100, decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(Icons.schedule_rounded, size: 48, color: AppColors.warning.withValues(alpha: 0.5))),
      const SizedBox(height: 20), Text('No Products Found', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6), Text('Try a different search term.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary))])));
  }
}
