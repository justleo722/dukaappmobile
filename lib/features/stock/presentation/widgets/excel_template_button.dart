import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/app/typography.dart';

class ExcelTemplateButton extends StatelessWidget {
  final VoidCallback? onDownload;

  const ExcelTemplateButton({super.key, this.onDownload});

  static const String _fileName = 'StockTemplate.xlsx';
  static const _channel = MethodChannel('com.example.dukaapp/downloads');

  Uint8List _generateTemplate() {
    final excel = Excel.createExcel();
    final sheet = excel['Stock Template'];
    excel.setDefaultSheet('Stock Template');

    final headers = [
      'Product Name',
      'Quantity',
      'Buying Price',
      'Selling Price',
      'Wholesale Price',
      'Reorder Level',
      'Barcode',
      'Expiry Date',
      'Unit',
    ];

    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = TextCellValue(headers[i])
        ..cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#FF4CAF50'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFFFF'),
        );
    }

    final sampleRows = [
      ['Rice 1kg', '50', '300', '400', '380', '10', '', '', 'kg'],
      ['Cooking Oil 1L', '30', '250', '350', '320', '5', '', '', 'litre'],
      ['Sugar 1kg', '40', '200', '280', '260', '8', '', '', 'kg'],
    ];

    for (var r = 0; r < sampleRows.length; r++) {
      for (var c = 0; c < sampleRows[r].length; c++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
            .value = TextCellValue(sampleRows[r][c]);
      }
    }

    final fileBytes = excel.save();
    if (fileBytes == null) return Uint8List(0);
    return Uint8List.fromList(fileBytes);
  }

  Future<void> _downloadTemplate(BuildContext context) async {
    try {
      final bytes = _generateTemplate();

      if (Platform.isAndroid) {
        await _channel.invokeMethod('saveToDownloads', {
          'fileName': _fileName,
          'bytes': bytes,
        });
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$_fileName');
        await file.writeAsBytes(bytes, flush: true);
      }

      onDownload?.call();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Template saved to Downloads folder.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textWhite,
              ),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Template download error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to download template. $e',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textWhite,
              ),
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppConstants.buttonHeight,
      child: OutlinedButton.icon(
        onPressed: () => _downloadTemplate(context),
        icon: const Icon(Icons.download_rounded, size: 20),
        label: Text(
          'Download Excel Template',
          style: AppTypography.buttonLarge.copyWith(color: AppColors.primary),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          ),
        ),
      ),
    );
  }
}
