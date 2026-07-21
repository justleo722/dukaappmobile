import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/features/navigation/presentation/widgets/drawer_header.dart';
import 'package:dukaapp/features/navigation/presentation/widgets/drawer_menu_item.dart';
import 'package:dukaapp/features/navigation/presentation/widgets/shop_selector_bottom_sheet.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _activeShopId = 'S0003';

  final List<Map<String, dynamic>> _shops = const [
    {'id': 'S0021', 'name': 'ABC MARKET'},
    {'id': 'S0019', 'name': 'ASU COSMETICS'},
    {'id': 'S0018', 'name': 'BLACK MAGIC DESIGN'},
    {'id': 'S0020', 'name': 'JOHN PERFORMS'},
    {'id': 'S0003', 'name': 'SON COLLECTION'},
  ];

  String get _activeShopName {
    final shop = _shops.firstWhere(
      (s) => s['id'] == _activeShopId,
      orElse: () => _shops.last,
    );
    return shop['name'];
  }

  void _onShopSelected(Map<String, dynamic> shop) {
    setState(() {
      _activeShopId = shop['id'];
    });
  }

  void _openShopSelector() {
    ShopSelectorBottomSheet.show(
      context: context,
      shops: _shops,
      activeShopId: _activeShopId,
      onShopSelected: _onShopSelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth * 0.78;

    return Drawer(
      width: drawerWidth,
      backgroundColor: AppColors.card,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppDrawerHeader(
              userName: 'SON',
              userId: 'U0003',
              shopName: _activeShopName,
              activeShopId: _activeShopId,
              onEditProfile: () {},
              onSwitchShop: _openShopSelector,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(
                color: AppColors.divider,
                height: 1,
              ),
            ),
            const SizedBox(height: 8),
            DrawerMenuItem(
              icon: Icons.home_rounded,
              label: 'Dashboard',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            DrawerMenuItem(
              icon: Icons.add_rounded,
              label: 'Add Shop',
              onTap: () {
                Navigator.pop(context);
              },
              showExpandIcon: true,
            ),
            DrawerMenuItem(
              icon: Icons.settings_rounded,
              label: 'Shop Settings',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            DrawerMenuItem(
              icon: Icons.book_rounded,
              label: 'Guide',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            DrawerMenuItem(
              icon: Icons.logout_rounded,
              label: 'Logout',
              onTap: () {
                Navigator.pop(context);
                context.go('/login');
              },
              isDestructive: true,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
