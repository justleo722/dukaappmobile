import 'package:flutter/material.dart';
import 'package:dukaapp/app/typography.dart';

class ReportSection extends StatelessWidget {
  final String title;

  const ReportSection({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 4),
      child: Text(
        title,
        style: AppTypography.overline.copyWith(
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
