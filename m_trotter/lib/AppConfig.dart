class AppConfig {
  static const String serverUrl = String.fromEnvironment(
    'SERVER_URL',
    defaultValue: '',
  );
}