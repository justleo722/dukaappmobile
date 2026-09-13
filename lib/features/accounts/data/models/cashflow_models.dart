/// Data models for the Accounts / Cashflow module.
class CashflowItem {
  final String flowId;
  final String date;
  final String name;         // account_name or note
  final double cashIn;
  final double cashOut;
  final String currency;
  final String? note;

  const CashflowItem({
    required this.flowId,
    required this.date,
    required this.name,
    required this.cashIn,
    required this.cashOut,
    required this.currency,
    this.note,
  });

  double get balance => cashIn - cashOut;

  factory CashflowItem.fromJson(Map<String, dynamic> j) {
    return CashflowItem(
      flowId: j['flow_id']?.toString() ?? '',
      date: j['record_date']?.toString() ?? '',
      name: j['name']?.toString() ?? j['account_name']?.toString() ?? j['note']?.toString() ?? '',
      cashIn: _toDouble(j['cash_in'] ?? j['credit'] ?? j['amount_in']),
      cashOut: _toDouble(j['cash_out'] ?? j['debit'] ?? j['amount_out']),
      currency: j['currency']?.toString() ?? 'TSh',
      note: j['note']?.toString(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class CashflowSummary {
  final double totalCashIn;
  final double totalCashOut;
  final double cashInHand;
  final double customerWallets;

  const CashflowSummary({
    this.totalCashIn = 0,
    this.totalCashOut = 0,
    this.cashInHand = 0,
    this.customerWallets = 0,
  });

  static const empty = CashflowSummary();

  factory CashflowSummary.fromJson(Map<String, dynamic> j) => CashflowSummary(
        totalCashIn: _toDouble(j['cash_in'] ?? j['total_credit'] ?? j['total_in']),
        totalCashOut: _toDouble(j['cash_out'] ?? j['total_debit'] ?? j['total_out']),
        cashInHand: _toDouble(j['cash_in_hand'] ?? j['balance'] ?? j['net']),
        customerWallets: _toDouble(j['customer_wallets'] ?? j['customer_wallet']),
      );

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
