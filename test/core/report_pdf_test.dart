import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/core/utils/report_calculator.dart';
import 'package:invoice_pro/core/utils/report_pdf_content.dart';
import 'package:invoice_pro/models/dashboard_models.dart';
import 'package:invoice_pro/models/date_range.dart';
import 'package:invoice_pro/models/invoice_status.dart';
import 'package:invoice_pro/models/report.dart';
import 'package:invoice_pro/services/report_pdf_builder.dart';

void main() {
  group('ReportPdfContent', () {
    test('maps a sales snapshot into PDF fields with integer money', () {
      final now = DateTime(2026, 9, 3);
      final snapshot = ReportCalculator.calculate(
        range: DateRange.fromPreset(DateFilterPreset.thisMonth, now: now),
        now: now,
        currencyCode: 'PKR',
        invoices: [
          InvoiceRecord(
            id: 'inv_1',
            number: 'INV-00001',
            customerId: 'c1',
            customerName: 'Ali Store',
            status: InvoiceStatus.paid,
            total: Money.parse('1000.00'),
            paid: Money.parse('1000.00'),
            issueDate: DateTime(2026, 9, 2),
            lines: const [],
          ),
        ],
        payments: [
          PaymentRecord(
            id: 'pay_1',
            amount: Money.parse('1000.00'),
            paidAt: DateTime(2026, 9, 2),
          ),
        ],
        expenses: const [],
      );
      final content = ReportPdfContent.from(
        kind: ReportKind.sales,
        snapshot: snapshot,
        businessName: 'Khan Traders',
      );

      expect(content.title, AppStrings.salesReportTitle);
      expect(content.businessName, 'Khan Traders');
      expect(content.fileName, 'sales_report_2026-09-01_2026-09-03.pdf');
      expect(content.footer, 'Invoice App - Billing Manager');
      expect(content.summary.first.$1, AppStrings.totalRevenue);
      expect(content.summary.first.$2, snapshot.revenue.formatted);
    });
  });

  group('ReportPdfBuilder', () {
    test('writes a valid A4 PDF for a live-shaped sales report', () async {
      final now = DateTime(2026, 9, 3);
      final snapshot = ReportCalculator.calculate(
        range: DateRange.fromPreset(DateFilterPreset.thisMonth, now: now),
        now: now,
        currencyCode: 'PKR',
        invoices: const [],
        payments: const [],
        expenses: const [],
      );
      final bytes = await ReportPdfBuilder.build(
        ReportPdfContent.from(
          kind: ReportKind.sales,
          snapshot: snapshot,
          businessName: 'Khan Traders',
        ),
      );

      expect(bytes.length, greaterThan(500));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });
}
