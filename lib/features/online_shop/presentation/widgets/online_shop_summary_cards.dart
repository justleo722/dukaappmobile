import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

class OnlineShopSummaryCards extends StatelessWidget {
  const OnlineShopSummaryCards({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
        itemCount: _cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final card = _cards[index];
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

  static const List<Map<String, dynamic>> _cards = [
    {
      'title': 'Online Shop\nRevenue',
      'value': 'Tsh 0',
      'icon': Icons.attach_money_rounded,
      'color': Color(0xFF22C55E),
      'bgColor': Color(0xFFE8FAF0),
    },
    {
      'title': 'Online Shop\nProducts',
      'value': '0',
      'icon': Icons.inventory_2_rounded,
      'color': Color(0xFF14B8A6),
      'bgColor': Color(0xFFE0FFF9),
    },
    {
      'title': 'Online\nOrders',
      'value': '0',
      'icon': Icons.shopping_bag_rounded,
      'color': Color(0xFFFF7A00),
      'bgColor': Color(0xFFFFF0E0),
    },
    {
      'title': 'Online\nCustomers',
      'value': '0',
      'icon': Icons.people_rounded,
      'color': Color(0xFF9333EA),
      'bgColor': Color(0xFFF3E8FF),
    },
  ];
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
