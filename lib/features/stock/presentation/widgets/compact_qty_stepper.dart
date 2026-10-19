import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';

/// Slim, premium inline quantity stepper used on compact catalog rows.
///
/// [qty] is the currently selected quantity. When [qty] is 0 the minus button
/// is disabled and the stepper renders in its "inactive" state; pressing
/// [onRemove] at qty 1 deselects the product (the owning page keeps the item
/// around with quantity 0 so its controllers survive).
class CompactQtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const CompactQtyStepper({
    super.key,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final active = qty > 0;
    return Container(
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.background,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: active
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(
            icon: Icons.remove_rounded,
            color: active ? AppColors.primary : AppColors.textHint,
            onTap: active ? onRemove : null,
          ),
          SizedBox(
            width: 26,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: AppTypography.captionBold.copyWith(
                color: active ? AppColors.textPrimary : AppColors.textHint,
                fontSize: 13,
              ),
            ),
          ),
          _StepBtn(
            icon: Icons.add_rounded,
            color: AppColors.primary,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StepBtn({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        child: Icon(icon, size: 18, color: enabled ? color : AppColors.textHint),
      ),
    );
  }
}
