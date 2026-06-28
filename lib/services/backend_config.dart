class BackendConfig {
  static const bool useAwsBackend = bool.fromEnvironment(
    'USE_AWS_BACKEND',
    defaultValue: false,
  );

  static bool get useLocalBackend => !useAwsBackend;
}
