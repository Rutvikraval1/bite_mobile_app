import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'core/config/app_env.dart';
import 'core/services/first_launch_service.dart';
import 'core/theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installErrorHandlers();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // Missing/unreadable .env asset: AppEnv falls back to empty values and
    // BiteApp shows the ConfigErrorScreen instead of crashing at startup.
    debugPrint('[bite] Failed to load .env: $e');
  }
  AppEnv.validate();
  await FirstLaunchService.instance.load();
  runApp(const BiteApp());
}

/// Global crash protection so a single bad frame or stray async error
/// doesn't take the whole app down.
void _installErrorHandlers() {
  FlutterError.onError = (details) {
    debugPrint('[bite] FlutterError: ${details.exceptionAsString()}');
    if (kDebugMode) FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[bite] Uncaught async error: $error\n$stack');
    return true;
  };

  if (kReleaseMode) {
    ErrorWidget.builder = (details) => const ColoredBox(
          color: AppColors.bgDark,
          child: Center(
            child: Text(
              '⚠️',
              textDirection: TextDirection.ltr,
              style: TextStyle(fontSize: 20, color: Color(0x66FFFFFF)),
            ),
          ),
        );
  }
}
