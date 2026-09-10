import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/constants/firestore_paths.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/utils/app_logger.dart';
import 'package:invoice_pro/core/utils/invoice_number.dart';
import 'package:invoice_pro/models/business.dart';
import 'package:invoice_pro/models/invoice.dart';
import 'package:invoice_pro/repositories/invoice_repository.dart';

class FirebaseInvoiceRepository implements InvoiceRepository {
  FirebaseInvoiceRepository({FirebaseFirestore? firestore}) : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore get _firestore => _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String businessId) {
    return _firestore.collection(FirestorePaths.invoices(businessId));
  }

  DocumentReference<Map<String, dynamic>> _doc(String businessId, String invoiceId) {
    return _firestore.doc(FirestorePaths.invoice(businessId, invoiceId));
  }

  @override
  String newId(String businessId) => _collection(businessId).doc().id;

  @override
  Stream<List<Invoice>> watchAll(
    String businessId, {
    int limit = AppConstants.listPageSize,
  }) {
    return _collection(businessId)
        .orderBy('invoiceNumber', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return [for (final doc in snapshot.docs) Invoice.fromMap(doc.id, doc.data())];
        });
  }

  @override
  Future<Invoice?> fetch({required String businessId, required String invoiceId}) async {
    final snapshot = await _doc(businessId, invoiceId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return Invoice.fromMap(snapshot.id, data);
  }

  @override
  Future<Invoice> create({required Invoice invoice, required Business business}) async {
    try {
      final created = await _firestore.runTransaction<Invoice>((transaction) async {
        final businessRef = _firestore.doc(FirestorePaths.business(business.id));
        final businessSnap = await transaction.get(businessRef);
        final businessData = businessSnap.data();
        if (!businessSnap.exists || businessData == null) {
          throw const AppException(AppStrings.businessMissing, debugCode: 'business-missing');
        }
        final live = Business.fromMap(businessSnap.id, businessData);
        var sequence = live.invoiceNextNumber;
        if (sequence < 1) sequence = 1;
        final number = InvoiceNumberFormatter.format(number: sequence, prefix: live.invoicePrefix);
        final numbered = invoice.copyWith(invoiceNumber: number, invoiceSequence: sequence);
        transaction.set(_doc(numbered.businessId, numbered.id), numbered.toCreateMap());
        transaction.update(businessRef, {
          'invoiceNextNumber': sequence + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return numbered;
      });
      return created;
    } on AppException {
      rethrow;
    } on FirebaseException catch (error, stack) {
      AppLogger.error('Invoice create failed', error, stack);
      throw AppException(AppStrings.somethingWentWrong, debugCode: error.code, cause: error);
    }
  }

  @override
  Future<void> update(Invoice invoice) async {
    try {
      await _doc(invoice.businessId, invoice.id).update(invoice.toUpdateMap());
    } on FirebaseException catch (error, stack) {
      AppLogger.error('Invoice update failed', error, stack);
      throw AppException(AppStrings.somethingWentWrong, debugCode: error.code, cause: error);
    }
  }

  @override
  Future<void> delete(Invoice invoice) async {
    try {
      if (!invoice.canDelete) {
        throw const AppException(AppStrings.cannotDeleteInvoice, debugCode: 'invoice-locked');
      }
      await _doc(invoice.businessId, invoice.id).delete();
    } on AppException {
      rethrow;
    } on FirebaseException catch (error, stack) {
      AppLogger.error('Invoice delete failed', error, stack);
      throw AppException(AppStrings.somethingWentWrong, debugCode: error.code, cause: error);
    }
  }
}
