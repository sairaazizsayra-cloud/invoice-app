import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/constants/firestore_paths.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/utils/app_logger.dart';
import 'package:invoice_pro/models/expense.dart';
import 'package:invoice_pro/repositories/expense_repository.dart';

class FirebaseExpenseRepository implements ExpenseRepository {
  FirebaseExpenseRepository({FirebaseFirestore? firestore}) : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore get _firestore => _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String businessId) {
    return _firestore.collection(FirestorePaths.expenses(businessId));
  }

  DocumentReference<Map<String, dynamic>> _doc(String businessId, String expenseId) {
    return _firestore.doc(FirestorePaths.expense(businessId, expenseId));
  }

  @override
  String newId(String businessId) => _collection(businessId).doc().id;

  @override
  Stream<List<Expense>> watchAll(
    String businessId, {
    int limit = AppConstants.listPageSize,
  }) {
    return _collection(businessId)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return [for (final doc in snapshot.docs) Expense.fromMap(doc.id, doc.data())];
        });
  }

  @override
  Future<Expense?> fetch({required String businessId, required String expenseId}) async {
    final snapshot = await _doc(businessId, expenseId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return Expense.fromMap(snapshot.id, data);
  }

  @override
  Future<Expense> create(Expense expense) async {
    try {
      await _doc(expense.businessId, expense.id).set(expense.toCreateMap());
      return expense;
    } on FirebaseException catch (error, stack) {
      AppLogger.error('Expense create failed', error, stack);
      throw AppException(AppStrings.somethingWentWrong, debugCode: error.code, cause: error);
    }
  }

  @override
  Future<void> update(Expense expense) async {
    try {
      await _doc(expense.businessId, expense.id).update(expense.toUpdateMap());
    } on FirebaseException catch (error, stack) {
      AppLogger.error('Expense update failed', error, stack);
      throw AppException(AppStrings.somethingWentWrong, debugCode: error.code, cause: error);
    }
  }

  @override
  Future<void> delete(Expense expense) async {
    try {
      await _doc(expense.businessId, expense.id).delete();
    } on FirebaseException catch (error, stack) {
      AppLogger.error('Expense delete failed', error, stack);
      throw AppException(AppStrings.somethingWentWrong, debugCode: error.code, cause: error);
    }
  }
}
