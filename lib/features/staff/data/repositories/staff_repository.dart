import 'package:dukaapp/features/staff/data/datasources/staff_remote_datasource.dart';
import 'package:dukaapp/features/staff/data/models/staff_models.dart';

/// Repository wrapper for the Staff module.
class StaffRepository {
  final StaffRemoteDatasource _remote;
  const StaffRepository(this._remote);

  Future<List<Attendant>> fetchTeam() => _remote.fetchTeam();

  Future<Map<String, dynamic>> addStaff(Map<String, dynamic> body) =>
      _remote.addStaff(body);

  Future<Map<String, dynamic>> updateMember(Map<String, dynamic> body) =>
      _remote.updateMember(body);

  /// Soft-delete only — never hard DELETE.
  Future<Map<String, dynamic>> deleteAttendant(Map<String, dynamic> body) =>
      _remote.deleteAttendant(body);

  Future<Map<String, dynamic>> updateStatus(Map<String, dynamic> body) =>
      _remote.updateStatus(body);

  Future<Map<String, dynamic>> updatePermission(Map<String, dynamic> body) =>
      _remote.updatePermission(body);
}
