import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthLogo extends StatelessWidget {
  final double? size;
  final String assetPath;

  const AuthLogo({
    super.key,
    this.size,
    this.assetPath = 'assets/images/submark_logo.png',
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? 80.h;

    return Image.asset(
      assetPath,
      width: effectiveSize,
      height: effectiveSize,
      fit: BoxFit.contain,
    );
  }
}
