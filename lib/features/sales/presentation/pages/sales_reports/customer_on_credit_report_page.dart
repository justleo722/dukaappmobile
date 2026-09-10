import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/features/sales/presentation/providers/sales_provider.dart';
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
import 'package:dukaapp/shared/providers/filter_provider.dart';

class _CustomerCreditItem {
  final int sn;
  final String lastCreditDate;
  final String customer;
  final String phone;
  final double creditSales;
  final double total;
  final double paid;
  final double creditBalance;

  const _CustomerCreditItem({
    required this.sn,
    required this.lastCreditDate,
    required this.customer,
    required this.phone,
    required this.creditSales,
    required this.total,
    required this.paid,
    required this.creditBalance,
  });
}

class CustomerOnCreditReportPage extends ConsumerStatefulWidget {
  const CustomerOnCreditReportPage({super.key});

  @override
  ConsumerState<CustomerOnCreditReportPage> createState() =>
      _CustomerOnCreditReportPageState();
}

class _CustomerOnCreditReportPageState
    extends ConsumerState<CustomerOnCreditReportPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalController = ScrollController();

  List<_CustomerCreditItem> _allItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadItems());
  }

  Future<void> _loadItems({String? from, String? to}) async {
    try {
      final repo = ref.read(salesRepositoryProvider);
      final data = await repo.fetchReportOnCreditCustomers(from: from, to: to);
      if (!mounted) return;
      setState(() {
        _allItems = data.map((r) => _CustomerCreditItem(sn: r.sn, lastCreditDate: r.lastCreditDate, customer: r.customer, phone: r.phone, creditSales: r.creditSales, total: r.total, paid: r.paid, creditBalance: r.creditBalance)).toList();
      });
    } catch (_) {}
  }

  List<_CustomerCreditItem> get _filteredItems {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return _allItems;
    return _allItems
        .where((item) =>
            item.lastCreditDate.toLowerCase().contains(query) ||
            item.customer.toLowerCase().contains(query) ||
            item.phone.toLowerCase().contains(query))
        .toList();
  }

  double get _totalCreditSales => _filteredItems.fold(0, (s, i) => s + i.creditSales);
  double get _totalTotal => _filteredItems.fold(0, (s, i) => s + i.total);
  double get _totalPaid => _filteredItems.fold(0, (s, i) => s + i.paid);
  double get _totalCreditBalance => _filteredItems.fold(0, (s, i) => s + i.creditBalance);

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
    final fmt = NumberFormat('#,###');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Customer On Credit Report', style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 16)),
            pw.SizedBox(height: 2),
            pw.Text('SON COLLECTION  •  $now',
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
            headers: ['S/N', 'Last Credit Date', 'Customer', 'Phone', 'Credit Sales', 'Total', 'Paid', 'Credit Balance'],
            data: [
              ...items.map((i) => [
                '${i.sn}', i.lastCreditDate, i.customer, i.phone,
                fmt.format(i.creditSales), fmt.format(i.total), fmt.format(i.paid), fmt.format(i.creditBalance),
              ]),
              ['', 'TOTAL', '', '', fmt.format(_totalCreditSales), fmt.format(_totalTotal), fmt.format(_totalPaid), fmt.format(_totalCreditBalance)],
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
    final file = File('${dir.path}/CustomerOnCreditReport_$_exportDateTime.pdf');
    await file.writeAsBytes(await doc.save(), flush: true);
    await OpenFile.open(file.path);
  }

  Future<void> _exportExcel() async {
    final items = _filteredItems;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    final excel = xls.Excel.createExcel();
    excel.rename(excel.getDefaultSheet()!, 'Customer On Credit Report');

    final sheet = excel['Customer On Credit Report'];

    final headers = ['S/N', 'Last Credit Date', 'Customer', 'Phone', 'Credit Sales', 'Total', 'Paid', 'Credit Balance'];
    sheet.appendRow(headers.map((h) => xls.TextCellValue(h)).toList());

    for (final item in items) {
      sheet.appendRow([
        xls.DoubleCellValue(item.sn.toDouble()),
        xls.TextCellValue(item.lastCreditDate),
        xls.TextCellValue(item.customer),
        xls.TextCellValue(item.phone),
        xls.DoubleCellValue(item.creditSales),
        xls.DoubleCellValue(item.total),
        xls.DoubleCellValue(item.paid),
        xls.DoubleCellValue(item.creditBalance),
      ]);
    }

    sheet.appendRow([
      xls.TextCellValue(''),
      xls.TextCellValue('TOTAL'),
      xls.TextCellValue(''),
      xls.TextCellValue(''),
      xls.DoubleCellValue(_totalCreditSales),
      xls.DoubleCellValue(_totalTotal),
      xls.DoubleCellValue(_totalPaid),
      xls.DoubleCellValue(_totalCreditBalance),
    ]);

    final fileBytes = excel.save();
    if (fileBytes == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/CustomerOnCreditReport_$_exportDateTime.xlsx');
    await file.writeAsBytes(fileBytes, flush: true);
    await OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FilterState>(filterProvider, (_, f) => _loadItems(from: f.from, to: f.to));
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
              _buildCloseButton(context),
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
      title: Column(
        children: [
          Text(
            'Customer On Credit Report',
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'SON COLLECTION',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
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
                  'SON COLLECTION',
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
          hintText: 'Search customers...',
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

  Widget _buildTable(List<_CustomerCreditItem> items) {
    final fmt = NumberFormat('#,###');
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
              _buildTotalsRow(fmt),
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
          _headerCell('S/N', 35),
          _headerCell('Last Credit Date', 85),
          _headerCell('Customer', 100),
          _headerCell('Phone', 85),
          _headerCell('Credit Sales', 75),
          _headerCell('Total', 70),
          _headerCell('Paid', 65),
          _headerCell('Credit Balance', 80),
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

  Widget _buildTableRow(_CustomerCreditItem item, int index) {
    final isEven = index % 2 == 0;
    final fmt = NumberFormat('#,###');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isEven ? AppColors.card : AppColors.background,
      ),
      child: Row(
        children: [
          _dataCell('${item.sn}', 35),
          _dataCell(item.lastCreditDate, 85),
          _nameCell(item.customer, 100),
          _dataCell(item.phone, 85),
          _dataCell(fmt.format(item.creditSales), 75),
          _dataCell(fmt.format(item.total), 70),
          _dataCell(fmt.format(item.paid), 65),
          _balanceCell(item.creditBalance, 80),
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

  Widget _balanceCell(double value, double width) {
    final fmt = NumberFormat('#,###');
    return SizedBox(
      width: width,
      child: Text(
        fmt.format(value),
        style: AppTypography.caption.copyWith(
          color: value > 0 ? AppColors.danger : AppColors.textPrimary,
          fontWeight: value > 0 ? FontWeight.w600 : FontWeight.w400,
          fontSize: 10,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTotalsRow(NumberFormat fmt) {
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
          _totalCell('', 35),
          _totalLabelCell('TOTAL', 85),
          _totalCell('', 100),
          _totalCell('', 85),
          _totalCell(fmt.format(_totalCreditSales), 75),
          _totalCell(fmt.format(_totalTotal), 70),
          _totalCell(fmt.format(_totalPaid), 65),
          _totalCell(fmt.format(_totalCreditBalance), 80),
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

  Widget _buildCloseButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      child: SizedBox(
        width: double.infinity,
        height: AppConstants.buttonHeight,
        child: OutlinedButton(
          onPressed: () => context.pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            ),
          ),
          child: Text(
            'Close',
            style: AppTypography.buttonLarge.copyWith(color: AppColors.textPrimary),
          ),
        ),
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
                Icons.person_off_outlined,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Customers Found',
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
