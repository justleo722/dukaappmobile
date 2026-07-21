import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dukaapp/features/splash/splash_screen.dart';
import 'package:dukaapp/features/authentication/login/login_screen.dart';
import 'package:dukaapp/features/authentication/register/register_screen.dart';
import 'package:dukaapp/features/authentication/reset_password/reset_password_screen.dart';
import 'package:dukaapp/features/dashboard/dashboard_screen.dart';
import 'package:dukaapp/features/stock/presentation/pages/manage_stock_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/stock/manage',
        name: 'manage-stock',
        builder: (context, state) => const ManageStockPage(),
      ),
    ],
  );
});
