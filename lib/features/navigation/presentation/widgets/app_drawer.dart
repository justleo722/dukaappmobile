import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dukaapp/features/navigation/presentation/widgets/add_shop_bottom_sheet.dart';
import 'package:dukaapp/features/navigation/presentation/widgets/change_profile_image_dialog.dart';
import 'package:dukaapp/features/navigation/presentation/widgets/drawer_header.dart';
import 'package:dukaapp/features/navigation/presentation/widgets/drawer_menu_item.dart';
import 'package:dukaapp/features/navigation/presentation/widgets/shop_selector_bottom_sheet.dart';

class AppDrawer extends ConsumerStatefulWidget {
  final VoidCallback? onRefresh;

  const AppDrawer({super.key, this.onRefresh});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  String _activeShopId = 'S0003';
  File? _profileImage;

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

  void _openProfileImageDialog() {
    ChangeProfileImageDialog.show(
      context: context,
      onImageSelected: (file) {
        if (file != null) {
          setState(() {
            _profileImage = file;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile image updated'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
    );
  }

  Future<void> _openGuide() async {
    final uri = Uri.parse('https://www.youtube.com/@dukaapp');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    await ref.read(authProvider.notifier).signOut();
    nav.pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Logged out successfully'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (context.mounted) context.go('/login');
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
              onEditProfile: () {
                Navigator.pop(context);
                context.push('/edit-profile');
              },
              onSwitchShop: _openShopSelector,
              onProfileImageTap: _openProfileImageDialog,
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
                widget.onRefresh?.call();
              },
            ),
            DrawerMenuItem(
              icon: Icons.add_rounded,
              label: 'Add Shop',
              onTap: () {
                Navigator.pop(context);
                AddShopBottomSheet.show(
                  context: context,
                  onShopCreated: (shopData) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Shop "${shopData['name']}" created successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                );
              },
              showExpandIcon: true,
            ),
            DrawerMenuItem(
              icon: Icons.settings_rounded,
              label: 'Shop Settings',
              onTap: () {
                Navigator.pop(context);
                context.push('/shop-settings');
              },
            ),
            DrawerMenuItem(
              icon: Icons.book_rounded,
              label: 'Guide',
              onTap: () {
                Navigator.pop(context);
                _openGuide();
              },
            ),
            const Spacer(),
            DrawerMenuItem(
              icon: Icons.logout_rounded,
              label: 'Logout',
              onTap: () => _confirmLogout(),
              isDestructive: true,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
