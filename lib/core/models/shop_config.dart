import 'dart:convert';

/// Cached shop settings that control feature visibility across the app.
class ShopConfig {
  final String shopName;
  final String currency;
  final String shopType;

  // Dashboard KPI visibility
  final bool showTodaySales;
  final bool showTodayProfit;
  final bool showTodayExpenses;
  final bool showTodayStockIn;
  final bool showToPay;
  final bool showToReceive;
  final bool showOrders;
  final bool showCashInHand;
  final bool enableHomepageLiveSummary;

  // Feature flags
  final bool enableVat;
  final double vatRate;
  final String vatPolicy;
  final bool enableManufacturing;
  final bool enableOnlineStore;
  final bool enableReceiptMode;
  final bool enablePrinter;
  final bool enableEfd;
  final bool enableBarcodeScanner;
  final bool enableFifoMode;
  final bool useWholesalePrice;
  final bool enableQuickActions;
  final bool enableFinancialReports;

  const ShopConfig({
    this.shopName = '',
    this.currency = 'TZS',
    this.shopType = 'All',
    this.showTodaySales = true,
    this.showTodayProfit = true,
    this.showTodayExpenses = true,
    this.showTodayStockIn = true,
    this.showToPay = true,
    this.showToReceive = true,
    this.showOrders = true,
    this.showCashInHand = true,
    this.enableHomepageLiveSummary = true,
    this.enableVat = false,
    this.vatRate = 18.0,
    this.vatPolicy = 'exclusive',
    this.enableManufacturing = false,
    this.enableOnlineStore = false,
    this.enableReceiptMode = false,
    this.enablePrinter = false,
    this.enableEfd = false,
    this.enableBarcodeScanner = false,
    this.enableFifoMode = false,
    this.useWholesalePrice = false,
    this.enableQuickActions = true,
    this.enableFinancialReports = true,
  });

  static bool _b(dynamic v, {bool fallback = true}) {
    if (v == null) return fallback;
    if (v is bool) return v;
    final s = v.toString().toLowerCase().trim();
    return s == '1' || s == 'true' || s == 'yes' || s == 'on';
  }

  factory ShopConfig.fromMap(Map<String, dynamic> m) {
    return ShopConfig(
      shopName: m['shop_name']?.toString() ?? '',
      currency: m['currency']?.toString() ?? 'TZS',
      shopType: m['shop_type']?.toString() ?? 'All',
      showTodaySales: _b(m['show_todaysales']),
      showTodayProfit: _b(m['show_todayprofit']),
      showTodayExpenses: _b(m['show_expenses']),
      showTodayStockIn: _b(m['show_todaystockin']),
      showToPay: _b(m['show_topay']),
      showToReceive: _b(m['show_toreceive']),
      showOrders: _b(m['show_orders']),
      showCashInHand: _b(m['show_cashinhand']),
      enableHomepageLiveSummary: _b(m['enable_homepage_live_summary']),
      enableVat: _b(m['enable_vat'], fallback: false),
      vatRate: double.tryParse(m['vat_rate']?.toString() ?? '') ?? 18.0,
      vatPolicy: m['vat_policy']?.toString() ?? 'exclusive',
      enableManufacturing: _b(m['enable_manufacturing'], fallback: false),
      enableOnlineStore: _b(m['enable_online_store'], fallback: false),
      enableReceiptMode: _b(m['enable_receipt_mode'], fallback: false),
      enablePrinter: _b(m['enable_printer'], fallback: false),
      enableEfd: _b(m['enable_efd'], fallback: false),
      enableBarcodeScanner: _b(m['enable_barcode_scanner'], fallback: false),
      enableFifoMode: _b(m['enable_fifo_mode'], fallback: false),
      useWholesalePrice: _b(m['use_wholesale_price'], fallback: false),
      enableQuickActions: _b(m['enable_quick_actions']),
      enableFinancialReports: _b(m['enable_financial_reports']),
    );
  }

  Map<String, dynamic> toMap() => {
    'shop_name': shopName,
    'currency': currency,
    'shop_type': shopType,
    'show_todaysales': showTodaySales ? '1' : '0',
    'show_todayprofit': showTodayProfit ? '1' : '0',
    'show_expenses': showTodayExpenses ? '1' : '0',
    'show_todaystockin': showTodayStockIn ? '1' : '0',
    'show_topay': showToPay ? '1' : '0',
    'show_toreceive': showToReceive ? '1' : '0',
    'show_orders': showOrders ? '1' : '0',
    'show_cashinhand': showCashInHand ? '1' : '0',
    'enable_homepage_live_summary': enableHomepageLiveSummary ? '1' : '0',
    'enable_vat': enableVat ? '1' : '0',
    'vat_rate': vatRate.toString(),
    'vat_policy': vatPolicy,
    'enable_manufacturing': enableManufacturing ? '1' : '0',
    'enable_online_store': enableOnlineStore ? '1' : '0',
    'enable_receipt_mode': enableReceiptMode ? '1' : '0',
    'enable_printer': enablePrinter ? '1' : '0',
    'enable_efd': enableEfd ? '1' : '0',
    'enable_barcode_scanner': enableBarcodeScanner ? '1' : '0',
    'enable_fifo_mode': enableFifoMode ? '1' : '0',
    'use_wholesale_price': useWholesalePrice ? '1' : '0',
    'enable_quick_actions': enableQuickActions ? '1' : '0',
    'enable_financial_reports': enableFinancialReports ? '1' : '0',
  };

  String toJson() => jsonEncode(toMap());

  factory ShopConfig.fromJson(String source) =>
      ShopConfig.fromMap(jsonDecode(source) as Map<String, dynamic>);

  static const ShopConfig defaults = ShopConfig();
}
