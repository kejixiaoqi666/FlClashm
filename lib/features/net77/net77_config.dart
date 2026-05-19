class Net77Config {
  static const appName = '77net';

  static const appDisplayName = String.fromEnvironment(
    'NET77_APP_DISPLAY_NAME',
    defaultValue: '77net',
  );

  static const apiBaseUrl = String.fromEnvironment(
    'NET77_API_BASE_URL',
    defaultValue: 'https://flash.354873.xyz',
  );

  static const defaultCurrency = '¥';
}
