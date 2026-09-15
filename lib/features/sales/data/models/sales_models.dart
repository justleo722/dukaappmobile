/// Sales module data models.
///
/// Covers:
///   • [SalesSummary]    — summary card totals (paid, unpaid, total, vat)
///   • [SaleRecord]      — a single sale / invoice / order record
///   • [SaleProduct]     — a line item inside a sale
///   • [OrderSummary]    — order summary card
///   • [InvoiceSummary]  — invoice summary card
///   • [PaymentMode]     — payment mode used in a sale
///   • Report models: [TotalSaleItem], [CreditSaleItem], [SaleByProduct],
///     [SaleByCategory], [SaleByPayment], [SaleByCustomer], [SaleByStaff],
///     [CombinedTotalSaleItem], [CombinedStaffSale], [TeamSale],
///     [InvoiceReportItem], [CustomerCreditItem], [VatSaleItem],
///     [NonVatSaleItem], [StaffSaleByItem], [UnpaidProductSale]

// ignore_for_file: invalid_annotation_target

/// ─── Summary cards ────────────────────────────────────────────────────────

class SalesSummary {
  final double paid;
  final double unpaid;
  final double total;
  final double vat;
  final String currency;

  const SalesSummary({
    this.paid = 0,
    this.unpaid = 0,
    this.total = 0,
    this.vat = 0,
    this.currency = 'Tsh',
  });

  factory SalesSummary.fromJson(Map<String, dynamic> j) => SalesSummary(
        paid: _d(j['paid']),
        unpaid: _d(j['unpaid']),
        total: _d(j['total']),
        vat: _d(j['vat']),
        currency: (j['currency'] as String?) ?? 'Tsh',
      );

  static const empty = SalesSummary();
}

class OrderSummary {
  final double total;
  final double paid;
  final double unpaid;
  final String currency;

  const OrderSummary({
    this.total = 0,
    this.paid = 0,
    this.unpaid = 0,
    this.currency = 'Tsh',
  });

  factory OrderSummary.fromJson(Map<String, dynamic> j) => OrderSummary(
        total: _d(j['total']),
        paid: _d(j['paid']),
        unpaid: _d(j['unpaid']),
        currency: (j['currency'] as String?) ?? 'Tsh',
      );

  static const empty = OrderSummary();
}

class InvoiceSummary {
  final double total;
  final double paid;
  final double unpaid;
  final String currency;

  const InvoiceSummary({
    this.total = 0,
    this.paid = 0,
    this.unpaid = 0,
    this.currency = 'Tsh',
  });

  factory InvoiceSummary.fromJson(Map<String, dynamic> j) => InvoiceSummary(
        total: _d(j['total']),
        paid: _d(j['paid']),
        unpaid: _d(j['unpaid']),
        currency: (j['currency'] as String?) ?? 'Tsh',
      );

  static const empty = InvoiceSummary();
}

/// ─── Sale record ─────────────────────────────────────────────────────────

class SaleProduct {
  final String name;
  final int quantity;
  final double price;
  final double total;
  final double discount;
  final String productId;
  final String stockId;

  const SaleProduct({
    required this.name,
    required this.quantity,
    required this.price,
    required this.total,
    this.discount = 0,
    this.productId = '',
    this.stockId = '',
  });

  factory SaleProduct.fromJson(Map<String, dynamic> j) => SaleProduct(
        name: (j['product_name'] ?? j['name'] ?? '').toString(),
        quantity: _i(j['qty'] ?? j['quantity']),
        price: _d(j['price_per_unit'] ?? j['unit_price'] ?? j['price'] ?? j['selling_price']),
        total: _d(j['total_price'] ?? j['subtotal'] ?? j['total'] ?? j['total_amount']),
        discount: _d(j['discount']),
        productId: (j['product_id'] ?? '').toString(),
        stockId: (j['stock_id'] ?? '').toString(),
      );
}

class SaleRecord {
  final String saleId;
  final String date;
  final String paymentStatus; // Paid / Credit / Pending
  final String soldBy;
  final String total;
  final double totalRaw;
  final List<SaleProduct> products;
  final String paymentMethod;
  final double paid;
  final double discount;
  final double balance;
  final String customer;
  final String saleType; // cashsale / invoice / order
  final String? invoiceNo;

