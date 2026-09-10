import 'dart:typed_data';

import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/io/local_file_writer.dart';
import 'package:invoice_pro/core/utils/app_logger.dart';
import 'package:invoice_pro/core/utils/invoice_pdf_content.dart';
import 'package:invoice_pro/core/utils/platform_capabilities.dart';
import 'package:invoice_pro/models/invoice.dart';
import 'package:invoice_pro/services/invoice_pdf_builder.dart';
import 'package:invoice_pro/services/storage_service.dart';
import 'package:printing/printing.dart';

class InvoicePdfService {
  InvoicePdfService({StorageService? storage}) : _storage = storage ?? StorageService();

  final StorageService _storage;

  Future<Uint8List> build(Invoice invoice, {DateTime? now}) async {
    try {
      final logo = invoice.businessId.isEmpty ? null : await _storage.downloadBusinessLogo(invoice.businessId);
      return InvoicePdfBuilder.build(invoice: invoice, logoBytes: logo, now: now);
    } catch (error, stack) {
      AppLogger.error('Invoice PDF build failed', error, stack);
      throw const AppException(AppStrings.pdfFailed, debugCode: 'pdf-build');
    }
  }

  String fileName(Invoice invoice) => InvoicePdfContent.fileNameFor(invoice);

  Future<String> saveLocal(Invoice invoice, Uint8List bytes) async {
    try {
      if (!PlatformCapabilities.localFileSave) {
        await Printing.sharePdf(
          bytes: bytes,
          filename: fileName(invoice),
          subject: 'Invoice ${invoice.invoiceNumber}',
        );
        return fileName(invoice);
      }
      return LocalFileWriter.saveBytes(
        subdirectory: 'invoices',
        fileName: fileName(invoice),
        bytes: bytes,
      );
    } catch (error, stack) {
      AppLogger.error('Invoice PDF local save failed', error, stack);
      throw const AppException(AppStrings.pdfSaveFailed, debugCode: 'pdf-save');
    }
  }

  Future<String?> upload(Invoice invoice, Uint8List bytes) async {
    try {
      return await _storage.uploadInvoicePdf(
        businessId: invoice.businessId,
        invoiceId: invoice.id,
        bytes: bytes,
      );
    } on AppException catch (error) {
      if (error.debugCode == 'firebase-unconfigured') return null;
      rethrow;
    }
  }

  Future<void> share(Invoice invoice, Uint8List bytes) async {
    try {
      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName(invoice),
        subject: 'Invoice ${invoice.invoiceNumber}',
      );
    } catch (error, stack) {
      AppLogger.error('Invoice PDF share failed', error, stack);
      throw const AppException(AppStrings.pdfFailed, debugCode: 'pdf-share');
    }
  }

  Future<void> print(Invoice invoice, Uint8List bytes) async {
    try {
      await Printing.layoutPdf(
        name: fileName(invoice),
        onLayout: (format) async => bytes,
      );
    } catch (error, stack) {
      AppLogger.error('Invoice PDF print failed', error, stack);
      throw const AppException(AppStrings.pdfFailed, debugCode: 'pdf-print');
    }
  }
}
