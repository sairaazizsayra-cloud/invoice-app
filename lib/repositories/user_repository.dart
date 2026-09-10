import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/constants/firestore_paths.dart';
import 'package:invoice_pro/core/constants/user_roles.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/errors/auth_exception.dart';
import 'package:invoice_pro/models/app_user.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore}) : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore get _firestore => _firestoreOverride ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) {
    return _firestore.doc(FirestorePaths.user(uid));
  }

  Future<AppUser?> fetch(String uid) async {
    final snapshot = await _doc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return AppUser.fromMap(snapshot.data()!);
  }

  Future<void> create(AppUser user) async {
    await _doc(user.uid).set(user.toCreateMap(), SetOptions(merge: true));
  }

  Future<void> upsertIfMissing(AppUser user) async {
    final existing = await fetch(user.uid);
    if (existing == null) {
      await create(user);
    }
  }

  Future<void> syncEmailVerified({required String uid, required bool verified}) async {
    await _doc(uid).update({
      'emailVerified': verified,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setBusinessId({required String uid, required String businessId}) async {
    await _doc(uid).update({
      'businessId': businessId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateOwnerDetails({
    required String uid,
    required String name,
    required String businessName,
    required String phone,
  }) async {
    await _doc(uid).update({
      'name': name,
      'businessName': businessName,
      'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveFcmToken({required String uid, required String token}) async {
    await _doc(uid).update({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void assertActive(AppUser user) {
    if (!user.isActive) {
      throw const AuthException(AppStrings.authUserDisabled, debugCode: 'user-disabled');
    }
    if (user.role != UserRoles.businessOwner) {
      throw const AppException(AppStrings.somethingWentWrong, debugCode: 'role-denied');
    }
  }
}