  const SaleRecord({
    required this.saleId,
    required this.date,
    required this.paymentStatus,
    required this.soldBy,
    required this.total,
    required this.totalRaw,
    required this.products,
    required this.paymentMethod,
    required this.paid,
    required this.discount,
    required this.balance,
    required this.customer,
    this.saleType = 'cashsale',
    this.invoiceNo,
  });

  factory SaleRecord.fromJson(Map<String, dynamic> j) {
    // API returns items/products as key 'items' (from sales_table_data) or 'products'
    final rawProducts = j['items'] ?? j['products'];
    final List<SaleProduct> prods = rawProducts is List
        ? rawProducts
            .whereType<Map<String, dynamic>>()
            .map(SaleProduct.fromJson)
            .toList()
        : [];

    final totalRaw = _d(j['total_amount'] ?? j['total']);
    final currency = (j['currency'] as String?) ?? 'Tsh';
    final paid = _d(j['paid_amount'] ?? j['paid']);
    final balance = _d(j['balance_amount'] ?? j['balance']);

    // Determine payment status label
    String paymentStatus = 'Paid';
    final saleType = (j['sale_type'] ?? '').toString().toLowerCase();
    if (saleType == 'invoice') {
      paymentStatus = 'Invoice';
    } else if (saleType == 'order' || saleType == 'orders') {
      paymentStatus = 'Order';
    } else if (balance > 0.01) {
      paymentStatus = 'Credit';
    } else if (paid <= 0) {
      paymentStatus = 'Pending';
    }

    return SaleRecord(
      saleId: (j['sale_id'] ?? j['id'] ?? '').toString(),
      date: (j['date'] ?? j['record_date'] ?? j['created_at'] ?? '').toString(),
      paymentStatus: paymentStatus,
      soldBy: (j['sold_by'] ?? j['username'] ?? j['created_by_name'] ?? '').toString(),
      total: '$currency ${_formatNumber(totalRaw)}',
      totalRaw: totalRaw,
      products: prods,
      paymentMethod: (j['payment_mode'] ?? j['payment_method'] ?? '').toString(),
      paid: paid,
      discount: _d(j['discount']),
      balance: balance,
      customer: (j['customer'] ?? j['customer_name'] ?? 'Walk-in').toString(),
      saleType: saleType,
      invoiceNo: j['invoice_no']?.toString(),
    );
  }
}

/// ─── Report item models ──────────────────────────────────────────────────

class TotalSaleItem {
  final int sn;
  final String date;
  final String type;
  final double profit;
  final double total;
  final double paid;
  final double balance;

  const TotalSaleItem({
    required this.sn,
    required this.date,
    required this.type,
    required this.profit,
    required this.total,
    required this.paid,
    required this.balance,
  });

  factory TotalSaleItem.fromJson(int sn, Map<String, dynamic> j) => TotalSaleItem(
        sn: sn,
        date: (j['date'] ?? j['record_date'] ?? '').toString(),
        type: (j['payment_mode'] ?? j['type'] ?? '').toString(),
        profit: _d(j['profit']),
        total: _d(j['total_amount'] ?? j['total']),
        paid: _d(j['paid_amount'] ?? j['paid']),
        balance: _d(j['balance_amount'] ?? j['balance']),
      );
}

class CreditSaleItem {
  final int sn;
  final String date;
  final String customer;
  final String type;
  final double total;
  final double paid;
  final double balance;

  const CreditSaleItem({
    required this.sn,
    required this.date,
    required this.customer,
    required this.type,
    required this.total,
    required this.paid,
    required this.balance,
  });

  factory CreditSaleItem.fromJson(int sn, Map<String, dynamic> j) => CreditSaleItem(
        sn: sn,
        date: (j['date'] ?? j['record_date'] ?? '').toString(),
        customer: (j['customer'] ?? j['customer_name'] ?? 'Walk-in').toString(),
        type: (j['payment_mode'] ?? j['type'] ?? '').toString(),
        total: _d(j['total_amount'] ?? j['total']),
        paid: _d(j['paid_amount'] ?? j['paid']),
        balance: _d(j['balance_amount'] ?? j['balance']),
      );
}

