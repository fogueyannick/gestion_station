import 'package:flutter/foundation.dart';

class LogService {
  static const bool _enableLogs = kDebugMode; // Seulement en mode debug

  static void debug(String message) {
    if (_enableLogs) {
      debugPrint('🐛 [DEBUG] $message');
    }
  }

  static void info(String message) {
    if (_enableLogs) {
      debugPrint('ℹ️  [INFO] $message');
    }
  }

  static void warning(String message) {
    if (_enableLogs) {
      debugPrint('⚠️  [WARNING] $message');
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (_enableLogs) {
      debugPrint('❌ [ERROR] $message');
      if (error != null) debugPrint('Error: $error');
      if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
    }
  }

  static void api(String method, String endpoint, {int? statusCode}) {
    if (_enableLogs) {
      debugPrint('🌐 [API] $method $endpoint ${statusCode != null ? "($statusCode)" : ""}');
    }
  }
}
