import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:excel/excel.dart' as xls;
import 'package:csv/csv.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/features/stock/presentation/widgets/import_status_chip.dart';
import 'package:dukaapp/features/stock/presentation/widgets/sticky_import_buttons.dart';

class ImportPreviewPage extends StatefulWidget {
  final Uint8List fileBytes;
  final String fileName;

  const ImportPreviewPage({
    super.key,
    required this.fileBytes,
    required this.fileName,
  });

  @override
  State<ImportPreviewPage> createState() => _ImportPreviewPageState();
}

class _ImportPreviewPageState extends State<ImportPreviewPage> {
  String _searchQuery = '';
  List<Map<String, dynamic>> _products = [];
  List<String> _headers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _parseFile();
  }

  void _parseFile() {
    try {
      final name = widget.fileName.toLowerCase();
      if (name.endsWith('.csv')) {
        _parseCsv();
      } else if (name.endsWith('.xlsx')) {
        _parseExcel();
      } else {
        setState(() {
          _error = 'Unsupported file format.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to parse file: $e';
        _isLoading = false;
      });
    }
  }

  void _parseCsv() {
    final content = String.fromCharCodes(widget.fileBytes);
    final rows = const CsvToListConverter().convert(content);

    if (rows.isEmpty) {
      _error = 'File is empty.';
      return;
    }

    _headers = rows.first.map((e) => e.toString().trim()).toList();
    _products = [];

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((cell) => cell == null || cell.toString().trim().isEmpty)) {
        continue;
      }
      final product = _mapRowToProduct(row, i);
      _products.add(product);
    }
  }

  void _parseExcel() {
    final excel = xls.Excel.decodeBytes(widget.fileBytes);

    if (excel.tables.isEmpty) {
      _error = 'No sheets found in the file.';
      return;
    }

    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName]!;

    if (sheet.rows.isEmpty) {
      _error = 'Sheet is empty.';
      return;
    }

    _headers = sheet.rows.first
        .map((cell) => (cell?.value?.toString() ?? '').trim())
        .toList();
    _products = [];

    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final values = row.map((cell) => cell?.value).toList();
      if (values.every((v) => v == null || v.toString().trim().isEmpty)) {
        continue;
      }
      final product = _mapRowToProduct(values, i);
      _products.add(product);
    }
  }

  Map<String, dynamic> _mapRowToProduct(List<dynamic> row, int index) {
    String cellValue(int col) {
      if (col >= row.length) return '';
      final v = row[col];
      if (v == null) return '';
      return v.toString().trim();
    }

    int? parseInt(String s) {
      if (s.isEmpty) return null;
      return int.tryParse(s.replaceAll(RegExp(r'[^0-9-]'), ''));
    }

    double? parseDouble(String s) {
      if (s.isEmpty) return null;
      return double.tryParse(s.replaceAll(RegExp(r'[^0-9.]'), ''));
    }

    final name = cellValue(_findColumn('name', ['product name', 'name', 'item', 'product', 'item name', 'description']));
    final qty = parseInt(cellValue(_findColumn('quantity', ['quantity', 'qty', 'stock', 'count'])));
    final buying = parseDouble(cellValue(_findColumn('buying', ['buying price', 'buy price', 'cost', 'cost price', 'purchase price'])));
    final selling = parseDouble(cellValue(_findColumn('selling', ['selling price', 'sell price', 'price', 'retail price', 'retail'])));
    final wholesale = parseDouble(cellValue(_findColumn('wholesale', ['wholesale price', 'wholesale', 'bulk price'])));
    final reorder = parseInt(cellValue(_findColumn('reorder', ['reorder level', 'reorder', 'min stock', 'minimum'])));
    final barcode = cellValue(_findColumn('barcode', ['barcode', 'bar code', 'upc', 'ean', 'sku']));
    final expiry = cellValue(_findColumn('expiry', ['expiry date', 'expiry', 'exp date', 'expiration']));
    final unit = cellValue(_findColumn('unit', ['unit', 'uom', 'measure']));

    final displayRow = <String, String>{};
    for (var c = 0; c < _headers.length && c < row.length; c++) {
      displayRow[_headers[c]] = cellValue(c);
    }

    final isValid = name.isNotEmpty;

    return {
      'row': index,
      'name': name.isNotEmpty ? name : 'Row $index',
      'quantity': qty ?? 0,
      'buyingPrice': buying ?? 0,
      'sellingPrice': selling ?? 0,
      'wholesalePrice': wholesale,
      'reorderLevel': reorder ?? 0,
      'barcode': barcode,
      'expiryDate': expiry,
      'unit': unit.isNotEmpty ? unit : null,
      'isValid': isValid,
      'validationMessage': isValid ? null : 'Product name is missing.',
      'rawData': displayRow,
    };
  }

  int _findColumn(String key, List<String> aliases) {
    for (var i = 0; i < _headers.length; i++) {
      final h = _headers[i].toLowerCase();
      if (aliases.any((a) => h == a || h.contains(a))) return i;
    }
    return -1;
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products
        .where(
          (p) => (p['name'] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  int get _readyCount => _products.where((p) => p['isValid'] == true).length;
  int get _invalidCount =>
      _products.where((p) => p['isValid'] == false).length;
  int get _skippedCount => 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
            size: 24,
          ),
        ),
        title: Column(
          children: [
            Text(
              'Import Preview',
              style: AppTypography.h6.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              widget.fileName,
              style: AppTypography.caption.copyWith(fontSize: 11),
              overflow: TextOverflow.ellipsis,
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : Column(
                  children: [
                    _buildSummaryBar(),
                    _buildSearchField(),
                    Expanded(
                      child: _filteredProducts.isEmpty
                          ? _buildEmptyState()
                          : _buildProductList(),
                    ),
                    StickyImportButtons(
                      onChangeFile: () => context.pop(),
                      onCancel: () => context.pop(),
                      onSave: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${_readyCount} products imported successfully.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textWhite,
                              ),
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusSM,
                              ),
                            ),
                          ),
                        );
                        context.pop();
                      },
                    ),
                  ],
                ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLG,
        vertical: 12,
      ),
      color: AppColors.card,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ImportStatusChip(
            type: ImportStatusType.rows,
            count: _products.length,
          ),
          ImportStatusChip(type: ImportStatusType.ready, count: _readyCount),
          ImportStatusChip(
            type: ImportStatusType.invalid,
            count: _invalidCount,
          ),
          ImportStatusChip(
            type: ImportStatusType.skipped,
            count: _skippedCount,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingLG,
        12,
        AppConstants.paddingLG,
        4,
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: AppTypography.bodyMedium,
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          hintText: 'Search imported products',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textHint,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textHint,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () => setState(() => _searchQuery = ''),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                )
              : null,
          filled: true,
          fillColor: AppColors.card,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
            borderSide: const BorderSide(
              color: AppColors.inputFocusBorder,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingLG,
        12,
        AppConstants.paddingLG,
        8,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final rawData = product['rawData'] as Map<String, String>?;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${product['row']}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        product['name'] as String,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (product['isValid'] as bool)
                            ? AppColors.success.withAlpha(20)
                            : AppColors.danger.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        (product['isValid'] as bool) ? 'READY' : 'INVALID',
                        style: AppTypography.labelSmall.copyWith(
                          color: (product['isValid'] as bool)
                              ? AppColors.success
                              : AppColors.danger,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (product['validationMessage'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight.withAlpha(60),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 14,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            product['validationMessage'] as String,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (rawData != null && rawData.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: rawData.entries
                        .where((e) => e.value.isNotEmpty)
                        .map(
                          (e) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${e.key}: ${e.value}',
                              style: AppTypography.caption.copyWith(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.textHint.withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different search term',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.danger.withAlpha(150),
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: AppTypography.h6.copyWith(color: AppColors.danger),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
