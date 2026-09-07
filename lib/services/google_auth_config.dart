class GoogleAuthConfig {
  /// The OAuth 2.0 **Web** Client ID from Google Cloud Console — must be the
  /// exact same value as GOOGLE_OAUTH_CLIENT_ID in the backend's .env.
  ///
  /// This is used as GoogleSignIn's serverClientId, which makes the ID
  /// token's "aud" claim the Web client (not the Android/iOS client that
  /// google_sign_in also needs registered) — that's what the backend
  /// verifies against in verify_google_id_token().
  ///
  /// Also requires per-platform setup that only your Google Cloud project
  /// can provide: an Android OAuth client (with your app's package name +
  /// SHA-1 signing fingerprint) and/or an iOS OAuth client (with your
  /// bundle ID), both linked to the same project as this Web client.
  static const String serverClientId =
      '231819678017-rve5mb2osjr63rj686k768ueemj2efs6.apps.googleusercontent.com';
}
