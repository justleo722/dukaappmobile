// app/router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dukaapp/features/splash/splash_screen.dart';
import 'package:dukaapp/features/authentication/login/login_screen.dart';
import 'package:dukaapp/features/authentication/register/register_screen.dart';
import 'package:dukaapp/features/authentication/reset_password/reset_password_screen.dart';
import 'package:dukaapp/features/dashboard/dashboard_screen.dart';
import 'package:dukaapp/features/settings/presentation/pages/shop_settings_page.dart';
import 'package:dukaapp/features/settings/presentation/pages/shop_details_page.dart';
import 'package:dukaapp/features/settings/presentation/pages/custom_features_page.dart';
import 'package:dukaapp/features/settings/presentation/pages/data_backup_page.dart';
import 'package:dukaapp/features/settings/presentation/pages/storage_page.dart';
import 'package:dukaapp/features/settings/presentation/pages/system_logs_page.dart';
import 'package:dukaapp/features/renew/presentation/pages/renew_page.dart';
import 'package:dukaapp/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:dukaapp/features/stock/presentation/pages/manage_stock_page.dart';
import 'package:dukaapp/features/stock/presentation/pages/category_products_page.dart';
import 'package:dukaapp/features/stock/presentation/pages/add_product_page.dart';
import 'package:dukaapp/features/stock/presentation/pages/import_from_shop_page.dart';
import 'package:dukaapp/features/purchase/presentation/pages/purchase_stock_page.dart';
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
import 'package:dukaapp/features/sales/presentation/pages/manage_sales_page.dart';
import 'package:dukaapp/features/sales/presentation/pages/add_sale_page.dart';
import 'package:dukaapp/features/sales/presentation/pages/orders_page.dart';
import 'package:dukaapp/features/sales/presentation/pages/invoices_page.dart';
import 'package:dukaapp/features/sales/presentation/pages/create_invoice_page.dart';
import 'package:dukaapp/features/sales/presentation/pages/add_order_page.dart';
import 'package:dukaapp/features/purchase/presentation/pages/purchases_page.dart';
import 'package:dukaapp/features/purchase/presentation/pages/purchase_orders_page.dart';
import 'package:dukaapp/features/sales/presentation/pages/sales_reports_page.dart';
import 'package:dukaapp/features/sales/presentation/pages/sales_reports/total_sales_report_page.dart';
import 'package:dukaapp/features/sales/presentation/pages/sales_reports/combined_total_sales_report_page.dart';
import 'package:dukaapp/features/sales/presentation/pages/sales_reports/all_orders_report_page.dart';
import 'package:dukaapp/features/sales/presentation/pages/sales_reports/invoices_report_page.dart';
import 'package:dukaapp/features/sales/presentation/pages/sales_reports/credit_sales_report_page.dart';
import 'package:dukaapp/features/sales/presentation/pages/sales_reports/customer_on_credit_report_page.dart';
import 'package:dukaapp/features/sales/presentation/pages/sales_reports/sales_by_payments_report_page.dart';
import 'package:dukaapp/features/sales/presentation/pages/sales_reports/sales_by_category_report_page.dart';
import 'package:dukaapp/features/sales/presentation/pages/sales_reports/sales_by_product_report_page.dart';
import 'package:dukaapp/features/sales/presentation/pages/sales_reports/unpaid_sales_by_product_report_page.dart';
import 'package:dukaapp/features/sales/presentation/pages/sales_reports/sales_with_vat_report_page.dart';
import 'package:dukaapp/features/sales/presentation/pages/sales_reports/sales_without_vat_report_page.dart';
import 'package:dukaapp/features/sales/presentation/pages/sales_reports/staff_sales_by_items_report_page.dart';
import 'package:dukaapp/features/sales/presentation/pages/sales_reports/individual_team_sales_report_page.dart';
import 'package:dukaapp/features/sales/presentation/pages/sales_reports/sales_by_customer_report_page.dart';
import 'package:dukaapp/features/sales/presentation/pages/sales_reports/sales_by_staff_report_page.dart';
import 'package:dukaapp/features/sales/presentation/pages/sales_reports/combined_sales_by_staff_report_page.dart';
import 'package:dukaapp/features/customers/presentation/pages/customers_page.dart';
import 'package:dukaapp/features/customers/presentation/pages/add_customer_page.dart';
import 'package:dukaapp/features/customers/presentation/pages/customer_dashboard_page.dart';
import 'package:dukaapp/features/customers/presentation/pages/customers_wallet_page.dart';
import 'package:dukaapp/features/customers/data/models/customer_model.dart';
import 'package:dukaapp/features/suppliers/presentation/pages/suppliers_page.dart';
import 'package:dukaapp/features/suppliers/presentation/pages/add_supplier_page.dart';
import 'package:dukaapp/features/suppliers/presentation/pages/supplier_dashboard_page.dart';
import 'package:dukaapp/features/suppliers/data/models/supplier_model.dart';
import 'package:dukaapp/features/purchase/presentation/pages/purchase_reports/purchase_reports_hub_page.dart';
import 'package:dukaapp/features/purchase/presentation/pages/purchase_reports/purchase_report_page.dart';
import 'package:dukaapp/features/expenses/presentation/pages/profit_expenses_page.dart';
import 'package:dukaapp/features/expenses/presentation/pages/profit_expenses_reports_hub_page.dart';
import 'package:dukaapp/features/expenses/presentation/pages/profit_expenses_report_page.dart';
import 'package:dukaapp/features/accounts/presentation/pages/accounts_cashflow_page.dart';
import 'package:dukaapp/features/accounts/presentation/pages/accounts_reports/accounts_reports_page.dart';
import 'package:dukaapp/features/accounts/presentation/pages/accounts_reports/accounts_cashflow_report_page.dart';
import 'package:dukaapp/features/staff/presentation/pages/staff_management_page.dart';
import 'package:dukaapp/features/staff/presentation/pages/add_attendant_page.dart';
import 'package:dukaapp/features/staff/presentation/pages/edit_attendant_page.dart';
import 'package:dukaapp/features/staff/presentation/pages/manage_permissions_page.dart';
import 'package:dukaapp/features/manufacturing/presentation/pages/manufacturing_page.dart';
import 'package:dukaapp/features/manufacturing/presentation/pages/raw_materials_page.dart';
import 'package:dukaapp/features/manufacturing/presentation/pages/restock_raw_materials_page.dart';
import 'package:dukaapp/features/manufacturing/presentation/pages/add_raw_material_page.dart';
import 'package:dukaapp/features/manufacturing/presentation/pages/edit_raw_material_page.dart';
import 'package:dukaapp/features/manufacturing/presentation/pages/manage_recipes_page.dart';
import 'package:dukaapp/features/manufacturing/presentation/pages/create_recipe_page.dart';
import 'package:dukaapp/features/manufacturing/presentation/pages/edit_recipe_page.dart';
import 'package:dukaapp/features/manufacturing/presentation/pages/add_manufactured_product_page.dart';
import 'package:dukaapp/features/manufacturing/presentation/pages/edit_manufactured_product_page.dart';
import 'package:dukaapp/features/manufacturing/presentation/pages/manufacturing_reports_page.dart';
import 'package:dukaapp/features/manufacturing/presentation/pages/stock_reports/daily_production_report_page.dart';
import 'package:dukaapp/features/manufacturing/presentation/pages/stock_reports/raw_material_consumption_report_page.dart';
import 'package:dukaapp/features/manufacturing/presentation/pages/stock_reports/production_cost_analysis_report_page.dart';
import 'package:dukaapp/features/manufacturing/presentation/pages/stock_reports/low_stock_alert_report_page.dart';
import 'package:dukaapp/features/manufacturing/presentation/pages/stock_reports/product_by_recipe_report_page.dart';
import 'package:dukaapp/features/manufacturing/presentation/pages/reproduce_products_page.dart';
import 'package:dukaapp/features/manufacturing/presentation/pages/adjust_manufactured_products_page.dart';
import 'package:dukaapp/features/manufacturing/presentation/pages/transfer_products_page.dart';
import 'package:dukaapp/features/online_shop/presentation/pages/online_shop_dashboard_page.dart';
import 'package:dukaapp/features/online_shop/presentation/pages/online_shop_manage_products_page.dart';
import 'package:dukaapp/features/online_shop/presentation/pages/online_shop_manage_orders_page.dart';
import 'package:dukaapp/features/online_shop/presentation/pages/online_shop_order_details_page.dart';
import 'package:dukaapp/features/online_shop/presentation/pages/online_shop_coupon_codes_page.dart';
import 'package:dukaapp/features/online_shop/presentation/pages/online_shop_add_coupon_page.dart';
import 'package:dukaapp/features/online_shop/presentation/pages/online_shop_categories_page.dart';
import 'package:dukaapp/features/online_shop/presentation/pages/online_shop_add_category_page.dart';
import 'package:dukaapp/features/online_shop/presentation/pages/online_shop_delivery_methods_page.dart';
import 'package:dukaapp/features/online_shop/presentation/pages/online_shop_add_delivery_method_page.dart';
import 'package:dukaapp/features/online_shop/presentation/pages/online_shop_payment_methods_page.dart';
import 'package:dukaapp/features/online_shop/presentation/pages/online_shop_reports_page.dart';
import 'package:dukaapp/features/online_shop/presentation/pages/online_shop_settings_page.dart';
import 'package:dukaapp/features/online_shop/presentation/pages/storefront_page.dart';
import 'package:dukaapp/features/online_shop/presentation/pages/shopping_cart_page.dart';
import 'package:dukaapp/features/online_shop/presentation/pages/online_shop_checkout_page.dart';
import 'package:dukaapp/features/online_shop/presentation/pages/product_details_page.dart';
import 'package:dukaapp/features/tms/presentation/pages/tms_page.dart';

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
        path: '/shop-settings',
        name: 'shop-settings',
        builder: (context, state) => const ShopSettingsPage(),
      ),
      GoRoute(
        path: '/shop-settings/details',
        name: 'shop-settings-details',
        builder: (context, state) => const ShopDetailsPage(),
      ),
      GoRoute(
        path: '/shop-settings/custom-features',
        name: 'shop-settings-custom-features',
        builder: (context, state) => const CustomFeaturesPage(),
      ),
      GoRoute(
        path: '/shop-settings/data-backup',
        name: 'shop-settings-data-backup',
        builder: (context, state) => const DataBackupPage(),
      ),
      GoRoute(
        path: '/shop-settings/storage',
        name: 'shop-settings-storage',
        builder: (context, state) => const StoragePage(),
      ),
      GoRoute(
        path: '/shop-settings/storage/system-logs',
        name: 'shop-settings-storage-system-logs',
        builder: (context, state) => const SystemLogsPage(),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/renew',
        name: 'renew',
        builder: (context, state) => const RenewPage(),
      ),
      GoRoute(
        path: '/purchase',
        name: 'purchase',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final editMode = extra?['editMode'] as bool? ?? false;
          final createMode = extra?['createMode'] as bool? ?? false;
          final poNumber = extra?['poNumber'] as String?;
          final supplier = extra?['supplier'] as String?;
          final products = extra?['products'] as List<Map<String, dynamic>>?;
          final initialProduct = extra?['initialProduct'] as Map<String, dynamic>?;
          return PurchaseStockPage(
            initialProduct: initialProduct,
            editMode: editMode,
            createMode: createMode,
            poNumber: poNumber,
            initialSupplier: supplier,
            editProducts: products,
          );
        },
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
        path: '/sales/manage',
        name: 'manage-sales',
        builder: (context, state) => const ManageSalesPage(),
      ),
      GoRoute(
        path: '/sales/add',
        name: 'add-sale',
        builder: (context, state) {
          final sale = state.extra as Map<String, dynamic>?;
          return AddSalePage(existingSale: sale);
        },
      ),
      GoRoute(
        path: '/sales/orders',
        name: 'orders',
        builder: (context, state) => const OrdersPage(),
      ),
      GoRoute(
        path: '/sales/invoices',
        name: 'invoices',
        builder: (context, state) => const InvoicesPage(),
      ),
      GoRoute(
        path: '/sales/create-invoice',
        name: 'create-invoice',
        builder: (context, state) => const CreateInvoicePage(),
      ),
      GoRoute(
        path: '/sales/add-order',
        name: 'add-order',
        builder: (context, state) => const AddOrderPage(),
      ),
      GoRoute(
        path: '/sales/purchases',
        name: 'purchases',
        builder: (context, state) => const PurchasesPage(),
      ),
      GoRoute(
        path: '/purchases/orders',
        name: 'purchase-orders',
        builder: (context, state) => const PurchaseOrdersPage(),
      ),
      GoRoute(
        path: '/purchases/reports',
        name: 'purchase-reports',
        builder: (context, state) => const PurchaseReportsHubPage(),
        routes: [
          GoRoute(
            path: ':reportKey',
            name: 'purchase-report-detail',
            builder: (context, state) {
              final key = state.pathParameters['reportKey'] ?? '';
              final title = {
                'purchase_history': 'Purchase History',
                'total_purchase': 'Total Purchase',
                'orders': 'Orders',
                'suppliers': 'Suppliers',
                'cash_purchase': 'Cash Purchase',
                'credit_purchase': 'Credit Purchase',
                'by_category': 'Purchase by Category',
                'by_products': 'Purchase by Products',
                'by_supplier': 'Purchase by Supplier',
                'stock_returned': 'Stock Returned to Suppliers',
              }[key] ?? 'Report';
              return PurchaseReportPage(reportKey: key, title: title);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/sales/reports',
        name: 'sales-reports',
        builder: (context, state) => const SalesReportsPage(),
        routes: [
          GoRoute(path: 'total-sales', name: 'total-sales-report', builder: (context, state) => const TotalSalesReportPage()),
          GoRoute(path: 'combined-total-sales', name: 'combined-total-sales-report', builder: (context, state) => const CombinedTotalSalesReportPage()),
          GoRoute(path: 'all-orders', name: 'all-orders-report', builder: (context, state) => const AllOrdersReportPage()),
          GoRoute(path: 'invoices', name: 'invoices-report', builder: (context, state) => const InvoicesReportPage()),
          GoRoute(path: 'credit-sales', name: 'credit-sales-report', builder: (context, state) => const CreditSalesReportPage()),
          GoRoute(path: 'customer-on-credit', name: 'customer-on-credit-report', builder: (context, state) => const CustomerOnCreditReportPage()),
          GoRoute(path: 'sales-by-payments', name: 'sales-by-payments-report', builder: (context, state) => const SalesByPaymentsReportPage()),
          GoRoute(path: 'sales-by-category', name: 'sales-by-category-report', builder: (context, state) => const SalesByCategoryReportPage()),
          GoRoute(path: 'sales-by-product', name: 'sales-by-product-report', builder: (context, state) => const SalesByProductReportPage()),
          GoRoute(path: 'unpaid-sales-by-product', name: 'unpaid-sales-by-product-report', builder: (context, state) => const UnpaidSalesByProductReportPage()),
          GoRoute(path: 'sales-with-vat', name: 'sales-with-vat-report', builder: (context, state) => const SalesWithVatReportPage()),
          GoRoute(path: 'sales-without-vat', name: 'sales-without-vat-report', builder: (context, state) => const SalesWithoutVatReportPage()),
          GoRoute(path: 'staff-sales-by-items', name: 'staff-sales-by-items-report', builder: (context, state) => const StaffSalesByItemsReportPage()),
          GoRoute(path: 'individual-team-sales', name: 'individual-team-sales-report', builder: (context, state) => const IndividualTeamSalesReportPage()),
          GoRoute(path: 'sales-by-customer', name: 'sales-by-customer-report', builder: (context, state) => const SalesByCustomerReportPage()),
          GoRoute(path: 'sales-by-staff', name: 'sales-by-staff-report', builder: (context, state) => const SalesByStaffReportPage()),
          GoRoute(path: 'combined-sales-by-staff', name: 'combined-sales-by-staff-report', builder: (context, state) => const CombinedSalesByStaffReportPage()),
        ],
      ),
      GoRoute(
        path: '/profit-expenses',
        name: 'profit-expenses',
        builder: (context, state) => const ProfitExpensesPage(),
        routes: [
          GoRoute(
            path: 'reports',
            name: 'profit-expenses-reports',
            builder: (context, state) => const ProfitExpensesReportsHubPage(),
            routes: [
              GoRoute(
                path: ':reportKey',
                name: 'profit-expenses-report-detail',
                builder: (context, state) {
                  final key = state.pathParameters['reportKey'] ?? '';
                  final title = {
                    'daily-profit': 'Daily Profit',
                    'all-expenses': 'All Expenses',
                    'profits': 'Profits',
                    'loss': 'Loss',
                  }[key] ?? 'Report';
                  return ProfitExpensesReportPage(reportKey: key, title: title);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/accounts-cashflow',
        name: 'accounts-cashflow',
        builder: (context, state) => const AccountsCashflowPage(),
      ),
      GoRoute(
        path: '/accounts-reports',
        name: 'accounts-reports',
        builder: (context, state) => const AccountsReportsPage(),
        routes: [
          GoRoute(
            path: 'cash-in-hand-in-bank',
            name: 'cash-in-hand-in-bank-report',
            builder: (context, state) => const AccountsCashflowReportPage(reportKey: 'cash-in-hand-in-bank', title: 'Cash InHand & InBank'),
          ),
          GoRoute(
            path: 'cash-in',
            name: 'cash-in-report',
            builder: (context, state) => const AccountsCashflowReportPage(reportKey: 'cash-in', title: 'Cash In'),
          ),
          GoRoute(
            path: 'cash-out',
            name: 'cash-out-report',
            builder: (context, state) => const AccountsCashflowReportPage(reportKey: 'cash-out', title: 'Cash Out'),
          ),
          GoRoute(
            path: 'accounts-balance',
            name: 'accounts-balance-report',
            builder: (context, state) => const AccountsCashflowReportPage(reportKey: 'accounts-balance', title: 'Accounts Balance'),
          ),
        ],
      ),
      GoRoute(
        path: '/staff',
        name: 'staff',
        builder: (context, state) => const StaffManagementPage(),
        routes: [
          GoRoute(
            path: 'add',
            name: 'add-attendant',
            builder: (context, state) => const AddAttendantPage(),
          ),
          GoRoute(
            path: 'edit',
            name: 'edit-attendant',
            builder: (context, state) {
              final data = state.extra as Map<String, dynamic>;
              return EditAttendantPage(
                name: data['name'] ?? '',
                phone: data['phone'] ?? '',
                role: data['role'] ?? 'Normal Attendant',
                shops: List<String>.from(data['shops'] ?? []),
                roleId: data['roleId']?.toString(),
                isManager: data['isManager'] == true,
              );
            },
          ),
          GoRoute(
            path: 'permissions',
            name: 'manage-permissions',
            builder: (context, state) {
              final extra = state.extra;
              String? roleId;
              if (extra is Map) {
                roleId = extra['roleId']?.toString();
              } else if (extra is String) {
                roleId = extra;
              }
              return ManagePermissionsPage(roleId: roleId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/tms',
        name: 'tms',
        builder: (context, state) => const TmsPage(),
      ),
      GoRoute(
        path: '/manufacturing',
        name: 'manufacturing',
        builder: (context, state) => const ManufacturingPage(),
        routes: [
          GoRoute(
            path: 'raw-materials',
            name: 'raw-materials',
            builder: (context, state) => const RawMaterialsPage(),
            routes: [
              GoRoute(
                path: 'restock',
                name: 'restock-raw-materials',
                builder: (context, state) => const RestockRawMaterialsPage(),
              ),
              GoRoute(
                path: 'add',
                name: 'add-raw-material',
                builder: (context, state) => const AddRawMaterialPage(),
              ),
              GoRoute(
                path: 'edit',
                name: 'edit-raw-material',
                builder: (context, state) {
                  final data = state.extra as Map<String, dynamic>;
                  return EditRawMaterialPage(
                    name: data['name'] ?? '',
                    unit: data['unit'] ?? 'item',
                    unitCost: (data['unitCost'] as num?)?.toDouble() ?? 0,
                    status: data['status'] ?? 'In Stock',
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'recipes',
            name: 'manage-recipes',
            builder: (context, state) => const ManageRecipesPage(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'create-recipe',
                builder: (context, state) => const CreateRecipePage(),
              ),
              GoRoute(
                path: 'edit',
                name: 'edit-recipe',
                builder: (context, state) {
                  final data = state.extra as Map<String, dynamic>;
                  return EditRecipePage(
                    name: data['name'] ?? '',
                    yieldAmount: data['yieldAmount'] ?? '1',
                    ingredients: List<String>.from(data['ingredients'] ?? []),
                    estimatedCost: (data['estimatedCost'] as num?)?.toDouble() ?? 0,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'add-product',
            name: 'add-manufactured-product',
            builder: (context, state) => const AddManufacturedProductPage(),
          ),
          GoRoute(
            path: 'edit-product',
            name: 'edit-manufactured-product',
            builder: (context, state) {
              final data = state.extra as Map<String, dynamic>;
              return EditManufacturedProductPage(
                name: data['name'] ?? '',
                recipe: data['recipe'] ?? '',
                quantity: data['quantity'] ?? 1,
                unitCost: (data['unitCost'] as num?)?.toDouble() ?? 0,
                sellingPrice: (data['sellingPrice'] as num?)?.toDouble() ?? 0,
                wholesalePrice: (data['wholesalePrice'] as num?)?.toDouble() ?? 0,
                alertLevel: data['alertLevel'] ?? 10,
              );
            },
          ),
          GoRoute(
            path: 'reports',
            name: 'manufacturing-reports',
            builder: (context, state) => const ManufacturingReportsPage(),
            routes: [
              GoRoute(path: 'daily-production', name: 'daily-production-report', builder: (context, state) => const DailyProductionReportPage()),
              GoRoute(path: 'raw-material-consumption', name: 'raw-material-consumption-report', builder: (context, state) => const RawMaterialConsumptionReportPage()),
              GoRoute(path: 'production-cost-analysis', name: 'production-cost-analysis-report', builder: (context, state) => const ProductionCostAnalysisReportPage()),
              GoRoute(path: 'low-stock-alert', name: 'low-stock-alert-report', builder: (context, state) => const LowStockAlertReportPage()),
              GoRoute(path: 'product-by-recipe', name: 'product-by-recipe-report', builder: (context, state) => const ProductByRecipeReportPage()),
            ],
          ),
          GoRoute(
            path: 'reproduce',
            name: 'reproduce-products',
            builder: (context, state) => const ReproduceProductsPage(),
          ),
          GoRoute(
            path: 'adjust',
            name: 'adjust-manufactured-products',
            builder: (context, state) => const AdjustManufacturedProductsPage(),
          ),
          GoRoute(
            path: 'transfer',
            name: 'transfer-products',
            builder: (context, state) => const TransferProductsPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/online-shop',
        name: 'online-shop',
        builder: (context, state) => const OnlineShopDashboardPage(),
      ),
      GoRoute(
        path: '/online-shop/manage-products',
        name: 'online-shop-manage-products',
        builder: (context, state) => const OnlineShopManageProductsPage(),
      ),
      GoRoute(
        path: '/online-shop/manage-orders',
        name: 'online-shop-manage-orders',
        builder: (context, state) => const OnlineShopManageOrdersPage(),
      ),
      GoRoute(
        path: '/online-shop/order-details',
        name: 'online-shop-order-details',
        builder: (context, state) {
          final order = state.extra as Map<String, dynamic>;
          return OnlineShopOrderDetailsPage(order: order);
        },
      ),
      GoRoute(
        path: '/online-shop/coupons',
        name: 'online-shop-coupons',
        builder: (context, state) => const OnlineShopCouponCodesPage(),
      ),
      GoRoute(
        path: '/online-shop/coupons/add',
        name: 'online-shop-add-coupon',
        builder: (context, state) => const OnlineShopAddCouponPage(),
      ),
      GoRoute(
        path: '/online-shop/coupons/edit',
        name: 'online-shop-edit-coupon',
        builder: (context, state) {
          final extra = state.extra is Map ? Map<String, dynamic>.from(state.extra as Map) : null;
          return OnlineShopAddCouponPage(existingCoupon: extra);
        },
      ),
      GoRoute(
        path: '/online-shop/categories',
        name: 'online-shop-categories',
        builder: (context, state) => const OnlineShopCategoriesPage(),
      ),
      GoRoute(
        path: '/online-shop/categories/add',
        name: 'online-shop-add-category',
        builder: (context, state) => const OnlineShopAddCategoryPage(),
      ),
      GoRoute(
        path: '/online-shop/categories/edit',
        name: 'online-shop-edit-category',
        builder: (context, state) {
          final extra = state.extra is Map ? Map<String, dynamic>.from(state.extra as Map) : null;
          return OnlineShopAddCategoryPage(existingCategory: extra);
        },
      ),
      GoRoute(
        path: '/online-shop/delivery',
        name: 'online-shop-delivery',
        builder: (context, state) => const OnlineShopDeliveryMethodsPage(),
      ),
      GoRoute(
        path: '/online-shop/delivery/add',
        name: 'online-shop-add-delivery-method',
        builder: (context, state) => const OnlineShopAddDeliveryMethodPage(),
      ),
      GoRoute(
        path: '/online-shop/delivery/edit',
        name: 'online-shop-edit-delivery-method',
        builder: (context, state) {
          final extra = state.extra is Map ? Map<String, dynamic>.from(state.extra as Map) : null;
          return OnlineShopAddDeliveryMethodPage(existingMethod: extra);
        },
      ),
      GoRoute(
        path: '/online-shop/payments',
        name: 'online-shop-payments',
        builder: (context, state) => const OnlineShopPaymentMethodsPage(),
      ),
      GoRoute(
        path: '/online-shop/reports',
        name: 'online-shop-reports',
        builder: (context, state) => const OnlineShopReportsPage(),
      ),
      GoRoute(
        path: '/online-shop/settings',
        name: 'online-shop-settings',
        builder: (context, state) => const OnlineShopSettingsPage(),
      ),
      GoRoute(
        path: '/storefront',
        name: 'storefront',
        builder: (context, state) => const StorefrontPage(),
      ),
      GoRoute(
        path: '/product-details',
        name: 'product-details',
        builder: (context, state) {
          final product = state.extra as Map<String, dynamic>;
          return ProductDetailsPage(product: product);
        },
      ),
      GoRoute(
        path: '/shopping-cart',
        name: 'shopping-cart',
        builder: (context, state) {
          final cartItems = state.extra as List<Map<String, dynamic>>? ?? [];
          return ShoppingCartPage(cartItems: cartItems);
        },
      ),
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) {
          final cartItems = state.extra as List<Map<String, dynamic>>? ?? [];
          return OnlineShopCheckoutPage(cartItems: cartItems);
        },
      ),
      GoRoute(
        path: '/customers',
        name: 'customers',
        builder: (context, state) => const CustomersPage(),
        routes: [
          GoRoute(
            path: 'add',
            name: 'add-customer',
            builder: (context, state) {
              final customer = state.extra as dynamic;
              return AddCustomerPage(
                customer: customer,
              );
            },
          ),
          GoRoute(
            path: ':customerId/dashboard',
            name: 'customer-dashboard',
            builder: (context, state) {
              final customer = state.extra as Customer;
              return CustomerDashboardPage(
                customer: customer,
              );
            },
          ),
          GoRoute(
            path: 'wallet',
            name: 'customers-wallet',
            builder: (context, state) => const CustomersWalletPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/suppliers',
        name: 'suppliers',
        builder: (context, state) => const SuppliersPage(),
        routes: [
          GoRoute(
            path: 'add',
            name: 'add-supplier',
            builder: (context, state) {
              final supplier = state.extra as dynamic;
              return AddSupplierPage(
                supplier: supplier,
              );
            },
          ),
          GoRoute(
            path: ':supplierId/dashboard',
            name: 'supplier-dashboard',
            builder: (context, state) {
              final supplier = state.extra as Supplier;
              return SupplierDashboardPage(
                supplier: supplier,
              );
            },
          ),
        ],
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
            builder: (context, state) {
              final product = state.extra as Map<String, dynamic>?;
              return AddProductPage(product: product);
            },
          ),
          GoRoute(
            path: 'import-from-shop',
            name: 'import-from-shop',
            builder: (context, state) => const ImportFromShopPage(),
          ),
          GoRoute(
            path: 'purchase',
            name: 'purchase-stock',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final editMode = extra?['editMode'] as bool? ?? false;
              final createMode = extra?['createMode'] as bool? ?? false;
              final poNumber = extra?['poNumber'] as String?;
              final supplier = extra?['supplier'] as String?;
              final products = extra?['products'] as List<Map<String, dynamic>>?;
              final initialProduct = extra?['initialProduct'] as Map<String, dynamic>?;
              return PurchaseStockPage(
                initialProduct: initialProduct,
                editMode: editMode,
                createMode: createMode,
                poNumber: poNumber,
                initialSupplier: supplier,
                editProducts: products,
              );
            },
          ),
        ],
      ),
    ],
  );
});
