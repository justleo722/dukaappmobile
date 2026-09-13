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

class _CostItem {
  final int sn;
  final String productName;
  final String recipe;
  final int qtyProduced;
  final double costPerUnit;
  final double totalProductionCost;
  final double sellingPrice;
  final double expectedRevenue;
  final double expectedProfit;
  final double profitMargin;

  const _CostItem({
    required this.sn, required this.productName, required this.recipe, required this.qtyProduced,
    required this.costPerUnit, required this.totalProductionCost, required this.sellingPrice,
    required this.expectedRevenue, required this.expectedProfit, required this.profitMargin,
  });
}

class ProductionCostAnalysisReportPage extends ConsumerStatefulWidget {
  const ProductionCostAnalysisReportPage({super.key});

  @override
  ConsumerState<ProductionCostAnalysisReportPage> createState() => _ProductionCostAnalysisReportPageState();
}

class _ProductionCostAnalysisReportPageState extends ConsumerState<ProductionCostAnalysisReportPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<_CostItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getMfCostAnalysis();
      final body = res.data;
      List<_CostItem> items = [];
      if (body is Map) {
        final data = body['data'] ?? body['items'] ?? body;
        if (data is List) {
          for (int i = 0; i < data.length; i++) {
            final m = data[i] as Map;
            final qty = (m['quantity'] ?? m['qty_produced'] ?? 0) as num;
            final costUnit = (m['cost_per_unit'] ?? m['unit_cost'] ?? 0.0) as num;
            final totalCost = (m['total_cost'] ?? m['total_production_cost'] ?? costUnit * qty) as num;
            final selling = (m['selling_price'] ?? m['price'] ?? 0.0) as num;
            final revenue = (m['expected_revenue'] ?? selling * qty) as num;
            final profit = (m['expected_profit'] ?? revenue - totalCost) as num;
            final margin = totalCost > 0 ? (profit / revenue * 100) : 0.0;
            items.add(_CostItem(
              sn: i + 1,
              productName: (m['product_name'] ?? m['name'] ?? '').toString(),
              recipe: (m['recipe_name'] ?? m['recipe'] ?? '').toString(),
              qtyProduced: qty.toInt(),
              costPerUnit: costUnit.toDouble(),
              totalProductionCost: totalCost.toDouble(),
              sellingPrice: selling.toDouble(),
              expectedRevenue: revenue.toDouble(),
              expectedProfit: profit.toDouble(),
              profitMargin: margin.toDouble(),
            ));
          }
        }
      }
      setState(() { _items = items; _isLoading = false; });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  List<_CostItem> get _filteredItems {
    final q = _searchController.text.toLowerCase().trim();
    if (q.isEmpty) return _items;
    return _items.where((i) => i.productName.toLowerCase().contains(q) || i.recipe.toLowerCase().contains(q)).toList();
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
        pw.Text('Production Cost Analysis', style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 16)),
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
        headers: ['S/N', 'Product Name', 'Recipe', 'Qty', 'Cost/Unit', 'Total Cost', 'Selling', 'Revenue', 'Profit', 'Margin %'],
        data: items.map((i) => ['${i.sn}', i.productName, i.recipe, '${i.qtyProduced}', _fmt(i.costPerUnit), _fmt(i.totalProductionCost), _fmt(i.sellingPrice), _fmt(i.expectedRevenue), _fmt(i.expectedProfit), '${i.profitMargin}%']).toList(),
      )],
      footer: (context) => pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 7, color: PdfColors.grey500))),
    ));
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/ProductionCostAnalysis_$_exportDateTime.pdf');
    await file.writeAsBytes(await doc.save(), flush: true);
    await OpenFile.open(file.path);
  }

  Future<void> _exportExcel() async {
    final items = _filteredItems;
    if (items.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export'))); return; }
    final excel = xls.Excel.createExcel();
    excel.rename(excel.getDefaultSheet()!, 'Production Cost Analysis');
    final sheet = excel['Production Cost Analysis'];
    sheet.appendRow(['S/N', 'Product Name', 'Recipe', 'Qty', 'Cost/Unit', 'Total Cost', 'Selling', 'Revenue', 'Profit', 'Margin %'].map((h) => xls.TextCellValue(h)).toList());
    for (final i in items) {
      sheet.appendRow([xls.DoubleCellValue(i.sn.toDouble()), xls.TextCellValue(i.productName), xls.TextCellValue(i.recipe), xls.DoubleCellValue(i.qtyProduced.toDouble()), xls.DoubleCellValue(i.costPerUnit), xls.DoubleCellValue(i.totalProductionCost), xls.DoubleCellValue(i.sellingPrice), xls.DoubleCellValue(i.expectedRevenue), xls.DoubleCellValue(i.expectedProfit), xls.DoubleCellValue(i.profitMargin)]);
    }
    final fileBytes = excel.save();
    if (fileBytes == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/ProductionCostAnalysis_$_exportDateTime.xlsx');
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
      leadingWidth: 56, title: Text('Production Cost Analysis', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
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

  Widget _buildTable(List<_CostItem> items) {
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
        _hCell('S/N', 32), _hCell('Product Name', 100), _hCell('Recipe', 90), _hCell('Qty', 45),
        _hCell('Cost/Unit', 70), _hCell('Total Cost', 80), _hCell('Selling', 70),
        _hCell('Revenue', 80), _hCell('Profit', 70), _hCell('Margin %', 60),
      ]),
    );
  }

  Widget _hCell(String t, double w) => SizedBox(width: w, child: Text(t, style: AppTypography.caption.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w700, fontSize: 9), textAlign: TextAlign.center));

  Widget _buildTableRow(_CostItem item, int idx) {
    final isEven = idx % 2 == 0;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(color: isEven ? AppColors.card : AppColors.background),
      child: Row(children: [
        _dCell('${item.sn}', 32), _nCell(item.productName, 100), _dCell(item.recipe, 90),
        _dCell('${item.qtyProduced}', 45), _dCell(_fmt(item.costPerUnit), 70), _dCell(_fmt(item.totalProductionCost), 80),
        _dCell(_fmt(item.sellingPrice), 70), _dCell(_fmt(item.expectedRevenue), 80),
        _profitCell(item.expectedProfit, 70), _marginCell(item.profitMargin, 60),
      ]),
    );
  }

  Widget _dCell(String t, double w) => SizedBox(width: w, child: Text(t, style: AppTypography.caption.copyWith(color: AppColors.textPrimary, fontSize: 9), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis));
  Widget _nCell(String t, double w) => SizedBox(width: w, child: Text(t, style: AppTypography.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis));
  Widget _profitCell(double v, double w) => SizedBox(width: w, child: Text(_fmt(v), style: AppTypography.caption.copyWith(color: v >= 0 ? AppColors.success : AppColors.danger, fontWeight: FontWeight.w600, fontSize: 9), textAlign: TextAlign.center));
  Widget _marginCell(double v, double w) => SizedBox(width: w, child: Text('${v.toStringAsFixed(1)}%', style: AppTypography.caption.copyWith(color: v >= 50 ? AppColors.success : AppColors.warning, fontWeight: FontWeight.w600, fontSize: 9), textAlign: TextAlign.center));

  Widget _buildEmptyState() {
    return Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXXL, vertical: 60),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 100, height: 100, decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.06), shape: BoxShape.circle),
          child: Icon(Icons.analytics_outlined, size: 48, color: AppColors.success.withValues(alpha: 0.4))),
        const SizedBox(height: 20),
        Text('No Cost Data Found', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Try a different search term.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
      ]),
    ));
  }
}
