import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';

class ShopSwitchButton extends StatelessWidget {
  final VoidCallback onTap;

  const ShopSwitchButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.swap_horiz_rounded,
          color: AppColors.textWhite,
          size: 22,
        ),
      ),
    );
  }
}
