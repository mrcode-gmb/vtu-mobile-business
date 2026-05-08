// core/config/app_config.dart
import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static String get apiBaseUrl {
    const String configured = String.fromEnvironment('PTS_DATA_API_BASE_URL');
    if (configured.isNotEmpty) {
      return configured;
    }

    const String legacyConfigured = String.fromEnvironment(
      'AIRPLUG_API_BASE_URL',
    );
    if (legacyConfigured.isNotEmpty) {
      return legacyConfigured;
    }

    if (kIsWeb) {
      return 'https://ptsdata.com.ng/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return 'https://ptsdata.com.ng/api';
    }
  }
}
