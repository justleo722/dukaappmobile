import 'package:dukaapp/core/services/api_service.dart';
import 'package:dukaapp/features/expenses/data/models/expense_models.dart';

/// Remote datasource for the Expenses module.
class ExpenseRemoteDatasource {
  final ApiService _api;
  const ExpenseRemoteDatasource(this._api);

  /// Fetch all expenses for the active shop (respects date filter).
  Future<List<ExpenseItem>> fetchExpenses({String? from, String? to}) async {
    final res = await _api.getExpenses(from: from, to: to);
    final list = _unwrapList(res.data);
    return list.map(ExpenseItem.fromJson).toList();
  }

  /// Fetch expense summary totals.
  Future<ExpenseSummary> fetchExpenseSummary({String? from, String? to}) async {
    final res = await _api.getExpenseSummary(from: from, to: to);
    final raw = res.data;
    // API returns a bare JSON array: [{...}]
    if (raw is List && raw.isNotEmpty && raw.first is Map<String, dynamic>) {
      return ExpenseSummary.fromJson(raw.first as Map<String, dynamic>);
    }
    if (raw is Map<String, dynamic>) {
      final data = raw['data'] ?? raw;
      if (data is Map<String, dynamic>) return ExpenseSummary.fromJson(data);
      if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
        return ExpenseSummary.fromJson(data.first as Map<String, dynamic>);
      }
    }
    return ExpenseSummary.empty;
  }

  /// Fetch expense account categories.
  Future<List<ExpenseAccount>> fetchExpenseAccounts() async {
    final res = await _api.getExpenseAccounts();
    final list = _unwrapList(res.data);
    return list.map(ExpenseAccount.fromJson).toList();
  }

  /// Cashbook accounts (Bank, Cash, Mobile Money etc.) for from_account_id.
  Future<List<ExpenseAccount>> fetchCashbookAccounts() async {
    final res = await _api.getCashbookAccounts();
    final list = _unwrapList(res.data);
    return list.map((j) => ExpenseAccount(
      accountId: j['account_id']?.toString() ?? '',
      name: j['account_name']?.toString() ?? '',
    )).where((a) => a.accountId.isNotEmpty && a.name.isNotEmpty).toList();
  }

  /// Record a new expense.
  Future<Map<String, dynamic>> addExpense(Map<String, dynamic> body) =>
      _api.postCashflowAddExpense(body);

  /// Delete an expense entry.
  Future<Map<String, dynamic>> deleteExpense(Map<String, dynamic> body) =>
      _api.postCashflowDeleteExpense(body);

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
