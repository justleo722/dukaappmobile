import 'package:dukaapp/core/services/api_service.dart';
import 'package:dukaapp/features/suppliers/data/models/supplier_model.dart';

/// Remote datasource for the Suppliers module.
class SupplierRemoteDatasource {
  final ApiService _api;
  const SupplierRemoteDatasource(this._api);

  Future<List<Supplier>> fetchSuppliers() async {
    final res = await _api.getSuppliers();
    final list = _unwrapList(res.data);
    return list.map(Supplier.fromJson).toList();
  }

  Future<List<Supplier>> fetchOncreditSuppliers() async {
    final res = await _api.getOncreditSuppliers();
    final list = _unwrapList(res.data);
    return list.map(Supplier.fromJson).toList();
  }

  Future<List<Supplier>> fetchOncashSuppliers() async {
    final res = await _api.getOncashSuppliers();
    final list = _unwrapList(res.data);
    return list.map(Supplier.fromJson).toList();
  }

  Future<Map<String, dynamic>> addSupplier(Map<String, dynamic> body) =>
      _api.postSupplierAdd(body);

  Future<Map<String, dynamic>> bulkDeleteSuppliers(List<String> ids) =>
      _api.postSupplierBulkDelete({'supplier_ids': ids.join(',')});

  List<Map<String, dynamic>> _unwrapList(dynamic raw) {
    if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
    if (raw is Map<String, dynamic>) {
      final v = raw['data'] ?? raw['result'] ?? raw['items'];
      if (v is List) return v.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }
}
