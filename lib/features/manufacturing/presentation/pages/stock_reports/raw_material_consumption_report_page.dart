import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xls;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/services/api_service.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/shared/dialogs/app_filter_dialog.dart';

class _ConsumptionItem {
  final int sn;
  final String date;
  final String rawMaterial;
  final String unit;
  final int openingStock;
  final int consumedQty;
  final int closingStock;
  final double unitCost;
  final double consumptionCost;
  final String relatedProduction;

  const _ConsumptionItem({
    required this.sn, required this.date, required this.rawMaterial, required this.unit,
    required this.openingStock, required this.consumedQty, required this.closingStock,
    required this.unitCost, required this.consumptionCost, required this.relatedProduction,
  });
}

class RawMaterialConsumptionReportPage extends ConsumerStatefulWidget {
  const RawMaterialConsumptionReportPage({super.key});

  @override
  ConsumerState<RawMaterialConsumptionReportPage> createState() => _RawMaterialConsumptionReportPageState();
}

class _RawMaterialConsumptionReportPageState extends ConsumerState<RawMaterialConsumptionReportPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<_ConsumptionItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getMfRawConsumption();
      final body = res.data;
      List<_ConsumptionItem> items = [];
      final List rawList = body is List ? body : (body is Map ? ((body['data'] ?? body['items'] ?? []) as List? ?? []) : []);
      {
        {
          for (int i = 0; i < rawList.length; i++) {
            final m = rawList[i] as Map;
            items.add(_ConsumptionItem(
              sn: i + 1,
              date: (m['date'] ?? '').toString(),
              rawMaterial: (m['material_name'] ?? m['raw_material'] ?? m['name'] ?? '').toString(),
              unit: (m['unit'] ?? '').toString(),
              openingStock: (m['opening_stock'] ?? 0) as int? ?? 0,
              consumedQty: (m['consumed_qty'] ?? m['consumed'] ?? 0) as int? ?? 0,
              closingStock: (m['closing_stock'] ?? 0) as int? ?? 0,
              unitCost: ((m['unit_cost'] ?? 0) as num).toDouble(),
              consumptionCost: ((m['consumption_cost'] ?? m['total_cost'] ?? 0) as num).toDouble(),
              relatedProduction: (m['related_production'] ?? m['product_name'] ?? '').toString(),
            ));
          }
        }
      }
      setState(() { _items = items; _isLoading = false; });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  List<_ConsumptionItem> get _filteredItems {
    final q = _searchController.text.toLowerCase().trim();
    if (q.isEmpty) return _items;
    return _items.where((i) => i.rawMaterial.toLowerCase().contains(q) || i.relatedProduction.toLowerCase().contains(q)).toList();
  }

  String get _exportDateTime => DateFormat('dd-MM-yyyy_HH-mm').format(DateTime.now());

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  String _fmt(double v) => v >= 1000000 ? '${(v / 1000000).toStringAsFixed(1)}M' : v.toStringAsFixed(0);

  Future<void> _exportPdf() async {
    final items = _filteredItems;
    if (items.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export'))); return; }
    final doc = pw.Document();
    final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape, margin: const pw.EdgeInsets.all(20),
      header: (context) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('Raw Material Consumption', style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 16)),
        pw.SizedBox(height: 2), pw.Text(now, style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 4), pw.Divider(), pw.SizedBox(height: 4),
      ]),
      build: (context) => [pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 7, color: PdfColors.white),
        cellStyle: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 7),
        headerAlignment: pw.Alignment.center, cellAlignment: pw.Alignment.center,
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
        oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
        border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey400),
        headers: ['S/N', 'Date', 'Raw Material', 'Unit', 'Opening', 'Consumed', 'Closing', 'Unit Cost', 'Cost', 'Related Production'],
        data: items.map((i) => ['${i.sn}', i.date, i.rawMaterial, i.unit, '${i.openingStock}', '${i.consumedQty}', '${i.closingStock}', _fmt(i.unitCost), _fmt(i.consumptionCost), i.relatedProduction]).toList(),
      )],
      footer: (context) => pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 7, color: PdfColors.grey500))),
    ));
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/RawMaterialConsumption_$_exportDateTime.pdf');
    await file.writeAsBytes(await doc.save(), flush: true);
    await OpenFile.open(file.path);
  }

  Future<void> _exportExcel() async {
    final items = _filteredItems;
    if (items.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export'))); return; }
    final excel = xls.Excel.createExcel();
    excel.rename(excel.getDefaultSheet()!, 'Raw Material Consumption');
    final sheet = excel['Raw Material Consumption'];
    sheet.appendRow(['S/N', 'Date', 'Raw Material', 'Unit', 'Opening', 'Consumed', 'Closing', 'Unit Cost', 'Cost', 'Related Production'].map((h) => xls.TextCellValue(h)).toList());
    for (final i in items) {
      sheet.appendRow([xls.DoubleCellValue(i.sn.toDouble()), xls.TextCellValue(i.date), xls.TextCellValue(i.rawMaterial), xls.TextCellValue(i.unit), xls.DoubleCellValue(i.openingStock.toDouble()), xls.DoubleCellValue(i.consumedQty.toDouble()), xls.DoubleCellValue(i.closingStock.toDouble()), xls.DoubleCellValue(i.unitCost), xls.DoubleCellValue(i.consumptionCost), xls.TextCellValue(i.relatedProduction)]);
    }
    final fileBytes = excel.save();
    if (fileBytes == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/RawMaterialConsumption_$_exportDateTime.xlsx');
    await file.writeAsBytes(fileBytes, flush: true);
    await OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    return Scaffold(backgroundColor: const Color(0xFFF5F7FB), appBar: _buildAppBar(context),
      body: SafeArea(top: false, child: SingleChildScrollView(
        child: Column(children: [
          _buildActionButtons(context), const SizedBox(height: 12),
          _buildSearchField(), const SizedBox(height: 12),
          if (_isLoading) const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: CircularProgressIndicator()))
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
      title: Text('Raw Material Consumption', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
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
        decoration: InputDecoration(hintText: 'Search raw materials...', hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
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

  Widget _buildTable(List<_ConsumptionItem> items) {
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
        _hCell('S/N', 32), _hCell('Date', 75), _hCell('Raw Material', 100), _hCell('Unit', 50),
        _hCell('Opening', 55), _hCell('Consumed', 60), _hCell('Closing', 55), _hCell('Unit Cost', 65),
        _hCell('Cost', 80), _hCell('Related Production', 110),
      ]),
    );
  }

  Widget _hCell(String t, double w) => SizedBox(width: w, child: Text(t, style: AppTypography.caption.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w700, fontSize: 9), textAlign: TextAlign.center));

  Widget _buildTableRow(_ConsumptionItem item, int idx) {
    final isEven = idx % 2 == 0;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(color: isEven ? AppColors.card : AppColors.background),
      child: Row(children: [
        _dCell('${item.sn}', 32), _dCell(item.date, 75), _nCell(item.rawMaterial, 100), _dCell(item.unit, 50),
        _dCell('${item.openingStock}', 55), _dCell('${item.consumedQty}', 60), _dCell('${item.closingStock}', 55),
        _dCell(_fmt(item.unitCost), 65), _dCell(_fmt(item.consumptionCost), 80),
        _nCell(item.relatedProduction, 110),
      ]),
    );
  }

  Widget _dCell(String t, double w) => SizedBox(width: w, child: Text(t, style: AppTypography.caption.copyWith(color: AppColors.textPrimary, fontSize: 9), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis));
  Widget _nCell(String t, double w) => SizedBox(width: w, child: Text(t, style: AppTypography.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis));

  Widget _buildEmptyState() {
    return Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXXL, vertical: 60),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 100, height: 100, decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.06), shape: BoxShape.circle),
          child: Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.secondary.withValues(alpha: 0.4))),
        const SizedBox(height: 20),
        Text('No Consumption Data Found', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Try a different search term.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
      ]),
    ));
  }
}
