import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/utils/app_logger.dart';
import 'package:invoice_pro/models/expense.dart';
import 'package:invoice_pro/repositories/expense_repository.dart';

enum ExpenseListFilter { all, rent, salary, electricity, transport, marketing, inventory, other }

class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider(this._repository);

  final ExpenseRepository _repository;

  StreamSubscription<List<Expense>>? _subscription;
  String? _businessId;
  String _currencyCode = AppConstants.defaultCurrencyCode;
  List<Expense> _expenses = const [];
  String _query = '';
  ExpenseListFilter _filter = ExpenseListFilter.all;
  int _pageSize = AppConstants.listPageSize;
  bool _hasMore = false;
  bool _loading = false;
  bool _loadingMore = false;
  bool _saving = false;
  String? _error;

  String? get businessId => _businessId;
  String get currencyCode => _currencyCode;
  List<Expense> get allExpenses => _expenses;
  String get query => _query;
  ExpenseListFilter get filter => _filter;
  bool get hasMore => _hasMore;
  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;
  bool get isSaving => _saving;
  String? get error => _error;

  List<Expense> get visibleExpenses {
    var list = _expenses;
    if (_query.trim().isNotEmpty) {
      list = list.where((expense) => expense.matches(_query)).toList();
    }
    if (_filter != ExpenseListFilter.all) {
      final category = _categoryFor(_filter);
      list = list.where((expense) => expense.category == category).toList();
    }
    return list;
  }

  Expense? byId(String expenseId) {
    for (final expense in _expenses) {
      if (expense.id == expenseId) return expense;
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
      _expenses = const [];
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
        _expenses = value;
        _hasMore = value.length >= _pageSize;
        _loading = false;
        _loadingMore = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object error, StackTrace stack) {
        AppLogger.error('Expense watch failed', error, stack);
        _loading = false;
        _loadingMore = false;
        _error = 'Could not load expenses.';
        notifyListeners();
      },
    );
  }

  void setQuery(String value) {
    if (value == _query) return;
    _query = value;
    notifyListeners();
  }

  void setFilter(ExpenseListFilter value) {
    if (value == _filter) return;
    _filter = value;
    notifyListeners();
  }

  Future<Expense> save(Expense draft) async {
    if (draft.title.trim().length < 2) {
      throw const AppException(AppStrings.nameTooShort, debugCode: 'expense-title');
    }
    if (draft.amountMinor <= 0) {
      throw const AppException(AppStrings.amountMustBePositive, debugCode: 'expense-amount');
    }
    _saving = true;
    notifyListeners();
    try {
      final existing = byId(draft.id);
      if (existing == null) {
        final created = await _repository.create(draft);
        _expenses = [created, ..._expenses.where((item) => item.id != created.id)]
          ..sort((a, b) => b.date.compareTo(a.date));
        return created;
      }
      await _repository.update(draft);
      _expenses = [
        for (final item in _expenses)
          if (item.id == draft.id) draft else item,
      ]..sort((a, b) => b.date.compareTo(a.date));
      return draft;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> delete(Expense expense) async {
    _saving = true;
    notifyListeners();
    try {
      await _repository.delete(expense);
      _expenses = _expenses.where((item) => item.id != expense.id).toList();
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  String nextId() {
    final businessId = _businessId;
    if (businessId == null || businessId.isEmpty) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
    return _repository.newId(businessId);
  }

  ExpenseCategory _categoryFor(ExpenseListFilter filter) {
    switch (filter) {
      case ExpenseListFilter.all:
        return ExpenseCategory.other;
      case ExpenseListFilter.rent:
        return ExpenseCategory.rent;
      case ExpenseListFilter.salary:
        return ExpenseCategory.salary;
      case ExpenseListFilter.electricity:
        return ExpenseCategory.electricity;
      case ExpenseListFilter.transport:
        return ExpenseCategory.transport;
      case ExpenseListFilter.marketing:
        return ExpenseCategory.marketing;
      case ExpenseListFilter.inventory:
        return ExpenseCategory.inventory;
      case ExpenseListFilter.other:
        return ExpenseCategory.other;
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
