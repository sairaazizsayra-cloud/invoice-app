import 'package:flutter/material.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/widgets/app_states.dart';
import 'package:invoice_pro/providers/invoice_provider.dart';
import 'package:invoice_pro/services/invoice_pdf_service.dart';
import 'package:invoice_pro/services/storage_service.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

class InvoicePdfPreviewScreen extends StatelessWidget {
  const InvoicePdfPreviewScreen({super.key, required this.invoiceId});

  final String invoiceId;

  @override
  Widget build(BuildContext context) {
    final invoices = context.watch<InvoiceProvider>();
    final invoice = invoices.byId(invoiceId);

    if (invoice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.pdfPreviewTitle)),
        body: invoices.isLoading
            ? const AppLoading(message: AppStrings.loading)
            : const AppErrorState(title: AppStrings.pageNotFound),
      );
    }

    final pdf = InvoicePdfService(storage: context.read<StorageService>());
    return Scaffold(
      appBar: AppBar(title: Text(invoice.invoiceNumber)),
      body: PdfPreview(
        build: (format) => pdf.build(invoice),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: pdf.fileName(invoice),
      ),
    );
  }
}
