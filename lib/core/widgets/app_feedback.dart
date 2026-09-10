import 'package:flutter/material.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/theme/app_colors.dart';

enum AppSnackKind { success, error, info }

class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context, {
    required String message,
    AppSnackKind kind = AppSnackKind.info,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);

    final Color background;
    final Color foreground;
    switch (kind) {
      case AppSnackKind.success:
        background = semantic.success;
        foreground = semantic.onSuccess;
      case AppSnackKind.error:
        background = scheme.error;
        foreground = scheme.onError;
      case AppSnackKind.info:
        background = semantic.info;
        foreground = semantic.onInfo;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: TextStyle(color: foreground)),
          backgroundColor: background,
        ),
      );
  }

  static void success(BuildContext context, String message) {
    show(context, message: message, kind: AppSnackKind.success);
  }

  static void error(BuildContext context, String message) {
    show(context, message: message, kind: AppSnackKind.error);
  }

  static void info(BuildContext context, String message) {
    show(context, message: message, kind: AppSnackKind.info);
  }
}

class AppConfirmDialog {
  AppConfirmDialog._();

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = AppStrings.confirm,
    String cancelLabel = AppStrings.cancel,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    )
                  : null,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
