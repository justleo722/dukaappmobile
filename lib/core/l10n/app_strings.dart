import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'strings_en.dart';
import 'strings_sw.dart';

// ── Locale provider ─────────────────────────────────────────────────────────

class LocaleNotifier extends Notifier<String> {
  static const _key = 'app_locale';

  @override
  String build() {
    _loadSaved();
    return 'en';
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null && saved != state) state = saved;
  }

  Future<void> setLocale(String locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, String>(LocaleNotifier.new);

final stringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeProvider);
  return locale == 'sw' ? SwStrings() : EnStrings();
});

// ── Base class ───────────────────────────────────────────────────────────────

abstract class AppStrings {
  // ── App
  String get appName;
  String get loading;
  String get save;
  String get cancel;
  String get close;
  String get edit;
  String get delete;
  String get add;
  String get update;
  String get view;
  String get done;
  String get apply;
  String get clear;
  String get search;
  String get filter;
  String get sort;
  String get submit;
  String get retry;
  String get back;
  String get next;
  String get from;
  String get to;
  String get date;
  String get amount;
  String get total;
  String get price;
  String get quantity;
  String get type;
  String get status;
  String get action;
  String get balance;
  String get unit;
  String get title;
  String get note;
  String get address;
  String get phone;
  String get email;
  String get name;
  String get no;
  String get yes;
  String get or;
  String get page;
  String get paid;
  String get credit;
  String get cash;
  String get bank;
  String get cost;
  String get added;
  String get deleted;
  String get english;
  String get swahili;
  String get language;

  // ── Auth
  String get login;
  String get logout;
  String get register;
  String get resetPassword;
  String get signInToContinue;
  String get onlineShop;
  String get areYouSureLogout;
  String get loggedOutSuccessfully;

  // ── Biometric
  String get biometricLogin;
  String get biometricSubtitle;
  String get enableBiometric;
  String get biometricNotAvailable;
  String get enableBiometricPrompt;

  // ── Dashboard
  String get dashboard;
  String get sales;
  String get stock;
  String get expenses;
  String get accounts;
  String get suppliers;
  String get customers;
  String get staff;
  String get settings;
  String get reports;
  String get manufacturing;
  String get onlineShopModule;
  String get tmsLoans;
  String get productAndServices;

  // ── Dashboard stats & shortcuts
  String get todaySales;
  String get todayExpense;
  String get todayProfit;
  String get todayStockIn;
  String get todayOrders;
  String get toPay;
  String get toReceive;
  String get profitAndExpenses;
  String get accountsAndCashflowShort;
  String get shopSettings;
  String get addSaleShortcut;
  String get addProductShortcut;
  String get purchase;
  String get order;
  String get microfinance;
  String get tryAgain;

  // ── Sales
  String get addSale;
  String get salesReceipt;
  String get salesReport;
  String get creditSalesReport;
  String get totalSalesReport;
  String get salesByProductReport;
  String get salesByStaffReport;
  String get salesByCustomerReport;
  String get salesByPaymentReport;
  String get salesByCategoryReport;
  String get salesWithVatReport;
  String get salesWithoutVatReport;
  String get unpaidSalesByProductReport;
  String get combinedTotalSalesReport;
  String get salesByItemsReport;
  String get invoicesReport;
  String get clearCart;
  String get areYouSureClearCart;
  String get completePayment;
  String get pay;
  String get paymentRecorded;
  String get paymentFailed;
  String get pleaseSelectCustomer;
  String get pleaseSelectStatus;
  String get thankYou;
  String get receiptNo;
  String get invoiceDateUpdated;
  String get invoiceDeleted;
  String get invoicesDeleted;
  String get orderDateUpdated;
  String get orderStatusUpdated;
  String get countingSheet;

  // ── Stock
  String get addProduct;
  String get editProduct;
  String get deleteProduct;
  String get updateProduct;
  String get productUpdatedSuccessfully;
  String get productsDeleted;
  String get stockReport;
  String get allStockReport;
  String get allStockLevelsNormal;
  String get lowStock;
  String get lowStockReport;
  String get lowStockAlertReport;
  String get barcode;
  String get barcodeReport;
  String get generateBarcodes;
  String get priceList;
  String get expiredProducts;
  String get expiredProductsReport;
  String get badStockReport;
  String get lostStockReport;
  String get stockByCategoryReport;
  String get combinedStockValueReport;
  String get adjustStockTitle;
  String get adjustStockSubtitle;
  String get adjustmentsSavedSuccessfully;
  String get saveAdjustments;
  String get searchProductToAdjust;
  String get transferManufacturedProducts;
  String get transferInitiatedSuccessfully;
  String get setTransferQuantity;
  String get searchProductToTransfer;
  String get noProductsAvailable;
  String get noProductsFound;
  String get productsNotLoaded;
  String get loadingProducts;
  String get sellingPrice;
  String get wholesalePrice;
  String get restockDate;
  String get restockItems;
  String get productHistoryReport;
  String get importHistory;
  String get deleteImport;
  String get noImportsFound;
  String get aboutToExpire;
  String get aboutToExpireReport;
  String get badStock;
  String get lostStock;

