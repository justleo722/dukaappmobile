import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/features/navigation/presentation/widgets/shop_list_tile.dart';

class ShopSelectorBottomSheet extends StatelessWidget {
  final List<Map<String, dynamic>> shops;
  final String activeShopId;
  final ValueChanged<Map<String, dynamic>> onShopSelected;

  const ShopSelectorBottomSheet({
    super.key,
    required this.shops,
    required this.activeShopId,
    required this.onShopSelected,
  });

  static void show({
    required BuildContext context,
    required List<Map<String, dynamic>> shops,
    required String activeShopId,
    required ValueChanged<Map<String, dynamic>> onShopSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShopSelectorBottomSheet(
        shops: shops,
        activeShopId: activeShopId,
        onShopSelected: onShopSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Switch Shop',
                        style: AppTypography.h5.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select an active shop',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(
            color: AppColors.divider,
            height: 1,
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: shops.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final shop = shops[index];
                final isActive = shop['id'] == activeShopId;
                return ShopListTile(
                  shopName: shop['name'],
                  shopId: shop['id'],
                  isActive: isActive,
                  onTap: () {
                    onShopSelected(shop);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          SizedBox(height: bottomPadding + 8),
        ],
      ),
    );
  }
}
