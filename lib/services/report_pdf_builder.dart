import 'dart:typed_data';

import 'package:invoice_pro/core/utils/report_pdf_content.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportPdfBuilder {
  ReportPdfBuilder._();

  static const PdfColor _teal = PdfColor.fromInt(0xFF0F6B73);
  static const PdfColor _tealDark = PdfColor.fromInt(0xFF04363B);
  static const PdfColor _muted = PdfColor.fromInt(0xFF3F494A);
  static const PdfColor _line = PdfColor.fromInt(0xFFBFC8C9);
  static const PdfColor _headerText = PdfColor.fromInt(0xFFFFFFFF);

  static Future<Uint8List> build(ReportPdfContent content) async {
    final doc = pw.Document(title: content.title);
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
                pw.Text(content.title, style: const pw.TextStyle(color: _muted, fontSize: 9)),
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
          pw.Text(
            content.businessName,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _tealDark),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            content.title,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _teal),
          ),
          pw.SizedBox(height: 4),
          pw.Text(content.rangeLabel, style: const pw.TextStyle(fontSize: 10, color: _muted)),
          pw.SizedBox(height: 10),
          pw.Container(height: 3, color: _teal),
          pw.SizedBox(height: 16),
          _summary(content),
          pw.SizedBox(height: 16),
          _table(content),
        ],
      ),
    );
    return doc.save();
  }

  static pw.Widget _summary(ReportPdfContent content) {
    return pw.Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final item in content.summary)
          pw.Container(
            width: 230,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _line, width: 0.5),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(item.$1, style: const pw.TextStyle(fontSize: 8, color: _muted)),
                pw.SizedBox(height: 4),
                pw.Text(item.$2, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
      ],
    );
  }

  static pw.Widget _table(ReportPdfContent content) {
    final rows = content.tableRows;
    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.4),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _teal),
          children: [
            for (final header in content.tableHeaders) _cell(header, headerStyle: true),
          ],
        ),
        if (rows.isEmpty)
          pw.TableRow(
            children: [
              for (var i = 0; i < content.tableHeaders.length; i++)
                _cell(i == 0 ? content.emptyMessage : ''),
            ],
          )
        else
          for (final row in rows)
            pw.TableRow(
              children: [
                for (var i = 0; i < content.tableHeaders.length; i++)
                  _cell(i < row.length ? row[i] : '', align: i == 0 ? pw.TextAlign.left : pw.TextAlign.right),
              ],
            ),
      ],
    );
  }

  static pw.Widget _cell(
    String text, {
    bool headerStyle = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: headerStyle ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: headerStyle ? _headerText : PdfColors.black,
        ),
      ),
    );
  }
}
