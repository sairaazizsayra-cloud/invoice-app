import 'package:invoice_pro/models/app_user.dart';

class RegisterRequest {
  const RegisterRequest({
    required this.name,
    required this.businessName,
    required this.email,
    required this.phone,
    required this.password,
  });

  final String name;
  final String businessName;
  final String email;
  final String phone;
  final String password;
}

/// Auth operations used by the UI. Additional providers (Google, Apple) can
/// be added here later without changing screens.
abstract class AuthRepository {
  AuthSession? get currentSession;

  Stream<AuthSession?> watchSession();

  Future<void> register(RegisterRequest request);

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();

  Future<void> sendPasswordReset({required String email});

  Future<void> sendEmailVerification();

  Future<void> reloadAndRefresh();
}
