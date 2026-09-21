import 'strings_en.dart';

// Swahili translations — currently mirrors English.
// Replace each value with the Swahili translation.
class SwStrings extends EnStrings {
  // ── App
  @override String get appName => 'DukaApp';
  @override String get loading => 'Loading...';
  @override String get save => 'Save';
  @override String get cancel => 'Cancel';
  @override String get close => 'Close';
  @override String get edit => 'Edit';
  @override String get delete => 'Delete';
  @override String get add => 'Add';
  @override String get update => 'Update';
  @override String get view => 'View';
  @override String get done => 'Done';
  @override String get apply => 'Apply';
  @override String get clear => 'Clear';
  @override String get search => 'Search';
  @override String get filter => 'Filter';
  @override String get sort => 'Sort';
  @override String get submit => 'Submit';
  @override String get retry => 'Retry';
  @override String get back => 'Back';
  @override String get next => 'Next';
  @override String get from => 'From';
  @override String get to => 'To';
  @override String get date => 'Date';
  @override String get amount => 'Amount';
  @override String get total => 'Total';
  @override String get price => 'Price';
  @override String get quantity => 'Quantity';
  @override String get type => 'Type';
  @override String get status => 'Status';
  @override String get action => 'Action';
  @override String get balance => 'Balance';
  @override String get unit => 'Unit';
  @override String get title => 'Title';
  @override String get note => 'Note';
  @override String get address => 'Address';
  @override String get phone => 'Phone';
  @override String get email => 'Email';
  @override String get name => 'Name';
  @override String get no => 'No';
  @override String get yes => 'Yes';
  @override String get or => 'au';
  @override String get page => 'Ukurasa';
  @override String get paid => 'Imelipwa';
  @override String get credit => 'Credit';
  @override String get cash => 'Cash';
  @override String get bank => 'Bank';
  @override String get cost => 'Cost';
  @override String get added => 'Added';
  @override String get deleted => 'Deleted';
  @override String get english => 'Kiingereza';
  @override String get swahili => 'Kiswahili';
  @override String get language => 'Lugha';

  // ── Auth
  @override String get login => 'Ingia';
  @override String get logout => 'Toka';
  @override String get register => 'Jisajili';
  @override String get resetPassword => 'Weka Upya Nywila';
  @override String get signInToContinue => 'Ingia kuendelea kusimamia biashara yako';
  @override String get onlineShop => 'Duka la Mtandao';
  @override String get areYouSureLogout => 'Una uhakika unataka kutoka?';
  @override String get loggedOutSuccessfully => 'Umetoka kwa mafanikio';

  // ── Biometric
  @override String get biometricLogin => 'Biometric Login';
  @override String get biometricSubtitle => 'Ingia kwa kidole au uso wako';
  @override String get enableBiometric => 'Enable Biometrics';
  @override String get biometricNotAvailable => 'Simu hii haina biometrics zilizosanidiwa';
  @override String get enableBiometricPrompt => 'Wezesha kuingia kwa kidole/uso';

  // ── Dashboard
  @override String get dashboard => 'Dashibodi';
  @override String get sales => 'Mauzo';
  @override String get stock => 'Bidhaa';
  @override String get expenses => 'Matumizi';
  @override String get accounts => 'Akaunti';
  @override String get suppliers => 'Wasambazaji';
  @override String get customers => 'Wateja';
  @override String get staff => 'Wafanyakazi';
  @override String get settings => 'Mipangilio';
  @override String get reports => 'Ripoti';
  @override String get manufacturing => 'Uzalishaji';
  @override String get onlineShopModule => 'Duka la Mtandao';
  @override String get tmsLoans => 'Mikopo ya TMS';
  @override String get productAndServices => 'Bidhaa na Huduma';

  // ── Dashboard stats & shortcuts
  @override String get todaySales => 'Mauzo ya Leo';
  @override String get todayExpense => 'Matumizi ya Leo';
  @override String get todayProfit => 'Faida ya Leo';
  @override String get todayStockIn => 'Bidhaa Iliyoingia Leo';
  @override String get todayOrders => 'Maagizo ya Leo';
  @override String get toPay => 'Kulipa';
  @override String get toReceive => 'Kupokea';
  @override String get profitAndExpenses => 'Faida na Matumizi';
  @override String get accountsAndCashflowShort => 'Akaunti na Mtiririko wa Pesa';
  @override String get shopSettings => 'Mipangilio ya Duka';
  @override String get addSaleShortcut => 'Ongeza Mauzo';
  @override String get addProductShortcut => 'Ongeza Bidhaa';
  @override String get purchase => 'Ununuzi';
  @override String get order => 'Agizo';
  @override String get microfinance => 'Fedha Ndogo';
  @override String get tryAgain => 'Jaribu tena';

