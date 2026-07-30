import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';

class AvailableStockBadge extends StatelessWidget {
  final int stock;

  const AvailableStockBadge({
    super.key,
    required this.stock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_rounded,
            size: 13,
            color: AppColors.primary,
          ),
          const SizedBox(width: 5),
          Text(
            'Available: $stock',
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
