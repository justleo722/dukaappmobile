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

class _RecipeProductItem {
  final int sn;
  final String recipeName;
  final String productName;
  final int totalProductions;
  final int totalQtyProduced;
  final double estimatedCostPerUnit;
  final double totalProductionCost;
  final double avgDailyProduction;

  const _RecipeProductItem({
    required this.sn, required this.recipeName, required this.productName,
    required this.totalProductions, required this.totalQtyProduced,
    required this.estimatedCostPerUnit, required this.totalProductionCost,
    required this.avgDailyProduction,
  });
}

class ProductByRecipeReportPage extends ConsumerStatefulWidget {
  const ProductByRecipeReportPage({super.key});

  @override
  ConsumerState<ProductByRecipeReportPage> createState() => _ProductByRecipeReportPageState();
}

class _ProductByRecipeReportPageState extends ConsumerState<ProductByRecipeReportPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<_RecipeProductItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getMfProductionByRecipe();
      final body = res.data;
      List<_RecipeProductItem> items = [];
      if (body is Map) {
        final data = body['data'] ?? body['items'] ?? body;
        if (data is List) {
          for (int i = 0; i < data.length; i++) {
            final m = data[i] as Map;
            final qty = (m['total_qty_produced'] ?? m['total_quantity'] ?? 0) as num;
            final costUnit = (m['estimated_cost_per_unit'] ?? m['cost_per_unit'] ?? 0.0) as num;
            items.add(_RecipeProductItem(
              sn: i + 1,
              recipeName: (m['recipe_name'] ?? m['recipe'] ?? '').toString(),
              productName: (m['product_name'] ?? m['name'] ?? '').toString(),
              totalProductions: (m['total_productions'] ?? m['total_batches'] ?? 0) as int? ?? 0,
              totalQtyProduced: qty.toInt(),
              estimatedCostPerUnit: costUnit.toDouble(),
              totalProductionCost: ((m['total_production_cost'] ?? costUnit * qty) as num).toDouble(),
              avgDailyProduction: ((m['avg_daily_production'] ?? 0.0) as num).toDouble(),
            ));
          }
        }
      }
      setState(() { _items = items; _isLoading = false; });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  List<_RecipeProductItem> get _filteredItems {
    final q = _searchController.text.toLowerCase().trim();
    if (q.isEmpty) return _items;
    return _items.where((i) => i.recipeName.toLowerCase().contains(q) || i.productName.toLowerCase().contains(q)).toList();
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
        pw.Text('Product by Recipe', style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 16)),
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
        headers: ['S/N', 'Recipe Name', 'Product Name', 'Productions', 'Total Qty', 'Cost/Unit', 'Total Cost', 'Avg Daily'],
        data: items.map((i) => ['${i.sn}', i.recipeName, i.productName, '${i.totalProductions}', '${i.totalQtyProduced}', _fmt(i.estimatedCostPerUnit), _fmt(i.totalProductionCost), i.avgDailyProduction.toStringAsFixed(0)]).toList(),
      )],
      footer: (context) => pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 7, color: PdfColors.grey500))),
    ));
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/ProductByRecipe_$_exportDateTime.pdf');
    await file.writeAsBytes(await doc.save(), flush: true);
    await OpenFile.open(file.path);
  }

  Future<void> _exportExcel() async {
    final items = _filteredItems;
    if (items.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export'))); return; }
    final excel = xls.Excel.createExcel();
    excel.rename(excel.getDefaultSheet()!, 'Product by Recipe');
    final sheet = excel['Product by Recipe'];
    sheet.appendRow(['S/N', 'Recipe Name', 'Product Name', 'Productions', 'Total Qty', 'Cost/Unit', 'Total Cost', 'Avg Daily'].map((h) => xls.TextCellValue(h)).toList());
    for (final i in items) {
      sheet.appendRow([xls.DoubleCellValue(i.sn.toDouble()), xls.TextCellValue(i.recipeName), xls.TextCellValue(i.productName), xls.DoubleCellValue(i.totalProductions.toDouble()), xls.DoubleCellValue(i.totalQtyProduced.toDouble()), xls.DoubleCellValue(i.estimatedCostPerUnit), xls.DoubleCellValue(i.totalProductionCost), xls.DoubleCellValue(i.avgDailyProduction)]);
    }
    final fileBytes = excel.save();
    if (fileBytes == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/ProductByRecipe_$_exportDateTime.xlsx');
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
      leadingWidth: 56, title: Text('Product by Recipe', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
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
        decoration: InputDecoration(hintText: 'Search recipes or products...', hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
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

  Widget _buildTable(List<_RecipeProductItem> items) {
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
        _hCell('S/N', 32), _hCell('Recipe Name', 100), _hCell('Product Name', 100), _hCell('Productions', 70),
        _hCell('Total Qty', 60), _hCell('Cost/Unit', 70), _hCell('Total Cost', 80), _hCell('Avg Daily', 60),
      ]),
    );
  }

  Widget _hCell(String t, double w) => SizedBox(width: w, child: Text(t, style: AppTypography.caption.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w700, fontSize: 9), textAlign: TextAlign.center));

  Widget _buildTableRow(_RecipeProductItem item, int idx) {
    final isEven = idx % 2 == 0;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(color: isEven ? AppColors.card : AppColors.background),
      child: Row(children: [
        _dCell('${item.sn}', 32), _nCell(item.recipeName, 100), _nCell(item.productName, 100),
        _dCell('${item.totalProductions}', 70), _dCell('${item.totalQtyProduced}', 60),
        _dCell(_fmt(item.estimatedCostPerUnit), 70), _dCell(_fmt(item.totalProductionCost), 80),
        _dCell(item.avgDailyProduction.toStringAsFixed(0), 60),
      ]),
    );
  }

  Widget _dCell(String t, double w) => SizedBox(width: w, child: Text(t, style: AppTypography.caption.copyWith(color: AppColors.textPrimary, fontSize: 9), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis));
  Widget _nCell(String t, double w) => SizedBox(width: w, child: Text(t, style: AppTypography.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis));

  Widget _buildEmptyState() {
    return Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXXL, vertical: 60),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 100, height: 100, decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: 0.06), shape: BoxShape.circle),
          child: Icon(Icons.receipt_long_outlined, size: 48, color: const Color(0xFF8B5CF6).withValues(alpha: 0.4))),
        const SizedBox(height: 20),
        Text('No Recipe Data Found', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Try a different search term.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
      ]),
    ));
  }
}
