import 'package:invoice_pro/core/utils/money.dart';

/// Deterministic line-item math used by the invoice builder.
///
/// Discount is an absolute amount (not a percentage). Tax is applied after
/// discount using [taxPercentMinor] (`17.00%` → `1700`).
class LineAmountCalculator {
  LineAmountCalculator._();

  static LineAmountBreakdown calculate({
    required Money unitPrice,
    required int quantity,
    Money? discountAmount,
    int taxPercentMinor = 0,
  }) {
    if (quantity < 0) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be zero or positive');
    }
    if (taxPercentMinor < 0) {
      throw ArgumentError.value(taxPercentMinor, 'taxPercentMinor');
    }

    final subtotal = unitPrice.timesQuantity(quantity);
    final discount = discountAmount ?? Money.zero(currencyCode: unitPrice.currencyCode);
    if (discount.minorUnits > subtotal.minorUnits) {
      throw ArgumentError('Discount cannot exceed line subtotal');
    }
    final afterDiscount = subtotal - discount;
    final tax = afterDiscount.percentOf(taxPercentMinor);
    final total = afterDiscount + tax;

    return LineAmountBreakdown(
      subtotal: subtotal,
      discount: discount,
      tax: tax,
      total: total,
    );
  }
}

class LineAmountBreakdown {
  const LineAmountBreakdown({
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
  });

  final Money subtotal;
  final Money discount;
  final Money tax;
  final Money total;
}
