import 'package:dukaapp/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:dukaapp/features/dashboard/data/models/dashboard_model.dart';
import 'package:dukaapp/features/dashboard/data/models/session_user_model.dart';

class DashboardState {
  const DashboardState({
    required this.dashboard,
    required this.sessionUser,
  });

  final DashboardModel    dashboard;
  final SessionUserModel  sessionUser;

  // ── Cache serialisation ─────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'dashboard'   : dashboard.toJson(),
    'session_user': sessionUser.toJson(),
  };

  factory DashboardState.fromCache(Map<String, dynamic> json) {
    return DashboardState(
      dashboard  : DashboardModel.fromJson(
          json['dashboard']    as Map<String, dynamic>? ?? {}),
      sessionUser: SessionUserModel.fromJson(
          json['session_user'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class DashboardRepository {
  const DashboardRepository(this._datasource);

  final DashboardRemoteDatasource _datasource;

  Future<DashboardState> fetch() async {
    final (dashboard, sessionUser) = await _datasource.fetchAll();
    return DashboardState(dashboard: dashboard, sessionUser: sessionUser);
  }
}
