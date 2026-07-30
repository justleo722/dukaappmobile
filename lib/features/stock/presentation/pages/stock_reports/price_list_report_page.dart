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

class _PriceItem {
  final int sn;
  final String name;
  final double sellingPrice;

  const _PriceItem({
    required this.sn,
    required this.name,
    required this.sellingPrice,
  });
}

class PriceListReportPage extends StatefulWidget {
  const PriceListReportPage({super.key});

  @override
  State<PriceListReportPage> createState() => _PriceListReportPageState();
}

class _PriceListReportPageState extends State<PriceListReportPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalController = ScrollController();

  static const List<_PriceItem> _allItems = [
    _PriceItem(sn: 1, name: 'AIR', sellingPrice: 7000),
    _PriceItem(sn: 2, name: 'AIR FRESH', sellingPrice: 5500),
    _PriceItem(sn: 3, name: 'APPLE JUICE', sellingPrice: 2000),
    _PriceItem(sn: 4, name: 'BILIAN', sellingPrice: 12000),
    _PriceItem(sn: 5, name: 'COCA COLA 600ML', sellingPrice: 1000),
    _PriceItem(sn: 6, name: 'COKE', sellingPrice: 1000),
    _PriceItem(sn: 7, name: 'DESPERADO', sellingPrice: 4000),
    _PriceItem(sn: 8, name: 'ENERGY DRINK', sellingPrice: 2500),
    _PriceItem(sn: 9, name: 'JACK DANIEL', sellingPrice: 65000),
    _PriceItem(sn: 10, name: 'MANGO JUICE', sellingPrice: 1500),
    _PriceItem(sn: 11, name: 'ORANGE JUICE', sellingPrice: 1500),
    _PriceItem(sn: 12, name: 'SMIRNOFF VODKA', sellingPrice: 22000),
    _PriceItem(sn: 13, name: 'FANTA', sellingPrice: 1000),
    _PriceItem(sn: 14, name: 'SPRITE', sellingPrice: 1000),
    _PriceItem(sn: 15, name: 'PILSNER', sellingPrice: 200),
    _PriceItem(sn: 16, name: 'TUSKER', sellingPrice: 200),
    _PriceItem(sn: 17, name: 'WHITE CAP', sellingPrice: 200),
    _PriceItem(sn: 18, name: 'CHIVAS REGAL', sellingPrice: 85000),
    _PriceItem(sn: 19, name: 'JAMESON', sellingPrice: 45000),
    _PriceItem(sn: 20, name: 'PATRÓN TEQUILA', sellingPrice: 95000),
    _PriceItem(sn: 21, name: 'HENNESSY', sellingPrice: 75000),
    _PriceItem(sn: 22, name: 'MARTINI', sellingPrice: 15000),
    _PriceItem(sn: 23, name: 'BAILEYS', sellingPrice: 28000),
    _PriceItem(sn: 24, name: 'CAMPARI', sellingPrice: 12000),
    _PriceItem(sn: 25, name: 'JOHNNIE WALKER RED', sellingPrice: 35000),
    _PriceItem(sn: 26, name: 'JOHNNIE WALKER BLACK', sellingPrice: 65000),
    _PriceItem(sn: 27, name: 'GORDONS GIN', sellingPrice: 18000),
    _PriceItem(sn: 28, name: 'SMIRNOFF ICE', sellingPrice: 3000),
    _PriceItem(sn: 29, name: 'CASTLE LITE', sellingPrice: 250),
    _PriceItem(sn: 30, name: 'AMSTEL', sellingPrice: 250),
  ];

  List<_PriceItem> get _filteredItems {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return _allItems;
    return _allItems
        .where((p) => p.name.toLowerCase().contains(query))
        .toList();
  }

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
        pageFormat: PdfPageFormat.a4.portrait,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Price List',
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
                font: pw.Font.helveticaBold(), fontSize: 8, color: PdfColors.white),
            cellStyle: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 8),
            headerAlignment: pw.Alignment.center,
            cellAlignment: pw.Alignment.center,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey400),
            headers: ['S/N', 'Product Name', 'Selling Price'],
            data: items.map((i) => [
              '${i.sn}', i.name, 'Tsh ${_fmt(i.sellingPrice)}',
            ]).toList(),
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
    final file = File('${dir.path}/PriceList_$_exportDateTime.pdf');
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
    excel.rename(excel.getDefaultSheet()!, 'Price List');

    final sheet = excel['Price List'];

    final headers = ['S/N', 'Product Name', 'Selling Price'];
    sheet.appendRow(headers.map((h) => xls.TextCellValue(h)).toList());

    for (final item in items) {
      sheet.appendRow([
        xls.DoubleCellValue(item.sn.toDouble()),
        xls.TextCellValue(item.name),
        xls.DoubleCellValue(item.sellingPrice),
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/PriceList_$_exportDateTime.xlsx');
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
        'Price List',
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
          hintText: 'Search products...',
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

  Widget _buildTable(List<_PriceItem> items) {
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(color: AppColors.primary),
      child: Row(
        children: [
          _headerCell('S/N', 60),
          _headerCell('Product Name', 200),
          _headerCell('Selling Price', 120),
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
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableRow(_PriceItem item, int index) {
    final isEven = index % 2 == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: isEven ? AppColors.card : AppColors.background,
      ),
      child: Row(
        children: [
          _dataCell('${item.sn}', 60),
          _nameCell(item.name, 200),
          _priceCell(item.sellingPrice, 120),
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
          fontSize: 11,
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
          fontSize: 11,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _priceCell(double value, double width) {
    return SizedBox(
      width: width,
      child: Text(
        'Tsh ${_fmt(value)}',
        style: AppTypography.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
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
                Icons.local_offer_outlined,
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
