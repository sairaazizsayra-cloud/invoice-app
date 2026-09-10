import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/auth_exception.dart';
import 'package:invoice_pro/core/utils/customer_ledger.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/firebase/firebase_bootstrap.dart';
import 'package:invoice_pro/models/customer.dart';
import 'package:invoice_pro/repositories/customer_repository.dart';
import 'package:invoice_pro/repositories/firebase_customer_repository.dart';

CustomerRepository createCustomerRepository() {
  if (!FirebaseBootstrap.initialized) {
    return UnconfiguredCustomerRepository();
  }
  return FirebaseCustomerRepository();
}

class UnconfiguredCustomerRepository implements CustomerRepository {
  static const _notConfigured = AuthException(
    AppStrings.authFirebaseNotConfigured,
    debugCode: 'firebase-unconfigured',
  );

  @override
  String newId(String businessId) => 'unconfigured';

  @override
  Stream<List<Customer>> watchAll(
    String businessId, {
    int limit = AppConstants.listPageSize,
  }) async* {
    yield const [];
  }

  @override
  Future<Customer?> fetch({required String businessId, required String customerId}) async => null;

  @override
  Future<Customer> create(Customer customer) async => throw _notConfigured;

  @override
  Future<void> update(Customer customer) async => throw _notConfigured;

  @override
  Future<void> delete(Customer customer) async => throw _notConfigured;

  @override
  Future<CustomerLedger> loadLedger({
    required String businessId,
    required String customerId,
    required String currencyCode,
  }) async {
    return CustomerLedger.empty(currencyCode: currencyCode);
  }

  @override
  Future<Map<String, Money>> outstandingByCustomer({
    required String businessId,
    required String currencyCode,
  }) async {
    return const {};
  }
}
