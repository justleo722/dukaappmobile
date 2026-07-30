import 'package:flutter/material.dart';
import 'package:dukaapp/features/stock/presentation/widgets/stock_category_card.dart';

class StockCategoriesGrid extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final ValueChanged<String>? onCategoryTap;

  const StockCategoriesGrid({
    super.key,
    required this.products,
    this.onCategoryTap,
  });

  List<Map<String, dynamic>> get _categories {
    final Map<String, int> categoryCount = {};
    for (final product in products) {
      final category = product['category'] as String;
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }

    final List<Map<String, dynamic>> categories = [];
    final entries = categoryCount.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in entries) {
      categories.add({
        'name': entry.key,
        'count': entry.value,
        'icon': _getCategoryIcon(entry.key),
        'color': _getCategoryColor(entry.key),
        'bgColor': _getCategoryBgColor(entry.key),
      });
    }

    return categories;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Cosmetics':
        return Icons.face_rounded;
      case 'Accessories':
        return Icons.headphones_rounded;
      case 'Electronics':
        return Icons.devices_rounded;
      case 'Household':
        return Icons.home_rounded;
      case 'Beauty':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Cosmetics':
        return const Color(0xFFEC4899);
      case 'Accessories':
        return const Color(0xFF3B82F6);
      case 'Electronics':
        return const Color(0xFF22C55E);
      case 'Household':
        return const Color(0xFFFF7A00);
      case 'Beauty':
        return const Color(0xFF9333EA);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _getCategoryBgColor(String category) {
    switch (category) {
      case 'Cosmetics':
        return const Color(0xFFFCE8F3);
      case 'Accessories':
        return const Color(0xFFEBF2FF);
      case 'Electronics':
        return const Color(0xFFE8FAF0);
      case 'Household':
        return const Color(0xFFFFF0E0);
      case 'Beauty':
        return const Color(0xFFF3E8FF);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 3 : 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: categories.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final category = categories[index];
        return StockCategoryCard(
          categoryName: category['name'],
          productCount: category['count'],
          icon: category['icon'],
          color: category['color'],
          bgColor: category['bgColor'],
          onTap: () => onCategoryTap?.call(category['name']),
        );
      },
    );
  }
}
