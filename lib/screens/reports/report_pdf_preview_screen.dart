import 'package:flutter/material.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/widgets/app_states.dart';
import 'package:invoice_pro/models/report.dart';
import 'package:invoice_pro/services/report_pdf_service.dart';
import 'package:printing/printing.dart';

class ReportPdfPreviewScreen extends StatelessWidget {
  const ReportPdfPreviewScreen({super.key, required this.args});

  final ReportPdfArgs? args;

  @override
  Widget build(BuildContext context) {
    final payload = args;
    if (payload == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.reportPdfPreviewTitle)),
        body: const AppErrorState(title: AppStrings.pageNotFound),
      );
    }

    final pdf = ReportPdfService();
    final content = pdf.contentFor(
      kind: payload.kind,
      snapshot: payload.snapshot,
      businessName: payload.businessName,
    );
    return Scaffold(
      appBar: AppBar(title: Text(content.title)),
      body: PdfPreview(
        build: (format) => pdf.build(content),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: content.fileName,
      ),
    );
  }
}
