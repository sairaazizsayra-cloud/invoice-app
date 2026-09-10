import 'package:flutter/foundation.dart';

/// Chooses the App Check provider. Debug builds use the debug provider so
/// emulators can work after the token is registered in the Firebase console.
///
/// Optional CI token (never commit it, never log it):
/// `--dart-define=APP_CHECK_DEBUG_TOKEN=<token>`
class AppCheckConfig {
  AppCheckConfig._();

  static const String _debugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');

  static bool useDebugProvider({bool? isDebug}) => isDebug ?? kDebugMode;

  static String? get debugTokenOrNull {
    final token = _debugToken.trim();
    if (token.isEmpty) return null;
    return token;
  }
}
