import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/constants/firestore_paths.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/utils/app_logger.dart';
import 'package:invoice_pro/models/app_notification.dart';
import 'package:invoice_pro/repositories/notification_repository.dart';

class FirebaseNotificationRepository implements NotificationRepository {
  FirebaseNotificationRepository({FirebaseFirestore? firestore}) : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore get _firestore => _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String businessId) {
    return _firestore.collection(FirestorePaths.notifications(businessId));
  }

  DocumentReference<Map<String, dynamic>> _doc(String businessId, String notificationId) {
    return _firestore.doc(FirestorePaths.notification(businessId, notificationId));
  }

  @override
  Stream<List<AppNotification>> watchAll(
    String businessId, {
    int limit = AppConstants.notificationInboxLimit,
  }) {
    return _collection(businessId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return [for (final doc in snapshot.docs) AppNotification.fromMap(doc.id, doc.data())];
        });
  }

  @override
  Future<bool> upsert(AppNotification notification) async {
    try {
      final doc = _doc(notification.businessId, notification.id);
      return _firestore.runTransaction((transaction) async {
        final existing = await transaction.get(doc);
        if (existing.exists) return false;
        transaction.set(doc, notification.toCreateMap());
        return true;
      });
    } on FirebaseException catch (error, stack) {
      AppLogger.error('Notification upsert failed', error, stack);
      throw AppException(AppStrings.somethingWentWrong, debugCode: error.code, cause: error);
    }
  }

  @override
  Future<void> markRead(AppNotification notification) async {
    try {
      await _doc(notification.businessId, notification.id).update(notification.toReadUpdateMap(read: true));
    } on FirebaseException catch (error, stack) {
      AppLogger.error('Notification mark-read failed', error, stack);
      throw AppException(AppStrings.somethingWentWrong, debugCode: error.code, cause: error);
    }
  }

  @override
  Future<void> markAllRead(String businessId) async {
    try {
      final unread = await _collection(businessId).where('read', isEqualTo: false).limit(200).get();
      if (unread.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {
          'read': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } on FirebaseException catch (error, stack) {
      AppLogger.error('Notification mark-all-read failed', error, stack);
      throw AppException(AppStrings.somethingWentWrong, debugCode: error.code, cause: error);
    }
  }

  @override
  Future<void> delete(AppNotification notification) async {
    try {
      await _doc(notification.businessId, notification.id).delete();
    } on FirebaseException catch (error, stack) {
      AppLogger.error('Notification delete failed', error, stack);
      throw AppException(AppStrings.somethingWentWrong, debugCode: error.code, cause: error);
    }
  }
}
