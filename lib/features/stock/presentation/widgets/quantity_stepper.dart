import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

class QuantityStepper extends StatelessWidget {
  final int value;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onChanged;

  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.minValue = 0,
    this.maxValue = 9999,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildButton(
          icon: Icons.remove_rounded,
          onTap: value > minValue ? () => onChanged(value - 1) : null,
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 48,
          child: Text(
            '$value',
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 12),
        _buildButton(
          icon: Icons.add_rounded,
          onTap: value < maxValue ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }

  Widget _buildButton({required IconData icon, VoidCallback? onTap}) {
    final enabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.shortAnimation,
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
            width: 1.2,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.primary : AppColors.textHint,
        ),
      ),
    );
  }
}
