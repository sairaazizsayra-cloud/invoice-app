import 'package:flutter/material.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/core/widgets/app_button.dart';

/// Footer control for growing Firestore list windows.
class AppLoadMoreBar extends StatelessWidget {
  const AppLoadMoreBar({
    super.key,
    required this.visible,
    required this.loading,
    required this.onPressed,
  });

  final bool visible;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (!visible && !loading) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: AppButton(
          label: loading ? AppStrings.loadingMore : AppStrings.loadMore,
          onPressed: loading ? null : onPressed,
          isLoading: loading,
          variant: AppButtonVariant.tonal,
          icon: Icons.expand_more_rounded,
        ),
      ),
    );
  }
}
