import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/utils/app_logger.dart';
import 'package:invoice_pro/core/utils/platform_capabilities.dart';
import 'package:invoice_pro/firebase/firebase_bootstrap.dart';
import 'package:invoice_pro/models/app_notification.dart';
import 'package:invoice_pro/repositories/user_repository.dart';

class PushNotificationService {
  PushNotificationService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? local,
    this.onOpenInvoice,
  }) : _messaging = messaging,
       _local = local ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _local;
  final void Function(String invoiceId)? onOpenInvoice;

  bool _localReady = false;
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _messageSub;
  StreamSubscription<RemoteMessage>? _openedSub;

  FirebaseMessaging? get _fcm {
    if (_messaging != null) return _messaging;
    if (!FirebaseBootstrap.initialized || !PlatformCapabilities.pushMessaging) return null;
    return FirebaseMessaging.instance;
  }

  Future<void> start({required String uid, required UserRepository users}) async {
    if (!FirebaseBootstrap.initialized || !PlatformCapabilities.pushMessaging) return;
    await _ensureLocal();
    final fcm = _fcm;
    if (fcm == null) return;

    try {
      await fcm.requestPermission(alert: true, badge: true, sound: true);
    } catch (error, stack) {
      AppLogger.error('FCM permission request failed', error, stack);
    }

    try {
      final token = await fcm.getToken();
      if (token != null && token.isNotEmpty) {
        await users.saveFcmToken(uid: uid, token: token);
      }
    } catch (error, stack) {
      AppLogger.error('FCM token fetch failed', error, stack);
    }

    await _tokenSub?.cancel();
    _tokenSub = fcm.onTokenRefresh.listen((token) {
      if (token.isEmpty) return;
      unawaited(users.saveFcmToken(uid: uid, token: token));
    });

    await _messageSub?.cancel();
    _messageSub = FirebaseMessaging.onMessage.listen((message) {
      unawaited(_showRemote(message));
    });

    await _openedSub?.cancel();
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_openFromMessage);

    final initial = await fcm.getInitialMessage();
    if (initial != null) {
      _openFromMessage(initial);
    }
  }

  Future<void> showLocal(AppNotification notification) async {
    if (!FirebaseBootstrap.initialized) return;
    await _ensureLocal();
    try {
      await _local.show(
        id: notification.id.hashCode & 0x7fffffff,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            AppConstants.notificationChannelId,
            AppConstants.notificationChannelName,
            channelDescription: AppStrings.notificationChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
        payload: notification.invoiceId,
      );
    } catch (error, stack) {
      AppLogger.error('Local notification failed', error, stack);
    }
  }

  Future<void> _ensureLocal() async {
    if (_localReady) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings();
      await _local.initialize(
        settings: const InitializationSettings(
          android: android,
          iOS: darwin,
          macOS: darwin,
        ),
        onDidReceiveNotificationResponse: (response) {
          final invoiceId = response.payload ?? '';
          if (invoiceId.isEmpty) return;
          onOpenInvoice?.call(invoiceId);
        },
      );
      await _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              AppConstants.notificationChannelId,
              AppConstants.notificationChannelName,
              description: AppStrings.notificationChannelDescription,
              importance: Importance.high,
            ),
          );
      _localReady = true;
    } catch (error, stack) {
      AppLogger.error('Local notification plugin failed', error, stack);
    }
  }

  Future<void> _showRemote(RemoteMessage message) async {
    final title = message.notification?.title ?? _stringData(message, 'title');
    final body = message.notification?.body ?? _stringData(message, 'body');
    if (title.isEmpty && body.isEmpty) return;
    await showLocal(
      AppNotification(
        id: message.messageId ?? 'fcm_${DateTime.now().millisecondsSinceEpoch}',
        businessId: '',
        type: AppNotificationType.invoiceCreated,
        title: title,
        body: body,
        invoiceId: _stringData(message, 'invoiceId'),
      ),
    );
  }

  void _openFromMessage(RemoteMessage message) {
    final invoiceId = _stringData(message, 'invoiceId');
    if (invoiceId.isEmpty) return;
    onOpenInvoice?.call(invoiceId);
  }

  String _stringData(RemoteMessage message, String key) {
    final value = message.data[key];
    return value is String ? value : '';
  }

  Future<void> dispose() async {
    await _tokenSub?.cancel();
    await _messageSub?.cancel();
    await _openedSub?.cancel();
  }
}
