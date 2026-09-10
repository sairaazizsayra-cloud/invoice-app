import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/models/app_user.dart';

class Business {
  const Business({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.ownerName,
    required this.email,
    required this.phone,
    this.logoUrl,
    this.address = '',
    this.city = '',
    this.website = '',
    this.taxNumber = '',
    this.currencyCode = AppConstants.defaultCurrencyCode,
    this.defaultTaxPercentMinor = AppConstants.defaultTaxPercentMinor,
    this.invoicePrefix = AppConstants.defaultInvoicePrefix,
    this.invoiceNextNumber = AppConstants.defaultInvoiceStartNumber,
    this.paymentInstructions = '',
    this.termsAndConditions = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String name;
  final String ownerName;
  final String email;
  final String phone;
  final String? logoUrl;
  final String address;
  final String city;
  final String website;
  final String taxNumber;
  final String currencyCode;
  final int defaultTaxPercentMinor;
  final String invoicePrefix;
  final int invoiceNextNumber;
  final String paymentInstructions;
  final String termsAndConditions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Business.fromOwner({
    required String id,
    required AppUser owner,
  }) {
    return Business(
      id: id,
      ownerId: owner.uid,
      name: owner.businessName.trim().isEmpty ? owner.name : owner.businessName.trim(),
      ownerName: owner.name,
      email: owner.email,
      phone: owner.phone,
    );
  }

  Business copyWith({
    String? name,
    String? ownerName,
    String? email,
    String? phone,
    String? logoUrl,
    bool clearLogo = false,
    String? address,
    String? city,
    String? website,
    String? taxNumber,
    String? currencyCode,
    int? defaultTaxPercentMinor,
    String? invoicePrefix,
    int? invoiceNextNumber,
    String? paymentInstructions,
    String? termsAndConditions,
  }) {
    return Business(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      ownerName: ownerName ?? this.ownerName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      logoUrl: clearLogo ? null : (logoUrl ?? this.logoUrl),
      address: address ?? this.address,
      city: city ?? this.city,
      website: website ?? this.website,
      taxNumber: taxNumber ?? this.taxNumber,
      currencyCode: currencyCode ?? this.currencyCode,
      defaultTaxPercentMinor: defaultTaxPercentMinor ?? this.defaultTaxPercentMinor,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      invoiceNextNumber: invoiceNextNumber ?? this.invoiceNextNumber,
      paymentInstructions: paymentInstructions ?? this.paymentInstructions,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'ownerName': ownerName,
      'email': email,
      'phone': phone,
      'logoUrl': logoUrl,
      'address': address,
      'city': city,
      'website': website,
      'taxNumber': taxNumber,
      'currencyCode': currencyCode,
      'defaultTaxPercentMinor': defaultTaxPercentMinor,
      'invoicePrefix': invoicePrefix,
      'invoiceNextNumber': invoiceNextNumber,
      'paymentInstructions': paymentInstructions,
      'termsAndConditions': termsAndConditions,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'ownerName': ownerName,
      'email': email,
      'phone': phone,
      'logoUrl': logoUrl,
      'address': address,
      'city': city,
      'website': website,
      'taxNumber': taxNumber,
      'currencyCode': currencyCode,
      'defaultTaxPercentMinor': defaultTaxPercentMinor,
      'invoicePrefix': invoicePrefix,
      'invoiceNextNumber': invoiceNextNumber,
      'paymentInstructions': paymentInstructions,
      'termsAndConditions': termsAndConditions,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Business.fromMap(String id, Map<String, dynamic> data) {
    return Business(
      id: data['id'] as String? ?? id,
      ownerId: data['ownerId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      logoUrl: data['logoUrl'] as String?,
      address: data['address'] as String? ?? '',
      city: data['city'] as String? ?? '',
      website: data['website'] as String? ?? '',
      taxNumber: data['taxNumber'] as String? ?? '',
      currencyCode: data['currencyCode'] as String? ?? AppConstants.defaultCurrencyCode,
      defaultTaxPercentMinor: (data['defaultTaxPercentMinor'] as num?)?.toInt() ??
          AppConstants.defaultTaxPercentMinor,
      invoicePrefix: data['invoicePrefix'] as String? ?? AppConstants.defaultInvoicePrefix,
      invoiceNextNumber:
          (data['invoiceNextNumber'] as num?)?.toInt() ?? AppConstants.defaultInvoiceStartNumber,
      paymentInstructions: data['paymentInstructions'] as String? ?? '',
      termsAndConditions: data['termsAndConditions'] as String? ?? '',
      createdAt: AppUser.dateTimeFrom(data['createdAt']),
      updatedAt: AppUser.dateTimeFrom(data['updatedAt']),
    );
  }
}
