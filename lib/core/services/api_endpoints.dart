/// DukaApp API Endpoint Registry
///
/// Single source of truth for every API endpoint used by the mobile app.
/// All paths are relative to [ApiConfig.baseUrl] (https://dukaapp.net).
///
/// ─── Groups ─────────────────────────────────────────────────────────────────
///
///   auth*        — /api/v1/app/auth/*  (no Bearer token required)
///   getData*     — GET  /api/v1/app/get/getdata/{key}   (key-based dispatch)
///   getReport*   — GET  /api/v1/app/get/getreport/{key} (aggregated reports)
///   getMapped*   — GET  /api/v1/app/get/{path}          (controller-backed)
///   post*        — POST /api/v1/app/post/postdata/{key} (all write actions)
///
/// ─── Usage ───────────────────────────────────────────────────────────────────
///
///   final res = await client.get(ApiEndpoints.getDataDashboard);
///   await client.post(ApiEndpoints.postSalesAdd, data: payload);
///   await client.get(ApiEndpoints.getMappedStockPurchaseRecord('42'));
///
/// ─── Server-side dispatch ────────────────────────────────────────────────────
///
///   getdata   → application/helpers/query/data_helper.php    (switch/case)
///   getreport → application/helpers/query/reports_helper.php (switch/case)
///   postdata  → Post.php::postEndpointMap()                  (controller dispatch)
///   GET mapped→ Get.php::getEndpointMap()                    (controller dispatch)

import 'package:dukaapp/core/config/api_config.dart';

// ignore_for_file: non_constant_identifier_names

