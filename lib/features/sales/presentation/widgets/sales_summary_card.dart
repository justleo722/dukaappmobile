import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';

class SalesSummaryCard extends StatelessWidget {
  final String totalSales;
  final String totalCredits;
  final int totalOrders;
  final String profit;

  const SalesSummaryCard({
    super.key,
    required this.totalSales,
    required this.totalCredits,
    required this.totalOrders,
    required this.profit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _SummaryItem(
            icon: Icons.account_balance_wallet_rounded,
            iconColor: AppColors.primary,
            iconBg: AppColors.primary.withValues(alpha: 0.1),
            label: 'Total Sales',
            value: totalSales,
          ),
          const SizedBox(width: 12),
          _SummaryItem(
            icon: Icons.credit_score_rounded,
            iconColor: AppColors.secondary,
            iconBg: AppColors.secondary.withValues(alpha: 0.1),
            label: 'Total Credits',
            value: totalCredits,
          ),
          const SizedBox(width: 12),
          _SummaryItem(
            icon: Icons.shopping_bag_rounded,
            iconColor: AppColors.success,
            iconBg: AppColors.success.withValues(alpha: 0.1),
            label: 'Total Orders',
            value: '$totalOrders',
          ),
          const SizedBox(width: 12),
          _SummaryItem(
            icon: Icons.trending_up_rounded,
            iconColor: const Color(0xFF8B5CF6),
            iconBg: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
            label: 'Profit',
            value: profit,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;

  const _SummaryItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
