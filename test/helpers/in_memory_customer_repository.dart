import 'dart:async';

import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/utils/customer_ledger.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/models/customer.dart';
import 'package:invoice_pro/models/dashboard_models.dart';
import 'package:invoice_pro/repositories/customer_repository.dart';

class InMemoryCustomerRepository implements CustomerRepository {
  InMemoryCustomerRepository({
    List<Customer>? customers,
    List<InvoiceRecord>? invoices,
    List<PaymentRecord>? payments,
  }) : _customers = [...?customers],
       _invoices = [...?invoices],
       _payments = [...?payments],
       _next = (customers?.length ?? 0) + 1;

  final List<Customer> _customers;
  final List<InvoiceRecord> _invoices;
  final List<PaymentRecord> _payments;
  final StreamController<List<Customer>> _controller = StreamController<List<Customer>>.broadcast();
  int _next;

  static Customer sample({
    String id = 'cus_1',
    String businessId = 'biz_1',
    String name = 'Ali Store',
    String? company,
    String email = 'ali@store.pk',
    String phone = '03001112233',
    String city = 'Lahore',
  }) {
    return Customer(
      id: id,
      businessId: businessId,
      name: name,
      company: company ?? '',
      email: email,
      phone: phone,
      city: city,
    );
  }

  @override
  String newId(String businessId) {
    final id = 'cus_$_next';
    _next += 1;
    return id;
  }

  List<Customer> _forBusiness(String businessId) {
    final list = _customers.where((customer) => customer.businessId == businessId).toList()
      ..sort((a, b) => a.nameLower.compareTo(b.nameLower));
    return list;
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List<Customer>.from(_customers));
    }
  }

  @override
  Stream<List<Customer>> watchAll(
    String businessId, {
    int limit = AppConstants.listPageSize,
  }) async* {
    List<Customer> page() => _forBusiness(businessId).take(limit).toList();
    yield page();
    yield* _controller.stream.map((_) => page());
  }

  @override
  Future<Customer?> fetch({required String businessId, required String customerId}) async {
    for (final customer in _customers) {
      if (customer.businessId == businessId && customer.id == customerId) return customer;
    }
    return null;
  }

  @override
  Future<Customer> create(Customer customer) async {
    _customers.add(customer);
    _emit();
    return customer;
  }

  @override
  Future<void> update(Customer customer) async {
    final index = _customers.indexWhere((item) => item.id == customer.id);
    if (index >= 0) {
      _customers[index] = customer;
      _emit();
    }
  }

  @override
  Future<void> delete(Customer customer) async {
    final ledger = await loadLedger(
      businessId: customer.businessId,
      customerId: customer.id,
      currencyCode: 'PKR',
    );
    if (ledger.invoices.isNotEmpty) {
      throw const AppException(AppStrings.cannotDeleteCustomer, debugCode: 'customer-has-invoices');
    }
    _customers.removeWhere((item) => item.id == customer.id);
    _emit();
  }

  @override
  Future<CustomerLedger> loadLedger({
    required String businessId,
    required String customerId,
    required String currencyCode,
  }) async {
    final invoices = _invoices.where((invoice) => invoice.customerId == customerId).toList();
    final payments = _payments.where((payment) => payment.customerId == customerId).toList();
    return CustomerLedger.fromRecords(
      currencyCode: currencyCode,
      invoices: invoices,
      payments: payments,
    );
  }

  @override
  Future<Map<String, Money>> outstandingByCustomer({
    required String businessId,
    required String currencyCode,
  }) async {
    return CustomerLedger.outstandingByCustomer(currencyCode: currencyCode, invoices: _invoices);
  }

  void dispose() {
    unawaited(_controller.close());
  }
}
