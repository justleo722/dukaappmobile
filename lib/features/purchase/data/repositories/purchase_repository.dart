import 'package:dukaapp/features/purchase/data/datasources/purchase_remote_datasource.dart';
import 'package:dukaapp/features/purchase/data/models/purchase_models.dart';

/// Repository wrapper for the Purchase module.
class PurchaseRepository {
  final PurchaseRemoteDatasource _remote;
  const PurchaseRepository(this._remote);

  Future<List<PurchaseItem>> fetchPurchases({String? from, String? to}) =>
      _remote.fetchPurchases(from: from, to: to);

  Future<PurchaseSummary> fetchPurchaseSummary({String? from, String? to}) =>
      _remote.fetchPurchaseSummary(from: from, to: to);

  Future<List<PurchaseItem>> fetchPurchaseOrders({String? from, String? to}) =>
      _remote.fetchPurchaseOrders(from: from, to: to);

  Future<Map<String, dynamic>> createPurchase(Map<String, dynamic> body) =>
      _remote.createPurchase(body);

  Future<Map<String, dynamic>> addPayment(Map<String, dynamic> body) =>
      _remote.addPayment(body);

  Future<Map<String, dynamic>> bulkDelete(Map<String, dynamic> body) =>
      _remote.bulkDelete(body);

  Future<Map<String, dynamic>> updateOrderStatus(Map<String, dynamic> body) =>
      _remote.updateOrderStatus(body);

  Future<Map<String, dynamic>> backdate(Map<String, dynamic> body) =>
      _remote.backdate(body);
}
