import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/core/utils/validators.dart';
import 'package:invoice_pro/core/widgets/app_button.dart';
import 'package:invoice_pro/core/widgets/app_feedback.dart';
import 'package:invoice_pro/core/widgets/app_text_field.dart';
import 'package:invoice_pro/providers/auth_provider.dart';
import 'package:invoice_pro/routes/app_routes.dart';
import 'package:invoice_pro/screens/auth/auth_scaffold.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    try {
      await auth.signIn(email: _email.text, password: _password.text);
    } on AppException catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, error.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().isBusy;
    return AuthScaffold(
      title: AppStrings.loginTitle,
      subtitle: AppStrings.loginSubtitle,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _email,
                label: AppStrings.emailLabel,
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                enabled: !busy,
                autofillHints: const [AutofillHints.email],
                validator: AppValidators.email,
              ),
              const Gap(AppSpacing.md),
              AppPasswordField(
                controller: _password,
                label: AppStrings.passwordLabel,
                enabled: !busy,
                textInputAction: TextInputAction.done,
                validator: AppValidators.required,
                autofillHints: const [AutofillHints.password],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: busy ? null : () => context.push(AppRoutes.forgotPassword),
                  child: const Text(AppStrings.forgotPasswordLink),
                ),
              ),
              const Gap(AppSpacing.sm),
              AppButton(
                label: AppStrings.loginAction,
                expanded: true,
                isLoading: busy,
                onPressed: () => unawaited(_submit()),
              ),
              const Gap(AppSpacing.lg),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(AppStrings.loginNoAccount, style: Theme.of(context).textTheme.bodyMedium),
                  TextButton(
                    onPressed: busy ? null : () => context.go(AppRoutes.register),
                    child: const Text(AppStrings.loginCreateAccount),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
