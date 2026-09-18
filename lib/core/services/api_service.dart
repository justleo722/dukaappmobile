/// DukaApp ApiService
///
/// Single facade for every HTTP call the app makes.
/// Wraps [ApiClient] and maps each [ApiEndpoints] constant to a named method
/// so feature datasources never build URLs manually.
///
/// ─── Conventions ────────────────────────────────────────────────────────────
///
///   • GET  methods return the raw [Response] — callers parse `.data`.
///   • POST methods return [Map<String,dynamic>] (the parsed JSON body).
///   • Parameterised methods accept typed arguments; no string interpolation
///     inside feature code.
///   • Date filters: pass [from] / [to] as 'YYYY-MM-DD'. The server reads
///     them from query params `?from=&to=` on every getdata/getreport call.
///   • Upload methods accept [FormData] and an optional progress callback.
///
/// ─── Usage ───────────────────────────────────────────────────────────────────
///
///   // Inject via Riverpod (see core/providers.dart)
///   final svc = ref.read(apiServiceProvider);
///
///   // Read data
///   final res  = await svc.getDashboard();
///   final list = res.data as List;
///
///   // Write
///   final body = await svc.postSalesAdd({'items': [...], 'payment_mode': 'cash'});
///   if (body['status'] == true) { ... }

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dukaapp/core/network/api_client.dart';
import 'package:dukaapp/core/config/api_config.dart';
import 'package:dukaapp/core/services/api_endpoints.dart';

class ApiService {
  const ApiService(this._client);

  final ApiClient _client;

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTH
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sign in — phone / email / username + password.
  /// Response data: {token, data:{user, shop, shops}}
  Future<Map<String, dynamic>> authSignin(Map<String, dynamic> body) =>
      _post(ApiEndpoints.authSignin, body);

  /// Register a new account + first shop.
  Future<Map<String, dynamic>> authRegister(Map<String, dynamic> body) =>
      _post(ApiEndpoints.authRegister, body);

  /// Add a new shop to an existing account.
  Future<Map<String, dynamic>> authAddShop(Map<String, dynamic> body) =>
      _post(ApiEndpoints.authAddShop, body);

  /// Switch the active shop for the current session.
  Future<Map<String, dynamic>> authSwitchShop(String shopId) =>
      _post(ApiEndpoints.authSwitchShop(shopId), {});

  /// Send OTP / password-reset link.
  Future<Map<String, dynamic>> authResetSend(Map<String, dynamic> body) =>
      _post(ApiEndpoints.authResetSend, body);

  /// Invalidate the server-side session.
  Future<Response> authSignout() =>
      _client.get(ApiEndpoints.authSignout);

  /// Fetch signup constants (business categories, shop types, …).
  Future<Response> authConstants() =>
      _client.get(ApiEndpoints.authConstants);

  // ═══════════════════════════════════════════════════════════════════════════
  // SESSION / SHOP
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch the current role row with all permission flags (can_*).
  Future<Response> getSessionUser() =>
      _client.get(ApiEndpoints.getDataSessionUser);

  /// Fetch the current shop row.
  Future<Response> getSessionShop() =>
      _client.get(ApiEndpoints.getDataSessionShop);

  /// All shops the authenticated user has access to.
  Future<Response> getMyShops() =>
      _client.get(ApiEndpoints.getDataMyShops);

  /// Shop-level settings (VAT, currency, features, …).
  Future<Response> getShopSettings() =>
      _client.get(ApiEndpoints.getDataShopSettings);

  /// Navigation menu items for the current role.
  Future<Response> getSideMenu() =>
      _client.get(ApiEndpoints.getDataSideMenu);

  /// Date-filter presets.
  Future<Response> getFilterRange() =>
      _client.get(ApiEndpoints.getDataFilterRange);

  /// All permission keys and labels.
  Future<Response> getPermissions() =>
      _client.get(ApiEndpoints.getDataPermissions);

  // ═══════════════════════════════════════════════════════════════════════════
  // DASHBOARD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Today's summary totals: sales, profit, expense, stockin, orders, …
  Future<Response> getDashboard() =>
      _client.get(ApiEndpoints.getDataDashboard);

