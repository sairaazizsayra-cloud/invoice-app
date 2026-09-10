import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/core/utils/report_calculator.dart';
import 'package:invoice_pro/models/dashboard_models.dart';
import 'package:invoice_pro/models/date_range.dart';
import 'package:invoice_pro/models/invoice_status.dart';

void main() {
  group('ReportCalculator', () {
    test('returns zeros when invoices, payments, and expenses are empty', () {
      final now = DateTime(2026, 9, 3, 12);
      final snapshot = ReportCalculator.calculate(
        range: DateRange.fromPreset(DateFilterPreset.thisMonth, now: now),
        now: now,
        currencyCode: 'PKR',
        invoices: const [],
        payments: const [],
        expenses: const [],
      );

      expect(snapshot.revenue.minorUnits, 0);
      expect(snapshot.billed.minorUnits, 0);
      expect(snapshot.expenses.minorUnits, 0);
      expect(snapshot.netProfit.minorUnits, 0);
      expect(snapshot.paid.count, 0);
      expect(snapshot.customers, isEmpty);
      expect(snapshot.products, isEmpty);
      expect(snapshot.expenseCategories, isEmpty);
    });

    test('computes sales, invoice statuses, customers, products, and expenses', () {
      final now = DateTime(2026, 9, 3, 12);
      final range = DateRange.fromPreset(DateFilterPreset.thisMonth, now: now);
      const pkr = 'PKR';

      final snapshot = ReportCalculator.calculate(
        range: range,
        now: now,
        currencyCode: pkr,
        invoices: [
          InvoiceRecord(
            id: 'inv_paid',
            number: 'INV-00001',
            customerId: 'c1',
            customerName: 'Ali Store',
            status: InvoiceStatus.paid,
            total: Money.parse('1000.00'),
            paid: Money.parse('1000.00'),
            issueDate: DateTime(2026, 9, 2),
            dueDate: DateTime(2026, 9, 10),
            lines: [
              InvoiceLineRecord(
                productId: 'p1',
                name: 'Rice 10kg',
                lineTotal: Money.parse('1000.00'),
                quantity: 2,
              ),
            ],
          ),
          InvoiceRecord(
            id: 'inv_overdue',
            number: 'INV-00002',
            customerId: 'c2',
            customerName: 'Fatima Mart',
            status: InvoiceStatus.unpaid,
            total: Money.parse('500.00'),
            paid: Money.zero(),
            issueDate: DateTime(2026, 9, 1),
            dueDate: DateTime(2026, 8, 28),
            lines: [
              InvoiceLineRecord(
                productId: 'p2',
                name: 'Oil 5L',
                lineTotal: Money.parse('500.00'),
                quantity: 1,
              ),
            ],
          ),
          InvoiceRecord(
            id: 'inv_cancelled',
            number: 'INV-00003',
            customerId: 'c1',
            customerName: 'Ali Store',
            status: InvoiceStatus.cancelled,
            total: Money.parse('200.00'),
            paid: Money.zero(),
            issueDate: DateTime(2026, 9, 2),
            lines: const [],
          ),
          InvoiceRecord(
            id: 'inv_old',
            number: 'INV-00004',
            customerId: 'c1',
            customerName: 'Ali Store',
            status: InvoiceStatus.paid,
            total: Money.parse('9000.00'),
            paid: Money.parse('9000.00'),
            issueDate: DateTime(2026, 8, 1),
            lines: const [],
          ),
        ],
        payments: [
          PaymentRecord(
            id: 'pay_1',
            amount: Money.parse('1000.00'),
            paidAt: DateTime(2026, 9, 2, 16),
            customerName: 'Ali Store',
            invoiceNumber: 'INV-00001',
          ),
        ],
        expenses: [
          ExpenseRecord(
            id: 'exp_1',
            amount: Money.parse('200.00'),
            date: DateTime(2026, 9, 1),
            title: 'Shop rent',
            category: 'rent',
          ),
        ],
      );

      expect(snapshot.revenue.minorUnits, 100000);
      expect(snapshot.billed.minorUnits, 150000);
      expect(snapshot.expenses.minorUnits, 20000);
      expect(snapshot.netProfit.minorUnits, 80000);
      expect(snapshot.paid.count, 1);
      expect(snapshot.overdue.count, 1);
      expect(snapshot.cancelled.count, 1);
      expect(snapshot.invoices, hasLength(3));
      expect(snapshot.customers.first.name, 'Ali Store');
      expect(snapshot.customers.first.billed.minorUnits, 100000);
      expect(snapshot.products.first.name, 'Rice 10kg');
      expect(snapshot.products.first.quantity, 2);
      expect(snapshot.expenseCategories.single.category, 'Rent');
      expect(snapshot.expenseCategories.single.total.minorUnits, 20000);
    });

    test('buckets yearly sales by month', () {
      final now = DateTime(2026, 9, 3);
      final snapshot = ReportCalculator.calculate(
        range: DateRange.fromPreset(DateFilterPreset.thisYear, now: now),
        now: now,
        currencyCode: 'PKR',
        invoices: [
          InvoiceRecord(
            id: 'inv_1',
            number: 'INV-00001',
            customerId: 'c1',
            customerName: 'Ali Store',
            status: InvoiceStatus.paid,
            total: Money.parse('100.00'),
            paid: Money.parse('100.00'),
            issueDate: DateTime(2026, 9, 1),
            lines: const [],
          ),
        ],
        payments: const [],
        expenses: const [],
      );

      expect(snapshot.salesSeries.length, greaterThan(1));
      expect(snapshot.salesSeries.any((point) => point.amount.minorUnits == 10000), isTrue);
    });
  });
}
