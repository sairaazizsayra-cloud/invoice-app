import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/core/utils/responsive.dart';
import 'package:invoice_pro/core/widgets/app_button.dart';
import 'package:invoice_pro/core/widgets/app_logo.dart';
import 'package:invoice_pro/routes/app_routes.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.showBack = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showBack
          ? AppBar(
              leading: IconButton(
                icon: const BackButtonIcon(),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.login);
                  }
                },
              ),
            )
          : null,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.isMobile(context) ? double.infinity : 480,
            ),
            child: ListView(
              padding: Responsive.pagePadding(context),
              children: [
                const Gap(AppSpacing.lg),
                const Center(child: AppLogo(size: 72, showGlow: true)),
                const Gap(AppSpacing.xl),
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                if (subtitle != null) ...[
                  const Gap(AppSpacing.sm),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const Gap(AppSpacing.xl),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
