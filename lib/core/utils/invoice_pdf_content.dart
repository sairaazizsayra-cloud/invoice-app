import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/utils/date_formatter.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/models/invoice.dart';
import 'package:invoice_pro/models/invoice_status.dart';

/// Plain-text invoice fields used by the A4 PDF builder and unit tests.
///
/// Money is formatted from integer minor units. This type does not generate PDF
/// bytes, so tests can assert content without depending on platform plugins.
class InvoicePdfContent {
  const InvoicePdfContent({
    required this.fileName,
    required this.title,
    required this.number,
    required this.statusLabel,
    required this.businessName,
    required this.businessLines,
    required this.customerName,
    required this.customerLines,
    required this.issueDate,
    required this.dueDate,
    required this.paymentTerms,
    required this.lines,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.grandTotal,
    required this.paid,
    required this.amountDue,
    required this.notes,
    required this.paymentInstructions,
    required this.termsAndConditions,
    required this.footer,
  });

  final String fileName;
  final String title;
  final String number;
  final String statusLabel;
  final String businessName;
  final List<String> businessLines;
  final String customerName;
  final List<String> customerLines;
  final String issueDate;
  final String dueDate;
  final String paymentTerms;
  final List<InvoicePdfLineContent> lines;
  final String subtotal;
  final String discount;
  final String tax;
  final String grandTotal;
  final String paid;
  final String amountDue;
  final String notes;
  final String paymentInstructions;
  final String termsAndConditions;
  final String footer;

  factory InvoicePdfContent.from(Invoice invoice, {DateTime? now}) {
    final currency = invoice.currencyCode;
    return InvoicePdfContent(
      fileName: fileNameFor(invoice),
      title: 'INVOICE',
      number: invoice.invoiceNumber,
      statusLabel: invoice.displayStatus(now ?? DateTime.now()).label,
      businessName: invoice.businessName,
      businessLines: [
        if (invoice.businessAddress.isNotEmpty) invoice.businessAddress,
        if (invoice.businessCity.isNotEmpty) invoice.businessCity,
        if (invoice.businessPhone.isNotEmpty) invoice.businessPhone,
        if (invoice.businessEmail.isNotEmpty) invoice.businessEmail,
        if (invoice.businessTaxNumber.isNotEmpty) invoice.businessTaxNumber,
      ],
      customerName: invoice.customerName,
      customerLines: [
        if (invoice.customerCompany.isNotEmpty) invoice.customerCompany,
        if (invoice.customerPhone.isNotEmpty) invoice.customerPhone,
        if (invoice.customerEmail.isNotEmpty) invoice.customerEmail,
        if (invoice.customerAddress.isNotEmpty) invoice.customerAddress,
        if (invoice.customerCity.isNotEmpty) invoice.customerCity,
      ],
      issueDate: AppDateFormatter.display(invoice.issueDate),
      dueDate: AppDateFormatter.display(invoice.dueDate),
      paymentTerms: invoice.paymentTerms.label,
      lines: [
        for (final line in invoice.items)
          InvoicePdfLineContent(
            name: line.name,
            description: line.description,
            quantity: '${line.quantity} ${line.unit}',
            unitPrice: line.unitPrice(currencyCode: currency).formatted,
            discount: line.discount(currencyCode: currency).formatted,
            tax: '${Money.fromMinorUnits(line.taxPercentMinor).format(includeSymbol: false)}%',
            total: line.lineTotal(currencyCode: currency).formatted,
          ),
      ],
      subtotal: invoice.subtotal.formatted,
      discount: invoice.discount.formatted,
      tax: invoice.tax.formatted,
      grandTotal: invoice.total.formatted,
      paid: invoice.paid.formatted,
      amountDue: invoice.outstanding.formatted,
      notes: invoice.notes,
      paymentInstructions: invoice.paymentInstructions,
      termsAndConditions: invoice.termsAndConditions,
      // Helvetica (default PDF font) cannot draw the en-dash in appFullName.
      footer: '${AppConstants.appName} - ${AppConstants.appTagline}',
    );
  }

  static String fileNameFor(Invoice invoice) {
    final raw = invoice.invoiceNumber.trim().isEmpty ? invoice.id : invoice.invoiceNumber.trim();
    final safe = raw.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    return '$safe.pdf';
  }
}

class InvoicePdfLineContent {
  const InvoicePdfLineContent({
    required this.name,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.tax,
    required this.total,
  });

  final String name;
  final String description;
  final String quantity;
  final String unitPrice;
  final String discount;
  final String tax;
  final String total;
}
