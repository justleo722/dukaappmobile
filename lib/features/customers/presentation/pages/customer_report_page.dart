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
import 'package:dukaapp/features/customers/data/models/customer_model.dart';

class CustomerReportPage extends ConsumerStatefulWidget {
  final Customer customer;
  final String reportType; // 'wallet_statement' | 'wallet_sales' | 'statement'

  const CustomerReportPage({
    super.key,
    required this.customer,
    required this.reportType,
  });

  @override
  ConsumerState<CustomerReportPage> createState() => _CustomerReportPageState();
}

class _CustomerReportPageState extends ConsumerState<CustomerReportPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _hScroll = ScrollController();

  List<String> _headers = [];
  List<List<String>> _rows = [];
  bool _isLoading = false;

  String get _title {
    switch (widget.reportType) {
      case 'wallet_statement': return 'Wallet Statement';
      case 'wallet_sales':    return 'Wallet Sales';
      default:                return 'Customer Statement';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _hScroll.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final fmt = NumberFormat('#,###');
      double toNum(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;

      switch (widget.reportType) {
        case 'wallet_statement':
          final res = await api.getWalletCustomerStatement(widget.customer.id);
          final list = _unwrap(res.data);
          _headers = ['Date', 'Type', 'From', 'To', 'Title', 'Amount'];
          _rows = list.map((t) => [
            (t['record_date'] ?? '').toString(),
            (t['type'] ?? '').toString().toUpperCase(),
            (t['from_account_name'] ?? '-').toString(),
            (t['to_account_name'] ?? '-').toString(),
            (t['title'] ?? '-').toString(),
            fmt.format(toNum(t['amount'])),
          ]).toList();
          break;

        case 'wallet_sales':
          final res = await api.getWalletCustomerSalesStatement(widget.customer.id);
          final list = _unwrap(res.data);
          _headers = ['Date', 'Sale#', 'Invoice', 'Total', 'Paid', 'Balance'];
          _rows = list.map((s) => [
            (s['record_date'] ?? '').toString(),
            '#${s['sale_id'] ?? ''}',
            (s['invoice_no'] ?? '-').toString(),
            fmt.format(toNum(s['total_amount'])),
            fmt.format(toNum(s['paid_amount'])),
            fmt.format(toNum(s['balance_amount'])),
          ]).toList();
          break;

        default: // combined statement
          final today = DateTime.now().toIso8601String().substring(0, 10);
          final salesRes = await api.getCustomerSales(
            widget.customer.id,
            from: '1990-01-01',
            to: today,
          );
          final salesList = _unwrap(salesRes.data);
          _headers = ['Date', 'Sale#', 'Type', 'Status', 'Total', 'Paid', 'Balance'];
          _rows = salesList.map((s) {
            final bal = toNum(s['balance_amount'] ?? s['balance']);
            return [
              (s['record_date'] ?? s['date'] ?? '').toString(),
              '#${s['sale_id'] ?? s['id'] ?? ''}',
              (s['payment_mode'] ?? s['sale_type'] ?? '').toString(),
              bal > 0.01 ? 'Unpaid' : 'Paid',
              fmt.format(toNum(s['total_amount'] ?? s['total'])),
              fmt.format(toNum(s['paid_amount'] ?? s['paid'])),
              fmt.format(bal),
            ];
          }).toList();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _unwrap(dynamic raw) {
    if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
    if (raw is Map<String, dynamic>) {
      final v = raw['data'] ?? raw['result'] ?? raw['items'];
      if (v is List) return v.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  List<List<String>> get _filtered {
    final q = _searchController.text.toLowerCase().trim();
    if (q.isEmpty) return _rows;
    return _rows.where((r) => r.any((c) => c.toLowerCase().contains(q))).toList();
  }

  bool _isNumeric(String h) {
    final l = h.toLowerCase();
    return l.contains('total') || l.contains('paid') || l.contains('balance') || l.contains('amount');
  }

  String _parseNum(String s) => s.replaceAll(RegExp(r'[^0-9.]'), '');

  List<String> _totals(List<List<String>> rows) {
    final t = List<String>.filled(_headers.length, '');
    final fmt = NumberFormat('#,###');
    for (int c = 0; c < _headers.length; c++) {
      if (_isNumeric(_headers[c])) {
        double sum = 0;
        for (final r in rows) {
          if (c < r.length) sum += double.tryParse(_parseNum(r[c])) ?? 0;
        }
        t[c] = fmt.format(sum);
      }
    }
    return t;
  }

  double _colWidth(String h) {
    switch (h) {
      case 'Date': return 95;
      case 'Direction': return 55;
      case 'Sale#': return 60;
      case 'Type': case 'Status': return 65;
      default: return 90;
    }
  }

  Future<void> _exportPdf() async {
    final rows = _filtered;
    if (rows.isEmpty) { _snack('No data to export'); return; }
    final doc = pw.Document();
    final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final tots = _totals(rows);
    final hasTots = tots.any((t) => t.isNotEmpty);
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(20),
      header: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('$_title — ${widget.customer.name}', style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 14)),
        pw.SizedBox(height: 2),
        pw.Text(now, style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 4), pw.Divider(), pw.SizedBox(height: 4),
      ]),
      build: (_) => [
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 7, color: PdfColors.white),
          cellStyle: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 7),
          headerAlignment: pw.Alignment.center, cellAlignment: pw.Alignment.center,
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey400),
          headers: _headers,
          data: [
            ...rows,
            if (hasTots) tots.asMap().entries.map((e) => e.key == 0 ? 'TOTAL' : e.value).toList(),
          ],
        ),
      ],
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
          style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 7, color: PdfColors.grey500)),
      ),
    ));
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${widget.reportType}_${widget.customer.id}_${DateFormat('dd-MM-yyyy_HH-mm').format(DateTime.now())}.pdf');
    await file.writeAsBytes(await doc.save(), flush: true);
    await OpenFile.open(file.path);
  }

  Future<void> _exportExcel() async {
    final rows = _filtered;
    if (rows.isEmpty) { _snack('No data to export'); return; }
    final excel = xls.Excel.createExcel();
    excel.rename(excel.getDefaultSheet()!, _title);
    final sheet = excel[_title];
    sheet.appendRow(_headers.map((h) => xls.TextCellValue(h)).toList());
    for (final r in rows) {
      sheet.appendRow(r.asMap().entries.map((e) {
        if (_isNumeric(_headers[e.key])) return xls.DoubleCellValue(double.tryParse(_parseNum(e.value)) ?? 0);
        return xls.TextCellValue(e.value);
      }).toList());
    }
    final tots = _totals(rows);
    if (tots.any((t) => t.isNotEmpty)) {
      sheet.appendRow(tots.asMap().entries.map((e) {
        if (e.key == 0) return xls.TextCellValue('TOTAL');
        if (e.value.isEmpty) return xls.TextCellValue('');
        return xls.DoubleCellValue(double.tryParse(_parseNum(e.value)) ?? 0);
      }).toList());
    }
    final bytes = excel.save();
    if (bytes == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${widget.reportType}_${widget.customer.id}_${DateFormat('dd-MM-yyyy_HH-mm').format(DateTime.now())}.xlsx');
    await file.writeAsBytes(bytes, flush: true);
    await OpenFile.open(file.path);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.card, elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
            child: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20)),
          ),
        ),
        leadingWidth: 56,
        title: Column(children: [
          Text(_title, style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          Text(widget.customer.name, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10)),
        ]),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.divider)),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomPadding + 24),
          child: Column(children: [
            // Action buttons
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 10),
              color: AppColors.card,
              child: Row(children: [
                _actionBtn(Icons.picture_as_pdf_rounded, 'PDF', AppColors.danger, _exportPdf),
                const SizedBox(width: 8),
                _actionBtn(Icons.table_chart_rounded, 'Excel', AppColors.success, _exportExcel),
                const SizedBox(width: 8),
                _actionBtn(Icons.refresh_rounded, 'Refresh', AppColors.primary, _loadData),
              ]),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(AppConstants.paddingLG, 12, AppConstants.paddingLG, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(onPressed: () { _searchController.clear(); setState(() {}); }, icon: const Icon(Icons.close_rounded, color: AppColors.textHint, size: 18))
                    : null,
                  filled: true, fillColor: AppColors.card,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
            else if (rows.isEmpty)
              _emptyState()
            else
              _table(rows),
          ]),
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: color), const SizedBox(width: 6),
          Text(label, style: AppTypography.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ]),
      ),
    ),
  );

  Widget _table(List<List<String>> rows) {
    final tots = _totals(rows);
    final hasTots = tots.any((t) => t.isNotEmpty);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal, controller: _hScroll,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Row(children: _headers.map((h) => SizedBox(width: _colWidth(h), child: Text(h, style: AppTypography.caption.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w700, fontSize: 10), textAlign: TextAlign.center))).toList()),
            ),
            ...rows.asMap().entries.map((entry) {
              final isEven = entry.key % 2 == 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(color: isEven ? AppColors.card : AppColors.background),
                child: Row(children: entry.value.asMap().entries.map((e) => SizedBox(width: _colWidth(_headers[e.key]), child: Text(e.value, style: AppTypography.caption.copyWith(color: AppColors.textPrimary, fontSize: 10), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis))).toList()),
              );
            }),
            if (hasTots) Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), border: Border(top: BorderSide(color: AppColors.primary.withValues(alpha: 0.2), width: 1))),
              child: Row(children: tots.asMap().entries.map((e) {
                final label = e.key == 0 ? 'TOTAL' : e.value;
                return SizedBox(width: _colWidth(_headers[e.key]), child: Text(label, style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 10), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis));
              }).toList()),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXXL, vertical: 60),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 100, height: 100, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), shape: BoxShape.circle),
          child: Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.primary.withValues(alpha: 0.4))),
        const SizedBox(height: 20),
        Text('No Records Found', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('No data available for $_title.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
      ]),
    ),
  );
}
