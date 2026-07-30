import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';

class StockBadge extends StatelessWidget {
  final int stock;

  const StockBadge({
    super.key,
    required this.stock,
  });

  bool get _isLow => stock <= 5;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _isLow
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_rounded,
            size: 12,
            color: _isLow ? AppColors.primary : AppColors.success,
          ),
          const SizedBox(width: 4),
          Text(
            'Stock: $stock',
            style: AppTypography.caption.copyWith(
              color: _isLow ? AppColors.primary : AppColors.success,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
