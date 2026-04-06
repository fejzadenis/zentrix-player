class AppConstants {
  AppConstants._();

  static const String appName = 'Zentrix';
  static const String appVersion = '1.0.0';

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const int maxRecentChannels = 50;
  static const int defaultBufferMs = 30000;
  static const int minBufferMs = 15000;
  static const int maxBufferMs = 60000;

  static const String defaultUserAgent = 'Zentrix/1.0';

  static const List<String> supportedExtensions = ['.m3u', '.m3u8'];
}