  // ── Sales
  @override String get addSale => 'Ongeza Mauzo';
  @override String get salesReceipt => 'Sales Receipt';
  @override String get salesReport => 'Sales Report';
  @override String get creditSalesReport => 'Credit Sales Report';
  @override String get totalSalesReport => 'Total Sales Report';
  @override String get salesByProductReport => 'Sales by Product Report';
  @override String get salesByStaffReport => 'Sales by Staff Report';
  @override String get salesByCustomerReport => 'Sales by Customer Report';
  @override String get salesByPaymentReport => 'Sales by Payments Report';
  @override String get salesByCategoryReport => 'Sales by Category Report';
  @override String get salesWithVatReport => 'Sales with VAT Report';
  @override String get salesWithoutVatReport => 'Sales without VAT Report';
  @override String get unpaidSalesByProductReport => 'Unpaid Sales by Product Report';
  @override String get combinedTotalSalesReport => 'Combined Total Sales Report';
  @override String get salesByItemsReport => 'Staff Sales by Items Report';
  @override String get invoicesReport => 'Invoices Report';
  @override String get clearCart => 'Clear Cart';
  @override String get areYouSureClearCart => 'Are you sure you want to remove all items from your cart?';
  @override String get completePayment => 'Complete Payment';
  @override String get pay => 'Pay';
  @override String get paymentRecorded => 'Payment recorded';
  @override String get paymentFailed => 'Payment failed';
  @override String get pleaseSelectCustomer => 'Please select a customer';
  @override String get pleaseSelectStatus => 'Please select a status';
  @override String get thankYou => 'Thank you!';
  @override String get receiptNo => 'Receipt No';
  @override String get invoiceDateUpdated => 'Invoice date updated';
  @override String get invoiceDeleted => 'Invoice deleted';
  @override String get invoicesDeleted => 'Invoices deleted';
  @override String get orderDateUpdated => 'Order date updated';
  @override String get orderStatusUpdated => 'Order status updated';
  @override String get countingSheet => 'Counting Sheet';

  // ── Stock
  @override String get addProduct => 'Add Product';
  @override String get editProduct => 'Edit Product';
  @override String get deleteProduct => 'Delete Product';
  @override String get updateProduct => 'Update Product';
  @override String get productUpdatedSuccessfully => 'Product updated successfully';
  @override String get productsDeleted => 'Products deleted';
  @override String get stockReport => 'Stock Report';
  @override String get allStockReport => 'All Stock Report';
  @override String get allStockLevelsNormal => 'All Stock Levels Normal';
  @override String get lowStock => 'Low Stock';
  @override String get lowStockReport => 'Low Stock Report';
  @override String get lowStockAlertReport => 'Low Stock Alert Report';
  @override String get barcode => 'Barcode';
  @override String get barcodeReport => 'Barcode Report';
  @override String get generateBarcodes => 'Generate Barcodes';
  @override String get priceList => 'Price List';
  @override String get expiredProducts => 'Expired Products';
  @override String get expiredProductsReport => 'Expired Products Report';
  @override String get badStockReport => 'Bad Stock Report';
  @override String get lostStockReport => 'Lost Stock Report';
  @override String get stockByCategoryReport => 'Stock by Category Report';
  @override String get combinedStockValueReport => 'Combined Stock Value Report';
  @override String get adjustStockTitle => 'Adjust Manufactured Products';
  @override String get adjustStockSubtitle => 'Adjust product quantities and record adjustment reasons.';
  @override String get adjustmentsSavedSuccessfully => 'Adjustments saved successfully';
  @override String get saveAdjustments => 'Save Adjustments';
  @override String get searchProductToAdjust => 'Search a product to begin adjusting stock.';
  @override String get transferManufacturedProducts => 'Transfer Manufactured Products';
  @override String get transferInitiatedSuccessfully => 'Transfer initiated successfully';
  @override String get setTransferQuantity => 'Set transfer quantity for at least one product.';
  @override String get searchProductToTransfer => 'Search a product to begin transferring.';
  @override String get noProductsAvailable => 'No products available';
  @override String get noProductsFound => 'No Products Found';
  @override String get productsNotLoaded => 'Products not loaded. Tap to retry.';
  @override String get loadingProducts => 'Loading products, please wait...';
  @override String get sellingPrice => 'Selling Price';
  @override String get wholesalePrice => 'Wholesale Price';
  @override String get restockDate => 'Restock Date';
  @override String get restockItems => 'Restock Items';
  @override String get productHistoryReport => 'Product History Report';
  @override String get importHistory => 'Import History';
  @override String get deleteImport => 'Delete Import';
  @override String get noImportsFound => 'No Imports Found';
  @override String get aboutToExpire => 'About to Expire';
  @override String get aboutToExpireReport => 'About to Expire Report';
  @override String get badStock => 'Bad Stock';
  @override String get lostStock => 'Lost Stock';

