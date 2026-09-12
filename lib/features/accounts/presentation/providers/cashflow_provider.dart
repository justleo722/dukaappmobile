import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/accounts/data/datasources/cashflow_remote_datasource.dart';
import 'package:dukaapp/features/accounts/data/repositories/cashflow_repository.dart';

// ── DI providers ─────────────────────────────────────────────────────────────

final cashflowRemoteDatasourceProvider = Provider<CashflowRemoteDatasource>(
  (ref) => CashflowRemoteDatasource(ref.watch(apiServiceProvider)),
);

final cashflowRepositoryProvider = Provider<CashflowRepository>(
  (ref) => CashflowRepository(ref.watch(cashflowRemoteDatasourceProvider)),
);