class SaleByProduct {
  final int sn;
  final String date;
  final String product;
  final String type;
  final double bp;
  final double sp;
  final int qty;
  final double total;
  final double discount;
  final double profit;

  const SaleByProduct({
    required this.sn,
    required this.date,
    required this.product,
    required this.type,
    required this.bp,
    required this.sp,
    required this.qty,
    required this.total,
    required this.discount,
    required this.profit,
  });

  factory SaleByProduct.fromJson(int sn, Map<String, dynamic> j) => SaleByProduct(
        sn: sn,
        date: (j['date'] ?? j['record_date'] ?? '').toString(),
        product: (j['product_name'] ?? j['name'] ?? j['product'] ?? '').toString(),
        type: (j['payment_mode'] ?? j['type'] ?? '').toString(),
        bp: _d(j['buying_price'] ?? j['bp']),
        sp: _d(j['selling_price'] ?? j['sp'] ?? j['price']),
        qty: _i(j['quantity'] ?? j['qty']),
        total: _d(j['total']),
        discount: _d(j['discount']),
        profit: _d(j['profit']),
      );
}

class SaleByCategory {
  final int sn;
  final String category;
  final String lastSale;
  final double total;
  final double profit;

  const SaleByCategory({
    required this.sn,
    required this.category,
    required this.lastSale,
    required this.total,
    required this.profit,
  });

  factory SaleByCategory.fromJson(int sn, Map<String, dynamic> j) => SaleByCategory(
        sn: sn,
        category: (j['category'] ?? j['category_name'] ?? '').toString(),
        lastSale: (j['last_sale'] ?? j['date'] ?? '').toString(),
        total: _d(j['total']),
        profit: _d(j['profit']),
      );
}

class SaleByPayment {
  final int sn;
  final String mode;
  final double total;

  const SaleByPayment({
    required this.sn,
    required this.mode,
    required this.total,
  });

  factory SaleByPayment.fromJson(int sn, Map<String, dynamic> j) => SaleByPayment(
        sn: sn,
        mode: (j['payment_mode'] ?? j['mode'] ?? j['name'] ?? '').toString(),
        total: _d(j['total']),
      );
}

class SaleByCustomer {
  final int sn;
  final String customer;
  final double total;
  final double paid;
  final double salesBalance;
  final double creditBalance;

  const SaleByCustomer({
    required this.sn,
    required this.customer,
    required this.total,
    required this.paid,
    required this.salesBalance,
    required this.creditBalance,
  });

  factory SaleByCustomer.fromJson(int sn, Map<String, dynamic> j) => SaleByCustomer(
        sn: sn,
        customer: (j['customer'] ?? j['customer_name'] ?? '').toString(),
        total: _d(j['total']),
        paid: _d(j['paid']),
        salesBalance: _d(j['sales_balance'] ?? j['balance']),
        creditBalance: _d(j['credit_balance'] ?? j['wallet_balance'] ?? 0),
      );
}

class SaleByStaff {
  final int sn;
  final String staff;
  final double total;

  const SaleByStaff({
    required this.sn,
    required this.staff,
    required this.total,
  });

  factory SaleByStaff.fromJson(int sn, Map<String, dynamic> j) => SaleByStaff(
        sn: sn,
        staff: (j['staff'] ?? j['username'] ?? j['name'] ?? '').toString(),
        total: _d(j['total']),
      );
}

class CombinedTotalSaleItem {
  final int sn;
  final String attendantId;
  final String staff;
  final String shop;
  final double sales;
  final double total;

  const CombinedTotalSaleItem({
    required this.sn,
    required this.attendantId,
    required this.staff,
    required this.shop,
    required this.sales,
    required this.total,
  });

  factory CombinedTotalSaleItem.fromJson(int sn, Map<String, dynamic> j) =>
      CombinedTotalSaleItem(
        sn: sn,
        attendantId: (j['attendant_id'] ?? j['role_id'] ?? '').toString(),
        staff: (j['staff'] ?? j['username'] ?? '').toString(),
        shop: (j['shop'] ?? j['shop_name'] ?? '').toString(),
        sales: _d(j['sales'] ?? j['count']),
        total: _d(j['total']),
      );
}

