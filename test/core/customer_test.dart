import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_pro/core/utils/customer_ledger.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/models/customer.dart';
import 'package:invoice_pro/models/dashboard_models.dart';
import 'package:invoice_pro/models/invoice_status.dart';

void main() {
  group('Customer', () {
    test('reads a Firestore-shaped map', () {
      final customer = Customer.fromMap('cus_1', {
        'businessId': 'biz_1',
        'name': 'Ali Store',
        'company': 'Ali Traders',
        'email': 'ali@store.pk',
        'phone': '03001112233',
        'address': 'Mall Road',
        'city': 'Lahore',
        'notes': 'Wholesale',
      });
      expect(customer.id, 'cus_1');
      expect(customer.name, 'Ali Store');
      expect(customer.company, 'Ali Traders');
      expect(customer.city, 'Lahore');
      expect(customer.initials, 'AS');
      expect(customer.matches('lahore'), isTrue);
      expect(customer.matches('karachi'), isFalse);
    });
  });

  group('CustomerLedger', () {
    test('returns zeros when the customer has no invoices or payments', () {
      final ledger = CustomerLedger.fromRecords(
        currencyCode: 'PKR',
        invoices: const [],
        payments: const [],
      );
      expect(ledger.totalPurchases.minorUnits, 0);
      expect(ledger.outstanding.minorUnits, 0);
    });

    test('sums purchases and outstanding from live-shaped invoices', () {
      final ledger = CustomerLedger.fromRecords(
        currencyCode: 'PKR',
        invoices: [
          InvoiceRecord(
            id: 'inv_1',
            number: 'INV-00001',
            customerId: 'cus_1',
            customerName: 'Ali Store',
            status: InvoiceStatus.paid,
            total: Money.parse('1000.00'),
            paid: Money.parse('1000.00'),
            issueDate: DateTime(2026, 9, 1),
            lines: const [],
          ),
          InvoiceRecord(
            id: 'inv_2',
            number: 'INV-00002',
            customerId: 'cus_1',
            customerName: 'Ali Store',
            status: InvoiceStatus.unpaid,
            total: Money.parse('400.00'),
            paid: Money.zero(),
            issueDate: DateTime(2026, 9, 2),
            lines: const [],
          ),
          InvoiceRecord(
            id: 'inv_3',
            number: 'INV-00003',
            customerId: 'cus_1',
            customerName: 'Ali Store',
            status: InvoiceStatus.cancelled,
            total: Money.parse('50.00'),
            paid: Money.zero(),
            issueDate: DateTime(2026, 9, 3),
            lines: const [],
          ),
        ],
        payments: [
          PaymentRecord(
            id: 'pay_1',
            amount: Money.parse('1000.00'),
            paidAt: DateTime(2026, 9, 1),
            customerId: 'cus_1',
          ),
        ],
      );

      expect(ledger.totalPurchases.minorUnits, 140000);
      expect(ledger.outstanding.minorUnits, 40000);
      expect(ledger.invoices.first.number, 'INV-00003');
      expect(ledger.payments, hasLength(1));
    });
  });
}
