import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/services/app_update_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppUpdateService.checkForUpdate();
  runApp(
    const ProviderScope(
      child: DukaApp(),
    ),
  );
}
