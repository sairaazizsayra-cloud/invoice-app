import 'package:flutter/material.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = Card(
      color: color ?? (scheme.brightness == Brightness.light ? Colors.white : scheme.surfaceContainerHigh),
      margin: margin,
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return card;

    return Card(
      color: color ?? (scheme.brightness == Brightness.light ? Colors.white : scheme.surfaceContainerHigh),
      margin: margin,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
