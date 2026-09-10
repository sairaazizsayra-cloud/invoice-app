import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/models/expense.dart';

abstract class ExpenseRepository {
  String newId(String businessId);

  Stream<List<Expense>> watchAll(
    String businessId, {
    int limit = AppConstants.listPageSize,
  });

  Future<Expense?> fetch({required String businessId, required String expenseId});

  Future<Expense> create(Expense expense);

  Future<void> update(Expense expense);

  Future<void> delete(Expense expense);
}