class CombinedStaffSale {
  final int sn;
  final String shop;
  final String attendantId;
  final String staff;
  final double sales;
  final double total;
  final double paid;
  final double balance;

  const CombinedStaffSale({
    required this.sn,
    required this.shop,
    required this.attendantId,
    required this.staff,
    required this.sales,
    required this.total,
    required this.paid,
    required this.balance,
  });

  factory CombinedStaffSale.fromJson(int sn, Map<String, dynamic> j) =>
      CombinedStaffSale(
        sn: sn,
        shop: (j['shop'] ?? j['shop_name'] ?? '').toString(),
        attendantId: (j['attendant_id'] ?? j['role_id'] ?? '').toString(),
        staff: (j['staff'] ?? j['username'] ?? '').toString(),
        sales: _d(j['sales'] ?? j['count']),
        total: _d(j['total']),
        paid: _d(j['paid']),
        balance: _d(j['balance']),
      );
}

class TeamSale {
  final int sn;
  final String date;
  final String staff;
  final String type;
  final double total;

  const TeamSale({
    required this.sn,
    required this.date,
    required this.staff,
    required this.type,
    required this.total,
  });

  factory TeamSale.fromJson(int sn, Map<String, dynamic> j) => TeamSale(
        sn: sn,
        date: (j['date'] ?? j['record_date'] ?? '').toString(),
        staff: (j['staff'] ?? j['username'] ?? '').toString(),
        type: (j['payment_mode'] ?? j['type'] ?? '').toString(),
        total: _d(j['total']),
      );
}

class InvoiceReportItem {
  final int sn;
  final String date;
  final String customer;
  final String type;
  final String invoiceStatus;
  final double total;
  final double paid;
  final double balance;

  const InvoiceReportItem({
    required this.sn,
    required this.date,
    required this.customer,
    required this.type,
    required this.invoiceStatus,
    required this.total,
    required this.paid,
    required this.balance,
  });

  factory InvoiceReportItem.fromJson(int sn, Map<String, dynamic> j) =>
      InvoiceReportItem(
        sn: sn,
        date: (j['date'] ?? j['record_date'] ?? '').toString(),
        customer: (j['customer'] ?? j['customer_name'] ?? '').toString(),
        type: (j['payment_mode'] ?? j['type'] ?? '').toString(),
        invoiceStatus: (j['invoice_status'] ?? j['status'] ?? 'Pending').toString(),
        total: _d(j['total_amount'] ?? j['total']),
        paid: _d(j['paid_amount'] ?? j['paid']),
        balance: _d(j['balance_amount'] ?? j['balance']),
      );
}

class CustomerCreditItem {
  final int sn;
  final String lastCreditDate;
  final String customer;
  final String phone;
  final double creditSales;
  final double total;
  final double paid;
  final double creditBalance;

  const CustomerCreditItem({
    required this.sn,
    required this.lastCreditDate,
    required this.customer,
    required this.phone,
    required this.creditSales,
    required this.total,
    required this.paid,
    required this.creditBalance,
  });

  factory CustomerCreditItem.fromJson(int sn, Map<String, dynamic> j) =>
      CustomerCreditItem(
        sn: sn,
        lastCreditDate: (j['last_credit_date'] ?? j['date'] ?? '').toString(),
        customer: (j['customer'] ?? j['customer_name'] ?? '').toString(),
        phone: (j['phone'] ?? '').toString(),
        creditSales: _d(j['credit_sales'] ?? j['sales_count'] ?? j['count'] ?? 0),
        total: _d(j['total']),
        paid: _d(j['paid']),
        creditBalance: _d(j['credit_balance'] ?? j['balance']),
      );
}

class VatSaleItem {
  final int sn;
  final String date;
  final String type;
  final double vat;
  final double total;
  final double paid;
  final double balance;

  const VatSaleItem({
    required this.sn,
    required this.date,
    required this.type,
    required this.vat,
    required this.total,
    required this.paid,
    required this.balance,
  });

