import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/utils/app_logger.dart';
import 'package:invoice_pro/core/utils/customer_ledger.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/models/customer.dart';
import 'package:invoice_pro/repositories/customer_repository.dart';

enum CustomerListFilter { all, outstanding, hasEmail }

class CustomerProvider extends ChangeNotifier {
  CustomerProvider(this._repository);

  final CustomerRepository _repository;

  StreamSubscription<List<Customer>>? _subscription;
  String? _businessId;
  String _currencyCode = AppConstants.defaultCurrencyCode;
  List<Customer> _customers = const [];
  Map<String, Money> _outstanding = const {};
  String _query = '';
  CustomerListFilter _filter = CustomerListFilter.all;
  int _pageSize = AppConstants.listPageSize;
  bool _hasMore = false;
  bool _loading = false;
  bool _loadingMore = false;
  bool _saving = false;
  String? _error;

  String? get businessId => _businessId;
  List<Customer> get allCustomers => _customers;
  String get query => _query;
  CustomerListFilter get filter => _filter;
  bool get hasMore => _hasMore;
  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;
  bool get isSaving => _saving;
  String? get error => _error;

  List<Customer> get visibleCustomers {
    var list = _customers;
    if (_query.trim().isNotEmpty) {
      list = list.where((customer) => customer.matches(_query)).toList();
    }
    switch (_filter) {
      case CustomerListFilter.all:
        break;
      case CustomerListFilter.outstanding:
        list = list.where((customer) => outstandingOf(customer.id).isPositive).toList();
      case CustomerListFilter.hasEmail:
        list = list.where((customer) => customer.email.trim().isNotEmpty).toList();
    }
    return list;
  }

  Money outstandingOf(String customerId) {
    return _outstanding[customerId] ?? Money.zero(currencyCode: _currencyCode);
  }

  Customer? byId(String customerId) {
    for (final customer in _customers) {
      if (customer.id == customerId) return customer;
    }
    return null;
  }

  void bind({String? businessId, String currencyCode = AppConstants.defaultCurrencyCode}) {
    _currencyCode = currencyCode;
    if (businessId == _businessId && _subscription != null) return;
    unawaited(_resubscribe(businessId, resetPageSize: true));
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore || _businessId == null || _businessId!.isEmpty) return;
    _loadingMore = true;
    notifyListeners();
    _pageSize += AppConstants.listPageSize;
    await _resubscribe(_businessId, resetPageSize: false, showFullLoading: false);
  }

  Future<void> _resubscribe(
    String? businessId, {
    required bool resetPageSize,
    bool showFullLoading = true,
  }) async {
    await _subscription?.cancel();
    _subscription = null;
    _businessId = businessId;
    if (resetPageSize) {
      _pageSize = AppConstants.listPageSize;
      _customers = const [];
      _outstanding = const {};
    }
    _error = null;

    if (businessId == null || businessId.isEmpty) {
      _loading = false;
      _loadingMore = false;
      _hasMore = false;
      notifyListeners();
      return;
    }

    if (showFullLoading) {
      _loading = true;
      notifyListeners();
    }
    _subscription = _repository.watchAll(businessId, limit: _pageSize).listen(
      (value) {
        _customers = value;
        _hasMore = value.length >= _pageSize;
        _loading = false;
        _loadingMore = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object error, StackTrace stack) {
        AppLogger.error('Customer watch failed', error, stack);
        _loading = false;
        _loadingMore = false;
        _error = 'Could not load customers.';
        notifyListeners();
      },
    );
    await _refreshOutstanding(businessId);
  }

  Future<void> _refreshOutstanding(String businessId) async {
    try {
      _outstanding = await _repository.outstandingByCustomer(
        businessId: businessId,
        currencyCode: _currencyCode,
      );
      notifyListeners();
    } catch (error, stack) {
      AppLogger.error('Customer outstanding refresh failed', error, stack);
    }
  }

  void setQuery(String value) {
    if (value == _query) return;
    _query = value;
    notifyListeners();
  }

  void setFilter(CustomerListFilter value) {
    if (value == _filter) return;
    _filter = value;
    notifyListeners();
  }

  Future<Customer> save(Customer draft) async {
    final businessId = draft.businessId;
    _saving = true;
    notifyListeners();
    try {
      final existing = byId(draft.id);
      if (existing == null) {
        await _repository.create(draft);
      } else {
        await _repository.update(draft);
      }
      return draft;
    } finally {
      _saving = false;
      notifyListeners();
      if (businessId.isNotEmpty) {
        unawaited(_refreshOutstanding(businessId));
      }
    }
  }

  Future<void> delete(Customer customer) async {
    _saving = true;
    notifyListeners();
    try {
      await _repository.delete(customer);
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<CustomerLedger> ledgerFor(Customer customer) {
    return _repository.loadLedger(
      businessId: customer.businessId,
      customerId: customer.id,
      currencyCode: _currencyCode,
    );
  }

  Future<void> refreshOutstanding() async {
    final businessId = _businessId;
    if (businessId == null || businessId.isEmpty) return;
    await _refreshOutstanding(businessId);
  }

  String nextId() {
    final businessId = _businessId;
    if (businessId == null || businessId.isEmpty) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
    return _repository.newId(businessId);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
