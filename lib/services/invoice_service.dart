import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/auth_exception.dart';
import 'package:invoice_pro/firebase/firebase_bootstrap.dart';
import 'package:invoice_pro/models/business.dart';
import 'package:invoice_pro/models/invoice.dart';
import 'package:invoice_pro/repositories/firebase_invoice_repository.dart';
import 'package:invoice_pro/repositories/invoice_repository.dart';

InvoiceRepository createInvoiceRepository() {
  if (!FirebaseBootstrap.initialized) {
    return UnconfiguredInvoiceRepository();
  }
  return FirebaseInvoiceRepository();
}

class UnconfiguredInvoiceRepository implements InvoiceRepository {
  static const _notConfigured = AuthException(
    AppStrings.authFirebaseNotConfigured,
    debugCode: 'firebase-unconfigured',
  );

  @override
  String newId(String businessId) => 'unconfigured';

  @override
  Stream<List<Invoice>> watchAll(
    String businessId, {
    int limit = AppConstants.listPageSize,
  }) async* {
    yield const [];
  }

  @override
  Future<Invoice?> fetch({required String businessId, required String invoiceId}) async => null;

  @override
  Future<Invoice> create({required Invoice invoice, required Business business}) async =>
      throw _notConfigured;

  @override
  Future<void> update(Invoice invoice) async => throw _notConfigured;

  @override
  Future<void> delete(Invoice invoice) async => throw _notConfigured;
}