abstract final class ApiEndpoints {
  ApiEndpoints._();

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTH  —  /api/v1/app/auth/*
  // Public endpoints — no Bearer token required.
  // ═══════════════════════════════════════════════════════════════════════════

  /// POST — sign in with username / phone / email + password.
  /// Response: {status, token, data:{user, shop, shops}}
  static const authSignin = '${ApiConfig.appApiBase}/auth/signin';

  /// POST — register new account + first shop.
  /// Response: {status, token, data:{user, shop, shops}}
  static const authRegister = '${ApiConfig.appApiBase}/auth/register';

  /// POST — add a new shop to an existing account (requires token).
  static const authAddShop = '${ApiConfig.appApiBase}/auth/addshop';

  /// POST — switch the active shop for the current session.
  static String authSwitchShop(String shopId) =>
      '${ApiConfig.appApiBase}/auth/switchshop/$shopId';

  /// POST — send OTP / password-reset link (public).
  static const authResetSend = '${ApiConfig.appApiBase}/auth/reset/send';

  /// GET — invalidate the server-side session.
  static const authSignout = '${ApiConfig.appApiBase}/auth/signout';

  /// GET — business categories, shop types and other signup constants (public).
  static const authConstants = '${ApiConfig.appApiBase}/auth/constants';

  // ═══════════════════════════════════════════════════════════════════════════
  // GET DATA  —  GET /api/v1/app/get/getdata/{key}
  // All require Bearer token. Server returns raw JSON (no {status/data} wrapper).
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Session / shop ──────────────────────────────────────────────────────

  /// Current role's full session row (roles + users JOIN).
  /// Used to validate session and read permission flags (can_*).
  static final getDataSessionUser = _g('session_user');

  /// Current shop's session row.
  static final getDataSessionShop = _g('session_shop');

  /// All shops the authenticated user has access to.
  static final getDataMyShops = _g('my_shops');

  /// Shop-level settings (VAT, currency, feature flags, …).
  static final getDataShopSettings = _g('shop_settings');

  /// Sidebar / navigation menu items for the current role.
  static final getDataSideMenu = _g('sidemenu');

  /// Date-filter presets (today, this week, this month, …).
  static final getDataFilterRange = _g('filter_range');

  /// All permission keys and display labels.
  static final getDataPermissions = _g('permissions');

  // ── Dashboard ─────────────────────────────────────────────────────────

  /// Today's summary totals: sales, profit, expense, stockin, orders, …
  static final getDataDashboard = _g('dashboard');

  // ── Stock / products ─────────────────────────────────────────────────

  /// All products for the current shop.
  static final getDataProducts = _g('products');

  /// Full stock ledger (products + quantities + costs).
  static final getDataStock = _g('stock');

  /// Stock category list.
  static final getDataStockCategory = _g('stock_category');

  /// Stock grouped by category.
  static final getDataStockCategoryWise = _g('stockCategoryWise');

  /// Products at or below their reorder level.
  static final getDataLowStock = _g('low_stock');

  /// Products whose expiry date has passed.
  static final getDataExpiredStock = _g('expired_stock');

  /// Soft-deleted products.
  static final getDataDeletedStock = _g('deleted_stock');

  /// Products that can be sold (positive qty, not expired, not deleted).
  static final getDataSellableStock = _g('sellable_stock');

  /// Product price / cost history log.
  static final getDataProductHistory = _g('product_history');

  /// Stock value summary (total cost, total retail value).
  static final getDataStockValueSummary = _g('stock_value_summary');

  /// CSV bulk-import history.
  static final getDataImportHistory = _g('importHistory');

  // ── Sales ─────────────────────────────────────────────────────────────

  /// All sales for the current shop (respects active date filter).
  static final getDataSales = _g('sales');

  /// Sales summary card totals for the selected period.
  static final getDataSalesSummary = _g('sales_summary');

  /// Customer invoices.
  static final getDataInvoices = _g('invoices');

  /// Invoice summary (count, total value).
  static final getDataInvoiceSummary = _g('invoice_summary');

  /// Open table / bar orders.
  static final getDataOrders = _g('orders');

  /// Sales orders list.
  static final getDataSalesOrders = _g('sales_orders');

  /// Order summary card data.
  static final getDataOrderSummary = _g('order_summary');

  /// Products currently in a specific open order.
  static final getDataProductsInOrder = _g('productsInOrder');

  /// Soft-deleted sale records.
  static final getDataDeletedSales = _g('deleted_sales');

  // ── Purchases ─────────────────────────────────────────────────────────

  /// All purchase (stock-in) records.
  static final getDataPurchaseHistory = _g('purchase_history');

  /// Purchase summary totals.
  static final getDataPurchaseSummary = _g('purchase_summary');

  /// Open purchase orders (to receive from suppliers).
  static final getDataPurchaseOrders = _g('purchase_orders');

  /// Purchase order summary card data.
  static final getDataPurchaseOrderSummary = _g('purchase_order_summary');

  // ── Profit / expenses ─────────────────────────────────────────────────

  /// Profit summary (revenue − cost of goods sold).
  static final getDataProfitSummary = _g('profit_summary');

  /// Expense account list (Rent, Salary, Utilities, …).
  static final getDataExpenseAccounts = _g('expense_accounts');

  /// Expense records (respects date filter).
  static final getDataExpenses = _g('expenses');

  /// Expense summary totals.
  static final getDataExpenseSummary = _g('expense_summary');

  // ── Cashflow / accounts ───────────────────────────────────────────────

  /// Cashflow ledger entries (cash-in / cash-out).
  static final getDataCashflow = _g('cashflow');

  /// Cashflow summary (total in, total out, net balance).
  static final getDataCashflowSummary = _g('cashflow_summary');

  /// Cashbook accounts (petty-cash sub-accounts).
  static final getDataCashbookAccounts = _g('cashbookAccounts');

  /// Chart of accounts.
  static final getDataChartOfAccounts = _g('chatOfAccounts');

  /// Source-of-fund accounts.
  static final getDataSourceOfFundAccounts = _g('sourceOfFundAccounts');

  // ── Customers ─────────────────────────────────────────────────────────

  /// All customers.
  static final getDataCustomers = _g('customers');

  /// Customers with outstanding credit balances.
  static final getDataOncreditCustomers = _g('oncredit_customers');

  /// Customers who pay cash.
  static final getDataOncashCustomers = _g('oncash_customers');

  /// Contact list (broader than sales customers).
  static final getDataContacts = _g('contacts');

  /// Contact categories.
  static final getDataContactCategory = _g('contact_category');

  // ── Suppliers ─────────────────────────────────────────────────────────

  /// All suppliers.
  static final getDataSuppliers = _g('suppliers');

  /// Suppliers with outstanding credit.
  static final getDataOncreditSuppliers = _g('oncredit_suppliers');

  /// Cash-only suppliers.
  static final getDataOncashSuppliers = _g('oncash_suppliers');

  // ── Team / staff ──────────────────────────────────────────────────────

  /// Team members (attendants + managers) for the current shop.
  static final getDataTeam = _g('team');

  /// Waiters / bar staff list.
  static final getDataWaiters = _g('waiters');

  /// All shop records (admin view).
  static final getDataShops = _g('shops');

  /// All user accounts.
  static final getDataUsers = _g('users');

  // ── Payment ───────────────────────────────────────────────────────────

  /// Payment modes (Cash, M-Pesa, Card, Bank Transfer, …).
  static final getDataPaymentMode = _g('payment_mode');

  // ── Subscriptions / packages ──────────────────────────────────────────

  /// Available subscription packages.
  static final getDataPackages = _g('packages');

  /// Lines of business / business categories.
  static final getDataLobs = _g('lobs');

  // ── Manufacturing ─────────────────────────────────────────────────────

  /// Manufacturing dashboard KPI summary.
  static final getDataMfSummary             = _g('mf_summary');

  /// Raw materials inventory list.
  static final getDataMfRawMaterials        = _g('mf_raw_materials');

  /// Production recipe list.
  static final getDataMfRecipes             = _g('mf_recipes');

  /// Finished/manufactured products.
  static final getDataMfManufacturedProducts = _g('mf_manufactured_products');

  /// Daily production log.
  static final getDataMfDailyProduction     = _g('mf_daily_production');

  /// Raw material consumption per production run.
  static final getDataMfRawConsumption      = _g('mf_raw_consumption');

  /// Cost analysis per product / recipe.
  static final getDataMfCostAnalysis        = _g('mf_cost_analysis');

  /// Raw materials that are low in stock.
  static final getDataMfLowStockAlerts      = _g('mf_low_stock_alerts');

  /// Production output grouped by recipe.
  static final getDataMfProductionByRecipe  = _g('mf_production_by_recipe');

  // ── Online shop ───────────────────────────────────────────────────────

  /// Online-shop admin data (orders, products, payment accounts, …).
  static final getDataOnlineShopAdmin = _g('online_shop_admin');

  // ── System / storage ─────────────────────────────────────────────────

  /// Storage quota summary (used / available).
  static final getDataStorageSummary = _g('storage_summary');

  /// Detailed storage usage per folder.
  static final getDataStorageUsage   = _g('storage_usage');

  /// Server system info (PHP, MySQL, OS versions).
  static final getDataSystemInfo     = _g('systeminfo');

  /// Activity / audit log entries.
  static final getDataLogs           = _g('logs');

  // ── TMS ───────────────────────────────────────────────────────────────

  /// TMS loan-eligibility data.
  static final getDataTms = _g('tms');

  // ── Super admin ───────────────────────────────────────────────────────

  static final getDataSuperadminDashboard = _g('superadmin_dashboard');
  static final getDataSuperadminShops     = _g('superadmin_shops');
  static final getDataSuperadminCustomers = _g('superadmin_customers');
  static final getDataSuperadminAgents    = _g('superadmin_agents');
  static final getDataSuperadminServer    = _g('superadmin_server');
  static final getDataSuperadminProfile   = _g('superadmin_profile');
  static final getDataSuperadminPackages  = _g('superadmin_packages');

  // ═══════════════════════════════════════════════════════════════════════════
  // GET REPORT  —  GET /api/v1/app/get/getreport/{key}
  // Heavier aggregated reports (bypass getdata cache).
  // ═══════════════════════════════════════════════════════════════════════════

  static final getReportSales     = _r('sales');
  static final getReportProfit    = _r('profit');
  static final getReportExpenses  = _r('expenses');
  static final getReportCashflow  = _r('cashflow');
  static final getReportPurchases = _r('purchases');
  static final getReportStock     = _r('stock');
  static final getReportCustomers = _r('customers');
  static final getReportSuppliers = _r('suppliers');
  static final getReportTeam      = _r('team');

  // ── Sales sub-reports (getreport/{method}) ────────────────────────────────
  /// Dynamic sales sub-report: totalSales, creditSales, allOrders, invoiceSales,
  /// salesByPaymentMode, salesByCategory, salesByProduct, unpaidSalesByProduct,
  /// staffSalesByItems, individualTeamSales, salesByCustomer, salesByStaff,
  /// combinedSalesByStaff, combinedTotalSales, oncreditCustomers,
  /// salesWithVat, salesWithoutVat.
  static String getReportSalesByMethod(String method) => _r(method);

  // ═══════════════════════════════════════════════════════════════════════════
  // GET MAPPED  —  GET /api/v1/app/get/getdata/{path}
  // Controller-backed GET routes with typed parameters.
  // ═══════════════════════════════════════════════════════════════════════════

  /// GET single purchase record by ID.
  static String getMappedStockPurchaseRecord(String purchaseId) =>
      '${ApiConfig.appApiBase}/get/getdata/stock/purchase-record?purchase_id=$purchaseId';

  /// GET stock lob (line-of-business) categories.
  static const getMappedStockLobCategories =
      '${ApiConfig.appApiBase}/get/getdata/stock/lob-categories';

  /// GET single sale record by ID.
  static String getMappedSalesSaleRecord(String saleId) =>
      '${ApiConfig.appApiBase}/get/getdata/sales/sale-record?sale_id=$saleId';

  /// GET attendant access-schedule settings.
  static const getMappedSettingsAttendantSettings =
      '${ApiConfig.appApiBase}/get/getdata/settings/attendant-settings';

  /// GET customer wallet statement by customer ID.
  static String getMappedWalletCustomerStatement(String customerId) =>
      '${ApiConfig.appApiBase}/get/getdata/wallet/customer-statement?customer_id=$customerId';

  /// GET customer sales statement by customer ID.
  static String getMappedWalletCustomerSalesStatement(String customerId) =>
      '${ApiConfig.appApiBase}/get/getdata/wallet/customer-sales-statement?customer_id=$customerId';

  /// GET products belonging to a specific (remote) shop — used by import-from-shop
  /// and transfer flows. Requires [shopId] (not the session shop).
  static String getMappedStockRemoteProducts(String shopId) =>
      '${ApiConfig.appApiBase}/get/getdata/stock/remote-products?shop_id=$shopId';

  // ═══════════════════════════════════════════════════════════════════════════
  // POST  —  POST /api/v1/app/post/postdata/{key}
  // All write actions. Bearer token required unless noted.
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Banking ───────────────────────────────────────────────────────────
  static final postBankingCustomerTransaction = _p('banking/customer-transaction');

  // ── Cashflow ──────────────────────────────────────────────────────────

  /// Add a cash-in or cash-out fund entry.
  static final postCashflowAddFund    = _p('cashflow/add-fund');

  /// Record a new expense.
  static final postCashflowAddExpense = _p('cashflow/add-expense');

  /// Delete an expense entry.
  static final postCashflowDeleteExpense = _p('cashflow/delete-expense');

  // ── Customers ─────────────────────────────────────────────────────────
  static final postCustomerCreate         = _p('customer/create');
  static final postCustomerImport         = _p('customer/import');
  static final postCustomerCategoryCreate = _p('customer/category/create');
  static final postCustomerContactCreate  = _p('customer/contact/create');
  static final postCustomerSendBulkSms    = _p('customer/sms/send-bulk');
  static final postCustomerBulkDelete     = _p('customer/bulk-delete');

  // ── Manufacturing ─────────────────────────────────────────────────────
  static final postMfRawMaterialSave     = _p('manufacturing/raw-material/save');
  static final postMfRawMaterialRestock  = _p('manufacturing/raw-material/restock');
  static final postMfRawMaterialAdjust   = _p('manufacturing/raw-material/adjust');
  static final postMfRawMaterialDelete   = _p('manufacturing/raw-material/delete');
  static final postMfRecipeSave          = _p('manufacturing/recipe/save');
  static final postMfRecipeDelete        = _p('manufacturing/recipe/delete');
  static final postMfProductionSave      = _p('manufacturing/production/save');
  static final postMfProductionReproduce = _p('manufacturing/production/reproduce');
  static final postMfProductionTransfer  = _p('manufacturing/production/transfer');
  static final postMfProductionAdjust    = _p('manufacturing/production/adjust');
  static final postMfProductionDelete    = _p('manufacturing/production/delete');

  // ── Microfinance ──────────────────────────────────────────────────────
  static final postMicrofinanceLoanProductCreate = _p('microfinance/loan-product/create');
  static final postMicrofinanceGuarantorCreate   = _p('microfinance/guarantor/create');
  static final postMicrofinanceImport            = _p('microfinance/import');
  static final postMicrofinanceCategoryCreate    = _p('microfinance/category/create');
  static final postMicrofinanceContactCreate     = _p('microfinance/contact/create');
  static final postMicrofinanceSendBulkSms       = _p('microfinance/sms/send-bulk');
  static final postMicrofinanceLoanRecordCreate  = _p('microfinance/loan-record/create');
  static final postMicrofinanceLoanRecordUpdate  = _p('microfinance/loan-record/update');

  // ── Online shop ───────────────────────────────────────────────────────
  static final postOnlineshopCouponSave           = _p('onlineshop/coupon/save');
  static final postOnlineshopCouponDelete         = _p('onlineshop/coupon/delete');
  static final postOnlineshopPaymentAccountSave   = _p('onlineshop/payment-account/save');
  static final postOnlineshopPaymentAccountDelete = _p('onlineshop/payment-account/delete');
  static final postOnlineshopCategorySave         = _p('onlineshop/category/save');
  static final postOnlineshopCategoryDelete       = _p('onlineshop/category/delete');
  static final postOnlineshopDeliveryMethodSave   = _p('onlineshop/delivery-method/save');
  static final postOnlineshopDeliveryMethodDelete = _p('onlineshop/delivery-method/delete');
  static final postOnlineshopOrderUpdateStatus    = _p('onlineshop/order/update-status');

  // ── Sales ─────────────────────────────────────────────────────────────

  /// Create a new sale. Body: {items:[...], customer_id?, payment_mode, …}
  static final postSalesAdd          = _p('sales/add');

  /// Update an existing sale.
  static final postSalesUpdate       = _p('sales/update');

  /// Add a partial / full payment to a credit sale.
  static final postSalesAddPayment   = _p('sales/add-payment');

  /// Soft-delete a sale record.
  static final postSalesDeleteRecord = _p('sales/delete-record');

  /// Backdate a sale to a previous date.
  static final postSalesBackdate     = _p('sales/backdate');

  /// Bulk delete sales records.
  static final postSalesBulkDelete   = _p('sales/bulk-delete');

  /// Update a table-order status (open → served → closed).
  static final postSalesUpdateOrderStatus = _p('sales/update-order-status');

  // ── Settings ──────────────────────────────────────────────────────────
  static final postSettingsAccountCreate       = _p('settings/account/create');
  static final postSettingsRecordUpdate        = _p('settings/record/update');
  static final postSettingsShopUpdate          = _p('settings/shop/update');
  static final postSettingsRecordDelete        = _p('settings/record/delete');
  static final postSettingsAccountDelete       = _p('settings/account/delete');
  static final postSettingsProfileUpdate       = _p('settings/profile/update');
  static final postSettingsShopSettingsSave    = _p('settings/shop-settings/save');
  static final postSettingsEfdVerify           = _p('settings/efd/verify');
  static final postSettingsBackupCreate        = _p('settings/backup/create');
  static final postSettingsPreferencesSave     = _p('settings/preferences/save');
  static final postSettingsAttendantSaveAccess = _p('settings/attendant/save-access');
  static final postSettingsDataUsageTrack      = _p('settings/data-usage/track');
  static final postSettingsLastSeenPing        = _p('settings/lastseen/ping');

  // ── Stock ─────────────────────────────────────────────────────────────

  /// Register (create) a new product.
  static final postStockRegisterCreate  = _p('stock/register/create');

  /// Bulk-import products from CSV.
  static final postStockRegisterImport  = _p('stock/register/import');

  /// Stock-in: receive new inventory (purchase from supplier).
  static final postStockRestockCreate   = _p('stock/restock/create');

  /// Direct stock balance adjustment.
  static final postStockRestockBalance  = _p('stock/restock/balance');

  /// Update product details (name, price, category, barcode, …).
  static final postStockProductUpdate   = _p('stock/product/update');

  /// Remove a product's photo.
  static final postStockProductDeletePhoto = _p('stock/product/delete-photo');

  /// Bulk delete products.
  static final postStockProductBulkDelete  = _p('stock/product/bulk-delete');

  /// Create a new stock category.
  static final postStockCategoryCreate  = _p('stock/category/create');

  /// Transfer stock between warehouses / locations.
  static final postStockTransfer        = _p('stock/transfer');

  /// Copy products from another shop into this one.
  static final postStockCopyInProducts  = _p('stock/copy-in-products');

  /// Return an entire purchase batch to the supplier.
  static final postStockPurchaseReturnToSupplier = _p('stock/purchase/return-to-supplier');

  /// Return a single purchase line item.
  static final postStockPurchaseReturnItem       = _p('stock/purchase/return-item');

  /// Backdate a purchase record.
  static final postStockPurchaseBackdate         = _p('stock/purchase/backdate');

  /// Bulk delete purchase records.
  static final postStockPurchaseBulkDelete       = _p('stock/purchase/bulk-delete');

  /// Clear outstanding credit balance with a supplier.
  static final postStockPurchaseClearCreditBalance = _p('stock/purchase/clear-credit-balance');

  /// Update a purchase order status (pending → received, …).
  static final postStockPurchaseUpdateOrderStatus  = _p('stock/purchase/update-order-status');

  /// Delete a CSV import batch.
  static final postStockImportDelete = _p('stock/import/delete');

  // ── Suppliers ─────────────────────────────────────────────────────────

  /// Add a new supplier.
  static final postSupplierAdd               = _p('supplier/add');

  /// Bulk delete suppliers.
  static final postSupplierBulkDelete        = _p('supplier/bulk-delete');

  /// Clear a supplier's credit balance.
  static final postSupplierClearCreditBalance = _p('supplier/clear-credit-balance');

  // ── Team ──────────────────────────────────────────────────────────────

  /// Create a waiter / bar-staff account.
  static final postTeamWaiterCreate     = _p('team/waiter/create');

  /// Add an attendant or manager to the current shop.
  static final postTeamStaffAdd         = _p('team/staff/add');

  /// Add a non-staff member (e.g. commission-only).
  static final postTeamNonStaffAdd      = _p('team/nonstaff/add');

  /// Update a team member's profile.
  static final postTeamMemberUpdate     = _p('team/member/update');

  /// Enable / disable a team member's access.
  static final postTeamStatusUpdate     = _p('team/status/update');

  /// Toggle a single permission flag for an attendant.
  /// Body: {role_id, col, status}
  static final postTeamPermissionUpdate = _p('team/permission/update');

  /// Soft-delete an attendant role (also soft-deletes the user if no
  /// other active roles remain). Body: {role_id}
  static final postTeamAttendantDelete  = _p('team/attendant/delete');

  // ── Upload ────────────────────────────────────────────────────────────

  /// Upload shop logo (multipart/form-data). Body: file field "logo".
  static final postUploadLogo = _p('upload/logo');

  // ── Wallet ────────────────────────────────────────────────────────────

  /// Create a customer wallet / credit transaction.
  static final postWalletCustomerCreate = _p('wallet/customer/create');

  /// Update a customer wallet transaction.
  static final postWalletCustomerUpdate = _p('wallet/customer/update');

  /// Delete a customer wallet transaction.
  static final postWalletCustomerDelete = _p('wallet/customer/delete');

  /// Create a supplier wallet transaction.
  static final postWalletSupplierCreate = _p('wallet/supplier/create');

  // ═══════════════════════════════════════════════════════════════════════════
  // TMS (direct controller endpoints — not postdata/getdata)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Submit a TMS loan eligibility application.
  static const String postTmsApply = '${ApiConfig.appApiBase}/Tms/eligibility';

  // ═══════════════════════════════════════════════════════════════════════════
  // Private helpers
  // ═══════════════════════════════════════════════════════════════════════════

  static String _g(String key) => ApiConfig.getData(key);
  static String _r(String key) => ApiConfig.getReport(key);
  static String _p(String key) => ApiConfig.postData(key);
}
