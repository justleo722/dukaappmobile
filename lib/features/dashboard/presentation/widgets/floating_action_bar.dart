import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/features/dashboard/presentation/constants/dashboard_constants.dart';

class FloatingActionBar extends StatelessWidget {
  const FloatingActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: DashboardConstants.fabHeight,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DashboardConstants.fabRadius),
        boxShadow: [DashboardConstants.fabShadow],
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.add_shopping_cart_rounded,
              label: 'Add Sale',
              color: AppColors.secondary,
              onTap: () {},
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: AppColors.border,
          ),
          Expanded(
            child: _ActionButton(
              icon: Icons.inventory_2_rounded,
              label: 'Re-Stock',
              color: AppColors.secondary,
              onTap: () {},
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: AppColors.border,
          ),
          Expanded(
            child: _ActionButton(
              icon: Icons.receipt_long_rounded,
              label: 'Order',
              color: AppColors.secondary,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DashboardConstants.fabRadius),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
