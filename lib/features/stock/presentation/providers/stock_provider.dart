import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/stock/data/datasources/stock_remote_datasource.dart';
import 'package:dukaapp/features/stock/data/repositories/stock_repository.dart';
import 'package:dukaapp/features/stock/data/models/stock_models.dart';

// ── Providers ────────────────────────────────────────────────────────────────

final stockRemoteDatasourceProvider = Provider<StockRemoteDatasource>((ref) {
  return StockRemoteDatasource(ref.watch(apiClientProvider));
});

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  return StockRepository(
    ref.watch(stockRemoteDatasourceProvider),
    ref.watch(databaseServiceProvider),
  );
});

/// Main stock provider — AsyncNotifier with offline-first loading.
final stockProvider =
    AsyncNotifierProvider<StockNotifier, StockState>(StockNotifier.new);

class StockNotifier extends AsyncNotifier<StockState> {
  @override
  Future<StockState> build() => _load();

  Future<StockState> _load() {
    final repo = ref.read(stockRepositoryProvider);
    return repo.loadOfflineFirst(
      onUpdate: (fresh) {
        if (state.hasValue) state = AsyncData(fresh);
      },
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(stockRepositoryProvider).refresh(),
    );
  }
}
