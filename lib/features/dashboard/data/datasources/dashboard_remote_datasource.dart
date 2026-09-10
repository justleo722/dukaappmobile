/// DashboardRemoteDatasource — fetches dashboard summary and session user
/// from the DukaApp REST API.
///
/// Endpoints:
///   GET /api/v1/app/get/getdata/dashboard   → DashboardModel
///   GET /api/v1/app/get/getdata/session_user → SessionUserModel
///
/// Both requests are made in parallel via Future.wait for speed.

import 'package:dukaapp/core/config/api_config.dart';
import 'package:dukaapp/core/network/api_client.dart';
import 'package:dukaapp/features/dashboard/data/models/dashboard_model.dart';
import 'package:dukaapp/features/dashboard/data/models/session_user_model.dart';

class DashboardRemoteDatasource {
  const DashboardRemoteDatasource(this._client);

  final ApiClient _client;

  /// Fetch both dashboard summary and session user concurrently.
  Future<(DashboardModel, SessionUserModel)> fetchAll() async {
    final results = await Future.wait([
      _fetchDashboard(),
      _fetchSessionUser(),
    ]);
    return (results[0] as DashboardModel, results[1] as SessionUserModel);
  }

  Future<DashboardModel> _fetchDashboard() async {
    final response = await _client.get(ApiConfig.getData('dashboard'));
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return DashboardModel.fromJson(data);
    }
    return DashboardModel.empty;
  }

  Future<SessionUserModel> _fetchSessionUser() async {
    final response = await _client.get(ApiConfig.getData('session_user'));
    final data = response.data;
    if (data is List && data.isNotEmpty) {
      return SessionUserModel.fromJson(data.first as Map<String, dynamic>);
    }
    if (data is Map<String, dynamic>) {
      return SessionUserModel.fromJson(data);
    }
    throw Exception('Unexpected session_user response format');
  }
}
