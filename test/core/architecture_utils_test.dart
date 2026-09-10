import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_pro/core/constants/firestore_paths.dart';
import 'package:invoice_pro/core/utils/invoice_number.dart';
import 'package:invoice_pro/core/utils/line_amount_calculator.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/models/date_range.dart';

void main() {
  group('InvoiceNumberFormatter', () {
    test('pads sequential numbers with the default prefix', () {
      expect(InvoiceNumberFormatter.format(number: 1), 'INV-00001');
      expect(InvoiceNumberFormatter.format(number: 12), 'INV-00012');
    });

    test('supports a custom prefix', () {
      expect(
        InvoiceNumberFormatter.format(number: 7, prefix: 'BILL-', padding: 3),
        'BILL-007',
      );
    });
  });

  group('LineAmountCalculator', () {
    test('calculates subtotal, discount, tax, and total', () {
      final result = LineAmountCalculator.calculate(
        unitPrice: Money.parse('100.00'),
        quantity: 2,
        discountAmount: Money.parse('20.00'),
        taxPercentMinor: 1700,
      );
      expect(result.subtotal.format(includeSymbol: false), '200.00');
      expect(result.discount.format(includeSymbol: false), '20.00');
      expect(result.tax.format(includeSymbol: false), '30.60');
      expect(result.total.format(includeSymbol: false), '210.60');
    });
  });

  group('DateRange', () {
    test('builds this-month range from a fixed now', () {
      final now = DateTime(2026, 9, 3, 15);
      final range = DateRange.fromPreset(DateFilterPreset.thisMonth, now: now);
      expect(range.start, DateTime(2026, 9, 1));
      expect(range.end.day, 3);
      expect(range.end.hour, 23);
    });

    test('starts the week on Monday', () {
      final thursday = DateTime(2026, 9, 3);
      final range = DateRange.fromPreset(DateFilterPreset.thisWeek, now: thursday);
      expect(range.start, DateTime(2026, 8, 31));
    });
  });

  group('FirestorePaths', () {
    test('keeps business data nested under the business document', () {
      expect(FirestorePaths.invoice('biz_1', 'inv_1'), 'businesses/biz_1/invoices/inv_1');
      expect(FirestorePaths.payment('biz_1', 'pay_1'), 'businesses/biz_1/payments/pay_1');
      expect(FirestorePaths.expense('biz_1', 'exp_1'), 'businesses/biz_1/expenses/exp_1');
      expect(FirestorePaths.notification('biz_1', 'n_1'), 'businesses/biz_1/notifications/n_1');
      expect(FirestorePaths.customer('biz_1', 'cus_1'), 'businesses/biz_1/customers/cus_1');
      expect(FirestorePaths.product('biz_1', 'prd_1'), 'businesses/biz_1/products/prd_1');
      expect(StoragePaths.businessLogo('biz_1'), 'businesses/biz_1/logo.jpg');
      expect(StoragePaths.productImage('biz_1', 'prd_1'), 'businesses/biz_1/products/prd_1.jpg');
      expect(StoragePaths.invoiceDocument('biz_1', 'inv_1'), 'businesses/biz_1/invoices/inv_1.pdf');
    });
  });
}
