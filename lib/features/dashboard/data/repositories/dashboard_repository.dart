/// DashboardRepository — thin layer between the datasource and providers.
///
/// Wraps DashboardRemoteDatasource and exposes a single [fetch] method
/// that returns the dashboard data plus the current user session.
/// Exceptions from the datasource propagate up to the Riverpod provider
/// so they can be handled as AsyncError states in the UI.

import 'package:dukaapp/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:dukaapp/features/dashboard/data/models/dashboard_model.dart';
import 'package:dukaapp/features/dashboard/data/models/session_user_model.dart';

class DashboardState {
  const DashboardState({
    required this.dashboard,
    required this.sessionUser,
  });

  final DashboardModel dashboard;
  final SessionUserModel sessionUser;
}

class DashboardRepository {
  const DashboardRepository(this._datasource);

  final DashboardRemoteDatasource _datasource;

  /// Fetches dashboard summary and session user in parallel.
  Future<DashboardState> fetch() async {
    final (dashboard, sessionUser) = await _datasource.fetchAll();
    return DashboardState(dashboard: dashboard, sessionUser: sessionUser);
  }
}
