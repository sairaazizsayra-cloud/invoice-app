import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/core/widgets/app_button.dart';
import 'package:invoice_pro/core/widgets/app_logo.dart';
import 'package:invoice_pro/providers/auth_provider.dart';
import 'package:invoice_pro/providers/onboarding_provider.dart';
import 'package:invoice_pro/routes/app_routes.dart';
import 'package:invoice_pro/routes/auth_redirect.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_navigate());
    });
  }

  Future<void> _navigate() async {
    await Future<void>.delayed(AppConstants.splashMinDisplay);
    if (!mounted) return;
    final onboardingDone = context.read<OnboardingProvider>().isCompleted;
    final auth = context.read<AuthProvider>();
    final target = AuthRedirect.resolve(
      location: AppRoutes.onboarding,
      onboardingCompleted: onboardingDone,
      authStatus: auth.status,
    );
    context.go(target ?? (onboardingDone ? AppRoutes.login : AppRoutes.onboarding));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(size: 96, showGlow: true),
                const Gap(AppSpacing.xl),
                Text(
                  AppStrings.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(AppSpacing.sm),
                Text(
                  AppStrings.splashTagline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Gap(AppSpacing.xxl),
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
