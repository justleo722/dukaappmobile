import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';

enum ImportStatusType { ready, invalid, skipped, rows }

class ImportStatusChip extends StatelessWidget {
  final ImportStatusType type;
  final int count;

  const ImportStatusChip({super.key, required this.type, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: AppTypography.labelSmall.copyWith(
              color: _textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _label,
            style: AppTypography.caption.copyWith(
              color: _textColor,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String get _label {
    switch (type) {
      case ImportStatusType.ready:
        return 'Ready';
      case ImportStatusType.invalid:
        return 'Invalid';
      case ImportStatusType.skipped:
        return 'Skipped';
      case ImportStatusType.rows:
        return 'Rows';
    }
  }

  Color get _backgroundColor {
    switch (type) {
      case ImportStatusType.ready:
        return AppColors.success.withAlpha(20);
      case ImportStatusType.invalid:
        return AppColors.danger.withAlpha(20);
      case ImportStatusType.skipped:
        return AppColors.border;
      case ImportStatusType.rows:
        return AppColors.primary.withAlpha(20);
    }
  }

  Color get _textColor {
    switch (type) {
      case ImportStatusType.ready:
        return AppColors.success;
      case ImportStatusType.invalid:
        return AppColors.danger;
      case ImportStatusType.skipped:
        return AppColors.textSecondary;
      case ImportStatusType.rows:
        return AppColors.primary;
    }
  }
}