  // ── Expenses / Profit
  String get profit;
  String get netProfit;
  String get grossProfit;
  String get totalExpenses;
  String get todayExpenses;
  String get totalSales;
  String get cashInHand;
  String get addExpense;
  String get selectExpenseCategory;
  String get fillAllFields;
  String get noExpenseData;

  // ── Customers
  String get addNewCustomer;
  String get customerAddedSuccessfully;
  String get failedToDeleteCustomer;
  String get customerOnCreditReport;
  String get salesByCustomer;
  String get addCashToWallet;
  String get payCredit;
  String get payCreditBalance;
  String get noCustomers;

  // ── Suppliers
  String get addNewSupplier;
  String get supplierStatement;
  String get clearSupplierCredit;
  String get purchaseBalance;
  String get noPurchasesForSupplier;
  String get cashPurchases;
  String get creditPurchases;
  String get totalPurchases;
  String get totalOrders;
  String get purchaseDateUpdated;
  String get purchaseDeleted;
  String get purchaseOrderDeleted;
  String get purchaseOrderStatusUpdated;
  String get deletePurchaseOrder;
  String get purchaseReturned;
  String get purchasesDeleted;
  String get noSuppliers;

  // ── Staff / Attendants
  String get attendantsAndStaff;
  String get addNewAttendant;
  String get editAttendant;
  String get updateAttendant;
  String get saveAttendant;
  String get deleteAttendant;
  String get managePermissions;
  String get toggleAllPermissions;
  String get noAttendantsFound;
  String get tapToAddAttendant;
  String get individualSalesReport;
  String get combinedSalesByStaff;

  // ── Accounts / Cashflow
  String get accountsAndCashflow;
  String get accountsReports;
  String get cashflow;
  String get addCashIn;
  String get addCashOut;
  String get cashInRecorded;
  String get cashOutRecorded;
  String get trackCashMovement;
  String get startByAddingCash;
  String get noCashflowRecords;
  String get fromAccount;

  // ── Settings
  String get shopDetails;
  String get shopDetailsSaved;
  String get editProfile;
  String get profileUpdatedSuccessfully;
  String get profileImageUpdated;
  String get saveProfile;
  String get saveChanges;
  String get security;
  String get appLock;
  String get backupInterval;
  String get dataBackup;
  String get backupReady;
  String get backupSubtitle;
  String get settingsSavedSuccessfully;
  String get accountInfo;
  String get businessDetails;
  String get storage;

  // ── Manufacturing
  String get manageManufacturedProducts;
  String get manageRawMaterials;
  String get manageRecipes;
  String get addNewRawMaterial;
  String get editRawMaterial;
  String get deleteRawMaterial;
  String get saveRawMaterial;
  String get updateRawMaterial;
  String get rawMaterialSavedSuccessfully;
  String get rawMaterialUpdatedSuccessfully;
  String get addIngredient;
  String get addAnotherMaterial;
  String get ingredients;
  String get recipeInformation;
  String get materialInformation;
  String get createNewRecipe;
  String get newRecipe;
  String get editRecipe;
  String get updateRecipe;
  String get deleteRecipe;
  String get saveRecipe;
  String get recipeSavedSuccessfully;
  String get recipeUpdatedSuccessfully;
  String get chooseRecipe;
  String get selectRecipe;
  String get adjustManufacturedProducts;
  String get reProduceManufactureProducts;
  String get reProduceProducts;
  String get reProductionSavedSuccessfully;
  String get addProductToReproduce;
  String get noProductsForReproduction;
  String get manufacturingReports;
  String get dailyProductionSummary;
  String get rawMaterialConsumption;
  String get productionCostAnalysis;
  String get productByRecipe;
  String get noRawMaterialsFound;
  String get noManufacturedProducts;
  String get noManufacturedProductsFound;
  String get noRecipesFound;
  String get noMaterialsFound;
  String get tapToAddMaterial;
  String get tapToAddRecipe;
  String get transferProducts;
  String get transferManufactured;
  String get restockRawMaterials;
  String get restockSavedSuccessfully;

