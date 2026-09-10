import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/auth_exception.dart';
import 'package:invoice_pro/models/app_user.dart';
import 'package:invoice_pro/models/report.dart';
import 'package:invoice_pro/providers/auth_provider.dart';
import 'package:invoice_pro/routes/app_routes.dart';
import 'package:invoice_pro/routes/auth_redirect.dart';

void main() {
  group('AuthErrorMapper', () {
    test('maps common Firebase Auth codes to safe messages', () {
      expect(AuthErrorMapper.fromCode('invalid-email').userMessage, AppStrings.authInvalidEmail);
      expect(AuthErrorMapper.fromCode('wrong-password').userMessage, AppStrings.authWrongPassword);
      expect(AuthErrorMapper.fromCode('invalid-credential').userMessage, AppStrings.authWrongPassword);
      expect(AuthErrorMapper.fromCode('user-not-found').userMessage, AppStrings.authUserNotFound);
      expect(AuthErrorMapper.fromCode('user-disabled').userMessage, AppStrings.authUserDisabled);
      expect(AuthErrorMapper.fromCode('network-request-failed').userMessage, AppStrings.authNetworkError);
      expect(AuthErrorMapper.fromCode('email-already-in-use').userMessage, AppStrings.authEmailInUse);
      expect(AuthErrorMapper.fromCode('weak-password').userMessage, AppStrings.authWeakPassword);
      expect(AuthErrorMapper.fromCode('permission-denied').userMessage, AppStrings.authPermissionDenied);
      expect(
        AuthErrorMapper.fromCode('cloud_firestore/permission-denied').userMessage,
        AppStrings.authPermissionDenied,
      );
      expect(AuthErrorMapper.fromCode('invalid-app-credential').userMessage, AppStrings.authAppCheckBlocked);
      expect(AuthErrorMapper.fromCode('unauthorized-domain').userMessage, AppStrings.authUnauthorizedDomain);
    });

    test('does not expose unknown technical codes to users', () {
      final mapped = AuthErrorMapper.fromCode('internal-error');
      expect(mapped.userMessage, AppStrings.somethingWentWrong);
      expect(mapped.debugCode, 'internal-error');
    });
  });

  group('AppUser', () {
    test('reads a Firestore-shaped map without a password field', () {
      final user = AppUser.fromMap({
        'uid': 'abc',
        'name': 'Ali',
        'businessName': 'Ali Store',
        'email': 'ali@store.pk',
        'phone': '03001234567',
        'role': 'business_owner',
        'isActive': true,
        'emailVerified': false,
      });
      expect(user.uid, 'abc');
      expect(user.isBusinessOwner, isTrue);
      expect(user.email, 'ali@store.pk');
      expect(user.businessId, isNull);
    });

    test('treats a blank businessId as unset', () {
      final user = AppUser.fromMap({
        'uid': 'abc',
        'name': 'Ali',
        'businessName': 'Ali Store',
        'email': 'ali@store.pk',
        'phone': '03001234567',
        'role': 'business_owner',
        'isActive': true,
        'emailVerified': true,
        'businessId': '   ',
      });
      expect(user.businessId, isNull);
    });
  });

  group('AuthRedirect', () {
    test('sends newly registered users from register to verify email', () {
      expect(
        AuthRedirect.resolve(
          location: AppRoutes.register,
          onboardingCompleted: true,
          authStatus: AuthStatus.needsVerification,
        ),
        AppRoutes.verifyEmail,
      );
    });

    test('keeps signed-out users on the register route', () {
      expect(
        AuthRedirect.resolve(
          location: AppRoutes.register,
          onboardingCompleted: true,
          authStatus: AuthStatus.signedOut,
        ),
        isNull,
      );
    });

    test('keeps unfinished onboarding on the onboarding route', () {
      expect(
        AuthRedirect.resolve(
          location: AppRoutes.login,
          onboardingCompleted: false,
          authStatus: AuthStatus.signedOut,
        ),
        AppRoutes.onboarding,
      );
    });

    test('sends signed-out users to login after onboarding', () {
      expect(
        AuthRedirect.resolve(
          location: AppRoutes.dashboard,
          onboardingCompleted: true,
          authStatus: AuthStatus.signedOut,
        ),
        AppRoutes.login,
      );
    });

    test('blocks unverified users from the app shell', () {
      expect(
        AuthRedirect.resolve(
          location: AppRoutes.dashboard,
          onboardingCompleted: true,
          authStatus: AuthStatus.needsVerification,
        ),
        AppRoutes.verifyEmail,
      );
    });

    test('keeps authenticated users out of auth screens', () {
      expect(
        AuthRedirect.resolve(
          location: AppRoutes.login,
          onboardingCompleted: true,
          authStatus: AuthStatus.authenticated,
        ),
        AppRoutes.dashboard,
      );
    });

    test('keeps authenticated users on the business profile route', () {
      expect(
        AuthRedirect.resolve(
          location: AppRoutes.businessProfile,
          onboardingCompleted: true,
          authStatus: AuthStatus.authenticated,
        ),
        isNull,
      );
    });

    test('keeps authenticated users on customer routes', () {
      expect(
        AuthRedirect.resolve(
          location: AppRoutes.customerNew,
          onboardingCompleted: true,
          authStatus: AuthStatus.authenticated,
        ),
        isNull,
      );
    });

    test('keeps authenticated users on product routes', () {
      expect(
        AuthRedirect.resolve(
          location: AppRoutes.productNew,
          onboardingCompleted: true,
          authStatus: AuthStatus.authenticated,
        ),
        isNull,
      );
    });

    test('keeps authenticated users on invoice payment routes', () {
      expect(
        AuthRedirect.resolve(
          location: AppRoutes.invoicePay('inv_1'),
          onboardingCompleted: true,
          authStatus: AuthStatus.authenticated,
        ),
        isNull,
      );
    });

    test('keeps authenticated users on expense routes', () {
      expect(
        AuthRedirect.resolve(
          location: AppRoutes.expenseNew,
          onboardingCompleted: true,
          authStatus: AuthStatus.authenticated,
        ),
        isNull,
      );
    });

    test('keeps authenticated users on report routes', () {
      expect(
        AuthRedirect.resolve(
          location: AppRoutes.report(ReportKind.sales),
          onboardingCompleted: true,
          authStatus: AuthStatus.authenticated,
        ),
        isNull,
      );
    });

    test('keeps authenticated users on the notifications route', () {
      expect(
        AuthRedirect.resolve(
          location: AppRoutes.notifications,
          onboardingCompleted: true,
          authStatus: AuthStatus.authenticated,
        ),
        isNull,
      );
    });
  });
}
