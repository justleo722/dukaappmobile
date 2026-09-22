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
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/shared/dialogs/app_filter_dialog.dart';
import 'package:dukaapp/shared/providers/filter_provider.dart';

class _ProductionItem {
  final int sn;
  final String date;
  final String productName;
  final String recipeUsed;
  final int qtyProduced;
  final String unit;
  final double costPerUnit;
  final double totalCost;
  final DateTime expiryDate;
  final String producedBy;
  final String status;

  const _ProductionItem({
    required this.sn, required this.date, required this.productName, required this.recipeUsed,
    required this.qtyProduced, required this.unit, required this.costPerUnit, required this.totalCost,
    required this.expiryDate, required this.producedBy, required this.status,
  });
}

class DailyProductionReportPage extends ConsumerStatefulWidget {
  const DailyProductionReportPage({super.key});

  @override
  ConsumerState<DailyProductionReportPage> createState() => _DailyProductionReportPageState();
}

class _DailyProductionReportPageState extends ConsumerState<DailyProductionReportPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<_ProductionItem> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData({String? from, String? to}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getMfDailyProduction(from: from, to: to);
      final body = res.data;
      List<_ProductionItem> items = [];
      List raw = [];
      if (body is List) {
        raw = body;
      } else if (body is Map) {
        final d = body['data'] ?? body['items'] ?? body['result'];
        if (d is List) raw = d;
      }
      for (int i = 0; i < raw.length; i++) {
        final m = raw[i] as Map;
        final costUnit = num.tryParse((m['cost_per_unit'] ?? 0).toString()) ?? 0;
        final totalCost = num.tryParse((m['total_cost'] ?? 0).toString()) ?? 0;
        final expRaw = m['expiry_date']?.toString() ?? '';
        DateTime expiry = DateTime.now().add(const Duration(days: 365));
        try { expiry = DateTime.parse(expRaw); } catch (_) {}
        items.add(_ProductionItem(
          sn: i + 1,
          date: m['production_date']?.toString() ?? '',
          productName: m['product_name']?.toString() ?? '',
          recipeUsed: m['recipe_name']?.toString() ?? '',
          qtyProduced: int.tryParse((m['quantity_produced'] ?? 0).toString()) ?? 0,
          unit: m['unit']?.toString() ?? '',
          costPerUnit: costUnit.toDouble(),
          totalCost: totalCost.toDouble(),
          expiryDate: expiry,
          producedBy: m['produced_by']?.toString() ?? '',
          status: m['status']?.toString() ?? 'Completed',
        ));
      }
      if (mounted) setState(() { _items = items; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_ProductionItem> get _filteredItems {
    final q = _searchController.text.toLowerCase().trim();
    if (q.isEmpty) return _items;
    return _items.where((i) => i.productName.toLowerCase().contains(q) || i.recipeUsed.toLowerCase().contains(q)).toList();
  }

  String get _exportDateTime => DateFormat('dd-MM-yyyy_HH-mm').format(DateTime.now());

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  String _fmt(double v) => v >= 1000000 ? '${(v / 1000000).toStringAsFixed(1)}M' : v.toStringAsFixed(0);

  // ─── PDF ─────────────────────────────────────────────────────────────
  Future<void> _exportPdf() async {
    final items = _filteredItems;
    if (items.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export'))); return; }
    final doc = pw.Document();
    final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(20),
      header: (context) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('Daily Production Summary', style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 16)),
        pw.SizedBox(height: 2),
        pw.Text(now, style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 4), pw.Divider(), pw.SizedBox(height: 4),
      ]),
      build: (context) => [pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 7, color: PdfColors.white),
        cellStyle: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 7),
        headerAlignment: pw.Alignment.center, cellAlignment: pw.Alignment.center,
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
        oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
        border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey400),
        headers: ['S/N', 'Date', 'Product Name', 'Recipe Used', 'Qty', 'Unit', 'Cost/Unit', 'Total Cost', 'Expiry', 'Produced By', 'Status'],
        data: items.map((i) => ['${i.sn}', i.date, i.productName, i.recipeUsed, '${i.qtyProduced}', i.unit, _fmt(i.costPerUnit), _fmt(i.totalCost), '${i.expiryDate.day}/${i.expiryDate.month}/${i.expiryDate.year}', i.producedBy, i.status]).toList(),
      )],
      footer: (context) => pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 7, color: PdfColors.grey500))),
    ));
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/DailyProductionReport_$_exportDateTime.pdf');
    await file.writeAsBytes(await doc.save(), flush: true);
    await OpenFile.open(file.path);
  }

  // ─── EXCEL ───────────────────────────────────────────────────────────
  Future<void> _exportExcel() async {
    final items = _filteredItems;
    if (items.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export'))); return; }
    final excel = xls.Excel.createExcel();
    excel.rename(excel.getDefaultSheet()!, 'Daily Production Summary');
    final sheet = excel['Daily Production Summary'];
    sheet.appendRow(['S/N', 'Date', 'Product Name', 'Recipe Used', 'Qty', 'Unit', 'Cost/Unit', 'Total Cost', 'Expiry', 'Produced By', 'Status'].map((h) => xls.TextCellValue(h)).toList());
    for (final i in items) {
      sheet.appendRow([xls.DoubleCellValue(i.sn.toDouble()), xls.TextCellValue(i.date), xls.TextCellValue(i.productName), xls.TextCellValue(i.recipeUsed), xls.DoubleCellValue(i.qtyProduced.toDouble()), xls.TextCellValue(i.unit), xls.DoubleCellValue(i.costPerUnit), xls.DoubleCellValue(i.totalCost), xls.TextCellValue('${i.expiryDate.day}/${i.expiryDate.month}/${i.expiryDate.year}'), xls.TextCellValue(i.producedBy), xls.TextCellValue(i.status)]);
    }
    final fileBytes = excel.save();
    if (fileBytes == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/DailyProductionReport_$_exportDateTime.xlsx');
    await file.writeAsBytes(fileBytes, flush: true);
    await OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FilterState>(filterProvider, (_, f) => _loadData(from: f.from, to: f.to));
    final items = _filteredItems;
    return Scaffold(backgroundColor: const Color(0xFFF5F7FB), appBar: _buildAppBar(context),
      body: SafeArea(top: false, child: SingleChildScrollView(
        child: Column(children: [
          _buildActionButtons(context), const SizedBox(height: 12),
          _buildSearchField(), const SizedBox(height: 12),
          if (_isLoading) const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (items.isEmpty) _buildEmptyState() else _buildTable(items),
          const SizedBox(height: 24),
        ]),
      )),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(backgroundColor: AppColors.card, elevation: 0,
      leading: Padding(padding: const EdgeInsets.all(8.0), child: Container(
        decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
        child: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20)),
      )),
      leadingWidth: 56,
      title: Text('Daily Production Summary', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      centerTitle: true,
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.divider)),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 10), color: AppColors.card,
      child: Row(children: [
        _actionBtn(icon: Icons.picture_as_pdf_rounded, label: 'PDF', color: AppColors.danger, onTap: _exportPdf),
        const SizedBox(width: 8),
        _actionBtn(icon: Icons.table_chart_rounded, label: 'Excel', color: AppColors.success, onTap: _exportExcel),
        const SizedBox(width: 8),
        _actionBtn(icon: Icons.filter_list_rounded, label: 'Filter', color: AppColors.primary, onTap: () => AppFilterDialog.show(context)),
      ]),
    );
  }

  Widget _actionBtn({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Expanded(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10),
      child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: color), const SizedBox(width: 6),
          Text(label, style: AppTypography.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ]),
      ),
    ));
  }

  Widget _buildSearchField() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: TextField(controller: _searchController, onChanged: (_) => setState(() {}), style: AppTypography.bodyMedium,
        decoration: InputDecoration(hintText: 'Search products...', hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
          suffixIcon: _searchController.text.isNotEmpty ? IconButton(onPressed: () { _searchController.clear(); setState(() {}); },
            icon: const Icon(Icons.close_rounded, color: AppColors.textHint, size: 18)) : null,
          filled: true, fillColor: AppColors.card, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5)),
        )),
    );
  }

  Widget _buildTable(List<_ProductionItem> items) {
    return Container(margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))]),
      child: ClipRRect(borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(scrollDirection: Axis.horizontal,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildTableHeader(), ...items.asMap().entries.map((e) => _buildTableRow(e.value, e.key)),
          ]),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), decoration: const BoxDecoration(color: AppColors.primary),
      child: Row(children: [
        _hCell('S/N', 32), _hCell('Date', 75), _hCell('Product Name', 100), _hCell('Recipe Used', 90),
        _hCell('Qty', 45), _hCell('Unit', 40), _hCell('Cost/Unit', 65), _hCell('Total Cost', 75),
        _hCell('Expiry', 75), _hCell('Produced By', 75), _hCell('Status', 65),
      ]),
    );
  }

  Widget _hCell(String t, double w) => SizedBox(width: w, child: Text(t, style: AppTypography.caption.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w700, fontSize: 9), textAlign: TextAlign.center));

  Widget _buildTableRow(_ProductionItem item, int idx) {
    final isEven = idx % 2 == 0;
    final statusColor = item.status == 'Completed' ? AppColors.success : AppColors.warning;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(color: isEven ? AppColors.card : AppColors.background),
      child: Row(children: [
        _dCell('${item.sn}', 32), _dCell(item.date, 75), _nCell(item.productName, 100), _dCell(item.recipeUsed, 90),
        _dCell('${item.qtyProduced}', 45), _dCell(item.unit, 40), _dCell(_fmt(item.costPerUnit), 65), _dCell(_fmt(item.totalCost), 75),
        _dCell('${item.expiryDate.day}/${item.expiryDate.month}/${item.expiryDate.year}', 75),
        _dCell(item.producedBy, 75),
        SizedBox(width: 65, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
          child: Text(item.status, style: AppTypography.caption.copyWith(color: statusColor, fontWeight: FontWeight.w600, fontSize: 8), textAlign: TextAlign.center, maxLines: 1),
        )),
      ]),
    );
  }

  Widget _dCell(String t, double w) => SizedBox(width: w, child: Text(t, style: AppTypography.caption.copyWith(color: AppColors.textPrimary, fontSize: 9), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis));
  Widget _nCell(String t, double w) => SizedBox(width: w, child: Text(t, style: AppTypography.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis));

  Widget _buildEmptyState() {
    return Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXXL, vertical: 60),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 100, height: 100, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), shape: BoxShape.circle),
          child: Icon(Icons.factory_outlined, size: 48, color: AppColors.primary.withValues(alpha: 0.4))),
        const SizedBox(height: 20),
        Text('No Production Data Found', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Try a different search term.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
      ]),
    ));
  }
}