  // ── Expenses / Profit
  @override String get profit => 'Profit';
  @override String get netProfit => 'Net Profit';
  @override String get grossProfit => 'Gross Profit';
  @override String get totalExpenses => 'Total Expenses';
  @override String get todayExpenses => 'Today\'s Expenses';
  @override String get totalSales => 'Total Sales';
  @override String get cashInHand => 'Cash in Hand';
  @override String get addExpense => 'Add Expense';
  @override String get selectExpenseCategory => 'Select expense category and cash account';
  @override String get fillAllFields => 'Fill all fields and select both accounts';
  @override String get noExpenseData => 'No expense data';

  // ── Customers
  @override String get addNewCustomer => 'Add New Customer';
  @override String get customerAddedSuccessfully => 'Customer added successfully';
  @override String get failedToDeleteCustomer => 'Failed to delete customer';
  @override String get customerOnCreditReport => 'Customer On Credit Report';
  @override String get salesByCustomer => 'Sales by Customer Report';
  @override String get addCashToWallet => 'Add cash to customer wallet';
  @override String get payCredit => 'Pay Credit';
  @override String get payCreditBalance => 'Pay Credit Balance';
  @override String get noCustomers => 'No customers found';

  // ── Suppliers
  @override String get addNewSupplier => 'Add New Supplier';
  @override String get supplierStatement => 'Supplier Statement';
  @override String get clearSupplierCredit => 'Clear Supplier Credit';
  @override String get purchaseBalance => 'Purchase Balance';
  @override String get noPurchasesForSupplier => 'No purchases for this supplier';
  @override String get cashPurchases => 'Cash Purchases';
  @override String get creditPurchases => 'Credit Purchases';
  @override String get totalPurchases => 'Total Purchases';
  @override String get totalOrders => 'Total Orders';
  @override String get purchaseDateUpdated => 'Purchase date updated';
  @override String get purchaseDeleted => 'Purchase deleted';
  @override String get purchaseOrderDeleted => 'Purchase order deleted';
  @override String get purchaseOrderStatusUpdated => 'Purchase order status updated';
  @override String get deletePurchaseOrder => 'Delete Purchase Order';
  @override String get purchaseReturned => 'Purchase returned';
  @override String get purchasesDeleted => 'Purchases deleted';
  @override String get noSuppliers => 'No suppliers found';

  // ── Staff / Attendants
  @override String get attendantsAndStaff => 'Attendants & Staff Management';
  @override String get addNewAttendant => 'Add New Attendant';
  @override String get editAttendant => 'Edit Attendant';
  @override String get updateAttendant => 'Update Attendant';
  @override String get saveAttendant => 'Save Attendant';
  @override String get deleteAttendant => 'Delete Attendant';
  @override String get managePermissions => 'Manage Permissions';
  @override String get toggleAllPermissions => 'Toggle All Permissions';
  @override String get noAttendantsFound => 'No Attendants Found';
  @override String get tapToAddAttendant => 'Tap "Add New Attendant" to get started.';
  @override String get individualSalesReport => 'Individual Team Sales Report';
  @override String get combinedSalesByStaff => 'Combined Sales by Staff Report';

  // ── Accounts / Cashflow
  @override String get accountsAndCashflow => 'Accounts and Cashflow';
  @override String get accountsReports => 'Accounts Reports';
  @override String get cashflow => 'Cashflow';
  @override String get addCashIn => 'Add Cash In';
  @override String get addCashOut => 'Add Cash Out';
  @override String get cashInRecorded => 'Cash In recorded';
  @override String get cashOutRecorded => 'Cash Out recorded';
  @override String get trackCashMovement => 'Track cash movement.';
  @override String get startByAddingCash => 'Start by adding cash in or cash out.';
  @override String get noCashflowRecords => 'No Cashflow Records Found';
  @override String get fromAccount => 'From Account';