  factory VatSaleItem.fromJson(int sn, Map<String, dynamic> j) => VatSaleItem(
        sn: sn,
        date: (j['date'] ?? j['record_date'] ?? '').toString(),
        type: (j['payment_mode'] ?? j['type'] ?? '').toString(),
        vat: _d(j['vat']),
        total: _d(j['total_amount'] ?? j['total']),
        paid: _d(j['paid_amount'] ?? j['paid']),
        balance: _d(j['balance_amount'] ?? j['balance']),
      );
}

class NonVatSaleItem {
  final int sn;
  final String date;
  final String type;
  final double total;
  final double paid;
  final double balance;

  const NonVatSaleItem({
    required this.sn,
    required this.date,
    required this.type,
    required this.total,
    required this.paid,
    required this.balance,
  });

  factory NonVatSaleItem.fromJson(int sn, Map<String, dynamic> j) => NonVatSaleItem(
        sn: sn,
        date: (j['date'] ?? j['record_date'] ?? '').toString(),
        type: (j['payment_mode'] ?? j['type'] ?? '').toString(),
        total: _d(j['total_amount'] ?? j['total']),
        paid: _d(j['paid_amount'] ?? j['paid']),
        balance: _d(j['balance_amount'] ?? j['balance']),
      );
}

class StaffSaleByItem {
  final int sn;
  final String staff;
  final String item;
  final int qty;
  final double amount;

  const StaffSaleByItem({
    required this.sn,
    required this.staff,
    required this.item,
    required this.qty,
    required this.amount,
  });

  factory StaffSaleByItem.fromJson(int sn, Map<String, dynamic> j) => StaffSaleByItem(
        sn: sn,
        staff: (j['staff'] ?? j['username'] ?? '').toString(),
        item: (j['product_name'] ?? j['item'] ?? j['name'] ?? '').toString(),
        qty: _i(j['quantity'] ?? j['qty']),
        amount: _d(j['total'] ?? j['amount']),
      );
}

class UnpaidProductSale {
  final int sn;
  final String product;
  final String category;
  final String lastSale;
  final double total;
  final double paid;
  final double balance;
  final double profit;

  const UnpaidProductSale({
    required this.sn,
    required this.product,
    required this.category,
    required this.lastSale,
    required this.total,
    required this.paid,
    required this.balance,
    required this.profit,
  });

  factory UnpaidProductSale.fromJson(int sn, Map<String, dynamic> j) =>
      UnpaidProductSale(
        sn: sn,
        product: (j['product_name'] ?? j['name'] ?? j['product'] ?? '').toString(),
        category: (j['category'] ?? j['category_name'] ?? '').toString(),
        lastSale: (j['last_sale'] ?? j['date'] ?? '').toString(),
        total: _d(j['total']),
        paid: _d(j['paid']),
        balance: _d(j['balance']),
        profit: _d(j['profit']),
      );
}

class AllOrderItem {
  final int sn;
  final String date;
  final String type;
  final double total;
  final double paid;
  final double unpaid;

  const AllOrderItem({
    required this.sn,
    required this.date,
    required this.type,
    required this.total,
    required this.paid,
    required this.unpaid,
  });

  factory AllOrderItem.fromJson(int sn, Map<String, dynamic> j) => AllOrderItem(
        sn: sn,
        date: (j['date'] ?? j['record_date'] ?? '').toString(),
        type: (j['payment_mode'] ?? j['type'] ?? '').toString(),
        total: _d(j['total_amount'] ?? j['total']),
        paid: _d(j['paid_amount'] ?? j['paid']),
        unpaid: _d(j['balance_amount'] ?? j['balance'] ?? j['unpaid']),
      );
}

// ── Helpers ──────────────────────────────────────────────────────────────────

double _d(dynamic v) {
  if (v == null) return 0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _i(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  // Handle decimal strings like "1.00" from MySQL DECIMAL columns.
  final s = v.toString();
  return int.tryParse(s) ?? double.tryParse(s)?.toInt() ?? 0;
}

String _formatNumber(double v) {
  if (v == v.roundToDouble()) {
    return v.toInt().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]},',
        );
  }
  return v.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+\.)'),
        (m) => '${m[1]},',
      );
}
