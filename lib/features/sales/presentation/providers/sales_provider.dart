import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/sales/data/datasources/sales_remote_datasource.dart';
import 'package:dukaapp/features/sales/data/repositories/sales_repository.dart';
import 'package:dukaapp/features/sales/data/models/sales_models.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

final salesRemoteDatasourceProvider = Provider<SalesRemoteDatasource>((ref) {
  return SalesRemoteDatasource(ref.watch(apiServiceProvider));
});

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepository(ref.watch(salesRemoteDatasourceProvider));
});

// ── Sales list + summary ──────────────────────────────────────────────────────

class SalesState {
  final List<SaleRecord> sales;
  final SalesSummary summary;

  const SalesState({
    this.sales = const [],
    this.summary = SalesSummary.empty,
  });
}

class SalesNotifier extends AsyncNotifier<SalesState> {
  @override
  Future<SalesState> build() => _load();

  Future<SalesState> _load() async {
    final repo = ref.read(salesRepositoryProvider);
    final results = await Future.wait([
      repo.fetchSales(),
      repo.fetchSalesSummary(),
    ]);
    return SalesState(
      sales: results[0] as List<SaleRecord>,
      summary: results[1] as SalesSummary,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }
}

final salesProvider =
    AsyncNotifierProvider<SalesNotifier, SalesState>(SalesNotifier.new);

// ── Orders list + summary ─────────────────────────────────────────────────────

class OrdersState {
  final List<SaleRecord> orders;
  final OrderSummary summary;

  const OrdersState({
    this.orders = const [],
    this.summary = OrderSummary.empty,
  });
}

class OrdersNotifier extends AsyncNotifier<OrdersState> {
  @override
  Future<OrdersState> build() => _load();

  Future<OrdersState> _load() async {
    final repo = ref.read(salesRepositoryProvider);
    final results = await Future.wait([
      repo.fetchOrders(),
      repo.fetchOrderSummary(),
    ]);
    return OrdersState(
      orders: results[0] as List<SaleRecord>,
      summary: results[1] as OrderSummary,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }
}

final ordersProvider =
    AsyncNotifierProvider<OrdersNotifier, OrdersState>(OrdersNotifier.new);

// ── Invoices list + summary ───────────────────────────────────────────────────

class InvoicesState {
  final List<SaleRecord> invoices;
  final InvoiceSummary summary;

  const InvoicesState({
    this.invoices = const [],
    this.summary = InvoiceSummary.empty,
  });
}

class InvoicesNotifier extends AsyncNotifier<InvoicesState> {
  @override
  Future<InvoicesState> build() => _load();

  Future<InvoicesState> _load() async {
    final repo = ref.read(salesRepositoryProvider);
    final results = await Future.wait([
      repo.fetchInvoices(),
      repo.fetchInvoiceSummary(),
    ]);
    return InvoicesState(
      invoices: results[0] as List<SaleRecord>,
      summary: results[1] as InvoiceSummary,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }
}

final invoicesProvider =
    AsyncNotifierProvider<InvoicesNotifier, InvoicesState>(InvoicesNotifier.new);
