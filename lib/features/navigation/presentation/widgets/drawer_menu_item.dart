import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';

class DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool showExpandIcon;

  const DrawerMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.showExpandIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.danger : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Icon(
          icon,
          color: color,
          size: 22,
        ),
        title: Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: showExpandIcon
            ? Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
                size: 20,
              )
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        hoverColor: isDestructive
            ? AppColors.dangerLight.withValues(alpha: 0.3)
            : AppColors.primary.withValues(alpha: 0.05),
      ),
    );
  }
}
