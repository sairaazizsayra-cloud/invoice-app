import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/utils/app_logger.dart';
import 'package:invoice_pro/firebase/crash_reporting.dart';
import 'package:invoice_pro/models/app_user.dart';
import 'package:invoice_pro/repositories/auth_repository.dart';

enum AuthStatus { unknown, signedOut, needsVerification, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository) {
    _session = _repository.currentSession;
    _subscription = _repository.watchSession().listen(
      _applySession,
      onError: (Object error, StackTrace stack) {
        AppLogger.error('Auth session stream failed', error, stack);
        _syncFromRepository();
      },
    );
  }

  final AuthRepository _repository;
  StreamSubscription<AuthSession?>? _subscription;
  AuthSession? _session;
  bool _busy = false;

  AuthSession? get session => _session;
  AppUser? get profile => _session?.profile;
  bool get isBusy => _busy;

  bool get isSignedIn => _session != null;
  bool get isEmailVerified => _session?.emailVerified ?? false;
  bool get canAccessApp => _session?.canAccessApp ?? false;

  AuthStatus get status {
    final session = _session;
    if (session == null) return AuthStatus.signedOut;
    if (!session.emailVerified) return AuthStatus.needsVerification;
    if (session.profile != null && !session.profile!.isActive) {
      return AuthStatus.signedOut;
    }
    return AuthStatus.authenticated;
  }

  Future<void> register(RegisterRequest request) {
    return _run(() => _repository.register(request));
  }

  Future<void> signIn({required String email, required String password}) {
    return _run(() => _repository.signIn(email: email, password: password));
  }

  Future<void> signOut() {
    return _run(_repository.signOut);
  }

  Future<void> sendPasswordReset({required String email}) {
    return _run(() => _repository.sendPasswordReset(email: email));
  }

  Future<void> sendEmailVerification() {
    return _run(_repository.sendEmailVerification);
  }

  Future<void> reloadAndRefresh({bool showBusy = true}) async {
    if (showBusy) {
      await _run(_repository.reloadAndRefresh);
      return;
    }
    await _repository.reloadAndRefresh();
    _syncFromRepository();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    _busy = true;
    notifyListeners();
    try {
      await action();
    } on AppException {
      rethrow;
    } catch (error, stack) {
      AppLogger.error('Auth action failed', error, stack);
      rethrow;
    } finally {
      _syncFromRepository();
      _busy = false;
      notifyListeners();
    }
  }

  void _syncFromRepository() {
    final latest = _repository.currentSession;
    if (latest == null) {
      if (_session != null) _applySession(null);
      return;
    }

    final mergedProfile =
        latest.profile ?? (_session?.uid == latest.uid ? _session?.profile : null);
    final current = _session;
    if (current != null &&
        current.uid == latest.uid &&
        current.email == latest.email &&
        current.emailVerified == latest.emailVerified &&
        identical(current.profile, mergedProfile)) {
      return;
    }

    _applySession(
      AuthSession(
        uid: latest.uid,
        email: latest.email,
        emailVerified: latest.emailVerified,
        profile: mergedProfile,
      ),
    );
  }

  void _applySession(AuthSession? session) {
    _session = session;
    CrashReporting.setUserId(session?.uid);
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
