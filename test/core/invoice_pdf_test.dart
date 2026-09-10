import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_pro/core/utils/invoice_pdf_content.dart';
import 'package:invoice_pro/models/invoice_status.dart';
import 'package:invoice_pro/services/invoice_pdf_builder.dart';

import '../helpers/in_memory_invoice_repository.dart';

void main() {
  group('InvoicePdfContent', () {
    test('maps invoice snapshots and integer money into PDF fields', () {
      final invoice = InMemoryInvoiceRepository.sample(
        status: InvoiceStatus.unpaid,
      ).copyWith(
        businessAddress: 'Mall Road',
        businessCity: 'Lahore',
        notes: 'Thank you for your business.',
        paymentInstructions: 'JazzCash 0300-0000000',
        termsAndConditions: 'Payment due within 7 days.',
      );
      final content = InvoicePdfContent.from(invoice, now: DateTime(2026, 9, 3));

      expect(content.fileName, 'INV-00001.pdf');
      expect(content.number, 'INV-00001');
      expect(content.businessName, 'Khan Traders');
      expect(content.businessLines, containsAll(['Mall Road', 'Lahore']));
      expect(content.customerName, 'Ali Store');
      expect(content.statusLabel, InvoiceStatus.unpaid.label);
      expect(content.lines, hasLength(1));
      expect(content.lines.first.name, 'Rice 10kg');
      expect(content.grandTotal, invoice.total.formatted);
      expect(content.amountDue, invoice.outstanding.formatted);
      expect(content.issueDate, contains('2026'));
      expect(content.notes, 'Thank you for your business.');
      expect(content.paymentInstructions, 'JazzCash 0300-0000000');
      expect(content.termsAndConditions, 'Payment due within 7 days.');
      expect(content.footer, 'InvoicePro - Billing Manager');
    });

    test('sanitizes the PDF file name from the invoice number', () {
      expect(InvoicePdfContent.fileNameFor(InMemoryInvoiceRepository.sample()), 'INV-00001.pdf');
      expect(
        InvoicePdfContent.fileNameFor(
          InMemoryInvoiceRepository.sample(id: 'inv x', invoiceNumber: 'KT 01/26'),
        ),
        'KT_01_26.pdf',
      );
    });
  });

  group('InvoicePdfBuilder', () {
    test('writes a valid A4 PDF for a live-shaped invoice', () async {
      final invoice = InMemoryInvoiceRepository.sample();
      final bytes = await InvoicePdfBuilder.build(invoice: invoice, now: DateTime(2026, 9, 3));

      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });
}
