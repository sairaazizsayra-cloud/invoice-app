import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/models/app_user.dart';
import 'package:invoice_pro/models/invoice.dart';
import 'package:invoice_pro/models/payment.dart';

enum AppNotificationType { invoiceCreated, paymentReceived, invoiceOverdue }

extension AppNotificationTypeX on AppNotificationType {
  String get storage => name;

  static AppNotificationType fromStorage(String? raw) {
    for (final type in AppNotificationType.values) {
      if (type.name == raw) return type;
    }
    return AppNotificationType.invoiceCreated;
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.businessId,
    required this.type,
    required this.title,
    required this.body,
    this.invoiceId = '',
    this.invoiceNumber = '',
    this.paymentId = '',
    this.read = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String businessId;
  final AppNotificationType type;
  final String title;
  final String body;
  final String invoiceId;
  final String invoiceNumber;
  final String paymentId;
  final bool read;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static String issuedId(String invoiceId) => 'issued_$invoiceId';

  static String paymentReceivedId(String paymentId) => 'pay_$paymentId';

  static String overdueId(String invoiceId) => 'overdue_$invoiceId';

  factory AppNotification.invoiceCreated(Invoice invoice) {
    return AppNotification(
      id: issuedId(invoice.id),
      businessId: invoice.businessId,
      type: AppNotificationType.invoiceCreated,
      title: AppStrings.notificationInvoiceCreatedTitle,
      body: '${invoice.invoiceNumber} - ${invoice.customerName}',
      invoiceId: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
    );
  }

  factory AppNotification.paymentReceived(Payment payment) {
    return AppNotification(
      id: paymentReceivedId(payment.id),
      businessId: payment.businessId,
      type: AppNotificationType.paymentReceived,
      title: AppStrings.notificationPaymentReceivedTitle,
      body: '${payment.invoiceNumber} - ${payment.amount.formatted}',
      invoiceId: payment.invoiceId,
      invoiceNumber: payment.invoiceNumber,
      paymentId: payment.id,
    );
  }

  factory AppNotification.invoiceOverdue(Invoice invoice, {DateTime? now}) {
    return AppNotification(
      id: overdueId(invoice.id),
      businessId: invoice.businessId,
      type: AppNotificationType.invoiceOverdue,
      title: AppStrings.notificationInvoiceOverdueTitle,
      body: '${invoice.invoiceNumber} - ${invoice.customerName}',
      invoiceId: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      createdAt: now,
    );
  }

  AppNotification copyWith({
    bool? read,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppNotification(
      id: id,
      businessId: businessId,
      type: type,
      title: title,
      body: body,
      invoiceId: invoiceId,
      invoiceNumber: invoiceNumber,
      paymentId: paymentId,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'id': id,
      'businessId': businessId,
      'type': type.storage,
      'title': title,
      'body': body,
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'paymentId': paymentId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toReadUpdateMap({required bool read}) {
    return {
      'read': read,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory AppNotification.fromMap(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: data['id'] as String? ?? id,
      businessId: data['businessId'] as String? ?? '',
      type: AppNotificationTypeX.fromStorage(data['type'] as String?),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      invoiceId: data['invoiceId'] as String? ?? '',
      invoiceNumber: data['invoiceNumber'] as String? ?? '',
      paymentId: data['paymentId'] as String? ?? '',
      read: data['read'] as bool? ?? false,
      createdAt: AppUser.dateTimeFrom(data['createdAt']),
      updatedAt: AppUser.dateTimeFrom(data['updatedAt']),
    );
  }
}