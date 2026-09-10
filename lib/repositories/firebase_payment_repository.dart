import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/constants/firestore_paths.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/utils/app_logger.dart';
import 'package:invoice_pro/models/invoice.dart';
import 'package:invoice_pro/models/payment.dart';
import 'package:invoice_pro/repositories/payment_repository.dart';

class FirebasePaymentRepository implements PaymentRepository {
  FirebasePaymentRepository({FirebaseFirestore? firestore}) : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore get _firestore => _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String businessId) {
    return _firestore.collection(FirestorePaths.payments(businessId));
  }

  DocumentReference<Map<String, dynamic>> _paymentDoc(String businessId, String paymentId) {
    return _firestore.doc(FirestorePaths.payment(businessId, paymentId));
  }

  DocumentReference<Map<String, dynamic>> _invoiceDoc(String businessId, String invoiceId) {
    return _firestore.doc(FirestorePaths.invoice(businessId, invoiceId));
  }

  @override
  String newId(String businessId) => _collection(businessId).doc().id;

  @override
  Stream<List<Payment>> watchAll(
    String businessId, {
    int limit = AppConstants.listPageSize,
  }) {
    return _collection(businessId)
        .orderBy('paidAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return [for (final doc in snapshot.docs) Payment.fromMap(doc.id, doc.data())];
        });
  }

  @override
  Future<Payment> record({
    required Invoice invoice,
    required int amountMinor,
    required PaymentMethod method,
    required DateTime paidAt,
    String notes = '',
  }) async {
    try {
      return await _firestore.runTransaction<Payment>((transaction) async {
        final invoiceRef = _invoiceDoc(invoice.businessId, invoice.id);
        final snapshot = await transaction.get(invoiceRef);
        final data = snapshot.data();
        if (!snapshot.exists || data == null) {
          throw const AppException(AppStrings.invoiceMissing, debugCode: 'invoice-missing');
        }
        final live = Invoice.fromMap(snapshot.id, data);
        _assertCanRecord(live, amountMinor);
        final payment = Payment.fromInvoice(
          id: newId(live.businessId),
          invoice: live,
          amountMinor: amountMinor,
          method: method,
          paidAt: paidAt,
          notes: notes,
        );
        final settled = live.applyPaymentAmount(amountMinor);
        transaction.set(_paymentDoc(payment.businessId, payment.id), payment.toCreateMap());
        transaction.update(invoiceRef, settled.toSettlementMap());
        return payment;
      });
    } on AppException {
      rethrow;
    } on FirebaseException catch (error, stack) {
      AppLogger.error('Payment record failed', error, stack);
      throw AppException(AppStrings.somethingWentWrong, debugCode: error.code, cause: error);
    }
  }

  @override
  Future<void> delete(Payment payment) async {
    try {
      await _firestore.runTransaction<void>((transaction) async {
        final invoiceRef = _invoiceDoc(payment.businessId, payment.invoiceId);
        final paymentRef = _paymentDoc(payment.businessId, payment.id);
        final invoiceSnap = await transaction.get(invoiceRef);
        final paymentSnap = await transaction.get(paymentRef);
        if (!paymentSnap.exists) return;
        final invoiceData = invoiceSnap.data();
        if (invoiceSnap.exists && invoiceData != null) {
          final live = Invoice.fromMap(invoiceSnap.id, invoiceData);
          if (live.isDraft || live.isCancelled) {
            throw const AppException(AppStrings.cannotDeletePayment, debugCode: 'payment-locked');
          }
          transaction.update(invoiceRef, live.revertPaymentAmount(payment.amountMinor).toSettlementMap());
        }
        transaction.delete(paymentRef);
      });
    } on AppException {
      rethrow;
    } on FirebaseException catch (error, stack) {
      AppLogger.error('Payment delete failed', error, stack);
      throw AppException(AppStrings.somethingWentWrong, debugCode: error.code, cause: error);
    }
  }

  void _assertCanRecord(Invoice invoice, int amountMinor) {
    if (!invoice.canRecordPayment) {
      throw const AppException(AppStrings.cannotRecordPayment, debugCode: 'payment-locked');
    }
    if (amountMinor <= 0) {
      throw const AppException(AppStrings.amountMustBePositive, debugCode: 'payment-amount');
    }
    if (amountMinor > invoice.outstanding.minorUnits) {
      throw const AppException(AppStrings.paymentExceedsOutstanding, debugCode: 'payment-overpay');
    }
  }
}
