import 'dart:async';

import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/models/expense.dart';
import 'package:invoice_pro/repositories/expense_repository.dart';

class InMemoryExpenseRepository implements ExpenseRepository {
  InMemoryExpenseRepository({List<Expense>? expenses})
    : _expenses = [...?expenses],
      _next = (expenses?.length ?? 0) + 1;

  final List<Expense> _expenses;
  final StreamController<List<Expense>> _controller = StreamController<List<Expense>>.broadcast();
  int _next;

  static Expense sample({
    String id = 'exp_1',
    String businessId = 'biz_1',
    String title = 'Shop rent',
    ExpenseCategory category = ExpenseCategory.rent,
    int amountMinor = 20000,
    DateTime? date,
    String description = 'September rent',
  }) {
    return Expense(
      id: id,
      businessId: businessId,
      title: title,
      category: category,
      amountMinor: amountMinor,
      date: date ?? DateTime(2026, 9, 1),
      description: description,
    );
  }

  @override
  String newId(String businessId) {
    final id = 'exp_$_next';
    _next += 1;
    return id;
  }

  List<Expense> _forBusiness(String businessId) {
    final list = _expenses.where((expense) => expense.businessId == businessId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List<Expense>.from(_expenses));
    }
  }

  @override
  Stream<List<Expense>> watchAll(
    String businessId, {
    int limit = AppConstants.listPageSize,
  }) async* {
    List<Expense> page() => _forBusiness(businessId).take(limit).toList();
    yield page();
    yield* _controller.stream.map((_) => page());
  }

  @override
  Future<Expense?> fetch({required String businessId, required String expenseId}) async {
    for (final expense in _expenses) {
      if (expense.businessId == businessId && expense.id == expenseId) return expense;
    }
    return null;
  }

  @override
  Future<Expense> create(Expense expense) async {
    _expenses.add(expense);
    _emit();
    return expense;
  }

  @override
  Future<void> update(Expense expense) async {
    final index = _expenses.indexWhere((item) => item.id == expense.id);
    if (index >= 0) {
      _expenses[index] = expense;
      _emit();
    }
  }

  @override
  Future<void> delete(Expense expense) async {
    _expenses.removeWhere((item) => item.id == expense.id);
    _emit();
  }

  void dispose() {
    unawaited(_controller.close());
  }
}
