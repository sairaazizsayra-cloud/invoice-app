import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/models/dashboard_models.dart';

class CustomerLedger {
  const CustomerLedger({
    required this.totalPurchases,
    required this.outstanding,
    required this.invoices,
    required this.payments,
  });

  final Money totalPurchases;
  final Money outstanding;
  final List<InvoiceRecord> invoices;
  final List<PaymentRecord> payments;

  factory CustomerLedger.empty({String currencyCode = 'PKR'}) {
    final zero = Money.zero(currencyCode: currencyCode);
    return CustomerLedger(
      totalPurchases: zero,
      outstanding: zero,
      invoices: const [],
      payments: const [],
    );
  }

  static CustomerLedger fromRecords({
    required String currencyCode,
    required List<InvoiceRecord> invoices,
    required List<PaymentRecord> payments,
  }) {
    final zero = Money.zero(currencyCode: currencyCode);
    var purchases = zero;
    var outstanding = zero;
    for (final invoice in invoices) {
      if (invoice.isCancelled || invoice.isDraft) continue;
      purchases += invoice.total;
      outstanding += invoice.outstanding;
    }
    final sortedInvoices = [...invoices]
      ..sort((a, b) => (b.issueDate ?? DateTime(0)).compareTo(a.issueDate ?? DateTime(0)));
    final sortedPayments = [...payments]..sort((a, b) => b.paidAt.compareTo(a.paidAt));
    return CustomerLedger(
      totalPurchases: purchases,
      outstanding: outstanding,
      invoices: sortedInvoices,
      payments: sortedPayments,
    );
  }

  static Map<String, Money> outstandingByCustomer({
    required String currencyCode,
    required List<InvoiceRecord> invoices,
  }) {
    final totals = <String, Money>{};
    for (final invoice in invoices) {
      if (invoice.isCancelled || invoice.isDraft || invoice.customerId.isEmpty) continue;
      final current = totals[invoice.customerId] ?? Money.zero(currencyCode: currencyCode);
      totals[invoice.customerId] = current + invoice.outstanding;
    }
    return totals;
  }
}
