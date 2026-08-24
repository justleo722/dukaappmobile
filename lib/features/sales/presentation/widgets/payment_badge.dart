import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';

enum PaymentType { cash, credit, pending }

class PaymentBadge extends StatelessWidget {
  final PaymentType type;

  const PaymentBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final (Color bgColor, Color textColor, String label) = switch (type) {
      PaymentType.cash => (
        AppColors.success.withValues(alpha: 0.1),
        AppColors.success,
        'Cash',
      ),
      PaymentType.credit => (
        AppColors.secondary.withValues(alpha: 0.1),
        AppColors.secondary,
        'Credit',
      ),
      PaymentType.pending => (
        AppColors.textHint.withValues(alpha: 0.15),
        AppColors.textSecondary,
        'Pending',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
