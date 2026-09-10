import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/user_roles.dart';
import 'package:invoice_pro/core/utils/dashboard_calculator.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/models/app_user.dart';
import 'package:invoice_pro/models/business.dart';
import 'package:invoice_pro/models/dashboard_models.dart';
import 'package:invoice_pro/models/date_range.dart';
import 'package:invoice_pro/models/invoice_status.dart';

void main() {
  group('Business', () {
    test('reads a Firestore-shaped map with integer tax stored as minor units', () {
      final business = Business.fromMap('biz_1', {
        'ownerId': 'user_1',
        'name': 'Khan Traders',
        'ownerName': 'Ayesha Khan',
        'email': 'owner@business.pk',
        'phone': '03001234567',
        'city': 'Lahore',
        'currencyCode': 'PKR',
        'defaultTaxPercentMinor': 1700,
        'invoicePrefix': 'KT-',
      });

      expect(business.id, 'biz_1');
      expect(business.name, 'Khan Traders');
      expect(business.defaultTaxPercentMinor, 1700);
      expect(business.invoicePrefix, 'KT-');
      expect(business.currencyCode, AppConstants.defaultCurrencyCode);
    });

    test('seeds a workspace from the signed-in owner', () {
      const owner = AppUser(
        uid: 'user_1',
        name: 'Ayesha Khan',
        businessName: 'Khan Traders',
        email: 'owner@business.pk',
        phone: '03001234567',
        role: UserRoles.businessOwner,
        isActive: true,
        emailVerified: true,
        businessId: 'biz_1',
      );
      final business = Business.fromOwner(id: 'biz_1', owner: owner);
      expect(business.ownerId, 'user_1');
      expect(business.name, 'Khan Traders');
      expect(business.email, owner.email);
      expect(business.currencyCode, 'PKR');
    });
  });

  group('DashboardCalculator', () {
    test('returns zeros when invoices, payments, and expenses are empty', () {
      final now = DateTime(2026, 9, 3, 12);
      final snapshot = DashboardCalculator.calculate(
        range: DateRange.fromPreset(DateFilterPreset.thisMonth, now: now),
        now: now,
        currencyCode: 'PKR',
        invoices: const [],
        payments: const [],
        expenses: const [],
        customerCount: 0,
        productCount: 0,
      );

      expect(snapshot.revenue.minorUnits, 0);
      expect(snapshot.expenses.minorUnits, 0);
      expect(snapshot.netProfit.minorUnits, 0);
      expect(snapshot.invoiceCount, 0);
      expect(snapshot.paidCount, 0);
      expect(snapshot.unpaidCount, 0);
      expect(snapshot.overdueCount, 0);
      expect(snapshot.recentInvoices, isEmpty);
      expect(snapshot.topCustomers, isEmpty);
    });

    test('computes revenue, overdue, profit, and rankings from live-shaped records', () {
      final now = DateTime(2026, 9, 3, 12);
      final range = DateRange.fromPreset(DateFilterPreset.thisMonth, now: now);
      const pkr = 'PKR';

      final snapshot = DashboardCalculator.calculate(
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
            title: 'Fuel',
          ),
        ],
        customerCount: 4,
        productCount: 7,
      );

      expect(snapshot.revenue.minorUnits, 100000);
      expect(snapshot.expenses.minorUnits, 20000);
      expect(snapshot.netProfit.minorUnits, 80000);
      expect(snapshot.invoiceCount, 3);
      expect(snapshot.paidCount, 1);
      expect(snapshot.unpaidCount, 1);
      expect(snapshot.overdueCount, 1);
      expect(snapshot.customerCount, 4);
      expect(snapshot.productCount, 7);
      expect(snapshot.recentInvoices.first.number, 'INV-00001');
      expect(snapshot.topCustomers.first.name, 'Ali Store');
      expect(snapshot.topCustomers.first.total.minorUnits, 100000);
      expect(snapshot.topProducts.first.name, 'Rice 10kg');
      expect(snapshot.revenueSeries.any((point) => point.amount.minorUnits == 100000), isTrue);
    });
  });
}
