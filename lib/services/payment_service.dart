import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/auth_exception.dart';
import 'package:invoice_pro/firebase/firebase_bootstrap.dart';
import 'package:invoice_pro/models/invoice.dart';
import 'package:invoice_pro/models/payment.dart';
import 'package:invoice_pro/repositories/firebase_payment_repository.dart';
import 'package:invoice_pro/repositories/payment_repository.dart';

PaymentRepository createPaymentRepository() {
  if (!FirebaseBootstrap.initialized) {
    return UnconfiguredPaymentRepository();
  }
  return FirebasePaymentRepository();
}

class UnconfiguredPaymentRepository implements PaymentRepository {
  static const _notConfigured = AuthException(
    AppStrings.authFirebaseNotConfigured,
    debugCode: 'firebase-unconfigured',
  );

  @override
  String newId(String businessId) => 'unconfigured';

  @override
  Stream<List<Payment>> watchAll(
    String businessId, {
    int limit = AppConstants.listPageSize,
  }) async* {
    yield const [];
  }

  @override
  Future<Payment> record({
    required Invoice invoice,
    required int amountMinor,
    required PaymentMethod method,
    required DateTime paidAt,
    String notes = '',
  }) async =>
      throw _notConfigured;

  @override
  Future<void> delete(Payment payment) async => throw _notConfigured;
}
