import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:invoice_pro/core/utils/app_logger.dart';
import 'package:invoice_pro/core/utils/log_sanitizer.dart';
import 'package:invoice_pro/core/utils/platform_capabilities.dart';
import 'package:invoice_pro/firebase/firebase_bootstrap.dart';

/// Crashlytics wrapper. No-ops until Firebase has been initialized.
class CrashReporting {
  CrashReporting._();

  static Future<void> attach() async {
    if (!FirebaseBootstrap.initialized || !PlatformCapabilities.crashlytics) return;
    AppLogger.crashSink = recordNonFatal;
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    } catch (error, stack) {
      AppLogger.crashSink = null;
      AppLogger.debug('Crashlytics attach failed: $error $stack');
    }
  }

  static void recordNonFatal(String message, Object? error, StackTrace? stack) {
    unawaited(_record(message, error, stack, fatal: false));
  }

  static Future<void> recordFatal(String message, Object? error, StackTrace? stack) {
    return _record(message, error, stack, fatal: true);
  }

  static void setUserId(String? uid) {
    if (!FirebaseBootstrap.initialized || !PlatformCapabilities.crashlytics) return;
    unawaited(FirebaseCrashlytics.instance.setUserIdentifier(uid ?? ''));
  }

  static Future<void> _record(
    String message,
    Object? error,
    StackTrace? stack, {
    required bool fatal,
  }) async {
    if (!FirebaseBootstrap.initialized || !PlatformCapabilities.crashlytics) return;
    try {
      await FirebaseCrashlytics.instance.recordError(
        LogSanitizer.scrub(error?.toString() ?? message),
        stack,
        reason: LogSanitizer.scrub(message),
        fatal: fatal,
      );
    } catch (_) {
      // Never let diagnostics crash the app.
    }
  }
}
