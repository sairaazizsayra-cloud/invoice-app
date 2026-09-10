import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/core/utils/validators.dart';
import 'package:invoice_pro/core/widgets/app_button.dart';
import 'package:invoice_pro/core/widgets/app_feedback.dart';
import 'package:invoice_pro/core/widgets/app_text_field.dart';
import 'package:invoice_pro/providers/auth_provider.dart';
import 'package:invoice_pro/repositories/auth_repository.dart';
import 'package:invoice_pro/routes/app_routes.dart';
import 'package:invoice_pro/screens/auth/auth_scaffold.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _businessName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _businessName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      final formContext = _formKey.currentContext;
      if (formContext != null) {
        await Scrollable.ensureVisible(
          formContext,
          alignment: 0,
          duration: AppConstants.shortAnimation,
        );
      }
      return;
    }
    final auth = context.read<AuthProvider>();
    try {
      await auth.register(
        RegisterRequest(
          name: _name.text,
          businessName: _businessName.text,
          email: _email.text,
          phone: _phone.text,
          password: _password.text,
        ),
      );
    } on AppException catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, error.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().isBusy;
    return AuthScaffold(
      title: AppStrings.registerTitle,
      subtitle: AppStrings.registerSubtitle,
      showBack: true,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _name,
                label: AppStrings.fullNameLabel,
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                enabled: !busy,
                autofillHints: const [AutofillHints.name],
                validator: AppValidators.name,
              ),
              const Gap(AppSpacing.md),
              AppTextField(
                controller: _businessName,
                label: AppStrings.businessNameLabel,
                prefixIcon: Icons.storefront_outlined,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                enabled: !busy,
                autofillHints: const [AutofillHints.organizationName],
                validator: AppValidators.name,
              ),
              const Gap(AppSpacing.md),
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
              AppTextField(
                controller: _phone,
                label: AppStrings.phoneLabel,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                enabled: !busy,
                autofillHints: const [AutofillHints.telephoneNumber],
                validator: AppValidators.phone,
              ),
              const Gap(AppSpacing.md),
              AppPasswordField(
                controller: _password,
                label: AppStrings.passwordLabel,
                enabled: !busy,
                textInputAction: TextInputAction.next,
                validator: AppValidators.password,
                autofillHints: const [AutofillHints.newPassword],
              ),
              const Gap(AppSpacing.md),
              AppPasswordField(
                controller: _confirmPassword,
                label: AppStrings.confirmPasswordLabel,
                enabled: !busy,
                textInputAction: TextInputAction.done,
                validator: (value) => AppValidators.confirmPassword(value, _password.text),
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => unawaited(_submit()),
              ),
              const Gap(AppSpacing.xl),
              AppButton(
                label: AppStrings.registerAction,
                expanded: true,
                isLoading: busy,
                onPressed: () => unawaited(_submit()),
              ),
              const Gap(AppSpacing.lg),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(AppStrings.registerHaveAccount, style: Theme.of(context).textTheme.bodyMedium),
                  TextButton(
                    onPressed: busy ? null : () => context.go(AppRoutes.login),
                    child: const Text(AppStrings.registerSignIn),
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
