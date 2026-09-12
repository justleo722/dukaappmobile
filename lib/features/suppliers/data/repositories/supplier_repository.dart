import 'package:dukaapp/features/suppliers/data/datasources/supplier_remote_datasource.dart';
import 'package:dukaapp/features/suppliers/data/models/supplier_model.dart';

/// Repository wrapper for the Suppliers module.
class SupplierRepository {
  final SupplierRemoteDatasource _remote;
  const SupplierRepository(this._remote);

  Future<List<Supplier>> fetchSuppliers() => _remote.fetchSuppliers();
  Future<List<Supplier>> fetchOncreditSuppliers() => _remote.fetchOncreditSuppliers();
  Future<List<Supplier>> fetchOncashSuppliers() => _remote.fetchOncashSuppliers();
  Future<Map<String, dynamic>> addSupplier(Map<String, dynamic> body) =>
      _remote.addSupplier(body);
  Future<Map<String, dynamic>> bulkDeleteSuppliers(List<String> ids) =>
      _remote.bulkDeleteSuppliers(ids);
}
