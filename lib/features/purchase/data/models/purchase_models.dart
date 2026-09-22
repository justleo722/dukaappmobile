/// Data models for the Purchase module.

class PurchaseItem {
  final dynamic purchaseId;
  final String date;
  final String supplier;
  final double totalAmount;
  final double paidAmount;
  final double balance;
  final String paymentStatus;
  final String purchaseType;
  final String createdBy;
  final String currency;
  final List<Map<String, dynamic>> items;

  const PurchaseItem({
    required this.purchaseId,
    required this.date,
    required this.supplier,
    required this.totalAmount,
    required this.paidAmount,
    required this.balance,
    required this.paymentStatus,
    required this.purchaseType,
    required this.createdBy,
    required this.currency,
    this.items = const [],
  });

  factory PurchaseItem.fromJson(Map<String, dynamic> j) {
    final rawItems = j['items'] as List? ?? j['products'] as List? ?? [];
    return PurchaseItem(
      purchaseId: j['purchase_id'] ?? j['id'],
      date: j['record_date']?.toString() ?? j['date']?.toString() ?? '',
      supplier: j['supplier']?.toString() ?? j['supplier_name']?.toString() ?? '',
      totalAmount: _toDouble(j['total_amount']),
      paidAmount: _toDouble(j['paid_amount']),
      balance: _toDouble(j['balance_amount'] ?? j['balance']),
      paymentStatus: j['payment_status']?.toString() ?? j['status_label']?.toString() ?? j['purchase_group']?.toString() ?? 'pending',
      purchaseType: j['purchase_type']?.toString() ?? j['purchase_group']?.toString() ?? 'purchase',
      createdBy: j['username']?.toString() ?? '',
      currency: j['currency']?.toString() ?? 'TSh',
      // Normalise each item so downstream pages can safely use typed values.
      items: rawItems.whereType<Map<String, dynamic>>().map((item) => {
        'name': item['product_name']?.toString() ?? item['name']?.toString() ?? '',
        'price': _toDouble(item['price'] ?? item['cost_price'] ?? item['buying_price'] ?? item['unit_price'] ?? item['bp']),
        'quantity': _toInt(item['quantity'] ?? item['qty']),
        'total': _toDouble(item['total'] ?? item['total_price'] ?? item['subtotal']),
        'discount': _toDouble(item['discount']),
        'product_id': item['product_id'] ?? item['id'],
        'stock_id': item['stock_id'],
      }).toList(),
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? double.tryParse(v.toString())?.toInt() ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class PurchaseSummary {
  final double totalAmount;
  final double paidAmount;
  final double balance;
  final int count;

  const PurchaseSummary({
    this.totalAmount = 0,
    this.paidAmount = 0,
    this.balance = 0,
    this.count = 0,
  });

  static const empty = PurchaseSummary();

  factory PurchaseSummary.fromJson(Map<String, dynamic> j) => PurchaseSummary(
        totalAmount: _toDouble(j['total_amount'] ?? j['total']),
        paidAmount: _toDouble(j['paid_amount'] ?? j['paid']),
        balance: _toDouble(j['balance_amount'] ?? j['balance']),
        count: (j['count'] as num?)?.toInt() ?? 0,
      );

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
