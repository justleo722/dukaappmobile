import 'package:dukaapp/core/services/api_service.dart';
import 'package:dukaapp/features/staff/data/models/staff_models.dart';

/// Remote datasource for the Staff module.
class StaffRemoteDatasource {
  final ApiService _api;
  const StaffRemoteDatasource(this._api);

  Future<List<Attendant>> fetchTeam() async {
    final res = await _api.getTeam();
    final list = _unwrapList(res.data);
    return list.map(Attendant.fromJson).toList();
  }

  /// Add a team member (attendant or manager).
  Future<Map<String, dynamic>> addStaff(Map<String, dynamic> body) =>
      _api.postTeamStaffAdd(body);

  /// Update team member profile.
  Future<Map<String, dynamic>> updateMember(Map<String, dynamic> body) =>
      _api.postTeamMemberUpdate(body);

  /// Toggle active/inactive status.
  Future<Map<String, dynamic>> updateStatus(Map<String, dynamic> body) =>
      _api.postTeamStatusUpdate(body);

  /// Soft-delete an attendant (NEVER hard delete).
  Future<Map<String, dynamic>> deleteAttendant(Map<String, dynamic> body) =>
      _api.postTeamAttendantDelete(body);

  /// Update a permission flag.
  Future<Map<String, dynamic>> updatePermission(Map<String, dynamic> body) =>
      _api.postTeamPermissionUpdate(body);

  List<Map<String, dynamic>> _unwrapList(dynamic raw) {
    if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
    if (raw is Map<String, dynamic>) {
      final v = raw['data'] ?? raw['result'] ?? raw['items'];
      if (v is List) return v.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }
}
