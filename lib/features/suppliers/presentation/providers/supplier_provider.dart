import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/suppliers/data/datasources/supplier_remote_datasource.dart';
import 'package:dukaapp/features/suppliers/data/repositories/supplier_repository.dart';

// ── DI providers ─────────────────────────────────────────────────────────────

final supplierRemoteDatasourceProvider = Provider<SupplierRemoteDatasource>(
  (ref) => SupplierRemoteDatasource(ref.watch(apiServiceProvider)),
);

final supplierRepositoryProvider = Provider<SupplierRepository>(
  (ref) => SupplierRepository(ref.watch(supplierRemoteDatasourceProvider)),
);
