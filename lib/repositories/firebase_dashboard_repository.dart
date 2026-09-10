import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/firestore_paths.dart';
import 'package:invoice_pro/core/utils/app_logger.dart';
import 'package:invoice_pro/core/utils/dashboard_calculator.dart';
import 'package:invoice_pro/models/business.dart';
import 'package:invoice_pro/models/dashboard_models.dart';
import 'package:invoice_pro/models/date_range.dart';
import 'package:invoice_pro/repositories/dashboard_repository.dart';

class FirebaseDashboardRepository implements DashboardRepository {
  FirebaseDashboardRepository({FirebaseFirestore? firestore}) : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore get _firestore => _firestoreOverride ?? FirebaseFirestore.instance;

  @override
  Future<DashboardSnapshot> load({
    required Business business,
    required DateRange range,
    required DateTime now,
  }) async {
    final currency = business.currencyCode;
    final invoices = await _readInvoices(business.id, range, currency);
    final payments = await _readPayments(business.id, range, currency);
    final expenses = await _readExpenses(business.id, range, currency);
    final customerCount = await _count(FirestorePaths.customers(business.id));
    final productCount = await _count(FirestorePaths.products(business.id));

    return DashboardCalculator.calculate(
      range: range,
      now: now,
      currencyCode: currency,
      invoices: invoices,
      payments: payments,
      expenses: expenses,
      customerCount: customerCount,
      productCount: productCount,
    );
  }

  Future<List<InvoiceRecord>> _readInvoices(
    String businessId,
    DateRange range,
    String currency,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.invoices(businessId))
          .where('issueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
          .where('issueDate', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
          .orderBy('issueDate', descending: true)
          .limit(AppConstants.dashboardQueryLimit)
          .get();
      return [
        for (final doc in snapshot.docs) InvoiceRecord.fromMap(doc.id, doc.data(), currencyCode: currency),
      ];
    } catch (error, stack) {
      AppLogger.error('Dashboard invoice query failed', error, stack);
      return const [];
    }
  }

  Future<List<PaymentRecord>> _readPayments(
    String businessId,
    DateRange range,
    String currency,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.payments(businessId))
          .where('paidAt', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
          .where('paidAt', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
          .orderBy('paidAt', descending: true)
          .limit(AppConstants.dashboardQueryLimit)
          .get();
      return [
        for (final doc in snapshot.docs) PaymentRecord.fromMap(doc.id, doc.data(), currencyCode: currency),
      ];
    } catch (error, stack) {
      AppLogger.error('Dashboard payment query failed', error, stack);
      return const [];
    }
  }

  Future<List<ExpenseRecord>> _readExpenses(
    String businessId,
    DateRange range,
    String currency,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.expenses(businessId))
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
          .orderBy('date', descending: true)
          .limit(AppConstants.dashboardQueryLimit)
          .get();
      return [
        for (final doc in snapshot.docs) ExpenseRecord.fromMap(doc.id, doc.data(), currencyCode: currency),
      ];
    } catch (error, stack) {
      AppLogger.error('Dashboard expense query failed', error, stack);
      return const [];
    }
  }

  Future<int> _count(String collectionPath) async {
    try {
      final snapshot = await _firestore.collection(collectionPath).count().get();
      return snapshot.count ?? 0;
    } catch (error, stack) {
      AppLogger.error('Dashboard count failed for $collectionPath', error, stack);
      return 0;
    }
  }
}