  // ═══════════════════════════════════════════════════════════════════════════
  // STOCK / PRODUCTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// All products for the current shop.
  Future<Response> getProducts({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataProducts, queryParameters: _range(from, to));

  /// Full stock ledger (products + quantities + costs).
  Future<Response> getStock({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataStock, queryParameters: _range(from, to));

  /// Stock category list.
  Future<Response> getStockCategory() =>
      _client.get(ApiEndpoints.getDataStockCategory);

  /// Stock grouped by category.
  Future<Response> getStockCategoryWise() =>
      _client.get(ApiEndpoints.getDataStockCategoryWise);

  /// Products at or below their reorder level.
  Future<Response> getLowStock() =>
      _client.get(ApiEndpoints.getDataLowStock);

  /// Products whose expiry date has passed.
  Future<Response> getExpiredStock() =>
      _client.get(ApiEndpoints.getDataExpiredStock);

  /// Soft-deleted products.
  Future<Response> getDeletedStock() =>
      _client.get(ApiEndpoints.getDataDeletedStock);

  /// Products that can be sold (positive qty, not expired, not deleted).
  Future<Response> getSellableStock() =>
      _client.get(ApiEndpoints.getDataSellableStock);

  /// Product price / cost history log.
  Future<Response> getProductHistory() =>
      _client.get(ApiEndpoints.getDataProductHistory);

  /// Stock value summary (total cost, total retail value).
  Future<Response> getStockValueSummary() =>
      _client.get(ApiEndpoints.getDataStockValueSummary);

  /// CSV bulk-import history.
  Future<Response> getImportHistory() =>
      _client.get(ApiEndpoints.getDataImportHistory);

  /// Single purchase record by ID (controller-backed).
  Future<Response> getStockPurchaseRecord(String purchaseId) =>
      _client.get(ApiEndpoints.getMappedStockPurchaseRecord(purchaseId));

  /// Stock lob (line-of-business) categories.
  Future<Response> getStockLobCategories() =>
      _client.get(ApiEndpoints.getMappedStockLobCategories);

  // ── Stock writes ──────────────────────────────────────────────────────────

  /// Register (create) a new product.
  Future<Map<String, dynamic>> postStockRegisterCreate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postStockRegisterCreate, body);

  /// Bulk-import products from CSV.
  Future<Map<String, dynamic>> postStockRegisterImport(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postStockRegisterImport, body);

  /// Stock-in: receive new inventory (purchase from supplier).
  Future<Map<String, dynamic>> postStockRestockCreate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postStockRestockCreate, body);

  /// Direct stock balance adjustment.
  Future<Map<String, dynamic>> postStockRestockBalance(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postStockRestockBalance, body);

