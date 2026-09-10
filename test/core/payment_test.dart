import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_pro/models/invoice_status.dart';
import 'package:invoice_pro/models/payment.dart';

import '../helpers/in_memory_invoice_repository.dart';
import '../helpers/in_memory_payment_repository.dart';

void main() {
  group('PaymentMethod', () {
    test('maps FYP payment methods from storage names and labels', () {
      expect(PaymentMethodX.fromStorage('jazzcash'), PaymentMethod.jazzcash);
      expect(PaymentMethodX.fromStorage('Bank Transfer'), PaymentMethod.bankTransfer);
      expect(PaymentMethod.card.label, 'Credit/Debit Card');
      expect(PaymentMethod.easypaisa.label, 'Easypaisa');
    });
  });

  group('InMemoryPaymentRepository', () {
    test('records a partial payment and updates invoice outstanding', () async {
      final invoices = InMemoryInvoiceRepository(
        invoices: [InMemoryInvoiceRepository.sample()],
      );
      final payments = InMemoryPaymentRepository(invoices: invoices);
      final invoice = InMemoryInvoiceRepository.sample();

      await payments.record(
        invoice: invoice,
        amountMinor: 100000,
        method: PaymentMethod.jazzcash,
        paidAt: DateTime(2026, 9, 3),
        notes: 'First installment',
      );

      final updated = await invoices.fetch(businessId: 'biz_1', invoiceId: 'inv_1');
      expect(updated?.paidMinor, 100000);
      expect(updated?.status, InvoiceStatus.partiallyPaid);
      expect(updated?.outstanding.minorUnits, 150000);

      final history = await payments.watchAll('biz_1').first;
      expect(history, hasLength(1));
      expect(history.first.method, PaymentMethod.jazzcash);
      expect(history.first.amountMinor, 100000);
    });

    test('rejects an amount greater than the remaining balance', () async {
      final invoices = InMemoryInvoiceRepository(
        invoices: [InMemoryInvoiceRepository.sample()],
      );
      final payments = InMemoryPaymentRepository(invoices: invoices);

      expect(
        () => payments.record(
          invoice: InMemoryInvoiceRepository.sample(),
          amountMinor: 250001,
          method: PaymentMethod.cash,
          paidAt: DateTime(2026, 9, 3),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('marking the remaining balance paid settles the invoice', () async {
      final invoices = InMemoryInvoiceRepository(
        invoices: [InMemoryInvoiceRepository.sample()],
      );
      final payments = InMemoryPaymentRepository(invoices: invoices);
      final invoice = InMemoryInvoiceRepository.sample();

      await payments.record(
        invoice: invoice,
        amountMinor: invoice.outstanding.minorUnits,
        method: PaymentMethod.cash,
        paidAt: DateTime(2026, 9, 3),
      );

      final updated = await invoices.fetch(businessId: 'biz_1', invoiceId: 'inv_1');
      expect(updated?.status, InvoiceStatus.paid);
      expect(updated?.outstanding.minorUnits, 0);
    });
  });
}
