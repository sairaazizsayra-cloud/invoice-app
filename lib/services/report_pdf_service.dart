import 'dart:typed_data';

import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/io/local_file_writer.dart';
import 'package:invoice_pro/core/utils/app_logger.dart';
import 'package:invoice_pro/core/utils/platform_capabilities.dart';
import 'package:invoice_pro/core/utils/report_pdf_content.dart';
import 'package:invoice_pro/models/report.dart';
import 'package:invoice_pro/services/report_pdf_builder.dart';
import 'package:printing/printing.dart';

class ReportPdfService {
  ReportPdfContent contentFor({
    required ReportKind kind,
    required ReportSnapshot snapshot,
    required String businessName,
  }) {
    return ReportPdfContent.from(kind: kind, snapshot: snapshot, businessName: businessName);
  }

  Future<Uint8List> build(ReportPdfContent content) async {
    try {
      return ReportPdfBuilder.build(content);
    } catch (error, stack) {
      AppLogger.error('Report PDF build failed', error, stack);
      throw const AppException(AppStrings.pdfFailed, debugCode: 'report-pdf-build');
    }
  }

  Future<String> saveLocal(ReportPdfContent content, Uint8List bytes) async {
    try {
      if (!PlatformCapabilities.localFileSave) {
        await Printing.sharePdf(
          bytes: bytes,
          filename: content.fileName,
          subject: content.title,
        );
        return content.fileName;
      }
      return LocalFileWriter.saveBytes(
        subdirectory: 'reports',
        fileName: content.fileName,
        bytes: bytes,
      );
    } catch (error, stack) {
      AppLogger.error('Report PDF local save failed', error, stack);
      throw const AppException(AppStrings.pdfSaveFailed, debugCode: 'report-pdf-save');
    }
  }

  Future<void> share(ReportPdfContent content, Uint8List bytes) async {
    try {
      await Printing.sharePdf(
        bytes: bytes,
        filename: content.fileName,
        subject: content.title,
      );
    } catch (error, stack) {
      AppLogger.error('Report PDF share failed', error, stack);
      throw const AppException(AppStrings.pdfFailed, debugCode: 'report-pdf-share');
    }
  }

  Future<void> print(ReportPdfContent content, Uint8List bytes) async {
    try {
      await Printing.layoutPdf(
        name: content.fileName,
        onLayout: (format) async => bytes,
      );
    } catch (error, stack) {
      AppLogger.error('Report PDF print failed', error, stack);
      throw const AppException(AppStrings.pdfFailed, debugCode: 'report-pdf-print');
    }
  }
}
