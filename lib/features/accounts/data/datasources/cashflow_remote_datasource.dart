import 'package:dukaapp/core/services/api_service.dart';
import 'package:dukaapp/features/accounts/data/models/cashflow_models.dart';

/// Remote datasource for the Accounts / Cashflow module.
class CashflowRemoteDatasource {
  final ApiService _api;
  const CashflowRemoteDatasource(this._api);

  Future<List<CashflowItem>> fetchCashflow({String? from, String? to}) async {
    final res = await _api.getCashflow(from: from, to: to);
    final list = _unwrapList(res.data);
    return list.map(CashflowItem.fromJson).toList();
  }

  Future<CashflowSummary> fetchCashflowSummary({String? from, String? to}) async {
    final res = await _api.getCashflowSummary(from: from, to: to);
    final raw = res.data;
    // PHP returns a bare list: [[{cash_in, cash_out, cash_in_hand, ...}]]
    if (raw is List && raw.isNotEmpty) {
      final first = raw.first;
      if (first is Map<String, dynamic>) return CashflowSummary.fromJson(first);
    }
    if (raw is Map<String, dynamic>) {
      final data = raw['data'] ?? raw;
      if (data is Map<String, dynamic>) return CashflowSummary.fromJson(data);
      if (data is List && data.isNotEmpty) {
        final first = data.first;
        if (first is Map<String, dynamic>) return CashflowSummary.fromJson(first);
      }
    }
    return CashflowSummary.empty;
  }

  Future<Map<String, dynamic>> addFund(Map<String, dynamic> body) =>
      _api.postCashflowAddFund(body);

  Future<Map<String, dynamic>> addExpense(Map<String, dynamic> body) =>
      _api.postCashflowAddExpense(body);

  Future<Map<String, dynamic>> deleteExpense(Map<String, dynamic> body) =>
      _api.postCashflowDeleteExpense(body);

  List<Map<String, dynamic>> _unwrapList(dynamic raw) {
    if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
    if (raw is Map<String, dynamic>) {
      final v = raw['data'] ?? raw['result'] ?? raw['items'];
      if (v is List) return v.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }
}
