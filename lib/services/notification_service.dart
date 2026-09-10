import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/firebase/firebase_bootstrap.dart';
import 'package:invoice_pro/models/app_notification.dart';
import 'package:invoice_pro/repositories/firebase_notification_repository.dart';
import 'package:invoice_pro/repositories/notification_repository.dart';

NotificationRepository createNotificationRepository() {
  if (!FirebaseBootstrap.initialized) {
    return UnconfiguredNotificationRepository();
  }
  return FirebaseNotificationRepository();
}

class UnconfiguredNotificationRepository implements NotificationRepository {
  @override
  Stream<List<AppNotification>> watchAll(
    String businessId, {
    int limit = AppConstants.notificationInboxLimit,
  }) async* {
    yield const [];
  }

  @override
  Future<bool> upsert(AppNotification notification) async => false;

  @override
  Future<void> markRead(AppNotification notification) async {}

  @override
  Future<void> markAllRead(String businessId) async {}

  @override
  Future<void> delete(AppNotification notification) async {}
}
