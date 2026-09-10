import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invoice_pro/core/constants/user_roles.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.businessName,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
    required this.emailVerified,
    this.createdAt,
    this.updatedAt,
    this.businessId,
  });

  final String uid;
  final String name;
  final String businessName;
  final String email;
  final String phone;
  final String role;
  final bool isActive;
  final bool emailVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? businessId;

  bool get isBusinessOwner => role == UserRoles.businessOwner;

  AppUser copyWith({
    String? name,
    String? businessName,
    String? phone,
    bool? isActive,
    bool? emailVerified,
    DateTime? updatedAt,
    String? businessId,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      businessName: businessName ?? this.businessName,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      isActive: isActive ?? this.isActive,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      businessId: businessId ?? this.businessId,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'uid': uid,
      'name': name,
      'businessName': businessName,
      'email': email,
      'phone': phone,
      'role': UserRoles.businessOwner,
      'isActive': isActive,
      'emailVerified': emailVerified,
      'businessId': businessId ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toVerificationUpdateMap({required bool verified}) {
    return {
      'emailVerified': verified,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] as String? ?? '',
      name: data['name'] as String? ?? '',
      businessName: data['businessName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: data['role'] as String? ?? UserRoles.businessOwner,
      isActive: data['isActive'] as bool? ?? true,
      emailVerified: data['emailVerified'] as bool? ?? false,
      createdAt: dateTimeFrom(data['createdAt']),
      updatedAt: dateTimeFrom(data['updatedAt']),
      businessId: _optionalId(data['businessId']),
    );
  }

  static String? _optionalId(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime? dateTimeFrom(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return null;
  }
}

class AuthSession {
  const AuthSession({
    required this.uid,
    required this.email,
    required this.emailVerified,
    this.profile,
  });

  final String uid;
  final String email;
  final bool emailVerified;
  final AppUser? profile;

  bool get canAccessApp => emailVerified && (profile?.isActive ?? true);
}
