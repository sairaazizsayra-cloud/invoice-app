import 'dart:async';

import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/models/invoice.dart';
import 'package:invoice_pro/models/payment.dart';
import 'package:invoice_pro/repositories/invoice_repository.dart';
import 'package:invoice_pro/repositories/payment_repository.dart';

class InMemoryPaymentRepository implements PaymentRepository {
  InMemoryPaymentRepository({
    required InvoiceRepository invoices,
    List<Payment>? payments,
  }) : _invoices = invoices,
       _payments = [...?payments],
       _nextId = (payments?.length ?? 0) + 1;

  final InvoiceRepository _invoices;
  final List<Payment> _payments;
  final StreamController<List<Payment>> _controller = StreamController<List<Payment>>.broadcast();
  int _nextId;

  static Payment sample({
    String id = 'pay_1',
    Invoice? invoice,
    int amountMinor = 100000,
    PaymentMethod method = PaymentMethod.cash,
    DateTime? paidAt,
  }) {
    final source = invoice ??
        Invoice.fromMap('inv_1', {
          'businessId': 'biz_1',
          'invoiceNumber': 'INV-00001',
          'customerId': 'cus_1',
          'customerName': 'Ali Store',
          'currencyCode': 'PKR',
        });
    return Payment.fromInvoice(
      id: id,
      invoice: source,
      amountMinor: amountMinor,
      method: method,
      paidAt: paidAt ?? DateTime(2026, 9, 3),
    );
  }

  @override
  String newId(String businessId) {
    final id = 'pay_$_nextId';
    _nextId += 1;
    return id;
  }

  List<Payment> _forBusiness(String businessId) {
    final list = _payments.where((payment) => payment.businessId == businessId).toList()
      ..sort((a, b) => b.paidAt.compareTo(a.paidAt));
    return list;
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List<Payment>.from(_payments));
    }
  }

  @override
  Stream<List<Payment>> watchAll(
    String businessId, {
    int limit = AppConstants.listPageSize,
  }) async* {
    List<Payment> page() => _forBusiness(businessId).take(limit).toList();
    yield page();
    yield* _controller.stream.map((_) => page());
  }

  @override
  Future<Payment> record({
    required Invoice invoice,
    required int amountMinor,
    required PaymentMethod method,
    required DateTime paidAt,
    String notes = '',
  }) async {
    final live = await _invoices.fetch(businessId: invoice.businessId, invoiceId: invoice.id) ?? invoice;
    if (!live.canRecordPayment) {
      throw const AppException(AppStrings.cannotRecordPayment, debugCode: 'payment-locked');
    }
    if (amountMinor <= 0) {
      throw const AppException(AppStrings.amountMustBePositive, debugCode: 'payment-amount');
    }
    if (amountMinor > live.outstanding.minorUnits) {
      throw const AppException(AppStrings.paymentExceedsOutstanding, debugCode: 'payment-overpay');
    }
    final payment = Payment.fromInvoice(
      id: newId(live.businessId),
      invoice: live,
      amountMinor: amountMinor,
      method: method,
      paidAt: paidAt,
      notes: notes,
    );
    await _invoices.update(live.applyPaymentAmount(amountMinor));
    _payments.add(payment);
    _emit();
    return payment;
  }

  @override
  Future<void> delete(Payment payment) async {
    final live = await _invoices.fetch(businessId: payment.businessId, invoiceId: payment.invoiceId);
    if (live != null) {
      if (live.isDraft || live.isCancelled) {
        throw const AppException(AppStrings.cannotDeletePayment, debugCode: 'payment-locked');
      }
      await _invoices.update(live.revertPaymentAmount(payment.amountMinor));
    }
    _payments.removeWhere((item) => item.id == payment.id);
    _emit();
  }

  void dispose() {
    unawaited(_controller.close());
  }
}
