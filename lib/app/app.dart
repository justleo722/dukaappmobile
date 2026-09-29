import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dukaapp/app/theme.dart';
import 'package:dukaapp/app/router.dart';

/// Global key for showing SnackBars from anywhere in the app,
/// even after navigation changes.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Show a global toast that floats above all pages.
void showAppToast(String message, {bool isError = false}) {
  scaffoldMessengerKey.currentState
    ?..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
}

class DukaApp extends ConsumerWidget {
  const DukaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'DukaApp',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: router,
          scaffoldMessengerKey: scaffoldMessengerKey,
        );
      },
    );
  }
}
