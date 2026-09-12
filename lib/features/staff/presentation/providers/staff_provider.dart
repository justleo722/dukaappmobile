import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/staff/data/datasources/staff_remote_datasource.dart';
import 'package:dukaapp/features/staff/data/repositories/staff_repository.dart';

// ── DI providers ─────────────────────────────────────────────────────────────

final staffRemoteDatasourceProvider = Provider<StaffRemoteDatasource>(
  (ref) => StaffRemoteDatasource(ref.watch(apiServiceProvider)),
);

final staffRepositoryProvider = Provider<StaffRepository>(
  (ref) => StaffRepository(ref.watch(staffRemoteDatasourceProvider)),
);
