import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_pro/models/app_notification.dart';
import 'package:invoice_pro/models/invoice.dart';
import 'package:invoice_pro/models/invoice_status.dart';
import 'package:invoice_pro/models/payment.dart';
import 'package:invoice_pro/providers/invoice_provider.dart';
import 'package:invoice_pro/providers/notification_provider.dart';
import 'package:invoice_pro/providers/payment_provider.dart';
import 'package:invoice_pro/services/notification_service.dart';

import '../helpers/in_memory_business_repository.dart';
import '../helpers/in_memory_invoice_repository.dart';
import '../helpers/in_memory_notification_repository.dart';
import '../helpers/in_memory_payment_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final business = InMemoryBusinessRepository.sampleBusiness();

  Invoice readyToIssue({String id = 'inv_new'}) {
    return Invoice.draft(
      id: id,
      business: business,
      now: DateTime(2026, 9, 3),
    )
        .copyWith(customerId: 'cus_1', customerName: 'Ali Store')
        .withItems([
          InvoiceLine.calculated(name: 'Rice 10kg', quantity: 1, unitPriceMinor: 250000),
        ]);
  }

  group('AppNotificationType', () {
    test('maps stored type names used by Firestore', () {
      expect(AppNotificationTypeX.fromStorage('invoiceCreated'), AppNotificationType.invoiceCreated);
      expect(AppNotificationTypeX.fromStorage('paymentReceived'), AppNotificationType.paymentReceived);
      expect(AppNotificationTypeX.fromStorage('invoiceOverdue'), AppNotificationType.invoiceOverdue);
      expect(AppNotificationType.invoiceCreated.storage, 'invoiceCreated');
    });
  });

  group('AppNotification', () {
    test('uses deterministic ids for invoice, payment, and overdue events', () {
      final invoice = InMemoryInvoiceRepository.sample();
      final payment = InMemoryPaymentRepository.sample(invoice: invoice);

      expect(AppNotification.invoiceCreated(invoice).id, 'issued_inv_1');
      expect(AppNotification.paymentReceived(payment).id, 'pay_pay_1');
      expect(AppNotification.invoiceOverdue(invoice).id, 'overdue_inv_1');
    });
  });

  group('InMemoryNotificationRepository', () {
    test('upserts once for the same notification id', () async {
      final notifications = InMemoryNotificationRepository();
      final notification = AppNotification.invoiceCreated(InMemoryInvoiceRepository.sample());

      expect(await notifications.upsert(notification), isTrue);
      expect(await notifications.upsert(notification), isFalse);

      final items = await notifications.watchAll('biz_1').first;
      expect(items, hasLength(1));
    });
  });

  group('UnconfiguredNotificationRepository', () {
    test('does not throw when Firebase is not configured', () async {
      final notifications = UnconfiguredNotificationRepository();
      expect(await notifications.upsert(AppNotification.invoiceCreated(InMemoryInvoiceRepository.sample())), isFalse);
      await notifications.markRead(AppNotification.invoiceCreated(InMemoryInvoiceRepository.sample()));
      await notifications.markAllRead('biz_1');
      await notifications.delete(AppNotification.invoiceCreated(InMemoryInvoiceRepository.sample()));
      expect(await notifications.watchAll('biz_1').first, isEmpty);
    });
  });

  group('InvoiceProvider notifications', () {
    test('does not notify when a draft is saved', () async {
      final invoices = InMemoryInvoiceRepository();
      final notifications = InMemoryNotificationRepository();
      final provider = InvoiceProvider(invoices, notifications: notifications);
      addTearDown(provider.dispose);

      await provider.save(readyToIssue(), business: business, asDraft: true);

      expect(await notifications.watchAll('biz_1').first, isEmpty);
    });

    test('notifies when an invoice is issued', () async {
      final invoices = InMemoryInvoiceRepository();
      final notifications = InMemoryNotificationRepository();
      final provider = InvoiceProvider(invoices, notifications: notifications);
      addTearDown(provider.dispose);

      final created = await provider.save(readyToIssue(id: 'inv_issued'), business: business, asDraft: false);

      final items = await notifications.watchAll('biz_1').first;
      expect(items, hasLength(1));
      expect(items.first.id, 'issued_inv_issued');
      expect(items.first.type, AppNotificationType.invoiceCreated);
      expect(items.first.invoiceNumber, created.invoiceNumber);
    });

    test('notifies once when a draft is issued later', () async {
      final invoices = InMemoryInvoiceRepository();
      final notifications = InMemoryNotificationRepository();
      final provider = InvoiceProvider(invoices, notifications: notifications);
      addTearDown(provider.dispose);
      provider.bind(businessId: business.id);

      final draft = await provider.save(readyToIssue(id: 'inv_later'), business: business, asDraft: true);
      for (var i = 0; i < 5 && provider.byId(draft.id) == null; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      await provider.save(draft, business: business, asDraft: false);

      final items = await notifications.watchAll('biz_1').first;
      expect(items, hasLength(1));
      expect(items.first.id, 'issued_inv_later');
    });

    test('does not notify when an issued invoice is duplicated', () async {
      final invoices = InMemoryInvoiceRepository();
      final notifications = InMemoryNotificationRepository();
      final provider = InvoiceProvider(invoices, notifications: notifications);
      addTearDown(provider.dispose);
      provider.bind(businessId: business.id);

      final issued = await provider.save(readyToIssue(id: 'inv_dup'), business: business, asDraft: false);
      await provider.duplicate(issued, business: business, now: DateTime(2026, 9, 3));

      final items = await notifications.watchAll('biz_1').first;
      expect(items, hasLength(1));
      expect(items.first.id, 'issued_inv_dup');
    });
  });

  group('PaymentProvider notifications', () {
    test('notifies when a payment is recorded', () async {
      final invoices = InMemoryInvoiceRepository(invoices: [InMemoryInvoiceRepository.sample()]);
      final notifications = InMemoryNotificationRepository();
      final provider = PaymentProvider(
        InMemoryPaymentRepository(invoices: invoices),
        notifications: notifications,
      );
      addTearDown(provider.dispose);

      final payment = await provider.record(
        invoice: InMemoryInvoiceRepository.sample(),
        amountMinor: 100000,
        method: PaymentMethod.cash,
        paidAt: DateTime(2026, 9, 3),
      );

      final items = await notifications.watchAll('biz_1').first;
      expect(items, hasLength(1));
      expect(items.first.id, 'pay_${payment.id}');
      expect(items.first.type, AppNotificationType.paymentReceived);
    });
  });

  group('NotificationProvider', () {
    test('records an overdue invoice once across repeated scans', () async {
      final notifications = InMemoryNotificationRepository();
      final provider = NotificationProvider(notifications);
      addTearDown(provider.dispose);
      final overdue = InMemoryInvoiceRepository.sample(
        status: InvoiceStatus.unpaid,
        dueDate: DateTime(2026, 8, 1),
      );

      await provider.scanOverdue([overdue], now: DateTime(2026, 9, 3));
      await provider.scanOverdue([overdue], now: DateTime(2026, 9, 3));

      expect(provider.allNotifications, hasLength(1));
      expect(provider.allNotifications.first.id, 'overdue_inv_1');
      expect(provider.allNotifications.first.type, AppNotificationType.invoiceOverdue);
      expect(provider.unreadCount, 1);
    });
  });
}
