import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/customers/data/datasources/customer_remote_datasource.dart';
import 'package:dukaapp/features/customers/data/models/customer_model.dart';
import 'package:dukaapp/features/customers/data/repositories/customer_repository.dart';

// ── DI providers ─────────────────────────────────────────────────────────────

final customerRemoteDatasourceProvider = Provider<CustomerRemoteDatasource>(
  (ref) => CustomerRemoteDatasource(ref.watch(apiServiceProvider)),
);

final customerRepositoryProvider = Provider<CustomerRepository>(
  (ref) => CustomerRepository(ref.watch(customerRemoteDatasourceProvider)),
);

// ── State ─────────────────────────────────────────────────────────────────────

class CustomerState {
  final List<Customer> customers;
  final bool isLoading;
  final String? error;

  const CustomerState({
    this.customers = const [],
    this.isLoading = false,
    this.error,
  });

  CustomerState copyWith({
    List<Customer>? customers,
    bool? isLoading,
    String? error,
  }) =>
      CustomerState(
        customers: customers ?? this.customers,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class CustomerNotifier extends AsyncNotifier<CustomerState> {
  @override
  Future<CustomerState> build() async {
    final customers = await ref
        .read(customerRepositoryProvider)
        .fetchCustomers();
    return CustomerState(customers: customers);
  }

  /// Reload customers from the API.
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final customers = await ref
          .read(customerRepositoryProvider)
          .fetchCustomers();
      return CustomerState(customers: customers);
    });
  }
}

final customerProvider =
    AsyncNotifierProvider<CustomerNotifier, CustomerState>(
  CustomerNotifier.new,
);
