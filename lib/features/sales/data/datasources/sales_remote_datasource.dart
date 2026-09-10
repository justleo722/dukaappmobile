import 'package:dukaapp/core/services/api_service.dart';
import 'package:dukaapp/features/sales/data/models/sales_models.dart';

/// Remote datasource for the Sales module.
///
/// Wraps [ApiService] and returns typed models.
class SalesRemoteDatasource {
  const SalesRemoteDatasource(this._api);

  final ApiService _api;

  // ── Summary cards ──────────────────────────────────────────────────────────

  Future<SalesSummary> fetchSalesSummary({String? from, String? to}) async {
    final res = await _api.getSalesSummary(from: from, to: to);
    final raw = res.data;
    if (raw == null) return SalesSummary.empty;
    final j = raw is List ? (raw.isNotEmpty ? raw[0] : null) : raw;
    if (j is! Map<String, dynamic>) return SalesSummary.empty;
    return SalesSummary.fromJson(j);
  }

  Future<OrderSummary> fetchOrderSummary({String? from, String? to}) async {
    final res = await _api.getOrderSummary(from: from, to: to);
    final raw = res.data;
    if (raw == null) return OrderSummary.empty;
    final j = raw is List ? (raw.isNotEmpty ? raw[0] : null) : raw;
    if (j is! Map<String, dynamic>) return OrderSummary.empty;
    return OrderSummary.fromJson(j);
  }

  Future<InvoiceSummary> fetchInvoiceSummary({String? from, String? to}) async {
    final res = await _api.getInvoiceSummary(from: from, to: to);
    final raw = res.data;
    if (raw == null) return InvoiceSummary.empty;
    final j = raw is List ? (raw.isNotEmpty ? raw[0] : null) : raw;
    if (j is! Map<String, dynamic>) return InvoiceSummary.empty;
    return InvoiceSummary.fromJson(j);
  }

  // ── Sales lists ────────────────────────────────────────────────────────────

  Future<List<SaleRecord>> fetchSales({String? from, String? to}) async {
    final res = await _api.getSales(from: from, to: to);
    return _parseList(res.data, SaleRecord.fromJson);
  }

  Future<List<SaleRecord>> fetchOrders({String? from, String? to}) async {
    final res = await _api.getOrders(from: from, to: to);
    return _parseList(res.data, SaleRecord.fromJson);
  }

