import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/auth_exception.dart';
import 'package:invoice_pro/firebase/firebase_bootstrap.dart';
import 'package:invoice_pro/models/app_user.dart';
import 'package:invoice_pro/repositories/auth_repository.dart';
import 'package:invoice_pro/repositories/firebase_auth_repository.dart';

AuthRepository createAuthRepository() {
  if (!FirebaseBootstrap.initialized) {
    return const UnconfiguredAuthRepository();
  }
  return FirebaseAuthRepository();
}

/// Used only when FlutterFire options have not been generated yet.
/// This is not a mock login — every credential action fails with a setup message.
class UnconfiguredAuthRepository implements AuthRepository {
  const UnconfiguredAuthRepository();

  static const AuthException _notConfigured = AuthException(
    AppStrings.authFirebaseNotConfigured,
    debugCode: 'firebase-unconfigured',
  );

  @override
  AuthSession? get currentSession => null;

  @override
  Stream<AuthSession?> watchSession() => Stream<AuthSession?>.value(null);

  @override
  Future<void> register(RegisterRequest request) async {
    throw _notConfigured;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    throw _notConfigured;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordReset({required String email}) async {
    throw _notConfigured;
  }

  @override
  Future<void> sendEmailVerification() async {
    throw _notConfigured;
  }

  @override
  Future<void> reloadAndRefresh() async {}
}
