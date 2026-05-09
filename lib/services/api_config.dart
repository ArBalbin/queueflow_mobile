import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _overrideBaseUrl = String.fromEnvironment(
    'QUEUEFLOW_API_BASE_URL',
  );

  static String get baseUrl {
    final override = _overrideBaseUrl.trim();
    if (override.isNotEmpty) return _stripTrailingSlash(override);

    if (kIsWeb) return 'http://localhost:5000';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://192.168.43.236:5000';
      case TargetPlatform.iOS:
        return 'http://127.0.0.1:5000';
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return 'http://localhost:5000';
    }
  }

  static String _stripTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
