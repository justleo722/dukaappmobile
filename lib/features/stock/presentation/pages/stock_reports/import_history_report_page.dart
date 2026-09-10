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

class _ImportRecord {
  final int sn;
  final dynamic purchaseId;
  final DateTime date;
  final String title;
  final String category;
  final String importedBy;
  final int items;
  final int qty;
  final double stockValue;

  const _ImportRecord({
    required this.sn,
    this.purchaseId,
    required this.date,
    required this.title,
    required this.category,
    required this.importedBy,
    required this.items,
    required this.qty,
    required this.stockValue,
  });
}

class ImportHistoryReportPage extends ConsumerStatefulWidget {
  const ImportHistoryReportPage({super.key});

  @override
  ConsumerState<ImportHistoryReportPage> createState() => _ImportHistoryReportPageState();
}

class _ImportHistoryReportPageState extends ConsumerState<ImportHistoryReportPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalController = ScrollController();

  List<_ImportRecord> _allImports = [];
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
      final records = await repo.fetchImportHistory();
      final items = records.asMap().entries.map((e) {
        final r = e.value;
        DateTime? date;
        try { date = DateTime.parse(r['date']?.toString() ?? ''); } catch (_) {}
        return _ImportRecord(
          sn: e.key + 1,
          purchaseId: r['purchase_id'] ?? r['id'],
          date: date ?? DateTime.now(),
          title: r['title']?.toString() ?? r['description']?.toString() ?? 'Import',
          category: r['category']?.toString() ?? '',
          importedBy: r['imported_by']?.toString() ?? r['created_by']?.toString() ?? '',
          items: int.tryParse(r['items']?.toString() ?? r['item_count']?.toString() ?? '0') ?? 0,
          qty: int.tryParse(r['qty']?.toString() ?? r['quantity']?.toString() ?? '0') ?? 0,
          stockValue: double.tryParse(r['stock_value']?.toString() ?? r['total_value']?.toString() ?? '0') ?? 0.0,
        );
      }).toList();
      if (mounted) setState(() => _allImports = items);
    } catch (_) {
      if (mounted) setState(() => _allImports = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_ImportRecord> get _filteredItems {
    final q = _searchController.text.toLowerCase().trim();
    if (q.isEmpty) return _allImports;
    return _allImports.where((i) => i.title.toLowerCase().contains(q) || i.importedBy.toLowerCase().contains(q)).toList();
  }

  int get _totalItems => _filteredItems.fold(0, (s, i) => s + i.items);
  int get _totalQty => _filteredItems.fold(0, (s, i) => s + i.qty);
  double get _totalValue => _filteredItems.fold(0, (s, i) => s + i.stockValue);

  String get _currentDateTime => '${DateFormat('dd MMM yyyy').format(DateTime.now())} • ${DateFormat('hh:mm a').format(DateTime.now())}';
  String get _exportDateTime => DateFormat('dd-MM-yyyy_HH-mm').format(DateTime.now());

  @override
  void dispose() { _searchController.dispose(); _horizontalController.dispose(); super.dispose(); }

  void _confirmDelete(_ImportRecord record) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Import'),
      content: Text('Delete "${record.title}"? This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary))),
        TextButton(onPressed: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${record.title} deleted'), backgroundColor: AppColors.danger)); },
          child: Text('Delete', style: AppTypography.bodyMedium.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600))),
      ],
    ));
  }

  Future<void> _exportPdf() async {
    final items = _filteredItems;
    if (items.isEmpty) return;
    final doc = pw.Document();
    final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    doc.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4.landscape, margin: const pw.EdgeInsets.all(20),
      header: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('Import History', style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 16)),
        pw.SizedBox(height: 2), pw.Text('DukaApp Main Shop  •  $now', style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 4), pw.Divider(), pw.SizedBox(height: 4)]),
      build: (_) => [pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 6, color: PdfColors.white),
        cellStyle: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 6),
        headerAlignment: pw.Alignment.center, cellAlignment: pw.Alignment.center,
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
        oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
        border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey400),
        headers: ['S/N', 'Date', 'Import Title', 'Category', 'Imported By', 'Items', 'Qty', 'Stock Value'],
        data: [
          ...items.map((i) => [
            '${i.sn}', DateFormat('dd/MM/yy HH:mm').format(i.date), i.title, i.category, i.importedBy,
            '${i.items}', '${i.qty}', _fmt(i.stockValue),
          ]),
          ['', '', '', '', 'TOTAL', '$_totalItems', '$_totalQty', _fmt(_totalValue)],
        ],
      )],
    ));
    final dir = await getApplicationDocumentsDirectory();
    await File('${dir.path}/ImportHistory_$_exportDateTime.pdf').writeAsBytes(await doc.save(), flush: true);
    await OpenFile.open('${dir.path}/ImportHistory_$_exportDateTime.pdf');
  }

  Future<void> _exportExcel() async {
    final items = _filteredItems;
    if (items.isEmpty) return;
    final excel = xls.Excel.createExcel();
    excel.rename(excel.getDefaultSheet()!, 'Import History');
    final sheet = excel['Import History'];
    sheet.appendRow(['S/N', 'Date', 'Import Title', 'Category', 'Imported By', 'Items', 'Qty', 'Stock Value'].map((h) => xls.TextCellValue(h)).toList());
    for (final i in items) {
      sheet.appendRow([
        xls.DoubleCellValue(i.sn.toDouble()), xls.TextCellValue(DateFormat('dd/MM/yy HH:mm').format(i.date)),
        xls.TextCellValue(i.title), xls.TextCellValue(i.category), xls.TextCellValue(i.importedBy),
        xls.DoubleCellValue(i.items.toDouble()), xls.DoubleCellValue(i.qty.toDouble()), xls.DoubleCellValue(i.stockValue),
      ]);
    }
    sheet.appendRow([xls.TextCellValue(''), xls.TextCellValue(''), xls.TextCellValue(''), xls.TextCellValue(''), xls.TextCellValue('TOTAL'),
      xls.DoubleCellValue(_totalItems.toDouble()), xls.DoubleCellValue(_totalQty.toDouble()), xls.DoubleCellValue(_totalValue)]);
    final bytes = excel.save(); if (bytes == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/ImportHistory_$_exportDateTime.xlsx');
    await file.writeAsBytes(bytes, flush: true); await OpenFile.open(file.path);
  }

  String _fmt(double v) => v >= 1000000 ? '${(v / 1000000).toStringAsFixed(1)}M' : v.toStringAsFixed(0);

  @override
  Widget build(BuildContext context) {
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
      leadingWidth: 56, title: Text('Import History', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      centerTitle: true, bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.divider)));
  }

  Widget _buildShopHeader() {
    return Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 12), color: AppColors.card,
      child: Row(children: [Icon(Icons.storefront_rounded, size: 18, color: AppColors.primary), const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('DukaApp Main Shop', style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
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
      style: AppTypography.bodyMedium, decoration: InputDecoration(hintText: 'Search imports...', hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
        suffixIcon: _searchController.text.isNotEmpty ? IconButton(onPressed: () { _searchController.clear(); setState(() {}); }, icon: const Icon(Icons.close_rounded, color: AppColors.textHint, size: 18)) : null,
        filled: true, fillColor: AppColors.card, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5)))));
  }

  Widget _buildTable(List<_ImportRecord> items) {
    return Container(margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))]),
      child: ClipRRect(borderRadius: BorderRadius.circular(14), child: SingleChildScrollView(scrollDirection: Axis.horizontal, controller: _horizontalController,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildTableHeader(), ...items.asMap().entries.map((e) => _buildTableRow(e.value, e.key)), _buildTotalsRow()]))));
  }

  Widget _buildTableHeader() {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), decoration: const BoxDecoration(color: AppColors.primary),
      child: Row(children: [
        _headerCell('S/N', 36), _headerCell('Date', 100), _headerCell('Import Title', 120),
        _headerCell('Category', 90), _headerCell('Imported By', 100), _headerCell('Items', 50),
        _headerCell('Qty', 50), _headerCell('Stock Value', 80), _headerCell('Action', 60)]));
  }

  Widget _headerCell(String text, double width) {
    return SizedBox(width: width, child: Text(text, style: AppTypography.caption.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w700, fontSize: 9), textAlign: TextAlign.center));
  }

  Widget _buildTableRow(_ImportRecord item, int index) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9), decoration: BoxDecoration(color: index % 2 == 0 ? AppColors.card : AppColors.background),
      child: Row(children: [
        _dataCell('${item.sn}', 36), _dateCell(item.date, 100), _nameCell(item.title, 120),
        _dataCell(item.category, 90), _dataCell(item.importedBy, 100), _dataCell('${item.items}', 50),
        _dataCell('${item.qty}', 50), _valueCell(item.stockValue, 80), _actionCell(item, 60)]));
  }

  Widget _dataCell(String t, double w) => SizedBox(width: w, child: Text(t, style: AppTypography.caption.copyWith(color: AppColors.textPrimary, fontSize: 9), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis));
  Widget _nameCell(String t, double w) => SizedBox(width: w, child: Text(t, style: AppTypography.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis));
  Widget _dateCell(DateTime d, double w) => SizedBox(width: w, child: Text(DateFormat('dd/MM/yy\nhh:mm a').format(d), style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 8), textAlign: TextAlign.center, maxLines: 2));
  Widget _valueCell(double v, double w) => SizedBox(width: w, child: Text(_fmt(v), style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 9), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis));

  Widget _actionCell(_ImportRecord item, double w) {
    return SizedBox(width: w, child: IconButton(
      onPressed: () => _confirmDelete(item),
      icon: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
      padding: EdgeInsets.zero, constraints: const BoxConstraints(),
    ));
  }

  Widget _buildTotalsRow() {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06),
      border: Border(top: BorderSide(color: AppColors.primary.withValues(alpha: 0.2), width: 1))),
      child: Row(children: [_totalW('', 36), _totalW('', 100), _totalW('', 120), _totalW('', 90),
        _totalLabelW('TOTAL', 100), _totalW('$_totalItems', 50), _totalW('$_totalQty', 50), _totalW(_fmt(_totalValue), 80), _totalW('', 60)]));
  }

  Widget _totalW(String t, double w) => SizedBox(width: w, child: Text(t, style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 9), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis));
  Widget _totalLabelW(String t, double w) => SizedBox(width: w, child: Text(t, style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis));

  Widget _buildEmptyState() {
    return Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXXL, vertical: 60), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 100, height: 100, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), shape: BoxShape.circle),
        child: Icon(Icons.history_rounded, size: 48, color: AppColors.primary.withValues(alpha: 0.4))),
      const SizedBox(height: 20), Text('No Imports Found', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6), Text('Try a different search term.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary))])));
  }
}