  // ── Settings
  @override String get shopDetails => 'Shop Details';
  @override String get shopDetailsSaved => 'Shop details saved successfully';
  @override String get editProfile => 'Edit Profile';
  @override String get profileUpdatedSuccessfully => 'Profile updated successfully';
  @override String get profileImageUpdated => 'Profile image updated';
  @override String get saveProfile => 'Save Profile';
  @override String get saveChanges => 'Save Changes';
  @override String get security => 'Security';
  @override String get appLock => 'App Lock';
  @override String get backupInterval => 'Backup Interval';
  @override String get dataBackup => 'Data Backup';
  @override String get backupReady => 'Backup ready!';
  @override String get backupSubtitle => 'Backup exports all your shop data as an Excel file.';
  @override String get settingsSavedSuccessfully => 'Settings saved successfully';
  @override String get accountInfo => 'Account Info';
  @override String get businessDetails => 'Business Details';
  @override String get storage => 'Storage';

  // ── Manufacturing
  @override String get manageManufacturedProducts => 'Manage Manufactured Products';
  @override String get manageRawMaterials => 'Manage Raw Materials';
  @override String get manageRecipes => 'Manage Recipes';
  @override String get addNewRawMaterial => 'Add New Raw Material';
  @override String get editRawMaterial => 'Edit Raw Material';
  @override String get deleteRawMaterial => 'Delete Material';
  @override String get saveRawMaterial => 'Save Raw Material';
  @override String get updateRawMaterial => 'Update Raw Material';
  @override String get rawMaterialSavedSuccessfully => 'Raw material saved successfully';
  @override String get rawMaterialUpdatedSuccessfully => 'Raw material updated successfully';
  @override String get addIngredient => 'Add Ingredient';
  @override String get addAnotherMaterial => 'Add Another Material';
  @override String get ingredients => 'Ingredients';
  @override String get recipeInformation => 'Recipe Information';
  @override String get materialInformation => 'Material Information';
  @override String get createNewRecipe => 'Create New Recipe';
  @override String get newRecipe => 'New Recipe';
  @override String get editRecipe => 'Edit Recipe';
  @override String get updateRecipe => 'Update Recipe';
  @override String get deleteRecipe => 'Delete Recipe';
  @override String get saveRecipe => 'Save Recipe';
  @override String get recipeSavedSuccessfully => 'Recipe saved successfully';
  @override String get recipeUpdatedSuccessfully => 'Recipe updated successfully';
  @override String get chooseRecipe => 'Choose a recipe';
  @override String get selectRecipe => 'Select Recipe';
  @override String get adjustManufacturedProducts => 'Adjust Manufactured Products';
  @override String get reProduceManufactureProducts => 'Re-Produce Manufacture Products';
  @override String get reProduceProducts => 'Re-produce existing manufactured products.';
  @override String get reProductionSavedSuccessfully => 'Re-production saved successfully';
  @override String get addProductToReproduce => 'Add Product to Re-Produce';
  @override String get noProductsForReproduction => 'No products available for re-production. Add products first.';
  @override String get manufacturingReports => 'Manufacturing Reports';
  @override String get dailyProductionSummary => 'Daily Production Summary';
  @override String get rawMaterialConsumption => 'Raw Material Consumption';
  @override String get productionCostAnalysis => 'Production Cost Analysis';
  @override String get productByRecipe => 'Product by Recipe';
  @override String get noRawMaterialsFound => 'No Raw Materials Found';
  @override String get noManufacturedProducts => 'No Manufactured Products';
  @override String get noManufacturedProductsFound => 'No manufactured products found';
  @override String get noRecipesFound => 'No Recipes Found';
  @override String get noMaterialsFound => 'No materials found';
  @override String get tapToAddMaterial => 'Tap "Add New Raw Material" to get started.';
  @override String get tapToAddRecipe => 'Tap "New Recipe" to get started.';
  @override String get transferProducts => 'Transfer Manufactured Products';
  @override String get transferManufactured => 'Transfer manufactured products to other shops.';
  @override String get restockRawMaterials => 'Restock Raw Materials';
  @override String get restockSavedSuccessfully => 'Restock saved successfully';

