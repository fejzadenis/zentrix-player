/// Compile-time license API configuration.
///
/// Production: pass at build time, e.g.
/// `flutter build apk --dart-define=LICENSE_API_BASE_URL=https://license.example.com`
class LicenseConstants {
  LicenseConstants._();

  static const String apiBaseUrl = String.fromEnvironment(
    'LICENSE_API_BASE_URL',
    defaultValue: '',
  );

  /// When true (and [apiBaseUrl] is set), app sends `X-App-Secret` header.
  static const String appSecret = String.fromEnvironment(
    'LICENSE_APP_SECRET',
    defaultValue: '',
  );

  /// Offline grace after last successful validation (Smarters-style short window).
  static const Duration offlineGrace = Duration(hours: 24);

  static const Duration trialDuration = Duration(days: 3);

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
