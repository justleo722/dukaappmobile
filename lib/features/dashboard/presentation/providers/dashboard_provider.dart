/// DashboardProvider — offline-first Riverpod notifier.
///
/// Flow:
///   1. Emit cached data from LocalDB immediately (no loading flash)
///   2. Fetch fresh data from API in background
///   3. Update state with fresh data → UI rebuilds softly
///
/// Pull-to-refresh forces an API fetch and waits for it.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/core/database/offline_repository.dart';
import 'package:dukaapp/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:dukaapp/features/dashboard/data/repositories/dashboard_repository.dart';

export 'package:dukaapp/features/dashboard/data/repositories/dashboard_repository.dart'
    show DashboardState;
export 'package:dukaapp/features/dashboard/data/models/dashboard_model.dart'
    show DashboardModel;
export 'package:dukaapp/features/dashboard/data/models/session_user_model.dart'
    show SessionUserModel;

// ── Datasource & repository providers ─────────────────────────────────────
final dashboardDatasourceProvider = Provider<DashboardRemoteDatasource>((ref) {
  return DashboardRemoteDatasource(ref.watch(apiClientProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dashboardDatasourceProvider));
});

// ── State notifier ─────────────────────────────────────────────────────────
class DashboardNotifier extends AsyncNotifier<DashboardState> {
  @override
  Future<DashboardState> build() async {
    // Offline-first: serve cache → refresh in background
    return await _loadOfflineFirst();
  }

  Future<DashboardState> _loadOfflineFirst() async {
    final db  = ref.read(databaseServiceProvider);
    final repo = ref.read(dashboardRepositoryProvider);

    // Try cached data first
    if (db.isOpen) {
      final cachedRaw = await db.get('dashboard', 'state');
      if (cachedRaw != null) {
        // Serve cache immediately, then refresh silently in background
        _backgroundRefresh(repo, db);
        return DashboardState.fromCache(cachedRaw as Map<String, dynamic>);
      }
    }

    // No cache — fetch from API (shows loading spinner once only)
    return await _fetchAndCache(repo, db);
  }

  /// Background refresh — updates state without showing loading spinner.
  void _backgroundRefresh(DashboardRepository repo, dynamic db) {
    Future.microtask(() async {
      try {
        final fresh = await _fetchAndCache(repo, db);
        state = AsyncData(fresh);
      } catch (_) {
        // Ignore background errors — user already has cached data
      }
    });
  }

  Future<DashboardState> _fetchAndCache(DashboardRepository repo, dynamic db) async {
    final fresh = await repo.fetch();
    // Persist to local DB for next cold start
    if (db.isOpen) {
      await db.put('dashboard', 'state', fresh.toJson());
    }
    return fresh;
  }

  /// Pull-to-refresh: force a live fetch, show loading.
  Future<void> refresh() async {
    state = const AsyncLoading();
    final repo = ref.read(dashboardRepositoryProvider);
    final db   = ref.read(databaseServiceProvider);
    state = await AsyncValue.guard(() => _fetchAndCache(repo, db));
  }
}

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardState>(
  DashboardNotifier.new,
);
