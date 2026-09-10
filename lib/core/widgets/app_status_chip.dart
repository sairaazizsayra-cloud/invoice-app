import 'package:flutter/material.dart';
import 'package:invoice_pro/core/theme/app_colors.dart';
import 'package:invoice_pro/models/invoice_status.dart';

class AppStatusChip extends StatelessWidget {
  const AppStatusChip({super.key, required this.status});

  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;

    final Color background;
    final Color foreground;
    switch (status) {
      case InvoiceStatus.paid:
        background = semantic.successContainer;
        foreground = semantic.success;
      case InvoiceStatus.overdue:
        background = semantic.overdueContainer;
        foreground = semantic.overdue;
      case InvoiceStatus.partiallyPaid:
        background = semantic.warningContainer;
        foreground = semantic.warning;
      case InvoiceStatus.cancelled:
        background = scheme.surfaceContainerHighest;
        foreground = scheme.onSurfaceVariant;
      case InvoiceStatus.draft:
        background = scheme.surfaceContainerHighest;
        foreground = scheme.onSurfaceVariant;
      case InvoiceStatus.sent:
      case InvoiceStatus.unpaid:
        background = semantic.infoContainer;
        foreground = semantic.info;
    }

    return Chip(
      visualDensity: VisualDensity.compact,
      backgroundColor: background,
      side: BorderSide.none,
      label: Text(
        status.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
