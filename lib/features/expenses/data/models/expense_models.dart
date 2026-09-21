/// Data models for the Expenses module.
class ExpenseItem {
  final String flowId;
  final String date;
  final String title;
  final String category;
  final double amount;
  final String currency;
  final String? note;
  final String? account;

  const ExpenseItem({
    required this.flowId,
    required this.date,
    required this.title,
    required this.category,
    required this.amount,
    required this.currency,
    this.note,
    this.account,
  });

  factory ExpenseItem.fromJson(Map<String, dynamic> j) {
    return ExpenseItem(
      flowId: j['flow_id']?.toString() ?? '',
      date: j['record_date']?.toString() ?? '',
      // cashflow.title is the primary label; fall back to note or category
      title: j['title']?.toString().isNotEmpty == true
          ? j['title'].toString()
          : (j['note']?.toString() ?? j['description']?.toString() ?? ''),
      category: j['account_name']?.toString() ?? j['category']?.toString() ?? 'Expense',
      amount: _toDouble(j['amount']),
      currency: j['currency']?.toString() ?? 'TSh',
      note: j['note']?.toString(),
      account: j['account_name']?.toString(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class ExpenseSummary {
  final double totalExpenses;
  final double todayExpenses;
  final double totalSales;
  final double grossProfit;
  final double netProfit;
  final double badStock;
  final double cashInHand;

  const ExpenseSummary({
    this.totalExpenses = 0,
    this.todayExpenses = 0,
    this.totalSales = 0,
    this.grossProfit = 0,
    this.netProfit = 0,
    this.badStock = 0,
    this.cashInHand = 0,
  });

  static const empty = ExpenseSummary();

  factory ExpenseSummary.fromJson(Map<String, dynamic> j) {
    return ExpenseSummary(
      totalExpenses: _toDouble(j['total_expense'] ?? j['total_expenses'] ?? j['total_amount'] ?? j['expense']),
      todayExpenses: _toDouble(j['today_expense'] ?? j['today_expenses']),
      totalSales: _toDouble(j['total_sales'] ?? j['sales']),
      grossProfit: _toDouble(j['gross_profit'] ?? j['profit']),
      netProfit: _toDouble(j['net_profit'] ?? j['netprofit']),
      badStock: _toDouble(j['bad_stock'] ?? j['bad_stock_value']),
      cashInHand: _toDouble(j['cash_in_hand'] ?? j['cash_inhand']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class ExpenseAccount {
  final String accountId;
  final String name;

  const ExpenseAccount({required this.accountId, required this.name});

  factory ExpenseAccount.fromJson(Map<String, dynamic> j) => ExpenseAccount(
        accountId: j['account_id']?.toString() ?? '',
        name: j['account_name']?.toString() ?? '',
      );
}
