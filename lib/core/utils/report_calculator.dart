import 'package:invoice_pro/core/utils/dashboard_calculator.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/models/dashboard_models.dart';
import 'package:invoice_pro/models/date_range.dart';
import 'package:invoice_pro/models/expense.dart';
import 'package:invoice_pro/models/invoice_status.dart';
import 'package:invoice_pro/models/report.dart';

class ReportCalculator {
  ReportCalculator._();

  static ReportSnapshot calculate({
    required DateRange range,
    required DateTime now,
    required String currencyCode,
    required List<InvoiceRecord> invoices,
    required List<PaymentRecord> payments,
    required List<ExpenseRecord> expenses,
  }) {
    final zero = Money.zero(currencyCode: currencyCode);
    final inRangeInvoices = invoices.where((invoice) {
      final date = invoice.issueDate;
      if (date == null) return false;
      return !date.isBefore(range.start) && !date.isAfter(range.end);
    }).toList()
      ..sort((a, b) => (b.issueDate ?? DateTime(0)).compareTo(a.issueDate ?? DateTime(0)));

    final inRangePayments = payments.where((payment) {
      return !payment.paidAt.isBefore(range.start) && !payment.paidAt.isAfter(range.end);
    }).toList();

    final inRangeExpenses = expenses.where((expense) {
      return !expense.date.isBefore(range.start) && !expense.date.isAfter(range.end);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    var billed = zero;
    var paidCount = 0;
    var paidTotal = zero;
    var unpaidCount = 0;
    var unpaidTotal = zero;
    var overdueCount = 0;
    var overdueTotal = zero;
    var cancelledCount = 0;
    var cancelledTotal = zero;
    var invoicePaidTotal = zero;

    for (final invoice in inRangeInvoices) {
      invoicePaidTotal += invoice.paid;
      if (invoice.isCancelled) {
        cancelledCount += 1;
        cancelledTotal += invoice.total;
        continue;
      }
      if (invoice.isDraft) continue;
      billed += invoice.total;
      if (invoice.isSettled) {
        paidCount += 1;
        paidTotal += invoice.total;
      } else if (invoice.isOverdue(now)) {
        overdueCount += 1;
        overdueTotal += invoice.outstanding;
      } else {
        unpaidCount += 1;
        unpaidTotal += invoice.outstanding;
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

    return ReportSnapshot(
      range: range,
      currencyCode: currencyCode,
      revenue: revenue,
      billed: billed,
      expenses: expenseTotal,
      netProfit: revenue - expenseTotal,
      revenueSeries: DashboardCalculator.series(
        range: range,
        currencyCode: currencyCode,
        events: [
          for (final payment in inRangePayments) (payment.paidAt, payment.amount),
        ],
      ),
      salesSeries: DashboardCalculator.series(
        range: range,
        currencyCode: currencyCode,
        events: [
          for (final invoice in inRangeInvoices)
            if (invoice.issueDate != null && invoice.status != InvoiceStatus.cancelled && !invoice.isDraft)
              (invoice.issueDate!, invoice.total),
        ],
      ),
      expenseSeries: DashboardCalculator.series(
        range: range,
        currencyCode: currencyCode,
        events: [
          for (final expense in inRangeExpenses) (expense.date, expense.amount),
        ],
      ),
      paid: StatusMoneyCount(count: paidCount, total: paidTotal),
      unpaid: StatusMoneyCount(count: unpaidCount, total: unpaidTotal),
      overdue: StatusMoneyCount(count: overdueCount, total: overdueTotal),
      cancelled: StatusMoneyCount(count: cancelledCount, total: cancelledTotal),
      invoices: inRangeInvoices,
      customers: _customers(inRangeInvoices, currencyCode),
      products: _products(inRangeInvoices, currencyCode),
      expenseCategories: _expenseCategories(inRangeExpenses, currencyCode),
      expenseRows: inRangeExpenses,
    );
  }

  static List<CustomerReportRow> _customers(List<InvoiceRecord> invoices, String currencyCode) {
    final rows = <String, CustomerReportRow>{};
    final zero = Money.zero(currencyCode: currencyCode);
    for (final invoice in invoices) {
      if (invoice.isCancelled || invoice.isDraft) continue;
      final key = invoice.customerId.isEmpty ? invoice.customerName : invoice.customerId;
      if (key.isEmpty) continue;
      final current = rows[key];
      rows[key] = CustomerReportRow(
        id: key,
        name: invoice.customerName.isEmpty ? 'Customer' : invoice.customerName,
        invoiceCount: (current?.invoiceCount ?? 0) + 1,
        billed: (current?.billed ?? zero) + invoice.total,
        outstanding: (current?.outstanding ?? zero) + invoice.outstanding,
      );
    }
    final ranked = rows.values.toList()..sort((a, b) => b.billed.compareTo(a.billed));
    return ranked;
  }

  static List<ProductReportRow> _products(List<InvoiceRecord> invoices, String currencyCode) {
    final rows = <String, ProductReportRow>{};
    final zero = Money.zero(currencyCode: currencyCode);
    for (final invoice in invoices) {
      if (invoice.isCancelled || invoice.isDraft) continue;
      for (final line in invoice.lines) {
        final key = line.productId.isEmpty ? line.name : line.productId;
        if (key.isEmpty) continue;
        final current = rows[key];
        rows[key] = ProductReportRow(
          id: key,
          name: line.name,
          quantity: (current?.quantity ?? 0) + line.quantity,
          total: (current?.total ?? zero) + line.lineTotal,
        );
      }
    }
    final ranked = rows.values.toList()..sort((a, b) => b.total.compareTo(a.total));
    return ranked;
  }

  static List<ExpenseCategoryTotal> _expenseCategories(List<ExpenseRecord> expenses, String currencyCode) {
    final rows = <String, ExpenseCategoryTotal>{};
    final zero = Money.zero(currencyCode: currencyCode);
    for (final expense in expenses) {
      final category = ExpenseCategoryX.fromStorage(expense.category).label;
      final current = rows[category];
      rows[category] = ExpenseCategoryTotal(
        category: category,
        count: (current?.count ?? 0) + 1,
        total: (current?.total ?? zero) + expense.amount,
      );
    }
    final ranked = rows.values.toList()..sort((a, b) => b.total.compareTo(a.total));
    return ranked;
  }
}
