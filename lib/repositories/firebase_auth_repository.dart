import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/constants/user_roles.dart';
import 'package:invoice_pro/core/errors/auth_exception.dart';
import 'package:invoice_pro/core/utils/app_logger.dart';
import 'package:invoice_pro/models/app_user.dart';
import 'package:invoice_pro/repositories/auth_repository.dart';
import 'package:invoice_pro/repositories/business_repository.dart';
import 'package:invoice_pro/repositories/firebase_business_repository.dart';
import 'package:invoice_pro/repositories/user_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    UserRepository? users,
    BusinessRepository? businesses,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _users = users ?? UserRepository(),
       _businesses = businesses ?? FirebaseBusinessRepository();

  static const int _profileHydrateAttempts = 10;
  static const Duration _profileHydrateRetryDelay = Duration(milliseconds: 200);

  final FirebaseAuth _auth;
  final UserRepository _users;
  final BusinessRepository _businesses;

  @override
  AuthSession? get currentSession {
    final user = _auth.currentUser;
    if (user == null) return null;
    return AuthSession(
      uid: user.uid,
      email: user.email ?? '',
      emailVerified: user.emailVerified,
    );
  }

  @override
  Stream<AuthSession?> watchSession() async* {
    await for (final user in _auth.userChanges()) {
      if (user == null) {
        yield null;
        continue;
      }
      try {
        yield await _hydrate(user);
      } on AuthException catch (error, stack) {
        AppLogger.error('Auth hydrate rejected', error, stack);
        if (error.debugCode == 'user-disabled') {
          await _auth.signOut();
          yield null;
          continue;
        }
        yield _sessionFromUser(user);
      } catch (error, stack) {
        AppLogger.error('Auth hydrate failed', error, stack);
        yield _sessionFromUser(user);
      }
    }
  }

  @override
  Future<void> register(RegisterRequest request) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: request.email.trim(),
        password: request.password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException(AppStrings.somethingWentWrong, debugCode: 'register-no-user');
      }

      // Write the workspace first so the session stream can hydrate before the
      // slower verification email call finishes.
      final businessId = _businesses.newId();
      final profile = AppUser(
        uid: user.uid,
        name: request.name.trim(),
        businessName: request.businessName.trim(),
        email: request.email.trim(),
        phone: request.phone.trim(),
        role: UserRoles.businessOwner,
        isActive: true,
        emailVerified: user.emailVerified,
        businessId: businessId,
      );
      await _writeOwnerWorkspace(profile: profile, businessId: businessId);

      try {
        await user.updateDisplayName(request.name.trim());
      } on FirebaseAuthException catch (error, stack) {
        AppLogger.error('Display name update failed after register', error, stack);
      }
      unawaited(_sendRegisterVerification(user));
    } on FirebaseAuthException catch (error) {
      throw AuthErrorMapper.fromCode(error.code, cause: error);
    } on FirebaseException catch (error) {
      throw AuthErrorMapper.fromCode(error.code, cause: error);
    } on AuthException {
      rethrow;
    } catch (error, stack) {
      AppLogger.error('Register failed', error, stack);
      throw AuthException(AppStrings.somethingWentWrong, cause: error);
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException(AppStrings.somethingWentWrong, debugCode: 'login-no-user');
      }

      final profile = await _users.fetch(user.uid);
      if (profile != null) {
        _users.assertActive(profile);
        if (profile.emailVerified != user.emailVerified) {
          await _users.syncEmailVerified(uid: user.uid, verified: user.emailVerified);
        }
      }
    } on FirebaseAuthException catch (error) {
      throw AuthErrorMapper.fromCode(error.code, cause: error);
    } on AuthException {
      await _auth.signOut();
      rethrow;
    } catch (error, stack) {
      AppLogger.error('Sign-in failed', error, stack);
      throw AuthException(AppStrings.somethingWentWrong, cause: error);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw AuthErrorMapper.fromCode(error.code, cause: error);
    } catch (error, stack) {
      AppLogger.error('Password reset failed', error, stack);
      throw AuthException(AppStrings.somethingWentWrong, cause: error);
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException(AppStrings.somethingWentWrong, debugCode: 'verify-no-user');
    }
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (error) {
      throw AuthErrorMapper.fromCode(error.code, cause: error);
    }
  }

  @override
  Future<void> reloadAndRefresh() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.reload();
    final refreshed = _auth.currentUser;
    if (refreshed == null) return;
    try {
      await _users.syncEmailVerified(uid: refreshed.uid, verified: refreshed.emailVerified);
    } catch (error, stack) {
      AppLogger.error('Could not sync emailVerified', error, stack);
    }
  }

  Future<AuthSession> _hydrate(User user) async {
    var profile = await _fetchProfileWithRetry(user.uid);
    if (profile == null) {
      profile = AppUser(
        uid: user.uid,
        name: user.displayName ?? '',
        businessName: '',
        email: user.email ?? '',
        phone: user.phoneNumber ?? '',
        role: UserRoles.businessOwner,
        isActive: true,
        emailVerified: user.emailVerified,
      );
      try {
        await _users.upsertIfMissing(profile);
      } catch (error, stack) {
        AppLogger.error('Could not create missing user profile', error, stack);
        return _sessionFromUser(user);
      }
    } else {
      _users.assertActive(profile);
    }
    if (profile.emailVerified != user.emailVerified) {
      await _users.syncEmailVerified(uid: user.uid, verified: user.emailVerified);
      profile = profile.copyWith(emailVerified: user.emailVerified);
    }

    try {
      final business = await _businesses.ensureForOwner(profile);
      if (profile.businessId != business.id) {
        profile = profile.copyWith(businessId: business.id);
      }
    } catch (error, stack) {
      AppLogger.error('Could not ensure business workspace', error, stack);
    }

    return _sessionFromUser(user, profile: profile);
  }

  Future<AppUser?> _fetchProfileWithRetry(String uid) async {
    AppUser? profile;
    for (var attempt = 0; attempt < _profileHydrateAttempts; attempt++) {
      profile = await _users.fetch(uid);
      if (profile != null) return profile;
      if (attempt < _profileHydrateAttempts - 1) {
        await Future<void>.delayed(_profileHydrateRetryDelay);
      }
    }
    return profile;
  }

  AuthSession _sessionFromUser(User user, {AppUser? profile}) {
    return AuthSession(
      uid: user.uid,
      email: user.email ?? '',
      emailVerified: user.emailVerified,
      profile: profile,
    );
  }

  Future<void> _writeOwnerWorkspace({
    required AppUser profile,
    required String businessId,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await _users.create(profile);
        await _businesses.createForOwner(owner: profile, businessId: businessId);
        return;
      } catch (error, stack) {
        lastError = error;
        AppLogger.error('Owner workspace write failed', error, stack);
        if (attempt < 2) {
          await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
        }
      }
    }
    AppLogger.error('Owner workspace write gave up', lastError);
  }

  Future<void> _sendRegisterVerification(User user) async {
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (error, stack) {
      AppLogger.error('Verification email failed after register', error, stack);
    } catch (error, stack) {
      AppLogger.error('Verification email failed after register', error, stack);
    }
  }
}
