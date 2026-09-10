/// DashboardProvider — Riverpod AsyncNotifier that loads dashboard data.
///
/// Usage in widgets:
///   final state = ref.watch(dashboardProvider);
///   state.when(data: (s) {...}, loading: () {...}, error: (e, _) {...});
///
/// Call ref.invalidate(dashboardProvider) or ref.read(dashboardProvider.notifier).refresh()
/// to force a reload (e.g. after pull-to-refresh).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:dukaapp/features/dashboard/data/repositories/dashboard_repository.dart';

export 'package:dukaapp/features/dashboard/data/repositories/dashboard_repository.dart'
    show DashboardState;
export 'package:dukaapp/features/dashboard/data/models/dashboard_model.dart'
    show DashboardModel;
export 'package:dukaapp/features/dashboard/data/models/session_user_model.dart'
    show SessionUserModel;

// ── Datasource provider ────────────────────────────────────────────────────
final dashboardDatasourceProvider = Provider<DashboardRemoteDatasource>((ref) {
  final client = ref.watch(apiClientProvider);
  return DashboardRemoteDatasource(client);
});

// ── Repository provider ────────────────────────────────────────────────────
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final datasource = ref.watch(dashboardDatasourceProvider);
  return DashboardRepository(datasource);
});

// ── Async state notifier ───────────────────────────────────────────────────
class DashboardNotifier extends AsyncNotifier<DashboardState> {
  @override
  Future<DashboardState> build() => _load();

  Future<DashboardState> _load() {
    return ref.read(dashboardRepositoryProvider).fetch();
  }

  /// Pull-to-refresh: re-fetch data from the server.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardState>(
  DashboardNotifier.new,
);
