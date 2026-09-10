import 'package:invoice_pro/core/constants/app_constants.dart';

class InvoiceNumberFormatter {
  InvoiceNumberFormatter._();

  static String format({
    required int number,
    String prefix = AppConstants.defaultInvoicePrefix,
    int padding = AppConstants.invoiceNumberPadding,
  }) {
    if (number < 0) {
      throw ArgumentError.value(number, 'number', 'Must be zero or positive');
    }
    return '$prefix${number.toString().padLeft(padding, '0')}';
  }
}