  // ── Online Shop
  String get addCategory;
  String get deleteDeliveryMethod;
  String get shopLinkCopied;
  String get openingShopUrl;
  String get openingWhatsApp;
  String get couponApplied;
  String get maximumPhotos;
  String get noApplicationsYet;
  String get tapNewApplication;
  String get loanPortfolioInsights;
  String get applyForLoan;
  String get tmsDescription;
  String get renew;

  // ── System / Misc
  String get systemLogs;
  String get noLogsFound;
  String get comingSoon;
  String get selectReport;
  String get noDataToExport;
  String get printComingSoon;
  String get printingReceipt;
  String get printingTestPage;
  String get noShopsFound;
  String get loadingShops;
  String get selectShops;
  String get dir;
  String get noRecordsFound;
  String get tryDifferentDateRange;
  String get tryDifferentSearch;

  // ── Errors / Warnings
  String get enterValidAmount;
  String get pleaseAddAtLeastOneItem;
  String get pleaseFillAllFields;
  String get noAccountsFound;
  String get failedToLoadAccounts;
  String get failedToLoadProducts;
  String get failedToShareInvoice;
  String get couldNotCaptureInvoice;
  String get pleaseEnterTra;
  String get traVerified;

  // ── Navigation / Drawer
  String get addShop;
  String get guide;
  String get shopCreatedSuccessfully;

  // ── Sales — Manage
  String get manageSales;
  String get backdateSale;
  String get backdate;
  String get selectNewDateForSale;
  String get saleDateUpdated;
  String get deleteSale;
  String get deleteSales;
  String get saleDeleted;
  String get salesDeleted;
  String get amountPaid;
  String get exceedsBalance;
  String get viewList;
  String get download;
  String get deleteFailed;

  // ── Sales — Add Sale
  String get editSale;
  String get discount;
  String get summary;
  String get items;
  String get itemDiscounts;
  String get totalAmount;
  String get totalQuantity;
  String get finalAmount;
  String get paymentType;
  String get selectCustomer;
  String get selectProduct;
  String get addItem;
  String get scan;
  String get addNewPaymentMode;
  String get addPaymentMode;
  String get enterPaymentModeName;
  String get searchItemsScanBarcode;
  String get noItemsAddedYet;
  String get saleSavedSuccessfully;
  String get saleUpdatedSuccessfully;
  String get failedToSaveSale;
  String get wholesale;
  String get entries;
  String get mobileMoney;
  String get bankTransfer;

  // ── Sales — Orders
  String get orders;
  String get activeOrders;
  String get clearedOrders;
  String get newOrder;
  String get noOrdersFound;
  String get salesOrderReceipt;
  String get deleteOrder;
  String get deleteOrders;
  String get backdateOrder;
  String get selectNewDateForOrder;
  String get orderDeleted;
  String get ordersDeleted;
  String get updateOrderStatus;
  String get updateStatus;
  String get paidTotal;
  String get unpaidTotal;
  String get orderValue;
  String get amountToCollect;
  String get addPayment;
  String get selectAccount;
  String get customerName;
  String get statusDate;
  String get purchasedProducts;
  String get paymentRecordedSuccessfully;
  String get confirmedOrder;
  String get delivering;
  String get delivered;
  String get declineOrder;

  // ── Sales — Invoices
  String get invoices;
  String get noInvoicesFound;
  String get generateInvoice;
  String get deleteInvoice;
  String get deleteInvoices;
  String get backdateInvoice;
  String get selectNewDateForInvoice;
  String get printInvoice;
  String get balanceDue;
  String get paidAmount;
  String get paymentMode;
  String get subtotal;
  String get qty;

  // ── Stock
  String get manageStock;
  String get importStock;
  String get importFromShop;
  String get outOfStock;
  String get runningLow;
  String get toExpire;
  String get deleteProducts;
  String get confirmDeleteProduct;
  String get confirmDeleteProducts;
  String get all;

  // ── Expenses
  String get saveExpense;
  String get expenseName;
  String get expenseSavedSuccessfully;
  String get failedToSaveExpense;
  String get categoryNameHint;
  String get enterExpenseName;
  String get selectCategory;
  String get todayNetProfit;
  String get todayTotalExpenses;
  String get report;
  String get detailedBreakdown;

