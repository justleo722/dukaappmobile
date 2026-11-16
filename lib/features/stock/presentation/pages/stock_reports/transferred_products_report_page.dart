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
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/stock/presentation/providers/stock_provider.dart';
import 'package:dukaapp/shared/dialogs/app_filter_dialog.dart';
import 'package:dukaapp/shared/providers/filter_provider.dart';

/// One transfer line (Reports_model::transferredProducts).
class _TransferItem {
  final String date;
  final String time;
  final String product;
  final String direction; // Out | In
  final String otherShop;
  final double quantity;
  final double value;
  final String user;

  const _TransferItem({
    required this.date,
    required this.time,
    required this.product,
    required this.direction,
    required this.otherShop,
    required this.quantity,
    required this.value,
    required this.user,
  });

  factory _TransferItem.fromJson(Map<String, dynamic> m) {
    double d(dynamic v) => double.tryParse('${v ?? 0}') ?? 0;
    return _TransferItem(
      date: '${m['date'] ?? ''}',
      time: '${m['time'] ?? ''}',
      product: '${m['product_name'] ?? ''}',
      direction: '${m['direction'] ?? ''}',
      otherShop: '${m['other_shop'] ?? ''}',
      quantity: d(m['quantity']),
      value: d(m['total_amount']),
      user: '${m['username'] ?? ''}',
    );
  }
}

class TransferredProductsReportPage extends ConsumerStatefulWidget {
  const TransferredProductsReportPage({super.key});

  @override
  ConsumerState<TransferredProductsReportPage> createState() => _TransferredProductsReportPageState();
}

class _TransferredProductsReportPageState extends ConsumerState<TransferredProductsReportPage> {
  final TextEditingController _search = TextEditingController();
  List<_TransferItem> _all = [];
  bool _loading = true;

  static const _headers = ['Date', 'Time', 'Product', 'Direction', 'From / To Shop', 'Qty', 'Value', 'By'];
  static const _widths = <double>[90, 60, 160, 80, 140, 70, 100, 110];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final filter = ref.read(filterProvider);
      final rows = await ref
          .read(stockRepositoryProvider)
          .fetchReportRows('transferredProducts', from: filter.from, to: filter.to);
      if (mounted) setState(() => _all = rows.map(_TransferItem.fromJson).toList());
    } catch (_) {
      if (mounted) setState(() => _all = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_TransferItem> get _items {
    final q = _search.text.toLowerCase().trim();
    if (q.isEmpty) return _all;
    return _all
        .where((i) => i.product.toLowerCase().contains(q) || i.otherShop.toLowerCase().contains(q))
        .toList();
  }

  double get _totalQty => _items.fold(0, (s, i) => s + i.quantity);
  double get _totalValue => _items.fold(0, (s, i) => s + i.value);

  String _num(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  String get _stamp => DateFormat('dd-MM-yyyy_HH-mm').format(DateTime.now());

  List<String> _cells(_TransferItem i) => [
        i.date, i.time, i.product, i.direction, i.otherShop, _num(i.quantity), _num(i.value), i.user,
      ];

  Future<void> _exportPdf() async {
    final items = _items;
    if (items.isEmpty) return;
    final doc = pw.Document();
    final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(20),
      header: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('Transferred Products', style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 16)),
        pw.SizedBox(height: 2),
        pw.Text('${ref.read(shopNameProvider).valueOrNull ?? 'My Shop'}  •  $now',
            style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9, color: PdfColors.grey600)),
        pw.Divider(),
      ]),
      build: (_) => [
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 7, color: PdfColors.white),
          cellStyle: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 7),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey400),
          headers: _headers,
          data: [
            ...items.map(_cells),
            ['', '', 'TOTAL', '', '', _num(_totalQty), _num(_totalValue), ''],
          ],
        ),
      ],
    ));
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/Transfers_$_stamp.pdf';
    await File(path).writeAsBytes(await doc.save(), flush: true);
    await OpenFile.open(path);
  }

  Future<void> _exportExcel() async {
    final items = _items;
    if (items.isEmpty) return;
    final excel = xls.Excel.createExcel();
    excel.rename(excel.getDefaultSheet()!, 'Transfers');
    final sheet = excel['Transfers'];
    sheet.appendRow(_headers.map((h) => xls.TextCellValue(h)).toList());
    for (final i in items) {
      sheet.appendRow([
        xls.TextCellValue(i.date), xls.TextCellValue(i.time), xls.TextCellValue(i.product),
        xls.TextCellValue(i.direction), xls.TextCellValue(i.otherShop),
        xls.DoubleCellValue(i.quantity), xls.DoubleCellValue(i.value), xls.TextCellValue(i.user),
      ]);
    }
    final bytes = excel.save();
    if (bytes == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Transfers_$_stamp.xlsx');
    await file.writeAsBytes(bytes, flush: true);
    await OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FilterState>(filterProvider, (_, __) => _load());
    final items = _items;
    final filter = ref.watch(filterProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        ),
        title: Text('Transferred Products',
            style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Container(
                color: AppColors.card,
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 10),
                child: Row(children: [
                  const Icon(Icons.storefront_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${ref.read(shopNameProvider).valueOrNull ?? 'My Shop'}  •  ${filter.from} → ${filter.to}',
                      style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ),
              Container(
                color: AppColors.card,
                padding: const EdgeInsets.fromLTRB(AppConstants.paddingLG, 0, AppConstants.paddingLG, 10),
                child: Row(children: [
                  _action(Icons.picture_as_pdf_rounded, 'PDF', AppColors.danger, _exportPdf),
                  const SizedBox(width: 8),
                  _action(Icons.table_chart_rounded, 'Excel', AppColors.success, _exportExcel),
                  const SizedBox(width: 8),
                  _action(Icons.filter_list_rounded, 'Filter', AppColors.primary, () => AppFilterDialog.show(context)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppConstants.paddingLG, 12, AppConstants.paddingLG, 12),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search product or shop...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    filled: true,
                    fillColor: AppColors.card,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
                      borderSide: const BorderSide(color: AppColors.inputBorder),
                    ),
                  ),
                ),
              ),
              if (_loading)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
              else if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(children: [
                    Icon(Icons.swap_horiz_rounded, size: 56, color: AppColors.textHint.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text('No transfers found', style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary)),
                  ]),
                )
              else
                _table(items),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(IconData icon, String label, Color color, VoidCallback onTap) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: AppTypography.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      );

  Widget _row(List<String> cells, {Color? bg, TextStyle? style, List<Color?>? colors}) => Container(
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          for (var c = 0; c < cells.length; c++)
            SizedBox(
              width: _widths[c],
              child: Text(
                cells[c],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (style ?? AppTypography.caption.copyWith(fontSize: 11, color: AppColors.textPrimary))
                    .copyWith(color: colors?[c]),
              ),
            ),
        ]),
      );

  Widget _table(List<_TransferItem> items) {
    final bold = AppTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _row(_headers, bg: AppColors.primary, style: bold.copyWith(color: AppColors.textWhite)),
          for (var k = 0; k < items.length; k++)
            _row(
              _cells(items[k]),
              bg: k.isEven ? AppColors.card : AppColors.background,
              colors: [
                null, null, null,
                items[k].direction == 'Out' ? AppColors.danger : AppColors.success,
                null, null, null, null,
              ],
            ),
          _row(['', '', 'TOTAL', '', '', _num(_totalQty), _num(_totalValue), ''],
              bg: AppColors.primary.withValues(alpha: 0.06), style: bold.copyWith(color: AppColors.primary)),
        ]),
      ),
    );
  }
}
