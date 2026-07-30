import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

class ExpiryPicker extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateSelected;

  const ExpiryPicker({
    super.key,
    required this.label,
    this.selectedDate,
    required this.onDateSelected,
  });

  String get _displayDate {
    if (selectedDate == null) return 'Select date';
    final d = selectedDate!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.captionBold.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _pickDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _displayDate,
                    style: AppTypography.bodyMedium.copyWith(
                      color: selectedDate != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
