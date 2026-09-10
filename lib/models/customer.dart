import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invoice_pro/models/app_user.dart';

class Customer {
  const Customer({
    required this.id,
    required this.businessId,
    required this.name,
    this.company = '',
    this.email = '',
    this.phone = '',
    this.address = '',
    this.city = '',
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String businessId;
  final String name;
  final String company;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get nameLower => name.trim().toLowerCase();

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'C';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  String get subtitle {
    if (company.trim().isNotEmpty) return company.trim();
    if (phone.trim().isNotEmpty) return phone.trim();
    if (email.trim().isNotEmpty) return email.trim();
    return city.trim();
  }

  bool matches(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return name.toLowerCase().contains(needle) ||
        company.toLowerCase().contains(needle) ||
        email.toLowerCase().contains(needle) ||
        phone.toLowerCase().contains(needle) ||
        city.toLowerCase().contains(needle) ||
        notes.toLowerCase().contains(needle);
  }

  Customer copyWith({
    String? id,
    String? businessId,
    String? name,
    String? company,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? notes,
  }) {
    return Customer(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      company: company ?? this.company,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'id': id,
      'businessId': businessId,
      'name': name,
      'nameLower': nameLower,
      'company': company,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'nameLower': nameLower,
      'company': company,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Customer.fromMap(String id, Map<String, dynamic> data) {
    return Customer(
      id: data['id'] as String? ?? id,
      businessId: data['businessId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      company: data['company'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      address: data['address'] as String? ?? '',
      city: data['city'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
      createdAt: AppUser.dateTimeFrom(data['createdAt']),
      updatedAt: AppUser.dateTimeFrom(data['updatedAt']),
    );
  }
}