  // ── Customers
  String get newCustomer;
  String get deleteCustomer;
  String get loyalty;
  String get loyaltyComingSoon;
  String get wallet;
  String get tryDifferentSearchOrAddCustomer;
  String get customerDashboard;
  String get editCustomer;
  String get salesRecords;
  String get salesSummary;
  String get walletTransactions;
  String get walletBalance;
  String get walletSales;
  String get walletStatement;
  String get creditBalance;
  String get creditLimit;
  String get clearCredit;
  String get addCash;
  String get addCredit;
  String get totalSpent;
  String get deleteTransaction;
  String get transactionDeleted;
  String get noSalesRecordsYet;
  String get noWalletTransactionsYet;
  String get salePdf;
  String get statementPdf;
  String get notProvided;

  // ── Suppliers
  String get supplierManagement;
  String get newSupplier;
  String get deleteSupplier;
  String get onCash;
  String get onCredit;
  String get notSet;
  String get tryDifferentSearchOrAddSupplier;
  String get supplierDashboard;
  String get editSupplier;
  String get purchaseSummary;
  String get noCashPurchasesFound;
  String get noCreditPurchasesFound;
  String get noPurchaseOrdersFound;
  String get payCreditPurchase;
  String get completed;
  String get partial;
  String get pending;
  String get company;
  String get transactions;
  String get outstanding;

  // ── Staff
  String get searchAttendantByNameOrPhone;
  String get manager;
  String get permissions;

  // ── Accounts
  String get cashIn;
  String get cashOut;
  String get fromAccountSource;
  String get toAccountDestination;
  String get loadingAccounts;
  String get searchCashflow;
  String get selectAccountHint;
  String get balancing;
  String get capital;
  String get loan;
  String get toBank;
  String get toPersonalUse;
  String get customerWallet;
  String get fillAllFieldsAndSelectBothAccounts;

  // ── Profile
  String get changePassword;
  String get currentPassword;
  String get newPassword;
  String get enterEmail;
  String get enterPhoneNumber;
  String get enterRegion;
  String get enterUsername;
  String get region;

  // ── Purchases
  String get managePurchases;
  String get noPurchasesFound;
  String get deletePurchase;
  String get deletePurchases;
  String get backdatePurchase;
  String get selectNewDateForPurchase;
  String get purchaseReceipt;
  String get returnPurchase;
  String get returnAll;
  String get returnDate;
  String get confirmReturn;
  String get payFromAccount;
  String get amountToPay;
  String get totalPurchaseOrders;
  String get preview;
  String get print;

  // ── Purchase Orders
  String get purchaseOrders;
  String get newPurchaseOrder;
  String get backdatePurchaseOrder;
  String get updatePurchaseOrderStatus;
  String get outstandingBalance;
  String get purchaseOrderReceipt;
  String get selectStatus;
  String get orderedProducts;
  String get paymentAccount;

  // ── Dynamic strings (with parameters)
  String deletedItemName(String name);
  String deletedMaterialConfirm(String name);
  String deletedProductConfirm(String name);
  String deletedRecipeConfirm(String name);
  String deletedAttendantName(String name);
  String deletedRecordTitle(String title);
  String deleteRecordConfirm(String title);
  String categoryCleared(String category);
  String clearCategory(String category);
  String nameSettingsSaved(String name);
  String shopDeletedSuccessfully(String name);
  String controlUsage(String name);
  String connectingTo(String label);
  String orderIdCopied(String orderId);
  String statusUpdatedTo(String status);
  String paymentRecordedFor(String name);
  String itemsAvailable(int count);
  String itemSelected(int count);
  String addSelectedCount(int count);
  String pageOfPages(int page, int total);
  String supplierStatementTitle(String name);
  String productBalance(String balance);
  String browsingShop(String shopId);
  String trackingOrder(String orderId);
  String couponAppliedCode(String code);
  String deliveryMethodDeleted(String method);
  String paymentMethodDeleted(String method);
  String categoryDeleted(String category);
  String shopDataInfo(String data);
  String failedError(String e);
  String updateFailedError(String e);
  String saveFailedError(String e);
  String deleteFailedError(String e);
  String downloadFailedError(String e);
  String backdateFailedError(String e);
  String orderFailedError(String e);
  String paymentFailedError(String e);
  String failedToLoad(String e);
  String missingStockBatch(String names);
  String profileImagePath(String path);
  String lastBackupCreated(String date);
  String importCreated(String date);
  String importDeleted(String date);
  String productAddress(String address);
  String productCompany(String company);
  String productPhone(String phone);
  String productTin(String tin);
  String balanceTzs(String amount);
  String totalAmountTzs(String amount);
  String paidTzs(String amount);
}
