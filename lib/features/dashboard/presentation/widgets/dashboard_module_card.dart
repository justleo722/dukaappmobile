import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/features/dashboard/presentation/constants/dashboard_constants.dart';

class DashboardModuleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback? onTap;
  // Expired subscription: the card stays white and only its content fades.
  final bool locked;

  const DashboardModuleCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      DashboardConstants.moduleIconRadius + 6,
    );
    // The shadow sits on a white box under the card. Flutter paints a BoxShadow
    // as a full blurred shape, so on an unfilled box it greyed the whole card.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        boxShadow: [DashboardConstants.cardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Opacity(
              opacity: locked ? 0.6 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: DashboardConstants.moduleIconSize,
                        height: DashboardConstants.moduleIconSize,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(
                            DashboardConstants.moduleIconRadius,
                          ),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.textHint,
                        size: 14,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: AppTypography.caption.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
