import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/submark_logo.png',
              width: 120,
              height: 120,
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 200.ms)
                .slideY(
                  begin: -0.3,
                  end: 0,
                  duration: 800.ms,
                  delay: 200.ms,
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: 24),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Duka',
                    style: AppTypography.h2.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                  TextSpan(
                    text: 'App',
                    style: AppTypography.h2.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 600.ms)
                .slideY(
                  begin: 0.2,
                  end: 0,
                  duration: 600.ms,
                  delay: 600.ms,
                  curve: Curves.easeOut,
                ),
          ],
        ),
      ),
    );
  }
}
