import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_pro/core/constants/user_roles.dart';
import 'package:invoice_pro/models/app_user.dart';
import 'package:invoice_pro/providers/auth_provider.dart';
import 'package:invoice_pro/repositories/auth_repository.dart';

import '../helpers/in_memory_auth_repository.dart';

void main() {
  group('AuthProvider flows', () {
    test('register creates a session that still needs email verification', () async {
      final repo = InMemoryAuthRepository();
      final auth = AuthProvider(repo);
      addTearDown(auth.dispose);

      await auth.register(
        const RegisterRequest(
          name: 'Ali',
          businessName: 'Ali Store',
          email: 'ali@store.pk',
          phone: '03001112233',
          password: 'Secret123',
        ),
      );

      expect(auth.isSignedIn, isTrue);
      expect(auth.isEmailVerified, isFalse);
      expect(auth.status, AuthStatus.needsVerification);
      expect(auth.profile?.businessName, 'Ali Store');
    });

    test('register still advances when the session stream is silent', () async {
      final repo = _CurrentSessionOnlyAuthRepository();
      final auth = AuthProvider(repo);
      addTearDown(auth.dispose);

      await auth.register(
        const RegisterRequest(
          name: 'Sara',
          businessName: 'Sara Mart',
          email: 'sara@mart.pk',
          phone: '03001112233',
          password: 'Secret123',
        ),
      );

      expect(auth.isSignedIn, isTrue);
      expect(auth.isEmailVerified, isFalse);
      expect(auth.status, AuthStatus.needsVerification);
    });

    test('sign in, reload verification, then sign out', () async {
      final repo = InMemoryAuthRepository();
      final auth = AuthProvider(repo);
      addTearDown(auth.dispose);

      await auth.signIn(email: 'owner@business.pk', password: 'Secret123');
      await Future<void>.delayed(Duration.zero);
      expect(auth.status, AuthStatus.authenticated);
      expect(auth.canAccessApp, isTrue);

      await auth.signOut();
      await Future<void>.delayed(Duration.zero);
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.session, isNull);
    });

    test('password reset completes without exposing technical errors', () async {
      final repo = InMemoryAuthRepository();
      final auth = AuthProvider(repo);
      addTearDown(auth.dispose);

      await expectLater(
        auth.sendPasswordReset(email: 'owner@business.pk'),
        completes,
      );
    });

    test('disabled account surfaces a mapped AppException', () async {
      final repo = InMemoryAuthRepository();
      final auth = AuthProvider(repo);
      addTearDown(auth.dispose);

      await expectLater(
        auth.signIn(email: 'disabled@test.pk', password: 'x'),
        throwsA(isA<Exception>()),
      );
      expect(auth.status, AuthStatus.signedOut);
    });
  });
}

/// Updates [currentSession] on register but never emits on [watchSession],
/// matching a Firebase race where userChanges has not hydrated yet.
class _CurrentSessionOnlyAuthRepository implements AuthRepository {
  AuthSession? _session;

  @override
  AuthSession? get currentSession => _session;

  @override
  Stream<AuthSession?> watchSession() async* {
    yield _session;
  }

  @override
  Future<void> register(RegisterRequest request) async {
    _session = AuthSession(
      uid: 'user_silent',
      email: request.email.trim(),
      emailVerified: false,
      profile: AppUser(
        uid: 'user_silent',
        name: request.name.trim(),
        businessName: request.businessName.trim(),
        email: request.email.trim(),
        phone: request.phone.trim(),
        role: UserRoles.businessOwner,
        isActive: true,
        emailVerified: false,
        businessId: 'biz_silent',
      ),
    );
  }

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> signOut() async {
    _session = null;
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> reloadAndRefresh() async {}
}
