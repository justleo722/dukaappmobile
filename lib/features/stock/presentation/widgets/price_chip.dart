import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';

enum PriceType { bp, sp, wp }

class PriceChip extends StatelessWidget {
  final PriceType type;
  final double price;

  const PriceChip({
    super.key,
    required this.type,
    required this.price,
  });

  String get _label {
    switch (type) {
      case PriceType.bp:
        return 'BP';
      case PriceType.sp:
        return 'SP';
      case PriceType.wp:
        return 'WP';
    }
  }

  Color get _backgroundColor {
    switch (type) {
      case PriceType.bp:
        return AppColors.primary.withValues(alpha: 0.08);
      case PriceType.sp:
        return AppColors.success.withValues(alpha: 0.08);
      case PriceType.wp:
        return AppColors.secondary.withValues(alpha: 0.08);
    }
  }

  Color get _labelColor {
    switch (type) {
      case PriceType.bp:
        return AppColors.primary;
      case PriceType.sp:
        return AppColors.success;
      case PriceType.wp:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _label,
            style: AppTypography.caption.copyWith(
              color: _labelColor,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            price.toStringAsFixed(0),
            style: AppTypography.bodySmall.copyWith(
              color: _labelColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
