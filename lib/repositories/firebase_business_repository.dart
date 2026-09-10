import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invoice_pro/core/constants/firestore_paths.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/utils/app_logger.dart';
import 'package:invoice_pro/models/app_user.dart';
import 'package:invoice_pro/models/business.dart';
import 'package:invoice_pro/repositories/business_repository.dart';
import 'package:invoice_pro/repositories/user_repository.dart';

class FirebaseBusinessRepository implements BusinessRepository {
  FirebaseBusinessRepository({
    FirebaseFirestore? firestore,
    UserRepository? users,
  }) : _firestoreOverride = firestore,
       _users = users ?? UserRepository();

  final FirebaseFirestore? _firestoreOverride;
  final UserRepository _users;

  FirebaseFirestore get _firestore => _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.businesses);

  DocumentReference<Map<String, dynamic>> _doc(String businessId) =>
      _firestore.doc(FirestorePaths.business(businessId));

  @override
  String newId() => _collection.doc().id;

  @override
  Stream<Business?> watch(String businessId) {
    return _doc(businessId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return Business.fromMap(snapshot.id, data);
    });
  }

  @override
  Future<Business?> fetch(String businessId) async {
    final snapshot = await _doc(businessId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return Business.fromMap(snapshot.id, data);
  }

  @override
  Future<Business> createForOwner({required AppUser owner, String? businessId}) async {
    final id = (businessId == null || businessId.isEmpty) ? newId() : businessId;
    final business = Business.fromOwner(id: id, owner: owner);
    await _doc(id).set(business.toCreateMap());
    return business;
  }

  @override
  Future<void> update(Business business) async {
    await _doc(business.id).update(business.toUpdateMap());
  }

  @override
  Future<Business> ensureForOwner(AppUser owner) async {
    final existingId = owner.businessId;
    if (existingId != null) {
      final existing = await fetch(existingId);
      if (existing != null) {
        if (existing.ownerId != owner.uid) {
          throw const AppException('You do not have access to this business.', debugCode: 'business-forbidden');
        }
        return existing;
      }
    }

    final created = await createForOwner(owner: owner, businessId: existingId);
    try {
      await _users.setBusinessId(uid: owner.uid, businessId: created.id);
    } catch (error, stack) {
      AppLogger.error('Could not link businessId on user', error, stack);
    }
    return created;
  }
}
