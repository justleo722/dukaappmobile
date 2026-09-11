import 'package:dukaapp/features/customers/data/datasources/customer_remote_datasource.dart';
import 'package:dukaapp/features/customers/data/models/customer_model.dart';

/// Repository that wraps [CustomerRemoteDatasource] for the presentation layer.
class CustomerRepository {
  final CustomerRemoteDatasource _remote;
  const CustomerRepository(this._remote);

  Future<List<Customer>> fetchCustomers() => _remote.fetchCustomers();

  Future<Map<String, dynamic>> saveCustomer({
    String? customerId,
    required String name,
    required String phone,
    String? email,
    String? tinNumber,
    String? address,
    double creditLimit = 0,
    String? note,
  }) =>
      _remote.saveCustomer(
        customerId: customerId,
        name: name,
        phone: phone,
        email: email,
        tinNumber: tinNumber,
        address: address,
        creditLimit: creditLimit,
        note: note,
      );

  Future<Map<String, dynamic>> deleteCustomers(List<String> ids) =>
      _remote.deleteCustomers(ids);
}
