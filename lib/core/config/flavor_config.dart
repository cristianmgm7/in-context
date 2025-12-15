import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._({
    required this.name,
    required this.apiBaseUrl,
    required this.apiTimeout,
    required this.enableLogging,
  });

  static AppConfig? _instance;

  final String name;
  final String apiBaseUrl;
  final int apiTimeout;
  final bool enableLogging;

  static AppConfig get instance {
    if (_instance == null) {
      throw StateError(
        'AppConfig not initialized. Call initialize() first.',
      );
    }
    return _instance!;
  }

  static Future<void> initialize() async {
    // Load .env file
    await dotenv.load(fileName: '.env');

    _instance = AppConfig._(
      name: dotenv.env['APP_NAME'] ?? 'InContext',
      apiBaseUrl: dotenv.env['API_BASE_URL'] ?? '',
      apiTimeout: int.parse(dotenv.env['API_TIMEOUT'] ?? '30000'),
      enableLogging: dotenv.env['ENABLE_LOGGING'] == 'true',
    );
  }
}