  // ── Online Shop / TMS
  @override String get addCategory => 'Add Category';
  @override String get deleteDeliveryMethod => 'Delivery method deleted';
  @override String get shopLinkCopied => 'Shop link copied to clipboard';
  @override String get openingShopUrl => 'Opening shop URL';
  @override String get openingWhatsApp => 'Opening WhatsApp...';
  @override String get couponApplied => 'Coupon applied!';
  @override String get maximumPhotos => 'Maximum 3 photos allowed';
  @override String get noApplicationsYet => 'No applications yet';
  @override String get tapNewApplication => 'Tap "New Application" to apply.';
  @override String get loanPortfolioInsights => 'Loan Portfolio Insights';
  @override String get applyForLoan => 'Apply for TMS Loan';
  @override String get tmsDescription => 'TMS (Traders Microfinance Suite) analyses your sales, stock movement and repayment history to determine loan eligibility and recommended credit limits.';
  @override String get renew => 'Renew';

  // ── System / Misc
  @override String get systemLogs => 'System Logs';
  @override String get noLogsFound => 'No logs found';
  @override String get comingSoon => 'Coming soon';
  @override String get selectReport => 'Select a report to view.';
  @override String get noDataToExport => 'No data to export';
  @override String get printComingSoon => 'Print functionality coming soon';
  @override String get printingReceipt => 'Printing receipt...';
  @override String get printingTestPage => 'Printing test page...';
  @override String get noShopsFound => 'No shops found';
  @override String get loadingShops => 'Loading shops…';
  @override String get selectShops => 'Select Shops';
  @override String get dir => 'Dir';
  @override String get noRecordsFound => 'No Records Found';
  @override String get tryDifferentDateRange => 'Try a different date range or search term.';
  @override String get tryDifferentSearch => 'Try a different search term.';

  // ── Errors / Warnings
  @override String get enterValidAmount => 'Enter a valid amount';
  @override String get pleaseAddAtLeastOneItem => 'Please add at least one item';
  @override String get pleaseFillAllFields => 'Please fill in all fields';
  @override String get noAccountsFound => 'No accounts found. Configure payment accounts first.';
  @override String get failedToLoadAccounts => 'Failed to load accounts';
  @override String get failedToLoadProducts => 'Failed to load products';
  @override String get failedToShareInvoice => 'Failed to share invoice';
  @override String get couldNotCaptureInvoice => 'Could not capture invoice';
  @override String get pleaseEnterTra => 'Please enter TRA Client ID and Password';
  @override String get traVerified => 'TRA authentication verified successfully';

  // ── Navigation / Drawer
  @override String get addShop => 'Add Shop';
  @override String get guide => 'Guide';
  @override String get shopCreatedSuccessfully => 'Shop created successfully';

  // ── Sales — Manage
  @override String get manageSales => 'Manage Sales';
  @override String get backdateSale => 'Backdate Sale';
  @override String get backdate => 'Backdate';
  @override String get selectNewDateForSale => 'Select a new date for this sale';
  @override String get saleDateUpdated => 'Sale date updated';
  @override String get deleteSale => 'Delete Sale';
  @override String get deleteSales => 'Delete Sales';
  @override String get saleDeleted => 'Sale deleted';
  @override String get salesDeleted => 'Sales deleted';
  @override String get amountPaid => 'Amount Paid';
  @override String get exceedsBalance => 'Exceeds balance';
  @override String get viewList => 'View List';
  @override String get download => 'Download';
  @override String get deleteFailed => 'Delete failed';

  // ── Sales — Add Sale
  @override String get editSale => 'Edit Sale';
  @override String get discount => 'Discount';
  @override String get summary => 'Summary';
  @override String get items => 'Items';
  @override String get itemDiscounts => 'Item Discounts';
  @override String get totalAmount => 'Total Amount';
  @override String get totalQuantity => 'Total Quantity';
  @override String get finalAmount => 'Final Amount';
  @override String get paymentType => 'Payment Type';
  @override String get selectCustomer => 'Select Customer';
  @override String get selectProduct => 'Select Product';
  @override String get addItem => 'Add Item';
  @override String get scan => 'Scan';
  @override String get addNewPaymentMode => 'Add New Payment Mode';
  @override String get addPaymentMode => 'Add Payment Mode';
  @override String get enterPaymentModeName => 'Enter payment mode name';
  @override String get searchItemsScanBarcode => 'Search Items / Scan Barcode';
  @override String get noItemsAddedYet => 'No items added yet';
  @override String get saleSavedSuccessfully => 'Sale saved successfully';
  @override String get saleUpdatedSuccessfully => 'Sale updated successfully';
  @override String get failedToSaveSale => 'Failed to save sale';
  @override String get wholesale => 'Wholesale';
  @override String get entries => 'Entries';
  @override String get mobileMoney => 'Mobile Money';
  @override String get bankTransfer => 'Bank Transfer';

