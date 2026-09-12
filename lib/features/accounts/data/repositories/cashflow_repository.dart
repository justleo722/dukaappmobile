import 'package:dukaapp/features/accounts/data/datasources/cashflow_remote_datasource.dart';
import 'package:dukaapp/features/accounts/data/models/cashflow_models.dart';

/// Repository wrapper for the Accounts / Cashflow module.
class CashflowRepository {
  final CashflowRemoteDatasource _remote;
  const CashflowRepository(this._remote);

  Future<List<CashflowItem>> fetchCashflow({String? from, String? to}) =>
      _remote.fetchCashflow(from: from, to: to);

  Future<CashflowSummary> fetchCashflowSummary({String? from, String? to}) =>
      _remote.fetchCashflowSummary(from: from, to: to);

  Future<Map<String, dynamic>> addFund(Map<String, dynamic> body) =>
      _remote.addFund(body);

  Future<Map<String, dynamic>> addExpense(Map<String, dynamic> body) =>
      _remote.addExpense(body);

  Future<Map<String, dynamic>> deleteExpense(Map<String, dynamic> body) =>
      _remote.deleteExpense(body);
}
