import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/models/app_notification.dart';

abstract class NotificationRepository {
  Stream<List<AppNotification>> watchAll(
    String businessId, {
    int limit = AppConstants.notificationInboxLimit,
  });

  Future<bool> upsert(AppNotification notification);

  Future<void> markRead(AppNotification notification);

  Future<void> markAllRead(String businessId);

  Future<void> delete(AppNotification notification);
}
