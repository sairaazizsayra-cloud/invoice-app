import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/models/dashboard_models.dart';
import 'package:invoice_pro/models/date_range.dart';

enum ReportKind { sales, invoices, customers, products, expenses }

enum InvoiceReportFilter { all, paid, unpaid, overdue, cancelled }

extension ReportKindX on ReportKind {
  String get path => name;

  static ReportKind? fromPath(String? raw) {
    for (final kind in ReportKind.values) {
      if (kind.name == raw) return kind;
    }
    return null;
  }
}

class StatusMoneyCount {
  const StatusMoneyCount({
    required this.count,
    required this.total,
  });

  final int count;
  final Money total;
}

class CustomerReportRow {
  const CustomerReportRow({
    required this.id,
    required this.name,
    required this.invoiceCount,
    required this.billed,
    required this.outstanding,
  });

  final String id;
  final String name;
  final int invoiceCount;
  final Money billed;
  final Money outstanding;
}

class ProductReportRow {
  const ProductReportRow({
    required this.id,
    required this.name,
    required this.quantity,
    required this.total,
  });

  final String id;
  final String name;
  final int quantity;
  final Money total;
}

class ExpenseCategoryTotal {
  const ExpenseCategoryTotal({
    required this.category,
    required this.count,
    required this.total,
  });

  final String category;
  final int count;
  final Money total;
}

class ReportSnapshot {
  const ReportSnapshot({
    required this.range,
    required this.currencyCode,
    required this.revenue,
    required this.billed,
    required this.expenses,
    required this.netProfit,
    required this.revenueSeries,
    required this.salesSeries,
    required this.expenseSeries,
    required this.paid,
    required this.unpaid,
    required this.overdue,
    required this.cancelled,
    required this.invoices,
    required this.customers,
    required this.products,
    required this.expenseCategories,
    required this.expenseRows,
  });

  final DateRange range;
  final String currencyCode;
  final Money revenue;
  final Money billed;
  final Money expenses;
  final Money netProfit;
  final List<ChartPoint> revenueSeries;
  final List<ChartPoint> salesSeries;
  final List<ChartPoint> expenseSeries;
  final StatusMoneyCount paid;
  final StatusMoneyCount unpaid;
  final StatusMoneyCount overdue;
  final StatusMoneyCount cancelled;
  final List<InvoiceRecord> invoices;
  final List<CustomerReportRow> customers;
  final List<ProductReportRow> products;
  final List<ExpenseCategoryTotal> expenseCategories;
  final List<ExpenseRecord> expenseRows;

  factory ReportSnapshot.empty({
    required DateRange range,
    String currencyCode = AppConstants.defaultCurrencyCode,
  }) {
    final zero = Money.zero(currencyCode: currencyCode);
    final emptyStatus = StatusMoneyCount(count: 0, total: zero);
    return ReportSnapshot(
      range: range,
      currencyCode: currencyCode,
      revenue: zero,
      billed: zero,
      expenses: zero,
      netProfit: zero,
      revenueSeries: const [],
      salesSeries: const [],
      expenseSeries: const [],
      paid: emptyStatus,
      unpaid: emptyStatus,
      overdue: emptyStatus,
      cancelled: emptyStatus,
      invoices: const [],
      customers: const [],
      products: const [],
      expenseCategories: const [],
      expenseRows: const [],
    );
  }
}

class ReportPdfArgs {
  const ReportPdfArgs({
    required this.kind,
    required this.snapshot,
    required this.businessName,
  });

  final ReportKind kind;
  final ReportSnapshot snapshot;
  final String businessName;
}
