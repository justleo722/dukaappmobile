import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle _base({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double height = 1.5,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // Headings
  static TextStyle h1 = _base(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2);
  static TextStyle h2 = _base(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2);
  static TextStyle h3 = _base(fontSize: 24, fontWeight: FontWeight.w700, height: 1.3);
  static TextStyle h4 = _base(fontSize: 20, fontWeight: FontWeight.w700, height: 1.3);
  static TextStyle h5 = _base(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4);
  static TextStyle h6 = _base(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4);

  // Body
  static TextStyle bodyLarge = _base(fontSize: 16, fontWeight: FontWeight.w500);
  static TextStyle bodyMedium = _base(fontSize: 14, fontWeight: FontWeight.w500);
  static TextStyle bodySmall = _base(fontSize: 12, fontWeight: FontWeight.w500);

  // Caption
  static TextStyle caption = _base(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static TextStyle captionBold = _base(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary);

  // Label
  static TextStyle label = _base(fontSize: 14, fontWeight: FontWeight.w600);
  static TextStyle labelSmall = _base(fontSize: 12, fontWeight: FontWeight.w600);

  // Button
  static TextStyle buttonLarge = _base(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textWhite, height: 1.0);
  static TextStyle buttonMedium = _base(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textWhite, height: 1.0);
  static TextStyle buttonSmall = _base(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textWhite, height: 1.0);

  // Overline
  static TextStyle overline = _base(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: AppColors.textSecondary);
}
