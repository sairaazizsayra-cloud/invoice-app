import 'package:flutter/material.dart';

enum AppButtonVariant { filled, outlined, text, tonal }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.filled,
    this.expanded = false,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool expanded;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: variant == AppButtonVariant.filled
                  ? Theme.of(context).colorScheme.onPrimary
                  : null,
            ),
          )
        : _label();

    final callback = isLoading ? null : onPressed;

    final button = switch (variant) {
      AppButtonVariant.filled => icon == null || isLoading
          ? FilledButton(onPressed: callback, child: child)
          : FilledButton.icon(onPressed: callback, icon: Icon(icon), label: Text(label)),
      AppButtonVariant.outlined => icon == null || isLoading
          ? OutlinedButton(onPressed: callback, child: child)
          : OutlinedButton.icon(onPressed: callback, icon: Icon(icon), label: Text(label)),
      AppButtonVariant.text => icon == null || isLoading
          ? TextButton(onPressed: callback, child: child)
          : TextButton.icon(onPressed: callback, icon: Icon(icon), label: Text(label)),
      AppButtonVariant.tonal => icon == null || isLoading
          ? FilledButton.tonal(onPressed: callback, child: child)
          : FilledButton.tonalIcon(onPressed: callback, icon: Icon(icon), label: Text(label)),
    };

    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }

  Widget _label() => Text(label);
}

class Gap extends StatelessWidget {
  const Gap(this.size, {super.key});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size);
}
