class Config {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080',
  );
}
