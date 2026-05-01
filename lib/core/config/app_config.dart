import 'package:flutter/services.dart';

class AppConfig {
  AppConfig._();

  static final Map<String, String> _env = {};

  static Future<void> load() async {
    final content = await rootBundle.loadString('.env');
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final idx = trimmed.indexOf('=');
      if (idx == -1) continue;
      _env[trimmed.substring(0, idx).trim()] = trimmed.substring(idx + 1).trim();
    }
  }

  static String get geminiApiKey => _env['GEMINI_API_KEY'] ?? '';
  static String get groqApiKey => _env['GROQ_API_KEY'] ?? '';
  static String get cerebrasApiKey => _env['CEREBRAS_API_KEY'] ?? '';
  static String get metalsDevApiKey => _env['METALS_DEV_API_KEY'] ?? '';
  static String get binanceBaseUrl => _env['BINANCE_BASE_URL'] ?? 'https://api.binance.com/api/v3';
}
