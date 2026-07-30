import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dukaapp/features/splash/splash_screen.dart';
import 'package:dukaapp/features/authentication/login/login_screen.dart';
import 'package:dukaapp/features/authentication/register/register_screen.dart';
import 'package:dukaapp/features/authentication/reset_password/reset_password_screen.dart';
import 'package:dukaapp/features/dashboard/dashboard_screen.dart';
import 'package:dukaapp/features/stock/presentation/pages/manage_stock_page.dart';
import 'package:dukaapp/features/stock/presentation/pages/category_products_page.dart';
import 'package:dukaapp/features/stock/presentation/pages/add_product_page.dart';
import 'package:dukaapp/features/stock/presentation/pages/import_from_shop_page.dart';
import 'package:dukaapp/features/stock/presentation/pages/purchase_stock_page.dart';
import 'package:dukaapp/features/stock/presentation/pages/adjust_stock_page.dart';
import 'package:dukaapp/features/stock/presentation/pages/transfer_stock_page.dart';
import 'package:dukaapp/features/stock/presentation/pages/stock_reports_page.dart';
import 'package:dukaapp/features/stock/presentation/pages/stock_reports/all_stock_report_page.dart';
import 'package:dukaapp/features/stock/presentation/pages/stock_reports/combined_stock_value_report_page.dart';
import 'package:dukaapp/features/stock/presentation/pages/stock_reports/stock_by_category_report_page.dart';
import 'package:dukaapp/features/stock/presentation/pages/stock_reports/price_list_report_page.dart';
import 'package:dukaapp/features/stock/presentation/pages/stock_reports/counting_sheet_report_page.dart';
import 'package:dukaapp/features/stock/presentation/pages/stock_reports/low_stock_report_page.dart';
import 'package:dukaapp/features/stock/presentation/pages/stock_reports/bad_stock_report_page.dart';
import 'package:dukaapp/features/stock/presentation/pages/stock_reports/lost_stock_report_page.dart';
import 'package:dukaapp/features/stock/presentation/pages/stock_reports/about_to_expire_report_page.dart';
import 'package:dukaapp/features/stock/presentation/pages/stock_reports/expired_report_page.dart';
import 'package:dukaapp/features/stock/presentation/pages/stock_reports/import_history_report_page.dart';
import 'package:dukaapp/features/stock/presentation/pages/stock_reports/generate_barcode_report_page.dart';

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
        path: '/purchase',
        name: 'purchase',
        builder: (context, state) => const PurchaseStockPage(),
      ),
      GoRoute(
        path: '/adjust',
        name: 'adjust',
        builder: (context, state) => const AdjustStockPage(),
      ),
      GoRoute(
        path: '/transfer',
        name: 'transfer',
        builder: (context, state) => const TransferStockPage(),
      ),
      GoRoute(
        path: '/stock-reports',
        name: 'stock-reports',
        builder: (context, state) => const StockReportsPage(),
      ),
      GoRoute(
        path: '/stock-reports/all-stock',
        name: 'all-stock-report',
        builder: (context, state) => const AllStockReportPage(),
      ),
      GoRoute(
        path: '/stock-reports/combined-stock-value',
        name: 'combined-stock-value-report',
        builder: (context, state) => const CombinedStockValueReportPage(),
      ),
      GoRoute(
        path: '/stock-reports/stock-by-category',
        name: 'stock-by-category-report',
        builder: (context, state) => const StockByCategoryReportPage(),
      ),
      GoRoute(
        path: '/stock-reports/price-list',
        name: 'price-list-report',
        builder: (context, state) => const PriceListReportPage(),
      ),
      GoRoute(
        path: '/stock-reports/counting-sheet',
        name: 'counting-sheet-report',
        builder: (context, state) => const CountingSheetReportPage(),
      ),
      GoRoute(
        path: '/stock-reports/low-stock',
        name: 'low-stock-report',
        builder: (context, state) => const LowStockReportPage(),
      ),
      GoRoute(
        path: '/stock-reports/bad-stock',
        name: 'bad-stock-report',
        builder: (context, state) => const BadStockReportPage(),
      ),
      GoRoute(
        path: '/stock-reports/lost-stock',
        name: 'lost-stock-report',
        builder: (context, state) => const LostStockReportPage(),
      ),
      GoRoute(
        path: '/stock-reports/about-to-expire',
        name: 'about-to-expire-report',
        builder: (context, state) => const AboutToExpireReportPage(),
      ),
      GoRoute(
        path: '/stock-reports/expired',
        name: 'expired-report',
        builder: (context, state) => const ExpiredReportPage(),
      ),
      GoRoute(
        path: '/stock-reports/import-history',
        name: 'import-history-report',
        builder: (context, state) => const ImportHistoryReportPage(),
      ),
      GoRoute(
        path: '/stock-reports/generate-barcode',
        name: 'generate-barcode-report',
        builder: (context, state) => const GenerateBarcodeReportPage(),
      ),
      GoRoute(
        path: '/stock/manage',
        name: 'manage-stock',
        builder: (context, state) => const ManageStockPage(),
        routes: [
          GoRoute(
            path: 'category',
            name: 'category-products',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return CategoryProductsPage(
                categoryName: extra?['categoryName'] ?? 'Unknown',
                products: List<Map<String, dynamic>>.from(
                  extra?['products'] ?? [],
                ),
              );
            },
          ),
          GoRoute(
            path: 'add',
            name: 'add-product',
            builder: (context, state) => const AddProductPage(),
          ),
          GoRoute(
            path: 'import-from-shop',
            name: 'import-from-shop',
            builder: (context, state) => const ImportFromShopPage(),
          ),
          GoRoute(
            path: 'purchase',
            name: 'purchase-stock',
            builder: (context, state) => const PurchaseStockPage(),
          ),
        ],
      ),
    ],
  );
});
