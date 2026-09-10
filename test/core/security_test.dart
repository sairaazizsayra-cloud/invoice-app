import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_pro/core/utils/app_logger.dart';
import 'package:invoice_pro/core/utils/log_sanitizer.dart';
import 'package:invoice_pro/firebase/app_check_config.dart';
import 'package:invoice_pro/firebase/crash_reporting.dart';
import 'package:invoice_pro/firebase/firebase_bootstrap.dart';
import 'package:invoice_pro/providers/customer_provider.dart';
import 'package:invoice_pro/providers/invoice_provider.dart';

import '../helpers/in_memory_customer_repository.dart';
import '../helpers/in_memory_invoice_repository.dart';

void main() {
  group('Cross-business isolation', () {
    test('customer watch never returns another business workspace', () async {
      final repo = InMemoryCustomerRepository(
        customers: [
          InMemoryCustomerRepository.sample(id: 'cus_a', businessId: 'biz_1', name: 'Mine'),
          InMemoryCustomerRepository.sample(id: 'cus_b', businessId: 'biz_2', name: 'Theirs'),
        ],
      );
      final customers = CustomerProvider(repo);
      addTearDown(customers.dispose);

      customers.bind(businessId: 'biz_1');
      await Future<void>.delayed(Duration.zero);
      expect(customers.allCustomers.map((c) => c.id), ['cus_a']);
      expect(customers.allCustomers.every((c) => c.businessId == 'biz_1'), isTrue);
    });

    test('invoice watch never returns another business workspace', () async {
      final repo = InMemoryInvoiceRepository(
        invoices: [
          InMemoryInvoiceRepository.sample(id: 'inv_a', businessId: 'biz_1', invoiceNumber: 'INV-00001'),
          InMemoryInvoiceRepository.sample(id: 'inv_b', businessId: 'biz_2', invoiceNumber: 'INV-00001'),
        ],
      );
      final invoices = InvoiceProvider(repo);
      addTearDown(invoices.dispose);

      invoices.bind(businessId: 'biz_1');
      await Future<void>.delayed(Duration.zero);
      expect(invoices.allInvoices.map((i) => i.id), ['inv_a']);
      expect(invoices.allInvoices.every((i) => i.businessId == 'biz_1'), isTrue);
    });
  });

  group('AppCheckConfig', () {
    test('uses the debug provider in debug and Play Integrity in release', () {
      expect(AppCheckConfig.useDebugProvider(isDebug: true), isTrue);
      expect(AppCheckConfig.useDebugProvider(isDebug: false), isFalse);
    });
  });

  group('LogSanitizer', () {
    test('removes emails, password assignments, and long tokens', () {
      expect(LogSanitizer.scrub('Failed for ali@store.pk'), isNot(contains('ali@store.pk')));
      expect(LogSanitizer.scrub('password=hunter2 extra'), isNot(contains('hunter2')));
      expect(
        LogSanitizer.scrub('fcmToken=AAAA_this_is_a_very_long_fake_device_token_value_xxxxx'),
        isNot(contains('AAAA_this_is_a_very_long_fake_device_token_value_xxxxx')),
      );
      expect(LogSanitizer.scrub('Invoice INV-00001 for Ali Store'), contains('INV-00001'));
    });
  });

  group('CrashReporting', () {
    test('does not throw when Firebase is not configured', () async {
      expect(FirebaseBootstrap.initialized, isFalse);
      CrashReporting.setUserId('user_1');
      AppLogger.error('Invoice watch failed', Exception('ali@store.pk'));
      await CrashReporting.recordFatal('boom', Exception('x'), StackTrace.empty);
    });
  });
}
