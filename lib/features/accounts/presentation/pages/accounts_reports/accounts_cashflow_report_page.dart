// ignore_for_file: avoid_dynamic_calls
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

class AccountsCashflowReportPage extends ConsumerStatefulWidget {
  final String reportKey;
  final String title;

  const AccountsCashflowReportPage({super.key, required this.reportKey, required this.title});

  @override
  ConsumerState<AccountsCashflowReportPage> createState() => _AccountsCashflowReportPageState();
}

class _AccountsCashflowReportPageState extends ConsumerState<AccountsCashflowReportPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalController = ScrollController();

  List<Map<String, dynamic>> _rawData = [];
  bool _isLoading = false;
  String? _fromDate;
  String? _toDate;

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
      List<Map<String, dynamic>> items = [];

      switch (widget.reportKey) {
        case 'cash-in-hand-in-bank':
        case 'accounts-balance':
          // cashbookAccounts: account_name, total_credit, total_debit, balance, currency
          final res = await api.getCashbookAccounts();
          final raw = res.data;
          final list = _unwrapList(raw);
          int sn = 1;
          for (final row in list) {
            items.add({
              'sn': sn++,
              'currency': row['currency']?.toString() ?? 'TSh',
              'account': row['account_name']?.toString() ?? '',
              'cashIn': _toD(row['total_credit']),
              'cashOut': _toD(row['total_debit']),
              'balance': _toD(row['balance']),
            });
          }
          break;

        case 'cash-in':
          // cashflow list filtered to cash_in > 0
          final res = await api.getCashflow(from: from, to: to);
          final list = _unwrapList(res.data);
          int sn = 1;
          for (final row in list) {
            final cashIn = _toD(row['cash_in']);
            if (cashIn <= 0) continue;
            items.add({
              'sn': sn++,
              'date': row['record_date']?.toString() ?? '',
              'account': row['name']?.toString() ?? '',
              'title': row['title']?.toString() ?? row['category']?.toString() ?? '',
              'from': row['counter_account']?.toString() ?? '',
              'cashIn': cashIn,
              'balance': _toD(row['balance']),
            });
          }
          break;

        case 'cash-out':
          // cashflow list filtered to cash_out > 0
          final res = await api.getCashflow(from: from, to: to);
          final list = _unwrapList(res.data);
          int sn = 1;
          for (final row in list) {
            final cashOut = _toD(row['cash_out']);
            if (cashOut <= 0) continue;
            items.add({
              'sn': sn++,
              'date': row['record_date']?.toString() ?? '',
              'account': row['name']?.toString() ?? '',
              'title': row['title']?.toString() ?? row['category']?.toString() ?? '',
              'to': row['counter_account']?.toString() ?? '',
              'cashOut': cashOut,
              'balance': _toD(row['balance']),
            });
          }
          break;
      }

      if (!mounted) return;
      setState(() {
        _rawData = items;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _unwrapList(dynamic raw) {
    if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
    if (raw is Map<String, dynamic>) {
      final v = raw['data'] ?? raw['result'] ?? raw['items'];
      if (v is List) return v.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  static double _toD(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  List<String> get _headers {
    switch (widget.reportKey) {
      case 'cash-in-hand-in-bank':
        return ['S/N', 'Account', 'Currency', 'Cash In', 'Cash Out', 'Balance'];
      case 'cash-in':
        return ['S/N', 'Date', 'Account', 'Title', 'From', 'Cash In', 'Balance'];
      case 'cash-out':
        return ['S/N', 'Date', 'Account', 'Title', 'To', 'Cash Out', 'Balance'];
      case 'accounts-balance':
        return ['S/N', 'Account', 'Currency', 'Cash In', 'Cash Out', 'Balance'];
      default:
        return ['S/N', 'Account', 'Currency', 'Cash In', 'Cash Out', 'Balance'];
    }
  }

  List<double> get _columnWidths {
    switch (widget.reportKey) {
      case 'cash-in-hand-in-bank':
      case 'accounts-balance':
        return [40, 150, 80, 120, 120, 120];
      case 'cash-in':
        return [40, 110, 130, 140, 120, 120, 120];
      case 'cash-out':
        return [40, 110, 130, 140, 120, 120, 120];
      default:
        return [40, 150, 80, 120, 120, 120];
    }
  }

  List<Map<String, dynamic>> get _filteredItems {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return _rawData;
    return _rawData.where((i) => i.values.any((v) => v.toString().toLowerCase().contains(query))).toList();
  }

  double get _totalCashIn => _filteredItems.fold(0.0, (s, i) => s + _toD(i['cashIn']));
  double get _totalCashOut => _filteredItems.fold(0.0, (s, i) => s + _toD(i['cashOut']));
  double get _totalBalance => _filteredItems.fold(0.0, (s, i) => s + _toD(i['balance']));

  String get _exportDateTime => DateFormat('dd-MM-yyyy_HH-mm').format(DateTime.now());

  String _cellValue(Map<String, dynamic> item, String header) {
    switch (header) {
      case 'S/N':       return '${item['sn']}';
      case 'Currency':  return item['currency']?.toString() ?? '';
      case 'Date':      return item['date']?.toString() ?? '';
      case 'Account':   return item['account']?.toString() ?? '';
      case 'Title':     return item['title']?.toString() ?? '';
      case 'From':      return item['from']?.toString() ?? '';
      case 'To':        return item['to']?.toString() ?? '';
      case 'Cash In':   return _fmt(_toD(item['cashIn']));
      case 'Cash Out':  return _fmt(_toD(item['cashOut']));
      case 'Balance':   return _fmt(_toD(item['balance']));
      default:          return '';
    }
  }

  String _fmt(double v) {
    final fmt = NumberFormat('#,###');
    return 'Tsh ${fmt.format(v)}';
  }

  Future<void> _exportPdf() async {
    final items = _filteredItems;
    if (items.isEmpty) return;
    final doc = pw.Document();
    final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(20),
      header: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(widget.title, style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 16)),
        pw.SizedBox(height: 2),
        pw.Text('${ref.read(shopNameProvider).valueOrNull ?? 'My Shop'}  •  $now', style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 4), pw.Divider(), pw.SizedBox(height: 4),
      ]),
      build: (_) => [pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 7, color: PdfColors.white),
        cellStyle: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 7),
        headerAlignment: pw.Alignment.center, cellAlignment: pw.Alignment.center,
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
        oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
        border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey400),
        headers: _headers,
        data: [
          ...items.map((i) => _headers.map((h) => _cellValue(i, h)).toList()),
          _buildPdfTotalRow(),
        ],
      )],
    ));
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${widget.title.replaceAll(' ', '_')}_$_exportDateTime.pdf');
    await file.writeAsBytes(await doc.save(), flush: true);
    await OpenFile.open(file.path);
  }

  List<String> _buildPdfTotalRow() {
    final row = <String>[];
    for (final h in _headers) {
      if (h == 'Cash In') row.add(_fmt(_totalCashIn));
      else if (h == 'Cash Out') row.add(_fmt(_totalCashOut));
      else if (h == 'Balance') row.add(_fmt(_totalBalance));
      else if (h == _headers[1]) row.add('TOTAL');
      else row.add('');
    }
    return row;
  }

  Future<void> _exportExcel() async {
    final items = _filteredItems;
    if (items.isEmpty) return;
    final excel = xls.Excel.createExcel();
    excel.rename(excel.getDefaultSheet()!, widget.title);
    final sheet = excel[widget.title];
    sheet.appendRow(_headers.map((h) => xls.TextCellValue(h)).toList());
    for (final i in items) {
      sheet.appendRow(_headers.map((h) {
        final v = _cellValue(i, h);
        final num = double.tryParse(v.replaceAll(RegExp(r'[^0-9.\-]'), ''));
        return num != null ? xls.DoubleCellValue(num) : xls.TextCellValue(v);
      }).toList());
    }
    final totalRow = <xls.CellValue>[];
    for (final h in _headers) {
      if (h == 'Cash In') totalRow.add(xls.DoubleCellValue(_totalCashIn));
      else if (h == 'Cash Out') totalRow.add(xls.DoubleCellValue(_totalCashOut));
      else if (h == 'Balance') totalRow.add(xls.DoubleCellValue(_totalBalance));
      else if (h == _headers[1]) totalRow.add(xls.TextCellValue('TOTAL'));
      else totalRow.add(xls.TextCellValue(''));
    }
    sheet.appendRow(totalRow);
    final bytes = excel.save();
    if (bytes == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${widget.title.replaceAll(' ', '_')}_$_exportDateTime.xlsx');
    await file.writeAsBytes(bytes, flush: true);
    await OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FilterState>(filterProvider, (prev, next) {
      if (prev?.from != next.from || prev?.to != next.to) {
        _fromDate = next.from;
        _toDate = next.to;
        _loadData(from: next.from, to: next.to);
      }
    });

    final items = _filteredItems;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(context),
      body: SafeArea(top: false, child: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(children: [
              _buildActionButtons(context),
              const SizedBox(height: 12),
              _buildSearchField(),
              const SizedBox(height: 12),
              items.isEmpty ? _buildEmptyState() : _buildTable(items),
              const SizedBox(height: 24),
            ]),
          ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.card, elevation: 0,
      leading: Padding(padding: const EdgeInsets.all(8.0), child: Container(
        decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
        child: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20)),
      )),
      leadingWidth: 56,
      title: Text(widget.title, style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconButton(
            onPressed: () => _loadData(from: _fromDate, to: _toDate),
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textHint, size: 20),
          ),
        ),
      ],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.divider)),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 10), color: AppColors.card,
      child: Row(children: [
        _buildActionButton(icon: Icons.picture_as_pdf_rounded, label: 'PDF', color: AppColors.danger, onTap: _exportPdf),
        const SizedBox(width: 8),
        _buildActionButton(icon: Icons.table_chart_rounded, label: 'Excel', color: AppColors.success, onTap: _exportExcel),
        const SizedBox(width: 8),
        _buildActionButton(icon: Icons.filter_list_rounded, label: 'Filter', color: AppColors.primary, onTap: () => AppFilterDialog.show(context)),
      ]),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Expanded(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 16, color: color), const SizedBox(width: 6),
        Text(label, style: AppTypography.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 12))]),
    )));
  }

  Widget _buildSearchField() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG), child: TextField(
      controller: _searchController, onChanged: (_) => setState(() {}), style: AppTypography.bodyMedium,
      decoration: InputDecoration(hintText: 'Search...', hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
        suffixIcon: _searchController.text.isNotEmpty ? IconButton(onPressed: () { _searchController.clear(); setState(() {}); }, icon: const Icon(Icons.close_rounded, color: AppColors.textHint, size: 18)) : null,
        filled: true, fillColor: AppColors.card, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5)),
      ),
    ));
  }

  Widget _buildTable(List<Map<String, dynamic>> items) {
    return Container(margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))]),
      child: ClipRRect(borderRadius: BorderRadius.circular(14), child: SingleChildScrollView(scrollDirection: Axis.horizontal, controller: _horizontalController,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildTableHeader(),
          ...items.asMap().entries.map((e) => _buildTableRow(e.value, e.key)),
          _buildTotalsRow(),
        ]),
      )),
    );
  }

  Widget _buildTableHeader() {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: const BoxDecoration(color: AppColors.primary),
      child: Row(children: [for (int i = 0; i < _headers.length; i++) _headerCell(_headers[i], _columnWidths[i])]),
    );
  }

  Widget _headerCell(String text, double width) {
    return SizedBox(width: width, child: Text(text, style: AppTypography.caption.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w700, fontSize: 11), textAlign: TextAlign.center));
  }

  Widget _buildTableRow(Map<String, dynamic> item, int index) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: index % 2 == 0 ? AppColors.card : AppColors.background),
      child: Row(children: [for (int i = 0; i < _headers.length; i++) _dataCell(_cellValue(item, _headers[i]), _columnWidths[i], _headers[i] == 'Account' || _headers[i] == 'Title' || _headers[i] == 'From' || _headers[i] == 'To' || _headers[i] == 'Currency')]),
    );
  }

  Widget _dataCell(String text, double width, bool isName) {
    return SizedBox(width: width, child: Text(text,
      style: AppTypography.caption.copyWith(color: AppColors.textPrimary, fontWeight: isName ? FontWeight.w600 : FontWeight.w400, fontSize: 11),
      textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis));
  }

  Widget _buildTotalsRow() {
    final totalCells = <Widget>[];
    for (int i = 0; i < _headers.length; i++) {
      final h = _headers[i];
      String val = '';
      if (h == 'Cash In') val = _fmt(_totalCashIn);
      else if (h == 'Cash Out') val = _fmt(_totalCashOut);
      else if (h == 'Balance') val = _fmt(_totalBalance);
      else if (i == 1) val = 'TOTAL';
      totalCells.add(_totalCell(val, _columnWidths[i], i == 1));
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06),
      border: Border(top: BorderSide(color: AppColors.primary.withValues(alpha: 0.2), width: 1))),
      child: Row(children: totalCells),
    );
  }

  Widget _totalCell(String text, double width, bool isLabel) {
    return SizedBox(width: width, child: Text(text, style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: isLabel ? FontWeight.w800 : FontWeight.w700, fontSize: 11), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis));
  }

  Widget _buildEmptyState() {
    return Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXXL, vertical: 60), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 100, height: 100, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), shape: BoxShape.circle),
        child: Icon(Icons.receipt_long_rounded, size: 48, color: AppColors.primary.withValues(alpha: 0.4))),
      const SizedBox(height: 20),
      Text('No Records Found', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text('Try a different date range or search term.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
    ])));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }
}
