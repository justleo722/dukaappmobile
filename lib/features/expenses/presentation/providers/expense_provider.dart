import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/expenses/data/datasources/expense_remote_datasource.dart';
import 'package:dukaapp/features/expenses/data/repositories/expense_repository.dart';

// ── DI providers ─────────────────────────────────────────────────────────────

final expenseRemoteDatasourceProvider = Provider<ExpenseRemoteDatasource>(
  (ref) => ExpenseRemoteDatasource(ref.watch(apiServiceProvider)),
);

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => ExpenseRepository(ref.watch(expenseRemoteDatasourceProvider)),
);