  /// Update product details (name, price, category, barcode, …).
  Future<Map<String, dynamic>> postStockProductUpdate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postStockProductUpdate, body);

  /// Remove a product's photo.
  Future<Map<String, dynamic>> postStockProductDeletePhoto(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postStockProductDeletePhoto, body);

  /// Bulk delete products.
  Future<Map<String, dynamic>> postStockProductBulkDelete(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postStockProductBulkDelete, body);

  /// Create a new stock category.
  Future<Map<String, dynamic>> postStockCategoryCreate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postStockCategoryCreate, body);

  /// Transfer stock between warehouses / locations.
  Future<Map<String, dynamic>> postStockTransfer(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postStockTransfer, body);

  /// Copy products from another shop.
  Future<Map<String, dynamic>> postStockCopyInProducts(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postStockCopyInProducts, body);

  /// Return an entire purchase batch to the supplier.
  Future<Map<String, dynamic>> postStockPurchaseReturnToSupplier(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postStockPurchaseReturnToSupplier, body);

  /// Return a single purchase line item.
  Future<Map<String, dynamic>> postStockPurchaseReturnItem(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postStockPurchaseReturnItem, body);

  /// Backdate a purchase record.
  Future<Map<String, dynamic>> postStockPurchaseBackdate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postStockPurchaseBackdate, body);

  /// Bulk delete purchase records.
  Future<Map<String, dynamic>> postStockPurchaseBulkDelete(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postStockPurchaseBulkDelete, body);

  /// Clear outstanding credit balance with a supplier.
  Future<Map<String, dynamic>> postStockPurchaseClearCreditBalance(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postStockPurchaseClearCreditBalance, body);

  /// Update a purchase order status (pending → received, …).
  Future<Map<String, dynamic>> postStockPurchaseUpdateOrderStatus(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postStockPurchaseUpdateOrderStatus, body);

  /// Delete a CSV import batch.
  Future<Map<String, dynamic>> postStockImportDelete(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postStockImportDelete, body);

  // ═══════════════════════════════════════════════════════════════════════════
  // SALES
  // ═══════════════════════════════════════════════════════════════════════════

  /// All sales for the current shop (respects date filter).
  Future<Response> getSales({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataSales, queryParameters: _range(from, to));

  /// Sales summary card totals.
  Future<Response> getSalesSummary({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataSalesSummary, queryParameters: _range(from, to));

  /// Customer invoices.
  Future<Response> getInvoices({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataInvoices, queryParameters: _range(from, to));

  /// Invoice summary (count, total value).
  Future<Response> getInvoiceSummary({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataInvoiceSummary, queryParameters: _range(from, to));

  /// Open table / bar orders.
  Future<Response> getOrders({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataOrders, queryParameters: _range(from, to));

  /// Sales orders list.
  Future<Response> getSalesOrders({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataSalesOrders, queryParameters: _range(from, to));

  /// Order summary card data.
  Future<Response> getOrderSummary({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataOrderSummary, queryParameters: _range(from, to));

  /// Products currently in a specific open order.
  Future<Response> getProductsInOrder({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataProductsInOrder, queryParameters: _range(from, to));

  /// Soft-deleted sale records.
  Future<Response> getDeletedSales({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataDeletedSales, queryParameters: _range(from, to));

  /// Single sale record by ID (controller-backed).
  Future<Response> getSaleRecord(String saleId) =>
      _client.get(ApiEndpoints.getMappedSalesSaleRecord(saleId));

  // ── Sales writes ──────────────────────────────────────────────────────────

  /// Create a new sale. Body: {items:[{product_id, qty, price}], payment_mode, customer_id?, …}
  Future<Map<String, dynamic>> postSalesAdd(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postSalesAdd, body);

  /// Update an existing sale.
  Future<Map<String, dynamic>> postSalesUpdate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postSalesUpdate, body);

  /// Add a partial / full payment to a credit sale.
  Future<Map<String, dynamic>> postSalesAddPayment(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postSalesAddPayment, body);

  /// Soft-delete a sale record.
  Future<Map<String, dynamic>> postSalesDeleteRecord(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postSalesDeleteRecord, body);

  /// Backdate a sale to a previous date.
  Future<Map<String, dynamic>> postSalesBackdate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postSalesBackdate, body);

  /// Bulk delete sales records.
  Future<Map<String, dynamic>> postSalesBulkDelete(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postSalesBulkDelete, body);

  /// Update a table-order status (open → served → closed).
  Future<Map<String, dynamic>> postSalesUpdateOrderStatus(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postSalesUpdateOrderStatus, body);

  // ═══════════════════════════════════════════════════════════════════════════
  // PURCHASES
  // ═══════════════════════════════════════════════════════════════════════════

  /// All purchase (stock-in) records.
  Future<Response> getPurchaseHistory({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataPurchaseHistory, queryParameters: _range(from, to));

  /// Purchase summary totals.
  Future<Response> getPurchaseSummary({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataPurchaseSummary, queryParameters: _range(from, to));

  /// Open purchase orders (to receive from suppliers).
  Future<Response> getPurchaseOrders({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataPurchaseOrders, queryParameters: _range(from, to));

  /// Purchase order summary card data.
  Future<Response> getPurchaseOrderSummary({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataPurchaseOrderSummary, queryParameters: _range(from, to));

  // ═══════════════════════════════════════════════════════════════════════════
  // PROFIT / EXPENSES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Profit summary (revenue − cost of goods sold).
  Future<Response> getProfitSummary({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataProfitSummary, queryParameters: _range(from, to));

  /// Expense account list (Rent, Salary, Utilities, …).
  Future<Response> getExpenseAccounts() =>
      _client.get(ApiEndpoints.getDataExpenseAccounts);

  /// Expense records (respects date filter).
  Future<Response> getExpenses({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataExpenses, queryParameters: _range(from, to));

  /// Expense summary totals.
  Future<Response> getExpenseSummary({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataExpenseSummary, queryParameters: _range(from, to));

  // ── Expense writes ────────────────────────────────────────────────────────

  /// Record a new expense. Body: {account_id, amount, date?, note?}
  Future<Map<String, dynamic>> postCashflowAddExpense(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postCashflowAddExpense, body);

  /// Delete an expense entry.
  Future<Map<String, dynamic>> postCashflowDeleteExpense(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postCashflowDeleteExpense, body);

  // ── Profit report ─────────────────────────────────────────────────────────

  /// Aggregated profit report (getreport).
  Future<Response> getReportProfit({String? from, String? to}) =>
      _client.get(ApiEndpoints.getReportProfit, queryParameters: _range(from, to));

  /// Aggregated expenses report (getreport).
  Future<Response> getReportExpenses({String? from, String? to}) =>
      _client.get(ApiEndpoints.getReportExpenses, queryParameters: _range(from, to));

  // ═══════════════════════════════════════════════════════════════════════════
  // CASHFLOW / ACCOUNTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Cashflow ledger entries (cash-in / cash-out).
  Future<Response> getCashflow({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataCashflow, queryParameters: _range(from, to));

  /// Cashflow summary (total in, total out, net balance).
  Future<Response> getCashflowSummary({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataCashflowSummary, queryParameters: _range(from, to));

  /// Cashbook accounts (petty-cash sub-accounts).
  Future<Response> getCashbookAccounts() =>
      _client.get(ApiEndpoints.getDataCashbookAccounts);

  /// Chart of accounts.
  Future<Response> getChartOfAccounts() =>
      _client.get(ApiEndpoints.getDataChartOfAccounts);

  /// Source-of-fund accounts.
  Future<Response> getSourceOfFundAccounts() =>
      _client.get(ApiEndpoints.getDataSourceOfFundAccounts);

  // ── Cashflow writes ───────────────────────────────────────────────────────

  /// Add a cash-in or cash-out fund entry. Body: {account_id, amount, type:'in'|'out', …}
  Future<Map<String, dynamic>> postCashflowAddFund(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postCashflowAddFund, body);

  /// Cashflow aggregated report.
  Future<Response> getReportCashflow({String? from, String? to}) =>
      _client.get(ApiEndpoints.getReportCashflow, queryParameters: _range(from, to));

  /// Banking customer transaction.
  Future<Map<String, dynamic>> postBankingCustomerTransaction(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postBankingCustomerTransaction, body);

  // ═══════════════════════════════════════════════════════════════════════════
  // CUSTOMERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// All customers.
  Future<Response> getCustomers({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataCustomers, queryParameters: _range(from, to));

  /// Customers with outstanding credit balances.
  Future<Response> getOncreditCustomers() =>
      _client.get(ApiEndpoints.getDataOncreditCustomers);

  /// Customers who pay cash.
  Future<Response> getOncashCustomers() =>
      _client.get(ApiEndpoints.getDataOncashCustomers);

  /// Contact list.
  Future<Response> getContacts() =>
      _client.get(ApiEndpoints.getDataContacts);

  /// Contact categories.
  Future<Response> getContactCategory() =>
      _client.get(ApiEndpoints.getDataContactCategory);

  /// Customer wallet statement.
  Future<Response> getWalletCustomerStatement(String customerId) =>
      _client.get(ApiEndpoints.getMappedWalletCustomerStatement(customerId));

  /// Customer sales statement.
  Future<Response> getWalletCustomerSalesStatement(String customerId) =>
      _client.get(ApiEndpoints.getMappedWalletCustomerSalesStatement(customerId));

  /// Aggregated customers report.
  Future<Response> getReportCustomers({String? from, String? to}) =>
      _client.get(ApiEndpoints.getReportCustomers, queryParameters: _range(from, to));

  // ── Customer writes ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> postCustomerCreate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postCustomerCreate, body);

  Future<Map<String, dynamic>> postCustomerImport(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postCustomerImport, body);

  Future<Map<String, dynamic>> postCustomerCategoryCreate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postCustomerCategoryCreate, body);

  Future<Map<String, dynamic>> postCustomerContactCreate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postCustomerContactCreate, body);

  Future<Map<String, dynamic>> postCustomerSendBulkSms(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postCustomerSendBulkSms, body);

  Future<Map<String, dynamic>> postCustomerBulkDelete(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postCustomerBulkDelete, body);

  // ── Wallet writes ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> postWalletCustomerCreate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postWalletCustomerCreate, body);

  Future<Map<String, dynamic>> postWalletCustomerUpdate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postWalletCustomerUpdate, body);

  Future<Map<String, dynamic>> postWalletCustomerDelete(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postWalletCustomerDelete, body);

  Future<Map<String, dynamic>> postWalletSupplierCreate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postWalletSupplierCreate, body);

  // ═══════════════════════════════════════════════════════════════════════════
  // SUPPLIERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// All suppliers.
  Future<Response> getSuppliers() =>
      _client.get(ApiEndpoints.getDataSuppliers);

  /// Suppliers with outstanding credit.
  Future<Response> getOncreditSuppliers() =>
      _client.get(ApiEndpoints.getDataOncreditSuppliers);

  /// Cash-only suppliers.
  Future<Response> getOncashSuppliers() =>
      _client.get(ApiEndpoints.getDataOncashSuppliers);

  /// Aggregated suppliers report.
  Future<Response> getReportSuppliers({String? from, String? to}) =>
      _client.get(ApiEndpoints.getReportSuppliers, queryParameters: _range(from, to));

  // ── Supplier writes ───────────────────────────────────────────────────────

  /// Add a new supplier. Body: {name, phone?, email?, address?}
  Future<Map<String, dynamic>> postSupplierAdd(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postSupplierAdd, body);

  Future<Map<String, dynamic>> postSupplierBulkDelete(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postSupplierBulkDelete, body);

  Future<Map<String, dynamic>> postSupplierClearCreditBalance(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postSupplierClearCreditBalance, body);

  // ═══════════════════════════════════════════════════════════════════════════
  // TEAM / STAFF
  // ═══════════════════════════════════════════════════════════════════════════

  /// Team members (attendants + managers) for the current shop.
  Future<Response> getTeam() =>
      _client.get(ApiEndpoints.getDataTeam);

  /// Waiters / bar staff list.
  Future<Response> getWaiters() =>
      _client.get(ApiEndpoints.getDataWaiters);

  /// All user accounts (admin view).
  Future<Response> getUsers() =>
      _client.get(ApiEndpoints.getDataUsers);

  /// Attendant access-schedule settings.
  Future<Response> getAttendantSettings() =>
      _client.get(ApiEndpoints.getMappedSettingsAttendantSettings);

  /// Aggregated team report.
  Future<Response> getReportTeam({String? from, String? to}) =>
      _client.get(ApiEndpoints.getReportTeam, queryParameters: _range(from, to));

  // ── Team writes ───────────────────────────────────────────────────────────

  /// Create a waiter / bar-staff account.
  Future<Map<String, dynamic>> postTeamWaiterCreate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postTeamWaiterCreate, body);

  /// Add an attendant or manager. Body: {phone, name?, permissions?}
  Future<Map<String, dynamic>> postTeamStaffAdd(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postTeamStaffAdd, body);

  /// Add a non-staff (commission-only) member.
  Future<Map<String, dynamic>> postTeamNonStaffAdd(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postTeamNonStaffAdd, body);

  /// Update a team member's profile.
  Future<Map<String, dynamic>> postTeamMemberUpdate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postTeamMemberUpdate, body);

  /// Enable / disable a team member's access. Body: {role_id, status}
  Future<Map<String, dynamic>> postTeamStatusUpdate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postTeamStatusUpdate, body);

  /// Toggle a single permission flag. Body: {role_id, col, status}
  Future<Map<String, dynamic>> postTeamPermissionUpdate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postTeamPermissionUpdate, body);

  /// Soft-delete an attendant role. Body: {role_id}
  /// Also soft-deletes the user if no other active roles remain.
  Future<Map<String, dynamic>> postTeamAttendantDelete(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postTeamAttendantDelete, body);

  // ═══════════════════════════════════════════════════════════════════════════
  // SETTINGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Shop-level settings (VAT, currency, features, …).
  Future<Response> getShopSettingsData() =>
      _client.get(ApiEndpoints.getDataShopSettings);

  /// All shop records (owner view).
  Future<Response> getShops() =>
      _client.get(ApiEndpoints.getDataShops);

  /// All permission keys.
  Future<Response> getPermissionsData() =>
      _client.get(ApiEndpoints.getDataPermissions);

  /// Payment modes (Cash, M-Pesa, Card, …).
  Future<Response> getPaymentMode() =>
      _client.get(ApiEndpoints.getDataPaymentMode);

  /// Storage quota summary.
  Future<Response> getStorageSummary() =>
      _client.get(ApiEndpoints.getDataStorageSummary);

  /// Detailed storage usage per folder.
  Future<Response> getStorageUsage() =>
      _client.get(ApiEndpoints.getDataStorageUsage);

  /// System info (PHP, MySQL, OS versions).
  Future<Response> getSystemInfo() =>
      _client.get(ApiEndpoints.getDataSystemInfo);

  /// Activity / audit log entries.
  Future<Response> getLogs({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataLogs, queryParameters: _range(from, to));

  // ── Settings writes ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> postSettingsAccountCreate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postSettingsAccountCreate, body);

  Future<Map<String, dynamic>> postSettingsRecordUpdate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postSettingsRecordUpdate, body);

  Future<Map<String, dynamic>> postSettingsShopUpdate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postSettingsShopUpdate, body);

  Future<Map<String, dynamic>> postSettingsRecordDelete(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postSettingsRecordDelete, body);

  Future<Map<String, dynamic>> postSettingsAccountDelete(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postSettingsAccountDelete, body);

  /// Update the current user's profile. Body: {name?, email?, phone?, avatar?}
  Future<Map<String, dynamic>> postSettingsProfileUpdate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postSettingsProfileUpdate, body);

  /// Save shop custom-feature settings (VAT, restaurant mode, …).
  Future<Map<String, dynamic>> postSettingsShopSettingsSave(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postSettingsShopSettingsSave, body);

  Future<Map<String, dynamic>> postSettingsEfdVerify(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postSettingsEfdVerify, body);

  Future<Map<String, dynamic>> postSettingsBackupCreate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postSettingsBackupCreate, body);

  Future<Map<String, dynamic>> postSettingsPreferencesSave(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postSettingsPreferencesSave, body);

  Future<Map<String, dynamic>> postSettingsAttendantSaveAccess(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postSettingsAttendantSaveAccess, body);

  /// Track data usage (analytics ping).
  Future<Map<String, dynamic>> postSettingsDataUsageTrack(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postSettingsDataUsageTrack, body);

  /// Ping last-seen timestamp.
  Future<Map<String, dynamic>> postSettingsLastSeenPing(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postSettingsLastSeenPing, body);

  // ═══════════════════════════════════════════════════════════════════════════
  // UPLOAD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Upload shop logo (multipart/form-data). Field name: "logo".
  Future<Map<String, dynamic>> postUploadLogo(
    FormData formData, {
    ProgressCallback? onSendProgress,
  }) async {
    final response = await _client.upload(
      ApiEndpoints.postUploadLogo,
      data: formData,
      onSendProgress: onSendProgress,
    );
    return _body(response);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MANUFACTURING
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Response> getMfSummary({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataMfSummary, queryParameters: _range(from, to));

  Future<Response> getMfRawMaterials() =>
      _client.get(ApiEndpoints.getDataMfRawMaterials);

  Future<Response> getMfRecipes() =>
      _client.get(ApiEndpoints.getDataMfRecipes);

  Future<Response> getMfManufacturedProducts({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataMfManufacturedProducts, queryParameters: _range(from, to));

  Future<Response> getMfDailyProduction({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataMfDailyProduction, queryParameters: _range(from, to));

  Future<Response> getMfRawConsumption({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataMfRawConsumption, queryParameters: _range(from, to));

  Future<Response> getMfCostAnalysis({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataMfCostAnalysis, queryParameters: _range(from, to));

  Future<Response> getMfLowStockAlerts() =>
      _client.get(ApiEndpoints.getDataMfLowStockAlerts);

  Future<Response> getMfProductionByRecipe({String? from, String? to}) =>
      _client.get(ApiEndpoints.getDataMfProductionByRecipe, queryParameters: _range(from, to));

  // ── Manufacturing writes ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> postMfRawMaterialSave(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postMfRawMaterialSave, body);

  Future<Map<String, dynamic>> postMfRawMaterialRestock(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postMfRawMaterialRestock, body);

  Future<Map<String, dynamic>> postMfRawMaterialAdjust(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postMfRawMaterialAdjust, body);

  Future<Map<String, dynamic>> postMfRawMaterialDelete(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postMfRawMaterialDelete, body);

  Future<Map<String, dynamic>> postMfRecipeSave(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postMfRecipeSave, body);

  Future<Map<String, dynamic>> postMfRecipeDelete(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postMfRecipeDelete, body);

  Future<Map<String, dynamic>> postMfProductionSave(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postMfProductionSave, body);

  Future<Map<String, dynamic>> postMfProductionReproduce(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postMfProductionReproduce, body);

  Future<Map<String, dynamic>> postMfProductionTransfer(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postMfProductionTransfer, body);

  Future<Map<String, dynamic>> postMfProductionAdjust(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postMfProductionAdjust, body);

  Future<Map<String, dynamic>> postMfProductionDelete(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postMfProductionDelete, body);

  // ═══════════════════════════════════════════════════════════════════════════
  // ONLINE SHOP
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Response> getOnlineShopAdmin() =>
      _client.get(ApiEndpoints.getDataOnlineShopAdmin);

  /// Public storefront — pass [shopId] to filter by shop; omit for current session shop.
  Future<Response> getOnlineShopPublic({String? shopId}) =>
      _client.get(ApiEndpoints.getDataOnlineShopPublic,
          queryParameters: shopId != null ? {'shop_id': shopId} : null);

  /// Place an order on the public storefront. [encodedShopId] from [getOnlineShopAdmin] public_url.
  Future<Map<String, dynamic>> postOnlineshopPlaceOrder(
      String encodedShopId, Map<String, dynamic> payload) async {
    final url = '${ApiConfig.appApiBase}/Onlineshop/place_order/$encodedShopId';
    final response = await _client.post(url,
        data: payload,
        options: Options(contentType: 'application/json'));
    return _body(response);
  }

  /// Apply a coupon on the public storefront.
  Future<Map<String, dynamic>> postOnlineshopApplyCoupon(
      String encodedShopId, Map<String, dynamic> payload) async {
    final url = '${ApiConfig.appApiBase}/Onlineshop/apply_coupon/$encodedShopId';
    final response = await _client.post(url,
        data: payload,
        options: Options(contentType: 'application/json'));
    return _body(response);
  }

  Future<Map<String, dynamic>> postOnlineshopCouponSave(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postOnlineshopCouponSave, body);

  Future<Map<String, dynamic>> postOnlineshopCouponDelete(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postOnlineshopCouponDelete, body);

  Future<Map<String, dynamic>> postOnlineshopPaymentAccountSave(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postOnlineshopPaymentAccountSave, body);

  Future<Map<String, dynamic>> postOnlineshopPaymentAccountDelete(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postOnlineshopPaymentAccountDelete, body);

  Future<Map<String, dynamic>> postOnlineshopCategorySave(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postOnlineshopCategorySave, body);

  Future<Map<String, dynamic>> postOnlineshopCategoryDelete(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postOnlineshopCategoryDelete, body);

  Future<Map<String, dynamic>> postOnlineshopDeliveryMethodSave(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postOnlineshopDeliveryMethodSave, body);

  Future<Map<String, dynamic>> postOnlineshopDeliveryMethodDelete(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postOnlineshopDeliveryMethodDelete, body);

  Future<Map<String, dynamic>> postOnlineshopOrderUpdateStatus(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postOnlineshopOrderUpdateStatus, body);

  // ═══════════════════════════════════════════════════════════════════════════
  // MICROFINANCE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> postMicrofinanceLoanProductCreate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postMicrofinanceLoanProductCreate, body);

  Future<Map<String, dynamic>> postMicrofinanceGuarantorCreate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postMicrofinanceGuarantorCreate, body);

  Future<Map<String, dynamic>> postMicrofinanceImport(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postMicrofinanceImport, body);

  Future<Map<String, dynamic>> postMicrofinanceCategoryCreate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postMicrofinanceCategoryCreate, body);

  Future<Map<String, dynamic>> postMicrofinanceContactCreate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postMicrofinanceContactCreate, body);

  Future<Map<String, dynamic>> postMicrofinanceSendBulkSms(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postMicrofinanceSendBulkSms, body);

  Future<Map<String, dynamic>> postMicrofinanceLoanRecordCreate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postMicrofinanceLoanRecordCreate, body);

  Future<Map<String, dynamic>> postMicrofinanceLoanRecordUpdate(Map<String, dynamic> body) =>
      _post(ApiEndpoints.postMicrofinanceLoanRecordUpdate, body);

  Future<Response> getPackages() =>
      _client.get(ApiEndpoints.getDataPackages);

  Future<Response> getLobs() =>
      _client.get(ApiEndpoints.getDataLobs);

  // ═══════════════════════════════════════════════════════════════════════════
  // REPORTS (getreport)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Response> getReportSales({String? from, String? to}) =>
      _client.get(ApiEndpoints.getReportSales, queryParameters: _range(from, to));

  /// Generic sales sub-report by method name (e.g. 'totalSales', 'creditSales').
  /// Maps to GET /api/v1/app/get/getreport/{method}.
  Future<Response> getReportSalesByMethod(String method, {String? from, String? to}) =>
      _client.get(ApiEndpoints.getReportSalesByMethod(method),
          queryParameters: _range(from, to));

  Future<Response> getReportStock({String? from, String? to}) =>
      _client.get(ApiEndpoints.getReportStock, queryParameters: _range(from, to));

  Future<Response> getReportPurchases({String? from, String? to}) =>
      _client.get(ApiEndpoints.getReportPurchases, queryParameters: _range(from, to));

  // ═══════════════════════════════════════════════════════════════════════════
  // SUPER ADMIN
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Response> getSuperadminDashboard() =>
      _client.get(ApiEndpoints.getDataSuperadminDashboard);

  Future<Response> getSuperadminShops() =>
      _client.get(ApiEndpoints.getDataSuperadminShops);

  Future<Response> getSuperadminCustomers() =>
      _client.get(ApiEndpoints.getDataSuperadminCustomers);

  Future<Response> getSuperadminAgents() =>
      _client.get(ApiEndpoints.getDataSuperadminAgents);

  Future<Response> getSuperadminServer() =>
      _client.get(ApiEndpoints.getDataSuperadminServer);

  Future<Response> getSuperadminProfile() =>
      _client.get(ApiEndpoints.getDataSuperadminProfile);

  Future<Response> getSuperadminPackages() =>
      _client.get(ApiEndpoints.getDataSuperadminPackages);

  // ═══════════════════════════════════════════════════════════════════════════
  // Private helpers
  // ═══════════════════════════════════════════════════════════════════════════

  /// POST and return the parsed JSON body as [Map<String,dynamic>].
  ///
  /// Sends as `application/x-www-form-urlencoded` so that PHP's `$_POST`
  /// and `$this->input->post()` receive the fields correctly.
  /// Uses ResponseType.plain so Dio never attempts to JSON-decode the body
  /// itself — we decode manually in [_body], which tolerates mixed output.
  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final encoded = body.entries
        .where((e) => e.value != null)
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}='
            '${Uri.encodeQueryComponent(e.value.toString())}')
        .join('&');

    final response = await _client.post(
      path,
      data: encoded,
      options: Options(
        contentType: 'application/x-www-form-urlencoded',
        responseType: ResponseType.plain,
      ),
    );
    return _body(response);
  }

  /// Extract the JSON body from a [Response] as [Map<String,dynamic>].
  /// Handles plain text, pre-decoded maps, and strips any PHP noise before JSON.
  Map<String, dynamic> _body(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    final raw = data?.toString() ?? '';
    if (raw.isEmpty) return {};
    try {
      // Find the first '{' in case PHP emits warnings before the JSON.
      final start = raw.indexOf('{');
      final end = raw.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        final jsonStr = raw.substring(start, end + 1);
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map<String, dynamic>) return decoded;
      }
    } catch (_) {}
    return {};
  }

  /// Build a query-parameter map for date-range filtering.
  /// Only includes keys that are non-null.
  Map<String, dynamic>? _range(String? from, String? to) {
    if (from == null && to == null) return null;
    return {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    };
  }
}
