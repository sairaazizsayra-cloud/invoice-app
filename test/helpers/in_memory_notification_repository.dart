import 'dart:async';

import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/models/app_notification.dart';
import 'package:invoice_pro/repositories/notification_repository.dart';

class InMemoryNotificationRepository implements NotificationRepository {
  InMemoryNotificationRepository({List<AppNotification>? notifications})
    : _notifications = [...?notifications];

  final List<AppNotification> _notifications;
  final StreamController<List<AppNotification>> _controller = StreamController<List<AppNotification>>.broadcast();

  List<AppNotification> _forBusiness(String businessId) {
    final list = _notifications.where((item) => item.businessId == businessId).toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return list;
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List<AppNotification>.from(_notifications));
    }
  }

  @override
  Stream<List<AppNotification>> watchAll(
    String businessId, {
    int limit = AppConstants.notificationInboxLimit,
  }) async* {
    List<AppNotification> page() => _forBusiness(businessId).take(limit).toList();
    yield page();
    yield* _controller.stream.map((_) => page());
  }

  @override
  Future<bool> upsert(AppNotification notification) async {
    if (_notifications.any((item) => item.id == notification.id)) return false;
    _notifications.insert(0, notification.copyWith(createdAt: notification.createdAt ?? DateTime.now()));
    _emit();
    return true;
  }

  @override
  Future<void> markRead(AppNotification notification) async {
    final index = _notifications.indexWhere((item) => item.id == notification.id);
    if (index < 0) return;
    _notifications[index] = _notifications[index].copyWith(read: true, updatedAt: DateTime.now());
    _emit();
  }

  @override
  Future<void> markAllRead(String businessId) async {
    for (var i = 0; i < _notifications.length; i++) {
      final item = _notifications[i];
      if (item.businessId != businessId || item.read) continue;
      _notifications[i] = item.copyWith(read: true, updatedAt: DateTime.now());
    }
    _emit();
  }

  @override
  Future<void> delete(AppNotification notification) async {
    _notifications.removeWhere((item) => item.id == notification.id);
    _emit();
  }

  void dispose() {
    unawaited(_controller.close());
  }
}
