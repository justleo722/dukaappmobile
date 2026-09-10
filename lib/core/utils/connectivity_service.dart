import 'dart:async';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ConnectivityService {
  final InternetConnection _connection;
  StreamSubscription<InternetStatus>? _subscription;
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();

  ConnectivityService({InternetConnection? connection})
      : _connection = connection ?? InternetConnection();

  Stream<bool> get connectivityStream => _connectivityController.stream;

  void startListening() {
    _subscription = _connection.onStatusChange.listen((status) {
      _connectivityController.add(status == InternetStatus.connected);
    });
  }

  void stopListening() {
    _subscription?.cancel();
  }

  Future<bool> isConnected() async {
    return await _connection.hasInternetAccess;
  }

  void dispose() {
    stopListening();
    _connectivityController.close();
  }
}
