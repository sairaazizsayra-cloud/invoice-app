import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_pro/core/utils/invoice_number.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/models/invoice.dart';
import 'package:invoice_pro/models/invoice_status.dart';

void main() {
  group('InvoiceLine', () {
    test('stores integer line totals after discount and tax', () {
      final line = InvoiceLine.calculated(
        name: 'Rice 10kg',
        quantity: 2,
        unitPriceMinor: 10000,
        discountMinor: 2000,
        taxPercentMinor: 1700,
      );

      expect(line.lineSubtotalMinor, 20000);
      expect(line.discountMinor, 2000);
      expect(line.lineTaxMinor, 3060);
      expect(line.lineTotalMinor, 21060);
      expect(line.lineTotal().format(includeSymbol: false), '210.60');
    });
  });

  group('Invoice', () {
    test('sums line amounts into invoice totals', () {
      final invoice = Invoice.fromMap('inv_1', {
        'businessId': 'biz_1',
        'invoiceNumber': 'INV-00001',
        'invoiceSequence': 1,
        'customerId': 'cus_1',
        'customerName': 'Ali Store',
        'businessName': 'Khan Traders',
        'status': 'unpaid',
        'paymentTerms': 'net7',
        'issueDate': DateTime(2026, 9, 1),
        'dueDate': DateTime(2026, 9, 8),
        'currencyCode': 'PKR',
      }).withItems([
        InvoiceLine.calculated(name: 'Rice 10kg', quantity: 1, unitPriceMinor: 250000),
        InvoiceLine.calculated(
          name: 'Delivery',
          quantity: 1,
          unitPriceMinor: 50000,
          taxPercentMinor: 0,
        ),
      ]);

      expect(invoice.subtotalMinor, 300000);
      expect(invoice.totalMinor, 300000);
      expect(invoice.total.format(includeSymbol: false), '3,000.00');
      expect(invoice.matches('ali'), isTrue);
      expect(invoice.matches('INV-00001'), isTrue);
      expect(invoice.canEdit, isTrue);
      expect(invoice.canDelete, isFalse);
    });

    test('marks unpaid invoices overdue after the due date', () {
      final invoice = Invoice.fromMap('inv_2', {
        'businessId': 'biz_1',
        'invoiceNumber': 'INV-00002',
        'customerId': 'cus_1',
        'customerName': 'Ali Store',
        'businessName': 'Khan Traders',
        'status': 'unpaid',
        'issueDate': DateTime(2026, 8, 1),
        'dueDate': DateTime(2026, 8, 20),
        'totalMinor': 50000,
        'paidMinor': 0,
      });

      expect(invoice.isOverdue(DateTime(2026, 8, 20, 18)), isFalse);
      expect(invoice.isOverdue(DateTime(2026, 8, 21, 9)), isTrue);
      expect(invoice.displayStatus(DateTime(2026, 8, 21)), InvoiceStatus.overdue);
      expect(invoice.toRecord().outstanding.minorUnits, 50000);
    });

    test('due-on-receipt and net terms compute due dates without floating math', () {
      final issue = DateTime(2026, 9, 3);
      expect(InvoicePaymentTerms.dueOnReceipt.dueDateFrom(issue), DateTime(2026, 9, 3));
      expect(InvoicePaymentTerms.net7.dueDateFrom(issue), DateTime(2026, 9, 10));
      expect(InvoicePaymentTerms.net30.dueDateFrom(issue), DateTime(2026, 10, 3));
      expect(InvoiceNumberFormatter.format(number: 1), 'INV-00001');
      expect(Money.fromMinorUnits(250000).format(includeSymbol: false), '2,500.00');
    });

    test('partial and full payments update paid amount and status', () {
      final invoice = Invoice.fromMap('inv_3', {
        'businessId': 'biz_1',
        'invoiceNumber': 'INV-00003',
        'customerId': 'cus_1',
        'customerName': 'Ali Store',
        'businessName': 'Khan Traders',
        'status': 'unpaid',
        'issueDate': DateTime(2026, 9, 1),
        'dueDate': DateTime(2026, 9, 8),
        'totalMinor': 250000,
        'paidMinor': 0,
      });

      expect(invoice.canRecordPayment, isTrue);
      expect(invoice.outstanding.minorUnits, 250000);

      final partial = invoice.applyPaymentAmount(100000);
      expect(partial.paidMinor, 100000);
      expect(partial.outstanding.minorUnits, 150000);
      expect(partial.status, InvoiceStatus.partiallyPaid);
      expect(partial.canEdit, isFalse);
      expect(partial.canCancel, isFalse);
      expect(partial.canRecordPayment, isTrue);

      final paid = partial.applyPaymentAmount(150000);
      expect(paid.paidMinor, 250000);
      expect(paid.outstanding.minorUnits, 0);
      expect(paid.status, InvoiceStatus.paid);
      expect(paid.canRecordPayment, isFalse);

      final reverted = paid.revertPaymentAmount(250000);
      expect(reverted.paidMinor, 0);
      expect(reverted.status, InvoiceStatus.unpaid);
    });
  });
}
