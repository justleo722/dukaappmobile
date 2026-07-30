import 'package:flutter/material.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

class StockStatusChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const StockStatusChip({
    super.key,
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
    required this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.shortAnimation,
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: AppTypography.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
