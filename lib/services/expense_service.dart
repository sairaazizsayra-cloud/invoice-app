import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/auth_exception.dart';
import 'package:invoice_pro/firebase/firebase_bootstrap.dart';
import 'package:invoice_pro/models/expense.dart';
import 'package:invoice_pro/repositories/expense_repository.dart';
import 'package:invoice_pro/repositories/firebase_expense_repository.dart';

ExpenseRepository createExpenseRepository() {
  if (!FirebaseBootstrap.initialized) {
    return UnconfiguredExpenseRepository();
  }
  return FirebaseExpenseRepository();
}

class UnconfiguredExpenseRepository implements ExpenseRepository {
  static const _notConfigured = AuthException(
    AppStrings.authFirebaseNotConfigured,
    debugCode: 'firebase-unconfigured',
  );

  @override
  String newId(String businessId) => 'unconfigured';

  @override
  Stream<List<Expense>> watchAll(
    String businessId, {
    int limit = AppConstants.listPageSize,
  }) async* {
    yield const [];
  }

  @override
  Future<Expense?> fetch({required String businessId, required String expenseId}) async => null;

  @override
  Future<Expense> create(Expense expense) async => throw _notConfigured;

  @override
  Future<void> update(Expense expense) async => throw _notConfigured;

  @override
  Future<void> delete(Expense expense) async => throw _notConfigured;
}
