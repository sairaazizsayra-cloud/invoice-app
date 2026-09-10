import 'package:flutter/foundation.dart';
import 'package:invoice_pro/core/utils/log_sanitizer.dart';

typedef AppCrashSink = void Function(String message, Object? error, StackTrace? stack);

/// Debug logger plus an optional Crashlytics sink.
/// Never log passwords, tokens, or personal data from call sites.
class AppLogger {
  AppLogger._();

  static AppCrashSink? crashSink;

  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('[InvoicePro] $message');
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[InvoicePro][ERROR] ${LogSanitizer.scrub(message)}');
      if (error != null) {
        debugPrint('[InvoicePro][ERROR] ${LogSanitizer.scrub(error.toString())}');
      }
      if (stackTrace != null) {
        debugPrint('$stackTrace');
      }
    }
    crashSink?.call(message, error, stackTrace);
  }
}