  // ── Sales — Orders
  @override String get orders => 'Orders';
  @override String get activeOrders => 'Active Orders';
  @override String get clearedOrders => 'Cleared Orders';
  @override String get newOrder => 'New Order';
  @override String get noOrdersFound => 'No orders found';
  @override String get salesOrderReceipt => 'Sales Order Receipt';
  @override String get deleteOrder => 'Delete Order';
  @override String get deleteOrders => 'Delete Orders';
  @override String get backdateOrder => 'Backdate Order';
  @override String get selectNewDateForOrder => 'Select a new date for this order';
  @override String get orderDeleted => 'Order deleted';
  @override String get ordersDeleted => 'Orders deleted';
  @override String get updateOrderStatus => 'Update Order Status';
  @override String get updateStatus => 'Update Status';
  @override String get paidTotal => 'Paid Total';
  @override String get unpaidTotal => 'Unpaid Total';
  @override String get orderValue => 'Order Value';
  @override String get amountToCollect => 'Amount to Collect';
  @override String get addPayment => 'Add Payment';
  @override String get selectAccount => 'Select Account';
  @override String get customerName => 'Customer Name';
  @override String get statusDate => 'Status Date';
  @override String get purchasedProducts => 'Purchased Products';
  @override String get paymentRecordedSuccessfully => 'Payment recorded successfully';
  @override String get confirmedOrder => 'CONFIRMED ORDER';
  @override String get delivering => 'DELIVERING';
  @override String get delivered => 'DELIVERED';
  @override String get declineOrder => 'DECLINE ORDER';

  // ── Sales — Invoices
  @override String get invoices => 'Invoices';
  @override String get noInvoicesFound => 'No invoices found';
  @override String get generateInvoice => 'Generate Invoice';
  @override String get deleteInvoice => 'Delete Invoice';
  @override String get deleteInvoices => 'Delete Invoices';
  @override String get backdateInvoice => 'Backdate Invoice';
  @override String get selectNewDateForInvoice => 'Select a new date for this invoice';
  @override String get printInvoice => 'Print Invoice';
  @override String get balanceDue => 'Balance Due';
  @override String get paidAmount => 'Paid Amount';
  @override String get paymentMode => 'Payment Mode';
  @override String get subtotal => 'Subtotal';
  @override String get qty => 'Qty';

  // ── Stock
  @override String get manageStock => 'Manage Stock';
  @override String get importStock => 'Import';
  @override String get importFromShop => 'Import From Shop';
  @override String get outOfStock => 'Out of Stock';
  @override String get runningLow => 'Running Low';
  @override String get toExpire => 'To Expire';
  @override String get deleteProducts => 'Delete Products';
  @override String get confirmDeleteProduct => 'Are you sure you want to delete this product?';
  @override String get confirmDeleteProducts => 'Are you sure you want to delete these products?';
  @override String get all => 'All';

  // ── Expenses
  @override String get saveExpense => 'Save Expense';
  @override String get expenseName => 'Expense Name';
  @override String get expenseSavedSuccessfully => 'Expense saved successfully';
  @override String get failedToSaveExpense => 'Failed to save expense';
  @override String get categoryNameHint => 'Category name';
  @override String get enterExpenseName => 'Enter expense name';
  @override String get selectCategory => 'Select category';
  @override String get todayNetProfit => 'Today Net Profit';
  @override String get todayTotalExpenses => 'Today Total Expenses';
  @override String get report => 'Report';
  @override String get detailedBreakdown => 'Detailed Breakdown';

