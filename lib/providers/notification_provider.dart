import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/utils/app_logger.dart';
import 'package:invoice_pro/firebase/firebase_bootstrap.dart';
import 'package:invoice_pro/models/app_notification.dart';
import 'package:invoice_pro/models/invoice.dart';
import 'package:invoice_pro/repositories/notification_repository.dart';
import 'package:invoice_pro/services/push_notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider(
    this._repository, {
    PushNotificationService? push,
  }) : _push = push ?? PushNotificationService();

  final NotificationRepository _repository;
  final PushNotificationService _push;

  StreamSubscription<List<AppNotification>>? _subscription;
  String? _businessId;
  List<AppNotification> _notifications = const [];
  bool _loading = false;
  String? _error;
  String _overdueKey = '';
  bool _scanningOverdue = false;

  List<AppNotification> get allNotifications => _notifications;
  bool get isLoading => _loading;
  String? get error => _error;
  int get unreadCount => _notifications.where((item) => !item.read).length;

  void bind({String? businessId}) {
    if (businessId == _businessId && _subscription != null) return;
    unawaited(_resubscribe(businessId));
  }

  Future<void> _resubscribe(String? businessId) async {
    await _subscription?.cancel();
    _subscription = null;
    _businessId = businessId;
    _notifications = const [];
    _error = null;
    _overdueKey = '';

    if (businessId == null || businessId.isEmpty) {
      _loading = false;
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();
    _subscription = _repository.watchAll(businessId, limit: AppConstants.notificationInboxLimit).listen(
      (value) {
        _notifications = value;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object error, StackTrace stack) {
        AppLogger.error('Notification watch failed', error, stack);
        _loading = false;
        _error = 'Could not load notifications.';
        notifyListeners();
      },
    );
  }

  Future<void> scanOverdue(List<Invoice> invoices, {DateTime? now}) async {
    if (_scanningOverdue) return;
    final clock = now ?? DateTime.now();
    final overdue = invoices.where((invoice) => invoice.isOverdue(clock)).toList();
    final key = overdue.map((invoice) => invoice.id).join(',');
    if (key == _overdueKey) return;
    _scanningOverdue = true;
    try {
      final created = <AppNotification>[];
      for (final invoice in overdue) {
        final notification = AppNotification.invoiceOverdue(invoice, now: clock);
        final inserted = await _repository.upsert(notification);
        if (inserted) {
          created.add(notification);
          _mergeLocal(notification);
        }
      }
      _overdueKey = key;
      if (created.isEmpty || !FirebaseBootstrap.initialized) return;
      if (created.length == 1) {
        await _push.showLocal(created.first);
      } else {
        await _push.showLocal(
          AppNotification(
            id: 'overdue_summary',
            businessId: created.first.businessId,
            type: AppNotificationType.invoiceOverdue,
            title: created.first.title,
            body: AppStrings.notificationOverdueCount(created.length),
          ),
        );
      }
    } finally {
      _scanningOverdue = false;
    }
  }

  Future<void> markRead(AppNotification notification) async {
    if (notification.read) return;
    await _repository.markRead(notification);
    _notifications = [
      for (final item in _notifications)
        if (item.id == notification.id) item.copyWith(read: true) else item,
    ];
    notifyListeners();
  }

  Future<void> markAllRead() async {
    final businessId = _businessId;
    if (businessId == null || unreadCount == 0) return;
    await _repository.markAllRead(businessId);
    _notifications = [for (final item in _notifications) item.copyWith(read: true)];
    notifyListeners();
  }

  Future<void> delete(AppNotification notification) async {
    await _repository.delete(notification);
    _notifications = _notifications.where((item) => item.id != notification.id).toList();
    notifyListeners();
  }

  void _mergeLocal(AppNotification notification) {
    _notifications = [
      notification.copyWith(createdAt: notification.createdAt ?? DateTime.now()),
      ..._notifications.where((item) => item.id != notification.id),
    ];
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