  Future<List<SaleRecord>> fetchInvoices({String? from, String? to}) async {
    final res = await _api.getInvoices(from: from, to: to);
    return _parseList(res.data, SaleRecord.fromJson);
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> addSale(Map<String, dynamic> body) =>
      _api.postSalesAdd(body);

  Future<Map<String, dynamic>> updateSale(Map<String, dynamic> body) =>
      _api.postSalesUpdate(body);

  Future<Map<String, dynamic>> addPayment(Map<String, dynamic> body) =>
      _api.postSalesAddPayment(body);

  Future<Map<String, dynamic>> deleteRecord(Map<String, dynamic> body) =>
      _api.postSalesDeleteRecord(body);

  Future<Map<String, dynamic>> backdate(Map<String, dynamic> body) =>
      _api.postSalesBackdate(body);

  Future<Map<String, dynamic>> bulkDelete(Map<String, dynamic> body) =>
      _api.postSalesBulkDelete(body);

  Future<Map<String, dynamic>> updateOrderStatus(Map<String, dynamic> body) =>
      _api.postSalesUpdateOrderStatus(body);

  // ── Reports ────────────────────────────────────────────────────────────────

  Future<List<TotalSaleItem>> fetchReportTotalSales({String? from, String? to}) async {
    final res = await _api.getReportSalesByMethod('totalSales', from: from, to: to);
    return _parseIndexed(res.data, TotalSaleItem.fromJson);
  }

  Future<List<AllOrderItem>> fetchReportAllOrders({String? from, String? to}) async {
    final res = await _api.getReportSalesByMethod('allOrders', from: from, to: to);
    return _parseIndexed(res.data, AllOrderItem.fromJson);
  }

  Future<List<InvoiceReportItem>> fetchReportInvoices({String? from, String? to}) async {
    final res = await _api.getReportSalesByMethod('invoiceSales', from: from, to: to);
    return _parseIndexed(res.data, InvoiceReportItem.fromJson);
  }

  Future<List<CreditSaleItem>> fetchReportCreditSales({String? from, String? to}) async {
    final res = await _api.getReportSalesByMethod('creditSales', from: from, to: to);
    return _parseIndexed(res.data, CreditSaleItem.fromJson);
  }

  Future<List<SaleByPayment>> fetchReportSalesByPayment({String? from, String? to}) async {
    final res = await _api.getReportSalesByMethod('salesByPaymentMode', from: from, to: to);
    return _parseIndexed(res.data, SaleByPayment.fromJson);
  }

  Future<List<SaleByCategory>> fetchReportSalesByCategory({String? from, String? to}) async {
    final res = await _api.getReportSalesByMethod('salesByCategory', from: from, to: to);
    return _parseIndexed(res.data, SaleByCategory.fromJson);
  }

  Future<List<SaleByProduct>> fetchReportSalesByProduct({String? from, String? to}) async {
    final res = await _api.getReportSalesByMethod('salesByProduct', from: from, to: to);
    return _parseIndexed(res.data, SaleByProduct.fromJson);
  }

  Future<List<UnpaidProductSale>> fetchReportUnpaidSalesByProduct({String? from, String? to}) async {
    final res = await _api.getReportSalesByMethod('unpaidSalesByProduct', from: from, to: to);
    return _parseIndexed(res.data, UnpaidProductSale.fromJson);
  }

  Future<List<StaffSaleByItem>> fetchReportStaffSalesByItems({String? from, String? to}) async {
    final res = await _api.getReportSalesByMethod('staffSalesByItems', from: from, to: to);
    return _parseIndexed(res.data, StaffSaleByItem.fromJson);
  }

  Future<List<TeamSale>> fetchReportIndividualTeamSales({String? from, String? to}) async {
    final res = await _api.getReportSalesByMethod('individualTeamSales', from: from, to: to);
    return _parseIndexed(res.data, TeamSale.fromJson);
  }

  Future<List<SaleByCustomer>> fetchReportSalesByCustomer({String? from, String? to}) async {
    final res = await _api.getReportSalesByMethod('salesByCustomer', from: from, to: to);
    return _parseIndexed(res.data, SaleByCustomer.fromJson);
  }

  Future<List<SaleByStaff>> fetchReportSalesByStaff({String? from, String? to}) async {
    final res = await _api.getReportSalesByMethod('salesByStaff', from: from, to: to);
    return _parseIndexed(res.data, SaleByStaff.fromJson);
  }

  Future<List<CombinedStaffSale>> fetchReportCombinedSalesByStaff({String? from, String? to}) async {
    final res = await _api.getReportSalesByMethod('combinedSalesByStaff', from: from, to: to);
    return _parseIndexed(res.data, CombinedStaffSale.fromJson);
  }

  Future<List<CombinedTotalSaleItem>> fetchReportCombinedTotalSales({String? from, String? to}) async {
    final res = await _api.getReportSalesByMethod('combinedTotalSales', from: from, to: to);
    return _parseIndexed(res.data, CombinedTotalSaleItem.fromJson);
  }

  Future<List<CustomerCreditItem>> fetchReportOnCreditCustomers({String? from, String? to}) async {
    final res = await _api.getReportSalesByMethod('oncreditCustomers', from: from, to: to);
    return _parseIndexed(res.data, CustomerCreditItem.fromJson);
  }

  Future<List<VatSaleItem>> fetchReportSalesWithVat({String? from, String? to}) async {
    final res = await _api.getReportSalesByMethod('salesWithVat', from: from, to: to);
    return _parseIndexed(res.data, VatSaleItem.fromJson);
  }

  Future<List<NonVatSaleItem>> fetchReportSalesWithoutVat({String? from, String? to}) async {
    final res = await _api.getReportSalesByMethod('salesWithoutVat', from: from, to: to);
    return _parseIndexed(res.data, NonVatSaleItem.fromJson);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  List<T> _parseList<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) {
    if (raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList();
  }

  List<T> _parseIndexed<T>(dynamic raw, T Function(int, Map<String, dynamic>) fromJson) {
    if (raw is! List) return [];
    final list = raw.whereType<Map<String, dynamic>>().toList();
    return List.generate(list.length, (i) => fromJson(i + 1, list[i]));
  }
}
