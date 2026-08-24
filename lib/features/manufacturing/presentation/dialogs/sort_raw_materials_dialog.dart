import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

enum SortField { status, name, stock, unitCost, totalValue }
enum SortOrder { asc, desc }

class SortRawMaterialsDialog extends StatefulWidget {
  final SortField selectedField;
  final SortOrder selectedOrder;
  final String selectedStatusLabel;
  final ValueChanged<SortField> onFieldChanged;
  final ValueChanged<SortOrder> onOrderChanged;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onApply;

  const SortRawMaterialsDialog({
    super.key,
    required this.selectedField,
    required this.selectedOrder,
    required this.selectedStatusLabel,
    required this.onFieldChanged,
    required this.onOrderChanged,
    required this.onStatusChanged,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required SortField selectedField,
    required SortOrder selectedOrder,
    required String selectedStatusLabel,
    required ValueChanged<SortField> onFieldChanged,
    required ValueChanged<SortOrder> onOrderChanged,
    required ValueChanged<String> onStatusChanged,
    required VoidCallback onApply,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: AppColors.overlay,
      builder: (_) => SortRawMaterialsDialog(
        selectedField: selectedField,
        selectedOrder: selectedOrder,
        selectedStatusLabel: selectedStatusLabel,
        onFieldChanged: onFieldChanged,
        onOrderChanged: onOrderChanged,
        onStatusChanged: onStatusChanged,
        onApply: onApply,
      ),
    );
  }

  @override
  State<SortRawMaterialsDialog> createState() => _SortRawMaterialsDialogState();
}

class _SortRawMaterialsDialogState extends State<SortRawMaterialsDialog> {
  late SortField _field;
  late SortOrder _order;

  @override
  void initState() {
    super.initState();
    _field = widget.selectedField;
    _order = widget.selectedOrder;
    _selectedStatusLabel = widget.selectedStatusLabel;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusXL)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingXL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildSortSection('Status', [
                    _sortOption('All', SortField.status, SortOrder.asc),
                    _sortOption('In Stock', SortField.status, SortOrder.asc),
                    _sortOption('Running Low', SortField.status, SortOrder.asc),
                    _sortOption('Out of Stock', SortField.status, SortOrder.asc),
                    _sortOption('Expired', SortField.status, SortOrder.asc),
                  ]),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text('Sort Raw Materials', style: AppTypography.h5.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 24),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildSortSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.label.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }

  Widget _sortOption(String label, SortField field, SortOrder order) {
    final isSelected = _field == field && _getStatusLabel() == label;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
        child: InkWell(
          onTap: () => setState(() { _field = field; _order = order; _selectedStatusLabel = label; widget.onStatusChanged(label); }),
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: 1.5),
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? AppColors.primary : AppColors.textHint,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(label, style: AppTypography.bodyMedium.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _selectedStatusLabel = 'All';

  String _getStatusLabel() => _selectedStatusLabel;

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: AppConstants.buttonHeight,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
              ),
              child: Text('Cancel', style: AppTypography.buttonLarge.copyWith(color: AppColors.textSecondary)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: AppConstants.buttonHeight,
            child: ElevatedButton(
              onPressed: () {
                widget.onFieldChanged(_field);
                widget.onOrderChanged(_order);
                widget.onApply();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
              ),
              child: Text('Apply Sort', style: AppTypography.buttonLarge),
            ),
          ),
        ),
      ],
    );
  }
}
