import 'dart:async';

import 'package:flutter/material.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/core/widgets/app_button.dart';
import 'package:invoice_pro/core/widgets/app_logo.dart';
import 'package:invoice_pro/providers/onboarding_provider.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
    this.useLogo = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool useLogo;
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.receipt_long_rounded,
      title: AppStrings.onboardingTitle1,
      body: AppStrings.onboardingBody1,
      useLogo: true,
    ),
    _OnboardingPage(
      icon: Icons.groups_outlined,
      title: AppStrings.onboardingTitle2,
      body: AppStrings.onboardingBody2,
    ),
    _OnboardingPage(
      icon: Icons.insights_outlined,
      title: AppStrings.onboardingTitle3,
      body: AppStrings.onboardingBody3,
    ),
  ];

  final PageController _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await context.read<OnboardingProvider>().complete();
  }

  void _next() {
    if (_isLast) {
      unawaited(_finish());
      return;
    }
    unawaited(
      _controller.nextPage(
        duration: AppConstants.mediumAnimation,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          if (!_isLast)
            TextButton(
              onPressed: () => unawaited(_finish()),
              child: const Text(AppStrings.onboardingSkip),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (page.useLogo)
                          const AppLogo(size: 88, showGlow: true)
                        else
                          _IconBadge(icon: page.icon),
                        const Gap(AppSpacing.xxl),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Gap(AppSpacing.md),
                        Text(
                          page.body,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(_pages.length, (i) {
                      final selected = i == _index;
                      return AnimatedContainer(
                        duration: AppConstants.shortAnimation,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: selected ? 22 : 8,
                        decoration: BoxDecoration(
                          color: selected ? scheme.primary : scheme.outlineVariant,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                      );
                    }),
                  ),
                  const Gap(AppSpacing.xl),
                  AppButton(
                    label: _isLast ? AppStrings.onboardingGetStarted : AppStrings.onboardingNext,
                    onPressed: _next,
                    expanded: true,
                    icon: _isLast ? Icons.arrow_forward_rounded : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Icon(icon, size: 44, color: scheme.onPrimaryContainer),
    );
  }
}
