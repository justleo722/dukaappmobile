import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/features/dashboard/presentation/widgets/language_selector.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leadingWidth: 120,
      leading: Row(
        children: [
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            icon: const Icon(
              Icons.menu_rounded,
              size: 24,
            ),
          ),
          Image.asset(
            'assets/images/submark_logo.png',
            height: 28,
            width: 28,
          ),
        ],
      ),
      centerTitle: true,
      title: const LanguageSelector(),
      actions: [
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.refresh_rounded,
            color: AppColors.textPrimary,
            size: 22,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => context.go('/login'),
          icon: const Icon(
            Icons.logout_rounded,
            color: AppColors.textPrimary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}
