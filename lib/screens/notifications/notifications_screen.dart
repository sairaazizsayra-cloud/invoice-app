import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/core/utils/date_formatter.dart';
import 'package:invoice_pro/core/widgets/app_card.dart';
import 'package:invoice_pro/core/widgets/app_page.dart';
import 'package:invoice_pro/core/widgets/app_states.dart';
import 'package:invoice_pro/models/app_notification.dart';
import 'package:invoice_pro/providers/business_provider.dart';
import 'package:invoice_pro/providers/notification_provider.dart';
import 'package:invoice_pro/routes/app_routes.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final businessState = context.watch<BusinessProvider>();
    final notifications = context.watch<NotificationProvider>();
    final business = businessState.business;

    if ((businessState.isLoading && business == null) ||
        (notifications.isLoading && notifications.allNotifications.isEmpty)) {
      return const Scaffold(body: AppLoading(message: AppStrings.loading));
    }
    if (business == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.notificationsTitle)),
        body: const AppErrorState(title: AppStrings.businessMissing),
      );
    }

    final items = notifications.allNotifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.notificationsTitle),
        actions: [
          if (notifications.unreadCount > 0)
            TextButton(
              onPressed: () => unawaited(notifications.markAllRead()),
              child: const Text(AppStrings.markAllRead),
            ),
        ],
      ),
      body: AppPaddedBody(
        child: items.isEmpty
            ? const AppEmptyState(
                title: AppStrings.emptyNotificationsTitle,
                message: AppStrings.emptyNotificationsBody,
                icon: Icons.notifications_none_outlined,
              )
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _NotificationTile(
                    notification: item,
                    onTap: () => unawaited(_open(context, notifications, item)),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    NotificationProvider notifications,
    AppNotification notification,
  ) async {
    await notifications.markRead(notification);
    if (!context.mounted) return;
    if (notification.invoiceId.isEmpty) return;
    unawaited(context.push(AppRoutes.invoiceDetail(notification.invoiceId)));
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  IconData get _icon {
    switch (notification.type) {
      case AppNotificationType.invoiceCreated:
        return Icons.receipt_long_outlined;
      case AppNotificationType.paymentReceived:
        return Icons.payments_outlined;
      case AppNotificationType.invoiceOverdue:
        return Icons.warning_amber_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ListTile(
        leading: Icon(_icon, color: notification.read ? scheme.onSurfaceVariant : scheme.primary),
        title: Text(
          notification.title,
          style: notification.read ? null : Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          [
            notification.body,
            if (notification.createdAt != null) AppDateFormatter.display(notification.createdAt!),
          ].join(' - '),
        ),
        trailing: notification.read ? null : Icon(Icons.circle, size: 10, color: scheme.primary),
      ),
    );
  }
}
