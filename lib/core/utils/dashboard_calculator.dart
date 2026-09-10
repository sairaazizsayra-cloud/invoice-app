import 'package:intl/intl.dart';
import 'package:invoice_pro/core/utils/date_formatter.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/models/dashboard_models.dart';
import 'package:invoice_pro/models/date_range.dart';
import 'package:invoice_pro/models/invoice_status.dart';

class DashboardCalculator {
  DashboardCalculator._();

  static const int recentLimit = 5;
  static const int topLimit = 5;

  static DashboardSnapshot calculate({
    required DateRange range,
    required DateTime now,
    required String currencyCode,
    required List<InvoiceRecord> invoices,
    required List<PaymentRecord> payments,
    required List<ExpenseRecord> expenses,
    required int customerCount,
    required int productCount,
  }) {
    final zero = Money.zero(currencyCode: currencyCode);
    final inRangeInvoices = invoices.where((invoice) {
      final date = invoice.issueDate;
      if (date == null) return false;
      return !date.isBefore(range.start) && !date.isAfter(range.end);
    }).toList();

    final inRangePayments = payments.where((payment) {
      return !payment.paidAt.isBefore(range.start) && !payment.paidAt.isAfter(range.end);
    }).toList();

    final inRangeExpenses = expenses.where((expense) {
      return !expense.date.isBefore(range.start) && !expense.date.isAfter(range.end);
    }).toList();

    var paidCount = 0;
    var unpaidCount = 0;
    var overdueCount = 0;
    var invoicePaidTotal = zero;

    for (final invoice in inRangeInvoices) {
      invoicePaidTotal += invoice.paid;
      if (invoice.isCancelled || invoice.isDraft) continue;
      if (invoice.isSettled) {
        paidCount += 1;
      } else {
        unpaidCount += 1;
        if (invoice.isOverdue(now)) overdueCount += 1;
      }
    }

    var paymentTotal = zero;
    for (final payment in inRangePayments) {
      paymentTotal += payment.amount;
    }
    final revenue = inRangePayments.isNotEmpty ? paymentTotal : invoicePaidTotal;

    var expenseTotal = zero;
    for (final expense in inRangeExpenses) {
      expenseTotal += expense.amount;
    }

    final recentInvoices = [...inRangeInvoices]
      ..sort((a, b) => (b.issueDate ?? DateTime(0)).compareTo(a.issueDate ?? DateTime(0)));
    final recentPayments = [...inRangePayments]..sort((a, b) => b.paidAt.compareTo(a.paidAt));

    return DashboardSnapshot(
      revenue: revenue,
      expenses: expenseTotal,
      netProfit: revenue - expenseTotal,
      invoiceCount: inRangeInvoices.length,
      paidCount: paidCount,
      unpaidCount: unpaidCount,
      overdueCount: overdueCount,
      customerCount: customerCount,
      productCount: productCount,
      revenueSeries: series(
        range: range,
        currencyCode: currencyCode,
        events: [
          for (final payment in inRangePayments) (payment.paidAt, payment.amount),
        ],
      ),
      salesSeries: series(
        range: range,
        currencyCode: currencyCode,
        events: [
          for (final invoice in inRangeInvoices)
            if (invoice.issueDate != null && invoice.status != InvoiceStatus.cancelled)
              (invoice.issueDate!, invoice.total),
        ],
      ),
      recentInvoices: recentInvoices.take(recentLimit).toList(),
      recentPayments: recentPayments.take(recentLimit).toList(),
      topCustomers: _topCustomers(inRangeInvoices, currencyCode),
      topProducts: _topProducts(inRangeInvoices, currencyCode),
    );
  }

  static List<NamedMoneyTotal> _topCustomers(List<InvoiceRecord> invoices, String currencyCode) {
    final totals = <String, NamedMoneyTotal>{};
    for (final invoice in invoices) {
      if (invoice.isCancelled) continue;
      final key = invoice.customerId.isEmpty ? invoice.customerName : invoice.customerId;
      if (key.isEmpty) continue;
      final current = totals[key];
      final next = (current?.total ?? Money.zero(currencyCode: currencyCode)) + invoice.total;
      totals[key] = NamedMoneyTotal(
        id: key,
        name: invoice.customerName.isEmpty ? 'Customer' : invoice.customerName,
        total: next,
      );
    }
    final ranked = totals.values.toList()..sort((a, b) => b.total.compareTo(a.total));
    return ranked.take(topLimit).toList();
  }

  static List<NamedMoneyTotal> _topProducts(List<InvoiceRecord> invoices, String currencyCode) {
    final totals = <String, NamedMoneyTotal>{};
    for (final invoice in invoices) {
      if (invoice.isCancelled) continue;
      for (final line in invoice.lines) {
        final key = line.productId.isEmpty ? line.name : line.productId;
        if (key.isEmpty) continue;
        final current = totals[key];
        final next = (current?.total ?? Money.zero(currencyCode: currencyCode)) + line.lineTotal;
        totals[key] = NamedMoneyTotal(id: key, name: line.name, total: next);
      }
    }
    final ranked = totals.values.toList()..sort((a, b) => b.total.compareTo(a.total));
    return ranked.take(topLimit).toList();
  }

  static List<ChartPoint> series({
    required DateRange range,
    required String currencyCode,
    required List<(DateTime date, Money amount)> events,
  }) {
    final spanDays = range.end.difference(range.start).inDays;
    final monthly = spanDays > 31;
    final buckets = <DateTime, Money>{};

    void addBucket(DateTime key) {
      buckets.putIfAbsent(key, () => Money.zero(currencyCode: currencyCode));
    }

    if (monthly) {
      var cursor = DateTime(range.start.year, range.start.month);
      final last = DateTime(range.end.year, range.end.month);
      while (!cursor.isAfter(last)) {
        addBucket(cursor);
        cursor = DateTime(cursor.year, cursor.month + 1);
      }
    } else {
      var cursor = AppDateFormatter.startOfDay(range.start);
      final last = AppDateFormatter.startOfDay(range.end);
      while (!cursor.isAfter(last)) {
        addBucket(cursor);
        cursor = cursor.add(const Duration(days: 1));
      }
    }

    for (final event in events) {
      final key = monthly
          ? DateTime(event.$1.year, event.$1.month)
          : AppDateFormatter.startOfDay(event.$1);
      final current = buckets[key];
      if (current == null) continue;
      buckets[key] = current + event.$2;
    }

    final keys = buckets.keys.toList()..sort();
    final monthFormat = DateFormat('MMM');
    final dayFormat = DateFormat('dd MMM');
    return [
      for (final key in keys)
        ChartPoint(
          label: monthly ? monthFormat.format(key) : dayFormat.format(key),
          amount: buckets[key]!,
          sortKey: key,
        ),
    ];
  }
}
