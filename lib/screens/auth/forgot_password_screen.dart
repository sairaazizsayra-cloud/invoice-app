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
import 'package:invoice_pro/screens/auth/auth_scaffold.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    try {
      await auth.sendPasswordReset(email: _email.text);
      if (!mounted) return;
      AppSnackbar.success(context, AppStrings.forgotPasswordSent);
      context.pop();
    } on AppException catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, error.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().isBusy;
    return AuthScaffold(
      title: AppStrings.forgotPasswordTitle,
      subtitle: AppStrings.forgotPasswordSubtitle,
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AppTextField(
              controller: _email,
              label: AppStrings.emailLabel,
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              enabled: !busy,
              autofillHints: const [AutofillHints.email],
              validator: AppValidators.email,
              onFieldSubmitted: (_) => unawaited(_submit()),
            ),
            const Gap(AppSpacing.xl),
            AppButton(
              label: AppStrings.forgotPasswordAction,
              expanded: true,
              isLoading: busy,
              onPressed: () => unawaited(_submit()),
            ),
          ],
        ),
      ),
    );
  }
}
