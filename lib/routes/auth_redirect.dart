import 'package:invoice_pro/providers/auth_provider.dart';
import 'package:invoice_pro/routes/app_routes.dart';

class AuthRedirect {
  AuthRedirect._();

  static String? resolve({
    required String location,
    required bool onboardingCompleted,
    required AuthStatus authStatus,
  }) {
    if (location == AppRoutes.splash) return null;

    if (!onboardingCompleted) {
      return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
    }

    if (location == AppRoutes.onboarding) {
      return _homeFor(authStatus);
    }

    switch (authStatus) {
      case AuthStatus.unknown:
        return null;
      case AuthStatus.signedOut:
        return AppRoutes.authLocations.contains(location) ? null : AppRoutes.login;
      case AuthStatus.needsVerification:
        if (location == AppRoutes.verifyEmail) return null;
        return AppRoutes.verifyEmail;
      case AuthStatus.authenticated:
        if (AppRoutes.authLocations.contains(location) || location == AppRoutes.verifyEmail) {
          return AppRoutes.dashboard;
        }
        return null;
    }
  }

  static String _homeFor(AuthStatus status) {
    switch (status) {
      case AuthStatus.authenticated:
        return AppRoutes.dashboard;
      case AuthStatus.needsVerification:
        return AppRoutes.verifyEmail;
      case AuthStatus.unknown:
      case AuthStatus.signedOut:
        return AppRoutes.login;
    }
  }
}
