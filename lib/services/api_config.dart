class ApiConfig {
  /// The deployed backend. This is the default for every platform, because it
  /// is where the app is actually expected to talk in normal use: the backend
  /// runs in the cloud so phones can reach it from any network, and only the
  /// detector stays on a local machine with the camera.
  ///
  /// The previous default was a developer laptop's Wi-Fi LAN address. That
  /// address goes stale the moment the machine joins a different network or
  /// is reassigned by DHCP, and a release build carrying it cannot reach
  /// anything at all — which is exactly what happened: installed APKs were
  /// pointing at a LAN IP that no longer existed while the real backend was
  /// live and healthy.
  static const String cloudBaseUrl =
      'https://cv-auto-ticket-generation.onrender.com';

  /// Point the app somewhere else for local development, passing the LAN
  /// address of the machine running the backend:
  ///   `flutter run --dart-define=QUEUEFLOW_API_BASE_URL=http://192.168.1.5:5000`
  static const String _overrideBaseUrl = String.fromEnvironment(
    'QUEUEFLOW_API_BASE_URL',
  );

  static String get baseUrl {
    final override = _overrideBaseUrl.trim();
    if (override.isNotEmpty) return _stripTrailingSlash(override);
    return cloudBaseUrl;
  }

  static String _stripTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
