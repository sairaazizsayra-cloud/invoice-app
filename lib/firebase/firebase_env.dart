/// Selects development vs production Firebase options.
///
/// Pass `--dart-define=FIREBASE_ENV=production` for a production build.
class FirebaseAppEnvironment {
  FirebaseAppEnvironment._();

  static const String name = String.fromEnvironment(
    'FIREBASE_ENV',
    defaultValue: 'development',
  );

  static bool get isProduction => name == 'production';

  static const String missingConfigMessage =
      'Firebase is not configured. Create a Firebase project, enable Email/Password '
      'authentication, then run: flutterfire configure';
}
