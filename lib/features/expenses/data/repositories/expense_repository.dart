import 'package:dukaapp/features/expenses/data/datasources/expense_remote_datasource.dart';
import 'package:dukaapp/features/expenses/data/models/expense_models.dart';

/// Repository wrapper for the Expenses module.
class ExpenseRepository {
  final ExpenseRemoteDatasource _remote;
  const ExpenseRepository(this._remote);

  Future<List<ExpenseItem>> fetchExpenses({String? from, String? to}) =>
      _remote.fetchExpenses(from: from, to: to);

  Future<ExpenseSummary> fetchExpenseSummary({String? from, String? to}) =>
      _remote.fetchExpenseSummary(from: from, to: to);

  Future<List<ExpenseAccount>> fetchExpenseAccounts() =>
      _remote.fetchExpenseAccounts();

  Future<List<ExpenseAccount>> fetchCashbookAccounts() =>
      _remote.fetchCashbookAccounts();

  Future<Map<String, dynamic>> addExpense(Map<String, dynamic> body) =>
      _remote.addExpense(body);

  Future<Map<String, dynamic>> deleteExpense(Map<String, dynamic> body) =>
      _remote.deleteExpense(body);
}
