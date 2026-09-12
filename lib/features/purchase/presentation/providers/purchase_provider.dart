import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/purchase/data/datasources/purchase_remote_datasource.dart';
import 'package:dukaapp/features/purchase/data/repositories/purchase_repository.dart';

// ── DI providers ─────────────────────────────────────────────────────────────

final purchaseRemoteDatasourceProvider = Provider<PurchaseRemoteDatasource>(
  (ref) => PurchaseRemoteDatasource(ref.watch(apiServiceProvider)),
);

final purchaseRepositoryProvider = Provider<PurchaseRepository>(
  (ref) => PurchaseRepository(ref.watch(purchaseRemoteDatasourceProvider)),
);
