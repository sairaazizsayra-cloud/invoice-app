import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/constants/firestore_paths.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/utils/app_logger.dart';
import 'package:invoice_pro/core/utils/customer_ledger.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/models/customer.dart';
import 'package:invoice_pro/models/dashboard_models.dart';
import 'package:invoice_pro/repositories/customer_repository.dart';

class FirebaseCustomerRepository implements CustomerRepository {
  FirebaseCustomerRepository({FirebaseFirestore? firestore}) : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore get _firestore => _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String businessId) {
    return _firestore.collection(FirestorePaths.customers(businessId));
  }

  DocumentReference<Map<String, dynamic>> _doc(String businessId, String customerId) {
    return _firestore.doc(FirestorePaths.customer(businessId, customerId));
  }

  @override
  String newId(String businessId) => _collection(businessId).doc().id;

  @override
  Stream<List<Customer>> watchAll(
    String businessId, {
    int limit = AppConstants.listPageSize,
  }) {
    return _collection(businessId).orderBy('nameLower').limit(limit).snapshots().map((snapshot) {
      return [
        for (final doc in snapshot.docs) Customer.fromMap(doc.id, doc.data()),
      ];
    });
  }

  @override
  Future<Customer?> fetch({required String businessId, required String customerId}) async {
    final snapshot = await _doc(businessId, customerId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return Customer.fromMap(snapshot.id, data);
  }

  @override
  Future<Customer> create(Customer customer) async {
    try {
      await _doc(customer.businessId, customer.id).set(customer.toCreateMap());
      return customer;
    } on FirebaseException catch (error, stack) {
      AppLogger.error('Customer create failed', error, stack);
      throw AppException(AppStrings.somethingWentWrong, debugCode: error.code, cause: error);
    }
  }

  @override
  Future<void> update(Customer customer) async {
    try {
      await _doc(customer.businessId, customer.id).update(customer.toUpdateMap());
    } on FirebaseException catch (error, stack) {
      AppLogger.error('Customer update failed', error, stack);
      throw AppException(AppStrings.somethingWentWrong, debugCode: error.code, cause: error);
    }
  }

  @override
  Future<void> delete(Customer customer) async {
    try {
      final linked = await _firestore
          .collection(FirestorePaths.invoices(customer.businessId))
          .where('customerId', isEqualTo: customer.id)
          .limit(1)
          .get();
      if (linked.docs.isNotEmpty) {
        throw const AppException(AppStrings.cannotDeleteCustomer, debugCode: 'customer-has-invoices');
      }
      await _doc(customer.businessId, customer.id).delete();
    } on AppException {
      rethrow;
    } on FirebaseException catch (error, stack) {
      AppLogger.error('Customer delete failed', error, stack);
      throw AppException(AppStrings.somethingWentWrong, debugCode: error.code, cause: error);
    }
  }

  @override
  Future<CustomerLedger> loadLedger({
    required String businessId,
    required String customerId,
    required String currencyCode,
  }) async {
    final invoices = await _readCustomerInvoices(businessId, customerId, currencyCode);
    final payments = await _readCustomerPayments(businessId, customerId, currencyCode);
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
    try {
      final snapshot =
          await _firestore.collection(FirestorePaths.invoices(businessId)).limit(AppConstants.dashboardQueryLimit).get();
      final invoices = [
        for (final doc in snapshot.docs) InvoiceRecord.fromMap(doc.id, doc.data(), currencyCode: currencyCode),
      ];
      return CustomerLedger.outstandingByCustomer(currencyCode: currencyCode, invoices: invoices);
    } catch (error, stack) {
      AppLogger.error('Customer outstanding query failed', error, stack);
      return const {};
    }
  }

  Future<List<InvoiceRecord>> _readCustomerInvoices(
    String businessId,
    String customerId,
    String currencyCode,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.invoices(businessId))
          .where('customerId', isEqualTo: customerId)
          .orderBy('issueDate', descending: true)
          .limit(100)
          .get();
      return [
        for (final doc in snapshot.docs)
          InvoiceRecord.fromMap(doc.id, doc.data(), currencyCode: currencyCode),
      ];
    } catch (error, stack) {
      AppLogger.error('Customer invoice history query failed', error, stack);
      return const [];
    }
  }

  Future<List<PaymentRecord>> _readCustomerPayments(
    String businessId,
    String customerId,
    String currencyCode,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.payments(businessId))
          .where('customerId', isEqualTo: customerId)
          .orderBy('paidAt', descending: true)
          .limit(100)
          .get();
      return [
        for (final doc in snapshot.docs)
          PaymentRecord.fromMap(doc.id, doc.data(), currencyCode: currencyCode),
      ];
    } catch (error, stack) {
      AppLogger.error('Customer payment history query failed', error, stack);
      return const [];
    }
  }
}
