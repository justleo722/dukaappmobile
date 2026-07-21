import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool showDivider;
  final PreferredSizeWidget? bottom;
  final double? elevation;
  final SystemUiOverlayStyle? systemOverlayStyle;

  const AppAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.showDivider = true,
    this.bottom,
    this.elevation = 0,
    this.systemOverlayStyle,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: AppTypography.h6.copyWith(
          color: foregroundColor ?? AppColors.textPrimary,
        ),
      ),
      leading: leading,
      actions: actions,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? AppColors.card,
      foregroundColor: foregroundColor ?? AppColors.textPrimary,
      elevation: elevation,
      scrolledUnderElevation: 0,
      systemOverlayStyle: systemOverlayStyle,
      bottom: bottom != null
          ? PreferredSize(
              preferredSize: bottom!.preferredSize,
              child: Container(
                color: AppColors.card,
                child: bottom,
              ),
            )
          : showDivider
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    color: AppColors.divider,
                  ),
                )
              : null,
    );
  }
}

class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
      icon: Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 20.h,
        color: color ?? AppColors.textPrimary,
      ),
    );
  }
}