  // ── Customers
  @override String get newCustomer => 'New Customer';
  @override String get deleteCustomer => 'Delete Customer';
  @override String get loyalty => 'Loyalty';
  @override String get loyaltyComingSoon => 'Loyalty feature coming soon';
  @override String get wallet => 'Wallet';
  @override String get tryDifferentSearchOrAddCustomer => 'Try a different search or add a new customer';
  @override String get customerDashboard => 'Customer Dashboard';
  @override String get editCustomer => 'Edit Customer';
  @override String get salesRecords => 'Sales Records';
  @override String get salesSummary => 'Sales Summary';
  @override String get walletTransactions => 'Wallet Transactions';
  @override String get walletBalance => 'Wallet Balance';
  @override String get walletSales => 'Wallet Sales';
  @override String get walletStatement => 'Wallet Statement';
  @override String get creditBalance => 'Credit Balance';
  @override String get creditLimit => 'Credit Limit';
  @override String get clearCredit => 'Clear Credit';
  @override String get addCash => 'Add Cash';
  @override String get addCredit => 'Add Credit';
  @override String get totalSpent => 'Total Spent';
  @override String get deleteTransaction => 'Delete Transaction';
  @override String get transactionDeleted => 'Transaction deleted';
  @override String get noSalesRecordsYet => 'No sales records yet';
  @override String get noWalletTransactionsYet => 'No wallet transactions yet';
  @override String get salePdf => 'Sale PDF';
  @override String get statementPdf => 'Statement PDF';
  @override String get notProvided => 'Not provided';

  // ── Suppliers
  @override String get supplierManagement => 'Supplier Management';
  @override String get newSupplier => 'New Supplier';
  @override String get deleteSupplier => 'Delete Supplier';
  @override String get onCash => 'On Cash';
  @override String get onCredit => 'On Credit';
  @override String get notSet => 'Not set';
  @override String get tryDifferentSearchOrAddSupplier => 'Try a different search or add a new supplier';
  @override String get supplierDashboard => 'Supplier Dashboard';
  @override String get editSupplier => 'Edit Supplier';
  @override String get purchaseSummary => 'Purchase Summary';
  @override String get noCashPurchasesFound => 'No cash purchases found';
  @override String get noCreditPurchasesFound => 'No credit purchases found';
  @override String get noPurchaseOrdersFound => 'No purchase orders found';
  @override String get payCreditPurchase => 'Pay Credit Purchase';
  @override String get completed => 'Completed';
  @override String get partial => 'Partial';
  @override String get pending => 'Pending';
  @override String get company => 'Company';
  @override String get transactions => 'Transactions';
  @override String get outstanding => 'Outstanding';

  // ── Staff
  @override String get searchAttendantByNameOrPhone => 'Search attendant by name or phone…';
  @override String get manager => 'Manager';
  @override String get permissions => 'Permissions';

  // ── Accounts
  @override String get cashIn => 'Cash In';
  @override String get cashOut => 'Cash Out';
  @override String get fromAccountSource => 'From Account (source)';
  @override String get toAccountDestination => 'To Account (destination)';
  @override String get loadingAccounts => 'Loading accounts…';
  @override String get searchCashflow => 'Search cashflow…';
  @override String get selectAccountHint => 'Select account…';
  @override String get balancing => 'Balancing';
  @override String get capital => 'Capital';
  @override String get loan => 'Loan';
  @override String get toBank => 'To Bank';
  @override String get toPersonalUse => 'To Personal Use';
  @override String get customerWallet => 'Customer Wallet';
  @override String get fillAllFieldsAndSelectBothAccounts => 'Fill all fields and select both accounts';

  // ── Profile
  @override String get changePassword => 'Change Password';
  @override String get currentPassword => 'Current Password';
  @override String get newPassword => 'New Password';
  @override String get enterEmail => 'Enter email';
  @override String get enterPhoneNumber => 'Enter phone number';
  @override String get enterRegion => 'Enter region';
  @override String get enterUsername => 'Enter username';
  @override String get region => 'Region';

  // ── Purchases
  @override String get managePurchases => 'Manage Purchases';
  @override String get noPurchasesFound => 'No purchases found';
  @override String get deletePurchase => 'Delete Purchase';
  @override String get deletePurchases => 'Delete Purchases';
  @override String get backdatePurchase => 'Backdate Purchase';
  @override String get selectNewDateForPurchase => 'Select a new date for this purchase';
  @override String get purchaseReceipt => 'Purchase Receipt';
  @override String get returnPurchase => 'Return Purchase';
  @override String get returnAll => 'Return All';
  @override String get returnDate => 'Return Date';
  @override String get confirmReturn => 'Confirm Return';
  @override String get payFromAccount => 'Pay From Account';
  @override String get amountToPay => 'Amount to Pay';
  @override String get totalPurchaseOrders => 'Total Purchase Orders';
  @override String get preview => 'Preview';
  @override String get print => 'Print';

