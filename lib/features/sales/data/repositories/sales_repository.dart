import 'package:dukaapp/features/sales/data/datasources/sales_remote_datasource.dart';
import 'package:dukaapp/features/sales/data/models/sales_models.dart';

/// Repository for the Sales module.
///
/// Delegates all network calls to [SalesRemoteDatasource].
/// No local caching — sales data is always fresh from the server.
class SalesRepository {
  const SalesRepository(this._remote);

  final SalesRemoteDatasource _remote;

  // ── Summary ───────────────────────────────────────────────────────────────

  Future<SalesSummary> fetchSalesSummary({String? from, String? to}) =>
      _remote.fetchSalesSummary(from: from, to: to);

  Future<OrderSummary> fetchOrderSummary({String? from, String? to}) =>
      _remote.fetchOrderSummary(from: from, to: to);

  Future<InvoiceSummary> fetchInvoiceSummary({String? from, String? to}) =>
      _remote.fetchInvoiceSummary(from: from, to: to);

  // ── Lists ─────────────────────────────────────────────────────────────────

  Future<List<SaleRecord>> fetchSales({String? from, String? to}) =>
      _remote.fetchSales(from: from, to: to);

  Future<List<SaleRecord>> fetchOrders({String? from, String? to}) =>
      _remote.fetchOrders(from: from, to: to);

  Future<List<SaleRecord>> fetchInvoices({String? from, String? to}) =>
      _remote.fetchInvoices(from: from, to: to);

  // ── Writes ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> addSale(Map<String, dynamic> body) =>
      _remote.addSale(body);

  Future<Map<String, dynamic>> updateSale(Map<String, dynamic> body) =>
      _remote.updateSale(body);

  Future<Map<String, dynamic>> addPayment(Map<String, dynamic> body) =>
      _remote.addPayment(body);

  Future<Map<String, dynamic>> deleteRecord(Map<String, dynamic> body) =>
      _remote.deleteRecord(body);

  Future<Map<String, dynamic>> backdate(Map<String, dynamic> body) =>
      _remote.backdate(body);

  Future<Map<String, dynamic>> bulkDelete(Map<String, dynamic> body) =>
      _remote.bulkDelete(body);

  Future<Map<String, dynamic>> updateOrderStatus(Map<String, dynamic> body) =>
      _remote.updateOrderStatus(body);

  // ── Reports ───────────────────────────────────────────────────────────────

  Future<List<TotalSaleItem>> fetchReportTotalSales({String? from, String? to}) =>
      _remote.fetchReportTotalSales(from: from, to: to);

  Future<List<AllOrderItem>> fetchReportAllOrders({String? from, String? to}) =>
      _remote.fetchReportAllOrders(from: from, to: to);

  Future<List<InvoiceReportItem>> fetchReportInvoices({String? from, String? to}) =>
      _remote.fetchReportInvoices(from: from, to: to);

  Future<List<CreditSaleItem>> fetchReportCreditSales({String? from, String? to}) =>
      _remote.fetchReportCreditSales(from: from, to: to);

  Future<List<SaleByPayment>> fetchReportSalesByPayment({String? from, String? to}) =>
      _remote.fetchReportSalesByPayment(from: from, to: to);

  Future<List<SaleByCategory>> fetchReportSalesByCategory({String? from, String? to}) =>
      _remote.fetchReportSalesByCategory(from: from, to: to);

  Future<List<SaleByProduct>> fetchReportSalesByProduct({String? from, String? to}) =>
      _remote.fetchReportSalesByProduct(from: from, to: to);

  Future<List<UnpaidProductSale>> fetchReportUnpaidSalesByProduct({String? from, String? to}) =>
      _remote.fetchReportUnpaidSalesByProduct(from: from, to: to);

  Future<List<StaffSaleByItem>> fetchReportStaffSalesByItems({String? from, String? to}) =>
      _remote.fetchReportStaffSalesByItems(from: from, to: to);

  Future<List<TeamSale>> fetchReportIndividualTeamSales({String? from, String? to}) =>
      _remote.fetchReportIndividualTeamSales(from: from, to: to);

  Future<List<SaleByCustomer>> fetchReportSalesByCustomer({String? from, String? to}) =>
      _remote.fetchReportSalesByCustomer(from: from, to: to);

  Future<List<SaleByStaff>> fetchReportSalesByStaff({String? from, String? to}) =>
      _remote.fetchReportSalesByStaff(from: from, to: to);

  Future<List<CombinedStaffSale>> fetchReportCombinedSalesByStaff({String? from, String? to}) =>
      _remote.fetchReportCombinedSalesByStaff(from: from, to: to);

  Future<List<CombinedTotalSaleItem>> fetchReportCombinedTotalSales({String? from, String? to}) =>
      _remote.fetchReportCombinedTotalSales(from: from, to: to);

  Future<List<CustomerCreditItem>> fetchReportOnCreditCustomers({String? from, String? to}) =>
      _remote.fetchReportOnCreditCustomers(from: from, to: to);

  Future<List<VatSaleItem>> fetchReportSalesWithVat({String? from, String? to}) =>
      _remote.fetchReportSalesWithVat(from: from, to: to);

  Future<List<NonVatSaleItem>> fetchReportSalesWithoutVat({String? from, String? to}) =>
      _remote.fetchReportSalesWithoutVat(from: from, to: to);
}
