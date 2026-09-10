import 'dart:async';

import 'package:flutter/material.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/core/widgets/app_button.dart';
import 'package:invoice_pro/core/widgets/app_feedback.dart';
import 'package:invoice_pro/providers/auth_provider.dart';
import 'package:invoice_pro/screens/auth/auth_scaffold.dart';
import 'package:provider/provider.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with WidgetsBindingObserver {
  static const Duration _pollInterval = Duration(seconds: 4);

  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _poll = Timer.periodic(_pollInterval, (_) {
      if (!mounted) return;
      unawaited(context.read<AuthProvider>().reloadAndRefresh(showBusy: false));
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(context.read<AuthProvider>().reloadAndRefresh(showBusy: false));
    }
  }

  Future<void> _resend() async {
    try {
      await context.read<AuthProvider>().sendEmailVerification();
      if (!mounted) return;
      AppSnackbar.success(context, AppStrings.verifyResent);
    } on AppException catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, error.userMessage);
    }
  }

  Future<void> _continue() async {
    final auth = context.read<AuthProvider>();
    try {
      await auth.reloadAndRefresh();
      if (!mounted) return;
      if (!auth.isEmailVerified) {
        AppSnackbar.info(context, AppStrings.verifyStillPending);
      }
    } on AppException catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, error.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.session?.email ?? '';
    return AuthScaffold(
      title: AppStrings.verifyTitle,
      subtitle: AppStrings.verifySubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            email,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Gap(AppSpacing.xl),
          AppButton(
            label: AppStrings.verifyContinue,
            expanded: true,
            isLoading: auth.isBusy,
            onPressed: () => unawaited(_continue()),
          ),
          const Gap(AppSpacing.md),
          AppButton(
            label: AppStrings.verifyResend,
            expanded: true,
            variant: AppButtonVariant.tonal,
            isLoading: auth.isBusy,
            onPressed: () => unawaited(_resend()),
          ),
          const Gap(AppSpacing.md),
          AppButton(
            label: AppStrings.logout,
            expanded: true,
            variant: AppButtonVariant.text,
            onPressed: auth.isBusy ? null : () => unawaited(auth.signOut()),
          ),
        ],
      ),
    );
  }
}