  // ── Purchase Orders
  @override String get purchaseOrders => 'Purchase Orders';
  @override String get newPurchaseOrder => 'New Purchase Order';
  @override String get backdatePurchaseOrder => 'Backdate Purchase Order';
  @override String get updatePurchaseOrderStatus => 'Update Purchase Order Status';
  @override String get outstandingBalance => 'Outstanding Balance';
  @override String get purchaseOrderReceipt => 'Purchase Order Receipt';
  @override String get selectStatus => 'Select Status';
  @override String get orderedProducts => 'Ordered Products';
  @override String get paymentAccount => 'Payment Account';

  // ── Dynamic strings
  @override String deletedItemName(String name) => '${name} deleted';
  @override String deletedMaterialConfirm(String name) => 'Are you sure you want to delete "${name}"? This action cannot be undone.';
  @override String deletedProductConfirm(String name) => 'Are you sure you want to delete "$name"? This action cannot be undone.';
  @override String deletedRecipeConfirm(String name) => 'Are you sure you want to delete "$name"? This action cannot be undone.';
  @override String deletedAttendantName(String name) => '${name} deleted';
  @override String deletedRecordTitle(String title) => '${title} deleted';
  @override String deleteRecordConfirm(String title) => 'Delete "${title}"? This cannot be undone.';
  @override String categoryCleared(String category) => '$category cleared successfully';
  @override String clearCategory(String category) => 'Clear $category';
  @override String nameSettingsSaved(String name) => '$name settings saved';
  @override String shopDeletedSuccessfully(String name) => 'Shop "${name}" deleted successfully';
  @override String controlUsage(String name) => 'Control $name Usage';
  @override String connectingTo(String label) => 'Connecting to $label...';
  @override String orderIdCopied(String orderId) => 'Order ID "$orderId" copied!';
  @override String statusUpdatedTo(String status) => 'Status updated to $status';
  @override String paymentRecordedFor(String name) => 'Payment recorded for $name';
  @override String itemsAvailable(int count) => '$count available';
  @override String itemSelected(int count) => '$count selected';
  @override String addSelectedCount(int count) => 'Add Selected ($count)';
  @override String pageOfPages(int page, int total) => 'Page $page of $total';
  @override String supplierStatementTitle(String name) => 'Supplier Statement - $name';
  @override String productBalance(String balance) => 'Balance: TZS $balance';
  @override String browsingShop(String shopId) => 'Browsing shop #$shopId...';
  @override String trackingOrder(String orderId) => 'Tracking order #$orderId...';
  @override String couponAppliedCode(String code) => 'Coupon "$code" applied!';
  @override String deliveryMethodDeleted(String method) => 'Delivery method "$method" deleted';
  @override String paymentMethodDeleted(String method) => 'Payment method "$method" deleted';
  @override String categoryDeleted(String category) => 'Category "$category" cleared successfully';
  @override String shopDataInfo(String data) => 'Shop "$data"';
  @override String failedError(String e) => 'Failed: $e';
  @override String updateFailedError(String e) => 'Update failed: $e';
  @override String saveFailedError(String e) => 'Save failed: $e';
  @override String deleteFailedError(String e) => 'Delete failed: $e';
  @override String downloadFailedError(String e) => 'Download failed: $e';
  @override String backdateFailedError(String e) => 'Backdate failed: $e';
  @override String orderFailedError(String e) => 'Order failed: $e';
  @override String paymentFailedError(String e) => 'Payment failed: $e';
  @override String failedToLoad(String e) => 'Failed to load: $e';
  @override String missingStockBatch(String names) => 'These products have no stock batch: $names';
  @override String profileImagePath(String path) => path;
  @override String lastBackupCreated(String date) => 'Created: $date';
  @override String importCreated(String date) => 'Created: $date';
  @override String importDeleted(String date) => 'Deleted: $date';
  @override String productAddress(String address) => 'Address: $address';
  @override String productCompany(String company) => 'Company: $company';
  @override String productPhone(String phone) => 'Phone: $phone';
  @override String productTin(String tin) => 'TIN: $tin';
  @override String balanceTzs(String amount) => 'Balance: TZS $amount';
  @override String totalAmountTzs(String amount) => 'Total Amount: TZS $amount';
  @override String paidTzs(String amount) => 'Paid: TZS $amount';
}
