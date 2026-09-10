import 'dart:async';

import 'package:invoice_pro/core/constants/user_roles.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/models/app_user.dart';
import 'package:invoice_pro/repositories/auth_repository.dart';

class InMemoryAuthRepository implements AuthRepository {
  InMemoryAuthRepository({AuthSession? session}) : _session = session;

  AuthSession? _session;
  final StreamController<AuthSession?> _controller = StreamController<AuthSession?>.broadcast();

  @override
  AuthSession? get currentSession => _session;

  @override
  Stream<AuthSession?> watchSession() async* {
    yield _session;
    yield* _controller.stream;
  }

  void emit(AuthSession? session) {
    _session = session;
    _controller.add(session);
  }

  @override
  Future<void> register(RegisterRequest request) async {
    emit(
      AuthSession(
        uid: 'user_1',
        email: request.email.trim(),
        emailVerified: false,
        profile: AppUser(
          uid: 'user_1',
          name: request.name.trim(),
          businessName: request.businessName.trim(),
          email: request.email.trim(),
          phone: request.phone.trim(),
          role: UserRoles.businessOwner,
          isActive: true,
          emailVerified: false,
          businessId: 'biz_1',
        ),
      ),
    );
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (email == 'disabled@test.pk') {
      throw const AppException('This account has been disabled.', debugCode: 'user-disabled');
    }
    emit(verifiedSession(email: email.trim()));
  }

  @override
  Future<void> signOut() async => emit(null);

  @override
  Future<void> sendPasswordReset({required String email}) async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> reloadAndRefresh() async {
    final session = _session;
    if (session == null) return;
    emit(
      AuthSession(
        uid: session.uid,
        email: session.email,
        emailVerified: true,
        profile: session.profile?.copyWith(emailVerified: true),
      ),
    );
  }

  void dispose() {
    unawaited(_controller.close());
  }

  static AuthSession verifiedSession({
    String email = 'owner@business.pk',
    String name = 'Ayesha Khan',
  }) {
    return AuthSession(
      uid: 'user_1',
      email: email,
      emailVerified: true,
      profile: AppUser(
        uid: 'user_1',
        name: name,
        businessName: 'Khan Traders',
        email: email,
        phone: '03001234567',
        role: UserRoles.businessOwner,
        isActive: true,
        emailVerified: true,
        businessId: 'biz_1',
      ),
    );
  }

  static AuthSession unverifiedSession({String email = 'new@business.pk'}) {
    return AuthSession(
      uid: 'user_2',
      email: email,
      emailVerified: false,
      profile: AppUser(
        uid: 'user_2',
        name: 'New Owner',
        businessName: 'New Shop',
        email: email,
        phone: '03001112233',
        role: UserRoles.businessOwner,
        isActive: true,
        emailVerified: false,
        businessId: 'biz_2',
      ),
    );
  }
}
