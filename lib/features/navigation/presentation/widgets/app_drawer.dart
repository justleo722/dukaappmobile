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
import 'package:dukaapp/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:dukaapp/features/stock/presentation/providers/stock_provider.dart';
import 'package:dukaapp/features/sales/presentation/providers/sales_provider.dart';
import 'package:dukaapp/shared/providers/filter_provider.dart';

class AppDrawer extends ConsumerStatefulWidget {
  final VoidCallback? onRefresh;

  const AppDrawer({super.key, this.onRefresh});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  File? _profileImage;

  void _onShopSelected(Map<String, dynamic> shop) async {
    final shopId = shop['id']?.toString() ?? '';
    if (shopId.isEmpty) return;
    Navigator.pop(context);
    try {
      await ref.read(authProvider.notifier).switchShop(shopId);

      // Reset filter to today for the new shop
      ref.read(filterProvider.notifier).reset();

      // Invalidate all data providers so they reload with new shop's data
      ref.invalidate(dashboardProvider);
      ref.invalidate(stockProvider);
      ref.invalidate(salesProvider);
      ref.invalidate(ordersProvider);
      ref.invalidate(invoicesProvider);

      // Navigate to dashboard so user sees fresh data
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imeshindwa kubadilisha duka: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _openShopSelector() {
    final authState = ref.read(authProvider);
    final shops = (authState.shops ?? []).map((s) => {
      'id'  : s.id?.toString() ?? '',
      'name': s.shopName ?? s.id?.toString() ?? '',
      'shopId': s.id?.toString() ?? '',  // kept for switch logic
    }).toList();
    final activeId = authState.activeShop?.id?.toString() ?? '';

    ShopSelectorBottomSheet.show(
      context       : context,
      shops         : shops,
      activeShopId  : activeId,
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
    final authState  = ref.watch(authProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth * 0.78;

    final user       = authState.user;
    final activeShop = authState.activeShop;

    final userName   = user?.username ?? 'Mtumiaji';
    final userId     = user?.id?.toString() ?? '';
    final shopName   = activeShop?.shopName ?? activeShop?.id?.toString() ?? '—';
    final activeId   = activeShop?.id?.toString() ?? '';

    return Drawer(
      width: drawerWidth,
      backgroundColor: AppColors.card,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppDrawerHeader(
              userName          : userName,
              userId            : userId,
              shopName          : shopName,
              activeShopId      : activeId,
              onEditProfile     : () {
                Navigator.pop(context);
                context.push('/edit-profile');
              },
              onSwitchShop      : _openShopSelector,
              onProfileImageTap : _openProfileImageDialog,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: AppColors.divider, height: 1),
            ),
            const SizedBox(height: 8),
            DrawerMenuItem(
              icon : Icons.home_rounded,
              label: 'Dashboard',
              onTap: () {
                Navigator.pop(context);
                widget.onRefresh?.call();
              },
            ),
            DrawerMenuItem(
              icon          : Icons.add_rounded,
              label         : 'Add Shop',
              showExpandIcon: true,
              onTap: () {
                Navigator.pop(context);
                AddShopBottomSheet.show(
                  context: context,
                  onShopCreated: (shopData) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Shop "${shopData['name']}" created successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                );
              },
            ),
            DrawerMenuItem(
              icon : Icons.settings_rounded,
              label: 'Shop Settings',
              onTap: () {
                Navigator.pop(context);
                context.push('/shop-settings');
              },
            ),
            DrawerMenuItem(
              icon : Icons.book_rounded,
              label: 'Guide',
              onTap: () {
                Navigator.pop(context);
                _openGuide();
              },
            ),
            const Spacer(),
            DrawerMenuItem(
              icon        : Icons.logout_rounded,
              label       : 'Logout',
              onTap       : () => _confirmLogout(),
              isDestructive: true,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
