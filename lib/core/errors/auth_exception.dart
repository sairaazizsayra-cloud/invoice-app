import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';

class AuthException extends AppException {
  const AuthException(super.userMessage, {super.debugCode, super.cause});
}

/// Maps Firebase Auth error codes to user-facing messages.
///
/// Newer Firebase projects often return `invalid-credential` instead of
/// `user-not-found` / `wrong-password` because of email enumeration protection.
class AuthErrorMapper {
  AuthErrorMapper._();

  static AuthException fromCode(String code, {Object? cause}) {
    switch (_normalize(code)) {
      case 'invalid-email':
        return AuthException(AppStrings.authInvalidEmail, debugCode: code, cause: cause);
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return AuthException(AppStrings.authWrongPassword, debugCode: code, cause: cause);
      case 'user-not-found':
        return AuthException(AppStrings.authUserNotFound, debugCode: code, cause: cause);
      case 'user-disabled':
        return AuthException(AppStrings.authUserDisabled, debugCode: code, cause: cause);
      case 'network-request-failed':
      case 'unavailable':
      case 'deadline-exceeded':
        return AuthException(AppStrings.authNetworkError, debugCode: code, cause: cause);
      case 'email-already-in-use':
        return AuthException(AppStrings.authEmailInUse, debugCode: code, cause: cause);
      case 'weak-password':
        return AuthException(AppStrings.authWeakPassword, debugCode: code, cause: cause);
      case 'too-many-requests':
        return AuthException(AppStrings.authTooManyRequests, debugCode: code, cause: cause);
      case 'operation-not-allowed':
      case 'admin-restricted-operation':
      case 'configuration-not-found':
        return AuthException(AppStrings.authOperationNotAllowed, debugCode: code, cause: cause);
      case 'requires-recent-login':
        return AuthException(AppStrings.authRequiresRecentLogin, debugCode: code, cause: cause);
      case 'permission-denied':
        return AuthException(AppStrings.authPermissionDenied, debugCode: code, cause: cause);
      case 'not-found':
        return AuthException(AppStrings.authFirestoreNotReady, debugCode: code, cause: cause);
      case 'invalid-app-credential':
      case 'missing-app-credential':
      case 'app-not-authorized':
      case 'captcha-check-failed':
        return AuthException(AppStrings.authAppCheckBlocked, debugCode: code, cause: cause);
      case 'unauthorized-domain':
        return AuthException(AppStrings.authUnauthorizedDomain, debugCode: code, cause: cause);
      default:
        return AuthException(AppStrings.somethingWentWrong, debugCode: code, cause: cause);
    }
  }

  static String _normalize(String code) {
    final trimmed = code.trim();
    final slash = trimmed.lastIndexOf('/');
    if (slash >= 0 && slash < trimmed.length - 1) {
      return trimmed.substring(slash + 1);
    }
    return trimmed;
  }
}
