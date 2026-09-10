import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/utils/customer_ledger.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/models/customer.dart';

abstract class CustomerRepository {
  String newId(String businessId);

  Stream<List<Customer>> watchAll(
    String businessId, {
    int limit = AppConstants.listPageSize,
  });

  Future<Customer?> fetch({required String businessId, required String customerId});

  Future<Customer> create(Customer customer);

  Future<void> update(Customer customer);

  Future<void> delete(Customer customer);

  Future<CustomerLedger> loadLedger({
    required String businessId,
    required String customerId,
    required String currencyCode,
  });

  Future<Map<String, Money>> outstandingByCustomer({
    required String businessId,
    required String currencyCode,
  });
}
