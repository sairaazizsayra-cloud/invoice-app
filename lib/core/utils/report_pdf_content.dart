import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/utils/date_formatter.dart';
import 'package:invoice_pro/models/invoice_status.dart';
import 'package:invoice_pro/models/report.dart';

/// Plain-text report fields used by the A4 PDF builder and unit tests.
class ReportPdfContent {
  const ReportPdfContent({
    required this.fileName,
    required this.title,
    required this.businessName,
    required this.rangeLabel,
    required this.footer,
    required this.summary,
    required this.tableHeaders,
    required this.tableRows,
    required this.emptyMessage,
  });

  static const int pdfRowLimit = 80;

  final String fileName;
  final String title;
  final String businessName;
  final String rangeLabel;
  final String footer;
  final List<(String, String)> summary;
  final List<String> tableHeaders;
  final List<List<String>> tableRows;
  final String emptyMessage;

  factory ReportPdfContent.from({
    required ReportKind kind,
    required ReportSnapshot snapshot,
    required String businessName,
  }) {
    final rangeLabel =
        '${AppDateFormatter.display(snapshot.range.start)} - ${AppDateFormatter.display(snapshot.range.end)}';
    final title = _title(kind);
    final fileName = '${kind.path}_report_${AppDateFormatter.isoDate(snapshot.range.start)}_'
        '${AppDateFormatter.isoDate(snapshot.range.end)}.pdf';
    return ReportPdfContent(
      fileName: fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_'),
      title: title,
      businessName: businessName,
      rangeLabel: rangeLabel,
      footer: '${AppConstants.appName} - ${AppConstants.appTagline}',
      summary: _summary(kind, snapshot),
      tableHeaders: _headers(kind),
      tableRows: _rows(kind, snapshot),
      emptyMessage: AppStrings.emptyReportBody,
    );
  }

  static String _title(ReportKind kind) {
    switch (kind) {
      case ReportKind.sales:
        return AppStrings.salesReportTitle;
      case ReportKind.invoices:
        return AppStrings.invoiceReportTitle;
      case ReportKind.customers:
        return AppStrings.customerReportTitle;
      case ReportKind.products:
        return AppStrings.productReportTitle;
      case ReportKind.expenses:
        return AppStrings.expenseReportTitle;
    }
  }

  static List<(String, String)> _summary(ReportKind kind, ReportSnapshot snapshot) {
    switch (kind) {
      case ReportKind.sales:
        return [
          (AppStrings.totalRevenue, snapshot.revenue.formatted),
          (AppStrings.reportBilled, snapshot.billed.formatted),
          (AppStrings.totalExpenses, snapshot.expenses.formatted),
          (AppStrings.netProfit, snapshot.netProfit.formatted),
        ];
      case ReportKind.invoices:
        return [
          (AppStrings.paidInvoices, '${snapshot.paid.count} / ${snapshot.paid.total.formatted}'),
          (AppStrings.unpaidInvoices, '${snapshot.unpaid.count} / ${snapshot.unpaid.total.formatted}'),
          (AppStrings.overdueInvoices, '${snapshot.overdue.count} / ${snapshot.overdue.total.formatted}'),
          (AppStrings.filterCancelled, '${snapshot.cancelled.count} / ${snapshot.cancelled.total.formatted}'),
        ];
      case ReportKind.customers:
        return [
          (AppStrings.totalCustomers, '${snapshot.customers.length}'),
          (AppStrings.reportBilled, snapshot.billed.formatted),
        ];
      case ReportKind.products:
        return [
          (AppStrings.totalProducts, '${snapshot.products.length}'),
          (AppStrings.reportBilled, snapshot.billed.formatted),
        ];
      case ReportKind.expenses:
        return [
          (AppStrings.totalExpenses, snapshot.expenses.formatted),
        ];
    }
  }

  static List<String> _headers(ReportKind kind) {
    switch (kind) {
      case ReportKind.sales:
        return [AppStrings.reportPeriod, AppStrings.totalRevenue];
      case ReportKind.invoices:
        return [
          AppStrings.invoiceNumberLabel,
          AppStrings.customerNameLabel,
          AppStrings.reportStatusLabel,
          AppStrings.grandTotalLabel,
        ];
      case ReportKind.customers:
        return [
          AppStrings.customerNameLabel,
          AppStrings.totalInvoices,
          AppStrings.reportBilled,
          AppStrings.amountDueLabel,
        ];
      case ReportKind.products:
        return [AppStrings.productNameLabel, AppStrings.quantityLabel, AppStrings.reportBilled];
      case ReportKind.expenses:
        return [AppStrings.expenseCategoryLabel, AppStrings.reportCount, AppStrings.totalExpenses];
    }
  }

  static List<List<String>> _rows(ReportKind kind, ReportSnapshot snapshot) {
    switch (kind) {
      case ReportKind.sales:
        final points = snapshot.revenueSeries.any((point) => !point.amount.isZero)
            ? snapshot.revenueSeries
            : snapshot.salesSeries;
        return [
          for (final point in points.take(pdfRowLimit)) [point.label, point.amount.formatted],
        ];
      case ReportKind.invoices:
        return [
          for (final invoice in snapshot.invoices.take(pdfRowLimit))
            [
              invoice.number,
              invoice.customerName,
              invoice.status.label,
              invoice.total.formatted,
            ],
        ];
      case ReportKind.customers:
        return [
          for (final customer in snapshot.customers.take(pdfRowLimit))
            [
              customer.name,
              '${customer.invoiceCount}',
              customer.billed.formatted,
              customer.outstanding.formatted,
            ],
        ];
      case ReportKind.products:
        return [
          for (final product in snapshot.products.take(pdfRowLimit))
            [product.name, '${product.quantity}', product.total.formatted],
        ];
      case ReportKind.expenses:
        return [
          for (final category in snapshot.expenseCategories.take(pdfRowLimit))
            [category.category, '${category.count}', category.total.formatted],
        ];
    }
  }
}
