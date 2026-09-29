import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app/app.dart';
import 'core/services/app_update_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Desktop (Linux/Windows/macOS) needs FFI factory; mobile initialises itself.
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  AppUpdateService.checkForUpdate();
  runApp(
    const ProviderScope(
      child: DukaApp(),
    ),
  );
}
