import 'package:flutter/foundation.dart';

class ApiConfig {
  // Always override this per network with:
  //   flutter run --dart-define=QUEUEFLOW_API_BASE_URL=http://<your-pc-lan-ip>:5000
  // The Android fallback below is a specific developer machine's current
  // Wi-Fi LAN IP (check with `ipconfig` / `Get-NetIPAddress` on that PC) —
  // it WILL go stale the moment that machine reconnects to a different
  // network or gets reassigned a new DHCP address. Don't rely on it silently
  // matching; always pass the override for anyone else's setup.
  static const String _overrideBaseUrl = String.fromEnvironment(
    'QUEUEFLOW_API_BASE_URL',
  );

  static String get baseUrl {
    final override = _overrideBaseUrl.trim();
    if (override.isNotEmpty) return _stripTrailingSlash(override);

    if (kIsWeb) return 'http://localhost:5000';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.53.16.12:5000';
        // return 'https://cv-auto-ticket-generation.onrender.com';
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
