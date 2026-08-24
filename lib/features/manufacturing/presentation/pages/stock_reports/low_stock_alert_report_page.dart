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

class _LowStockItem {
  final int sn;
  final String rawMaterial;
  final String unit;
  final int currentStock;
  final int minimumStock;
  final int difference;
  final String lastPurchaseDate;
  final String status;

  const _LowStockItem({
    required this.sn, required this.rawMaterial, required this.unit,
    required this.currentStock, required this.minimumStock, required this.difference,
    required this.lastPurchaseDate, required this.status,
  });
}

class LowStockAlertReportPage extends StatefulWidget {
  const LowStockAlertReportPage({super.key});

  @override
  State<LowStockAlertReportPage> createState() => _LowStockAlertReportPageState();
}

class _LowStockAlertReportPageState extends State<LowStockAlertReportPage> {
  final TextEditingController _searchController = TextEditingController();

  static const List<_LowStockItem> _items = [
    _LowStockItem(sn: 1, rawMaterial: 'Cotton Fabric', unit: 'meters', currentStock: 15, minimumStock: 50, difference: -35, lastPurchaseDate: '10/08/2026', status: 'Critical'),
    _LowStockItem(sn: 2, rawMaterial: 'Denim Fabric', unit: 'meters', currentStock: 20, minimumStock: 40, difference: -20, lastPurchaseDate: '08/08/2026', status: 'Low'),
    _LowStockItem(sn: 3, rawMaterial: 'Dye', unit: 'liters', currentStock: 5, minimumStock: 20, difference: -15, lastPurchaseDate: '05/08/2026', status: 'Critical'),
    _LowStockItem(sn: 4, rawMaterial: 'Thread', unit: 'rolls', currentStock: 10, minimumStock: 30, difference: -20, lastPurchaseDate: '01/08/2026', status: 'Low'),
    _LowStockItem(sn: 5, rawMaterial: 'Elastic Band', unit: 'meters', currentStock: 8, minimumStock: 25, difference: -17, lastPurchaseDate: '12/08/2026', status: 'Critical'),
  ];

  List<_LowStockItem> get _filteredItems {
    final q = _searchController.text.toLowerCase().trim();
    if (q.isEmpty) return _items;
    return _items.where((i) => i.rawMaterial.toLowerCase().contains(q)).toList();
  }

  String get _exportDateTime => DateFormat('dd-MM-yyyy_HH-mm').format(DateTime.now());

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<void> _exportPdf() async {
    final items = _filteredItems;
    if (items.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export'))); return; }
    final doc = pw.Document();
    final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape, margin: const pw.EdgeInsets.all(20),
      header: (context) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('Low Stock Alert Report', style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 16)),
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
        headers: ['S/N', 'Raw Material', 'Unit', 'Current Stock', 'Minimum Stock', 'Difference', 'Last Purchase', 'Status'],
        data: items.map((i) => ['${i.sn}', i.rawMaterial, i.unit, '${i.currentStock}', '${i.minimumStock}', '${i.difference}', i.lastPurchaseDate, i.status]).toList(),
      )],
      footer: (context) => pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 7, color: PdfColors.grey500))),
    ));
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/LowStockAlert_$_exportDateTime.pdf');
    await file.writeAsBytes(await doc.save(), flush: true);
    await OpenFile.open(file.path);
  }

  Future<void> _exportExcel() async {
    final items = _filteredItems;
    if (items.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export'))); return; }
    final excel = xls.Excel.createExcel();
    excel.rename(excel.getDefaultSheet()!, 'Low Stock Alert');
    final sheet = excel['Low Stock Alert'];
    sheet.appendRow(['S/N', 'Raw Material', 'Unit', 'Current Stock', 'Minimum Stock', 'Difference', 'Last Purchase', 'Status'].map((h) => xls.TextCellValue(h)).toList());
    for (final i in items) {
      sheet.appendRow([xls.DoubleCellValue(i.sn.toDouble()), xls.TextCellValue(i.rawMaterial), xls.TextCellValue(i.unit), xls.DoubleCellValue(i.currentStock.toDouble()), xls.DoubleCellValue(i.minimumStock.toDouble()), xls.DoubleCellValue(i.difference.toDouble()), xls.TextCellValue(i.lastPurchaseDate), xls.TextCellValue(i.status)]);
    }
    final fileBytes = excel.save();
    if (fileBytes == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/LowStockAlert_$_exportDateTime.xlsx');
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
          if (items.isEmpty) _buildEmptyState() else _buildTable(items),
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
      leadingWidth: 56, title: Text('Low Stock Alert Report', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      centerTitle: true, bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.divider)),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 10), color: AppColors.card,
      child: Row(children: [
        _actionBtn(icon: Icons.picture_as_pdf_rounded, label: 'PDF', color: AppColors.danger, onTap: _exportPdf),
        const SizedBox(width: 8), _actionBtn(icon: Icons.table_chart_rounded, label: 'Excel', color: AppColors.success, onTap: _exportExcel),
        const SizedBox(width: 8), _actionBtn(icon: Icons.filter_list_rounded, label: 'Filter', color: AppColors.primary, onTap: () => AppFilterDialog.show(context)),
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

  Widget _buildTable(List<_LowStockItem> items) {
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
        _hCell('S/N', 32), _hCell('Raw Material', 110), _hCell('Unit', 50), _hCell('Current', 55),
        _hCell('Minimum', 55), _hCell('Difference', 65), _hCell('Last Purchase', 80), _hCell('Status', 65),
      ]),
    );
  }

  Widget _hCell(String t, double w) => SizedBox(width: w, child: Text(t, style: AppTypography.caption.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w700, fontSize: 9), textAlign: TextAlign.center));

  Widget _buildTableRow(_LowStockItem item, int idx) {
    final isEven = idx % 2 == 0;
    final statusColor = item.status == 'Critical' ? AppColors.danger : AppColors.warning;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(color: isEven ? AppColors.card : AppColors.background),
      child: Row(children: [
        _dCell('${item.sn}', 32), _nCell(item.rawMaterial, 110), _dCell(item.unit, 50),
        _dCell('${item.currentStock}', 55), _dCell('${item.minimumStock}', 55),
        _diffCell(item.difference, 65), _dCell(item.lastPurchaseDate, 80),
        SizedBox(width: 65, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
          child: Text(item.status, style: AppTypography.caption.copyWith(color: statusColor, fontWeight: FontWeight.w600, fontSize: 8), textAlign: TextAlign.center),
        )),
      ]),
    );
  }

  Widget _dCell(String t, double w) => SizedBox(width: w, child: Text(t, style: AppTypography.caption.copyWith(color: AppColors.textPrimary, fontSize: 9), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis));
  Widget _nCell(String t, double w) => SizedBox(width: w, child: Text(t, style: AppTypography.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis));
  Widget _diffCell(int v, double w) => SizedBox(width: w, child: Text('$v', style: AppTypography.caption.copyWith(color: v < 0 ? AppColors.danger : AppColors.success, fontWeight: FontWeight.w600, fontSize: 9), textAlign: TextAlign.center));

  Widget _buildEmptyState() {
    return Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXXL, vertical: 60),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 100, height: 100, decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.06), shape: BoxShape.circle),
          child: Icon(Icons.check_circle_outline, size: 48, color: AppColors.success.withValues(alpha: 0.4))),
        const SizedBox(height: 20),
        Text('All Stock Levels Normal', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('No low stock alerts at this time.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
      ]),
    ));
  }
}
