import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/features/stock/presentation/widgets/category_dropdown.dart';
import 'package:dukaapp/features/stock/presentation/widgets/excel_template_button.dart';
import 'package:dukaapp/features/stock/presentation/widgets/upload_card.dart';
import 'package:dukaapp/features/stock/presentation/pages/import_preview_page.dart';

class ImportStockPage extends StatefulWidget {
  const ImportStockPage({super.key});

  @override
  State<ImportStockPage> createState() => _ImportStockPageState();
}

class _ImportStockPageState extends State<ImportStockPage> {
  String? _selectedCategory;
  String? _selectedFileName;
  Uint8List? _fileBytes;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final ext = file.name.split('.').last.toLowerCase();
        if (!['xlsx', 'csv'].contains(ext)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Only .xlsx and .csv files are supported.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite),
                ),
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                ),
              ),
            );
          }
          return;
        }

        Uint8List? bytes = file.bytes;
        if (bytes == null && file.path != null) {
          bytes = await File(file.path!).readAsBytes();
        }

        setState(() {
          _selectedFileName = file.name;
          _fileBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to pick file.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textWhite,
              ),
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
          ),
        );
      }
    }
  }

  void _onPreviewFile() {
    if (_fileBytes == null || _selectedFileName == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImportPreviewPage(
          fileBytes: _fileBytes!,
          fileName: _selectedFileName!,
        ),
      ),
    );
  }

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
        title: Text(
          'Import Stock Items',
          style: AppTypography.h6.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ExcelTemplateButton(),
                  const SizedBox(height: 24),
                  CategoryDropdown(
                    value: _selectedCategory,
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                  const SizedBox(height: 24),
                  UploadCard(
                    fileName: _selectedFileName,
                    onBrowse: _pickFile,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: AppConstants.paddingLG,
              right: AppConstants.paddingLG,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: AppColors.card,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: AppConstants.buttonHeight,
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(
                          color: AppColors.border,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusLG,
                          ),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTypography.buttonLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: AppConstants.buttonHeight,
                    child: ElevatedButton(
                      onPressed: _fileBytes != null ? _onPreviewFile : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textWhite,
                        disabledBackgroundColor: AppColors.primary.withAlpha(128),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusLG,
                          ),
                        ),
                      ),
                      child: Text(
                        'Preview File',
                        style: AppTypography.buttonLarge,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
