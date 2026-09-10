import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/core/widgets/app_card.dart';
import 'package:invoice_pro/core/widgets/app_feedback.dart';
import 'package:invoice_pro/core/widgets/app_logo.dart';
import 'package:invoice_pro/core/widgets/app_page.dart';
import 'package:invoice_pro/providers/auth_provider.dart';
import 'package:invoice_pro/providers/onboarding_provider.dart';
import 'package:invoice_pro/providers/theme_provider.dart';
import 'package:invoice_pro/routes/app_routes.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profileTitle)),
      body: AppPaddedBody(
        child: ListView(
          children: [
            const _ProfileHeader(),
            const SizedBox(height: AppSpacing.xl),
            Text(AppStrings.accountSection, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.storefront_outlined),
                    title: const Text(AppStrings.businessProfileTitle),
                    subtitle: const Text(AppStrings.businessProfileSubtitle),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(AppRoutes.businessProfile),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet_outlined),
                    title: const Text(AppStrings.expensesTitle),
                    subtitle: const Text(AppStrings.expensesSubtitle),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(AppRoutes.expenses),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.insights_outlined),
                    title: const Text(AppStrings.reportsTitle),
                    subtitle: const Text(AppStrings.reportsSubtitle),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(AppRoutes.reports),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text(AppStrings.notificationsTitle),
                    subtitle: const Text(AppStrings.notificationsSubtitle),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(AppRoutes.notifications),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded),
                    title: const Text(AppStrings.logout),
                    onTap: () => unawaited(_signOut(context)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(AppStrings.appearance, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ThemeOption(
                    mode: ThemeMode.system,
                    selected: themeProvider.themeMode,
                    icon: Icons.brightness_auto_outlined,
                    label: AppStrings.themeSystem,
                    onSelected: (mode) => unawaited(themeProvider.setThemeMode(mode)),
                  ),
                  const Divider(height: 1),
                  _ThemeOption(
                    mode: ThemeMode.light,
                    selected: themeProvider.themeMode,
                    icon: Icons.light_mode_outlined,
                    label: AppStrings.themeLight,
                    onSelected: (mode) => unawaited(themeProvider.setThemeMode(mode)),
                  ),
                  const Divider(height: 1),
                  _ThemeOption(
                    mode: ThemeMode.dark,
                    selected: themeProvider.themeMode,
                    icon: Icons.dark_mode_outlined,
                    label: AppStrings.themeDark,
                    onSelected: (mode) => unawaited(themeProvider.setThemeMode(mode)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(AppStrings.about, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.info_outline_rounded),
                    title: Text(AppStrings.version),
                    subtitle: Text('${AppConstants.appFullName}  •  1.0.0'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.replay_outlined),
                    title: const Text(AppStrings.replayOnboarding),
                    subtitle: const Text(AppStrings.replayOnboardingBody),
                    onTap: () => unawaited(_replayOnboarding(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _replayOnboarding(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.replayOnboarding,
      message: AppStrings.replayOnboardingBody,
      confirmLabel: AppStrings.confirm,
    );
    if (!confirmed || !context.mounted) return;
    await context.read<OnboardingProvider>().reset();
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.logoutConfirmTitle,
      message: AppStrings.logoutConfirmBody,
      confirmLabel: AppStrings.logout,
    );
    if (!confirmed || !context.mounted) return;
    await context.read<AuthProvider>().signOut();
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.selected,
    required this.icon,
    required this.label,
    required this.onSelected,
  });

  final ThemeMode mode;
  final ThemeMode selected;
  final IconData icon;
  final String label;
  final void Function(ThemeMode mode) onSelected;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == mode;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.primary)
          : null,
      selected: isSelected,
      onTap: () => onSelected(mode),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final session = context.watch<AuthProvider>().session;
    final profile = session?.profile;
    final title = (profile?.name.trim().isNotEmpty ?? false)
        ? profile!.name.trim()
        : AppConstants.appName;
    final subtitle = (profile?.businessName.trim().isNotEmpty ?? false)
        ? profile!.businessName.trim()
        : (session?.email ?? AppStrings.appTagline);

    return AppCard(
      child: Row(
        children: [
          const AppLogo(size: 56),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
