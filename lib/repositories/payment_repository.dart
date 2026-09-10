import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/models/invoice.dart';
import 'package:invoice_pro/models/payment.dart';

abstract class PaymentRepository {
  String newId(String businessId);

  Stream<List<Payment>> watchAll(
    String businessId, {
    int limit = AppConstants.listPageSize,
  });

  Future<Payment> record({
    required Invoice invoice,
    required int amountMinor,
    required PaymentMethod method,
    required DateTime paidAt,
    String notes = '',
  });

  Future<void> delete(Payment payment);
}
