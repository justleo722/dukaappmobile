/// DashboardModel — parses the `getdata/dashboard` API response.
///
/// API response shape (from GET /api/v1/app/get/getdata/dashboard):
/// {
///   "id": 1,
///   "currency": "Tsh",
///   "today_sales": "0.00",
///   "today_profit": "0.0000",
///   "today_expense": "0.00",
///   "today_stockin": "0.0000",
///   "today_topay": "0.00",
///   "today_credit": "0.00",   // to_receive (credit purchases)
///   "today_orders": "0.00",
///   "thismonth_sales": "0.00",
///   "thismonth_profit": "0.0000",
///   "thismonth_expense": "0.00",
///   "thismonth_stockin": "0.0000",
///   ... (this month/year variants)
/// }

class DashboardModel {
  const DashboardModel({
    required this.currency,
    required this.todaySales,
    required this.todayProfit,
    required this.todayExpense,
    required this.todayStockin,
    required this.todayTopay,
    required this.todayCredit,
    required this.todayOrders,
    required this.thisMonthSales,
    required this.thisMonthProfit,
    required this.thisMonthExpense,
    required this.thisMonthStockin,
  });

  final String currency;
  final double todaySales;
  final double todayProfit;
  final double todayExpense;
  final double todayStockin;
  final double todayTopay;
  final double todayCredit;
  final double todayOrders;
  final double thisMonthSales;
  final double thisMonthProfit;
  final double thisMonthExpense;
  final double thisMonthStockin;

  static double _d(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0.0;

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      currency: json['currency']?.toString() ?? 'Tsh',
      todaySales: _d(json['today_sales']),
      todayProfit: _d(json['today_profit']),
      todayExpense: _d(json['today_expense']),
      todayStockin: _d(json['today_stockin']),
      todayTopay: _d(json['today_topay']),
      todayCredit: _d(json['today_credit']),
      todayOrders: _d(json['today_orders']),
      thisMonthSales: _d(json['thismonth_sales']),
      thisMonthProfit: _d(json['thismonth_profit']),
      thisMonthExpense: _d(json['thismonth_expense']),
      thisMonthStockin: _d(json['thismonth_stockin']),
    );
  }

  Map<String, dynamic> toJson() => {
    'currency'          : currency,
    'today_sales'       : todaySales,
    'today_profit'      : todayProfit,
    'today_expense'     : todayExpense,
    'today_stockin'     : todayStockin,
    'today_topay'       : todayTopay,
    'today_credit'      : todayCredit,
    'today_orders'      : todayOrders,
    'thismonth_sales'   : thisMonthSales,
    'thismonth_profit'  : thisMonthProfit,
    'thismonth_expense' : thisMonthExpense,
    'thismonth_stockin' : thisMonthStockin,
  };

  static const DashboardModel empty = DashboardModel(
    currency: 'Tsh',
    todaySales: 0,
    todayProfit: 0,
    todayExpense: 0,
    todayStockin: 0,
    todayTopay: 0,
    todayCredit: 0,
    todayOrders: 0,
    thisMonthSales: 0,
    thisMonthProfit: 0,
    thisMonthExpense: 0,
    thisMonthStockin: 0,
  );
}
