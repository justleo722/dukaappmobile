import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

class OnlineShopSummaryCards extends StatelessWidget {
  final String revenue;
  final String productCount;
  final String orderCount;
  final String customerCount;

  const OnlineShopSummaryCards({
    super.key,
    this.revenue = 'Tsh 0',
    this.productCount = '0',
    this.orderCount = '0',
    this.customerCount = '0',
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      {
        'title': 'Online Shop\nRevenue',
        'value': revenue,
        'icon': Icons.attach_money_rounded,
        'color': const Color(0xFF22C55E),
        'bgColor': const Color(0xFFE8FAF0),
      },
      {
        'title': 'Online Shop\nProducts',
        'value': productCount,
        'icon': Icons.inventory_2_rounded,
        'color': const Color(0xFF14B8A6),
        'bgColor': const Color(0xFFE0FFF9),
      },
      {
        'title': 'Online\nOrders',
        'value': orderCount,
        'icon': Icons.shopping_bag_rounded,
        'color': const Color(0xFFFF7A00),
        'bgColor': const Color(0xFFFFF0E0),
      },
      {
        'title': 'Online\nCustomers',
        'value': customerCount,
        'icon': Icons.people_rounded,
        'color': const Color(0xFF9333EA),
        'bgColor': const Color(0xFFF3E8FF),
      },
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final card = cards[index];
          return _SummaryCard(
            title: card['title'] as String,
            value: card['value'] as String,
            icon: card['icon'] as IconData,
            color: card['color'] as Color,
            bgColor: card['bgColor'] as Color,
          );
        },
      ),
    );
  }

}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: AppTypography.h6.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: AppTypography.caption.copyWith(fontSize: 10),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
