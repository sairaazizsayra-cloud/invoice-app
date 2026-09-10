import 'dart:typed_data';

import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/utils/invoice_pdf_content.dart';
import 'package:invoice_pro/models/invoice.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Builds an A4 invoice PDF from live invoice data (integer money, snapshots).
class InvoicePdfBuilder {
  InvoicePdfBuilder._();

  static const PdfColor _teal = PdfColor.fromInt(0xFF0F6B73);
  static const PdfColor _tealDark = PdfColor.fromInt(0xFF04363B);
  static const PdfColor _muted = PdfColor.fromInt(0xFF3F494A);
  static const PdfColor _line = PdfColor.fromInt(0xFFBFC8C9);
  static const PdfColor _headerText = PdfColor.fromInt(0xFFFFFFFF);
  static const PdfColor _surface = PdfColor.fromInt(0xFFF6FAFA);

  static Future<Uint8List> build({
    required Invoice invoice,
    Uint8List? logoBytes,
    DateTime? now,
  }) {
    final content = InvoicePdfContent.from(invoice, now: now);
    return buildFrom(content, logoBytes: logoBytes);
  }

  static Future<Uint8List> buildFrom(InvoicePdfContent content, {Uint8List? logoBytes}) async {
    final doc = pw.Document(title: '${content.title} ${content.number}');
    pw.ImageProvider? logo;
    if (logoBytes != null && logoBytes.isNotEmpty) {
      try {
        logo = pw.MemoryImage(logoBytes);
      } catch (_) {
        logo = null;
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 48),
        header: (context) {
          if (context.pageNumber == 1) return pw.SizedBox();
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(content.businessName, style: const pw.TextStyle(color: _muted, fontSize: 9)),
                pw.Text(content.number, style: const pw.TextStyle(color: _muted, fontSize: 9)),
              ],
            ),
          );
        },
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(content.footer, style: const pw.TextStyle(color: _muted, fontSize: 8)),
            pw.Text(
              '${context.pageNumber} / ${context.pagesCount}',
              style: const pw.TextStyle(color: _muted, fontSize: 8),
            ),
          ],
        ),
        build: (context) => [
          _header(content, logo),
          pw.SizedBox(height: 20),
          _parties(content),
          pw.SizedBox(height: 16),
          _items(content),
          pw.SizedBox(height: 16),
          _totals(content),
          if (content.notes.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _block(AppStrings.invoiceNotesLabel, content.notes),
          ],
          if (content.paymentInstructions.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _block(AppStrings.paymentInstructionsLabel, content.paymentInstructions),
          ],
          if (content.termsAndConditions.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _block(AppStrings.termsLabel, content.termsAndConditions),
          ],
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _header(InvoicePdfContent content, pw.ImageProvider? logo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logo != null) ...[
              pw.Container(
                width: 56,
                height: 56,
                alignment: pw.Alignment.center,
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
              pw.SizedBox(width: 12),
            ],
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    content.businessName,
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _tealDark),
                  ),
                  for (final line in content.businessLines)
                    pw.Text(line, style: const pw.TextStyle(fontSize: 9, color: _muted)),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  content.title,
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _teal),
                ),
                pw.SizedBox(height: 4),
                pw.Text(content.number, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: _teal,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    content.statusLabel,
                    style: pw.TextStyle(color: _headerText, fontSize: 9, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(height: 3, color: _teal),
      ],
    );
  }

  static pw.Widget _parties(InvoicePdfContent content) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Bill to', style: pw.TextStyle(fontSize: 9, color: _muted, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(content.customerName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              for (final line in content.customerLines)
                pw.Text(line, style: const pw.TextStyle(fontSize: 9, color: _muted)),
            ],
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: pw.Column(
            children: [
              _metaRow(AppStrings.invoiceDateLabel, content.issueDate),
              _metaRow(AppStrings.dueDateLabel, content.dueDate),
              _metaRow(AppStrings.paymentTermsLabel, content.paymentTerms),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _metaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: _muted)),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _items(InvoicePdfContent content) {
    final headers = [
      AppStrings.invoiceItems,
      AppStrings.quantityLabel,
      AppStrings.unitPriceLabel,
      AppStrings.discountLabel,
      AppStrings.taxLabel,
      AppStrings.lineTotalLabel,
    ];
    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.4),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.6),
        1: pw.FlexColumnWidth(1.1),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(1.1),
        4: pw.FlexColumnWidth(1.0),
        5: pw.FlexColumnWidth(1.2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _teal),
          children: [
            for (final header in headers) _cell(header, headerStyle: true),
          ],
        ),
        if (content.lines.isEmpty)
          pw.TableRow(
            children: [
              _cell(AppStrings.emptyInvoiceItemsTitle),
              _cell(''),
              _cell(''),
              _cell(''),
              _cell(''),
              _cell(''),
            ],
          )
        else
          for (final line in content.lines)
            pw.TableRow(
              children: [
                _itemCell(line),
                _cell(line.quantity, align: pw.TextAlign.right),
                _cell(line.unitPrice, align: pw.TextAlign.right),
                _cell(line.discount, align: pw.TextAlign.right),
                _cell(line.tax, align: pw.TextAlign.right),
                _cell(line.total, align: pw.TextAlign.right, bold: true),
              ],
            ),
      ],
    );
  }

  static pw.Widget _itemCell(InvoicePdfLineContent line) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(line.name, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          if (line.description.isNotEmpty)
            pw.Text(line.description, style: const pw.TextStyle(fontSize: 7, color: _muted)),
        ],
      ),
    );
  }

  static pw.Widget _cell(
    String text, {
    bool headerStyle = false,
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: headerStyle ? 8 : 8,
          fontWeight: headerStyle || bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: headerStyle ? _headerText : PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _totals(InvoicePdfContent content) {
    return pw.Row(
      children: [
        pw.Spacer(),
        pw.Container(
          width: 220,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: _surface,
            border: pw.Border.all(color: _line, width: 0.6),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            children: [
              _totalRow(AppStrings.subtotalLabel, content.subtotal),
              _totalRow(AppStrings.discountLabel, content.discount),
              _totalRow(AppStrings.taxLabel, content.tax),
              pw.Divider(color: _line),
              _totalRow(AppStrings.grandTotalLabel, content.grandTotal, emphasize: true),
              _totalRow(AppStrings.amountPaidLabel, content.paid),
              _totalRow(AppStrings.amountDueLabel, content.amountDue, emphasize: true),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _totalRow(String label, String value, {bool emphasize = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: emphasize ? 10 : 9,
              fontWeight: emphasize ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: emphasize ? _tealDark : _muted,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: emphasize ? 10 : 9,
              fontWeight: pw.FontWeight.bold,
              color: emphasize ? _tealDark : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _block(String title, String body) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _tealDark)),
        pw.SizedBox(height: 4),
        pw.Text(body, style: const pw.TextStyle(fontSize: 8, color: _muted)),
      ],
    );
  }
}
