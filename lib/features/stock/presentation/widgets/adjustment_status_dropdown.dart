import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

enum AdjustmentStatus {
  none,
  balancing,
  bad,
  expired,
  lost,
}

class AdjustmentStatusDropdown extends StatelessWidget {
  final AdjustmentStatus status;
  final ValueChanged<AdjustmentStatus?> onChanged;

  const AdjustmentStatusDropdown({
    super.key,
    required this.status,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'Status',
              style: AppTypography.captionBold.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<AdjustmentStatus>(
          initialValue: status,
          isExpanded: true,
          hint: Text(
            'Select status',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textHint,
          ),
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.card,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
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
              borderSide: const BorderSide(
                color: AppColors.inputFocusBorder,
                width: 1.5,
              ),
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: AdjustmentStatus.none,
              child: Text('N/A'),
            ),
            DropdownMenuItem(
              value: AdjustmentStatus.balancing,
              child: Text('Balancing'),
            ),
            DropdownMenuItem(
              value: AdjustmentStatus.bad,
              child: Text('Bad'),
            ),
            DropdownMenuItem(
              value: AdjustmentStatus.expired,
              child: Text('Expired'),
            ),
            DropdownMenuItem(
              value: AdjustmentStatus.lost,
              child: Text('Lost'),
            ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    if (status == AdjustmentStatus.none) return const SizedBox.shrink();

    final (label, color) = _getStatusInfo();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  (String, Color) _getStatusInfo() {
    switch (status) {
      case AdjustmentStatus.balancing:
        return ('Balancing', AppColors.primary);
      case AdjustmentStatus.bad:
        return ('Bad', AppColors.secondary);
      case AdjustmentStatus.expired:
        return ('Expired', AppColors.danger);
      case AdjustmentStatus.lost:
        return ('Lost', AppColors.textSecondary);
      case AdjustmentStatus.none:
        return ('', AppColors.textSecondary);
    }
  }
}
