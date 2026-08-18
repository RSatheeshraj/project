import 'package:flutter/foundation.dart' show debugPrint;

/// Application-wide structured logger.
///
/// Uses Flutter's [debugPrint] internally, which is automatically stripped
/// in release builds — making it safe for production.
///
/// Usage:
/// ```dart
/// AppLogger.d('[FarmRepository] watchFarms → ${farms.length} farms loaded');
/// AppLogger.e('[BatchRepository] addBatch failed', error: e, stackTrace: st);
/// ```
abstract final class AppLogger {
  // ── Log levels ─────────────────────────────────────────────────────────────

  /// Debug — verbose information useful during development.
  static void d(String message) {
    debugPrint('🐔 [DEBUG] $message');
  }

  /// Info — significant lifecycle events (data loaded, operations completed).
  static void i(String message) {
    debugPrint('🐔 [INFO]  $message');
  }

  /// Warning — unexpected but recoverable situations.
  static void w(String message) {
    debugPrint('🐔 [WARN]  $message');
  }

  /// Error — failures that require attention.
  ///
  /// Logs the [message], the optional [error] object, and optional [stackTrace].
  static void e(String message, {Object? error, StackTrace? stackTrace}) {
    debugPrint('🐔 [ERROR] $message');
    if (error != null) debugPrint('         ↳ Error: $error');
    if (stackTrace != null) debugPrint('         ↳ StackTrace:\n$stackTrace');
  }
}
