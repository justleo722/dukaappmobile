import 'package:dukaapp/core/services/api_service.dart';
import 'package:dukaapp/features/purchase/data/models/purchase_models.dart';

/// Remote datasource for the Purchase module.
class PurchaseRemoteDatasource {
  final ApiService _api;
  const PurchaseRemoteDatasource(this._api);

  Future<List<PurchaseItem>> fetchPurchases({String? from, String? to}) async {
    final res = await _api.getPurchaseHistory(from: from, to: to);
    final list = _unwrapList(res.data);
    return list.map(PurchaseItem.fromJson).toList();
  }

  Future<PurchaseSummary> fetchPurchaseSummary({String? from, String? to}) async {
    final res = await _api.getPurchaseSummary(from: from, to: to);
    final raw = res.data;
    if (raw is Map<String, dynamic>) {
      final data = raw['data'] ?? raw;
      if (data is Map<String, dynamic>) return PurchaseSummary.fromJson(data);
      if (data is List && data.isNotEmpty) {
        return PurchaseSummary.fromJson(data.first as Map<String, dynamic>);
      }
    }
    return PurchaseSummary.empty;
  }

  Future<List<PurchaseItem>> fetchPurchaseOrders({String? from, String? to}) async {
    final res = await _api.getPurchaseOrders(from: from, to: to);
    final list = _unwrapList(res.data);
    return list.map(PurchaseItem.fromJson).toList();
  }

  Future<Map<String, dynamic>> createPurchase(Map<String, dynamic> body) =>
      _api.postStockRestockCreate(body);

  Future<Map<String, dynamic>> addPayment(Map<String, dynamic> body) =>
      _api.postStockPurchaseClearCreditBalance(body);

  Future<Map<String, dynamic>> bulkDelete(Map<String, dynamic> body) =>
      _api.postStockPurchaseBulkDelete(body);

  Future<Map<String, dynamic>> updateOrderStatus(Map<String, dynamic> body) =>
      _api.postStockPurchaseUpdateOrderStatus(body);

  Future<Map<String, dynamic>> backdate(Map<String, dynamic> body) =>
      _api.postStockPurchaseBackdate(body);

  List<Map<String, dynamic>> _unwrapList(dynamic raw) {
    if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
    if (raw is Map<String, dynamic>) {
      final v = raw['data'] ?? raw['result'] ?? raw['items'];
      if (v is List) return v.whereType<Map<String, dynamic>>().toList();
      // Grouped response
      final allValues = raw.values.toList();
      final isGrouped = allValues.isNotEmpty && allValues.every((e) => e is List);
      if (isGrouped) {
        final flat = <Map<String, dynamic>>[];
        for (final group in allValues) {
          flat.addAll((group as List).whereType<Map<String, dynamic>>());
        }
        return flat;
      }
    }
    return [];
  }
}
