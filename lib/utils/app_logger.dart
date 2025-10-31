import 'dart:developer' as developer;

/// Utility class for logging throughout the application
/// Replaces print statements with proper logging that can be disabled in production
class AppLogger {
  static const String _appName = 'RelatorioApp';

  /// Log information messages
  static void info(String message, {String? tag}) {
    _log(message, tag: tag, level: 800);
  }

  /// Log warning messages
  static void warning(String message, {String? tag}) {
    _log(message, tag: tag, level: 900);
  }

  /// Log error messages
  static void error(String message, {String? tag, Object? error}) {
    _log(message, tag: tag, level: 1000, error: error);
  }

  /// Log debug messages (only in debug mode)
  static void debug(String message, {String? tag}) {
    assert(() {
      _log(message, tag: tag, level: 700);
      return true;
    }());
  }

  static void _log(
    String message, {
    String? tag,
    int level = 800,
    Object? error,
  }) {
    final formattedTag = tag != null ? '[$tag]' : '';
    developer.log(
      '$formattedTag $message',
      name: _appName,
      level: level,
      error: error,
    );
  }
}
