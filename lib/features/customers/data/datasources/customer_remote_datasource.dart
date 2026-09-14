import 'package:dukaapp/core/services/api_service.dart';
import 'package:dukaapp/features/customers/data/models/customer_model.dart';

/// Remote datasource for the Customers module.
///
/// All reads go through GET /getdata/customers (and related endpoints).
/// Writes go through POST /postdata/customer/create (create / update).
class CustomerRemoteDatasource {
  final ApiService _api;
  const CustomerRemoteDatasource(this._api);

  /// Fetch all active customers for the active shop.
  /// Pass [from] and [to] (YYYY-MM-DD) to filter by date range.
  Future<List<Customer>> fetchCustomers({String? from, String? to}) async {
    final res = await _api.getCustomers(from: from, to: to);
    final raw = res.data;
    final list = _unwrapList(raw);
    return list.map(Customer.fromJson).toList();
  }

  /// Create or update a customer.
  ///
  /// Omit [customerId] to create; include it to update.
  Future<Map<String, dynamic>> saveCustomer({
    String? customerId,
    required String name,
    required String phone,
    String? email,
    String? tinNumber,
    String? address,
    double creditLimit = 0,
    String? note,
  }) {
    final body = <String, dynamic>{
      'customer_name': name,
      'name': name,         // fallback alias
      'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (tinNumber != null && tinNumber.isNotEmpty) 'customer_tin': tinNumber,
      if (address != null && address.isNotEmpty) 'address': address,
      'credit_limit': creditLimit.toStringAsFixed(2),
      if (note != null && note.isNotEmpty) 'note': note,
      if (customerId != null && customerId.isNotEmpty) 'customer_id': customerId,
    };
    return _api.postCustomerCreate(body);
  }

  /// Soft-delete customers by ID list.
  Future<Map<String, dynamic>> deleteCustomers(List<String> ids) =>
      _api.postCustomerBulkDelete({'customer_ids': ids.join(',')});

  // ── Helpers ──────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _unwrapList(dynamic raw) {
    if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
    if (raw is Map<String, dynamic>) {
      final v = raw['data'] ?? raw['result'] ?? raw['items'];
      if (v is List) return v.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }
}
