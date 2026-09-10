import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/utils/date_formatter.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/models/app_user.dart';
import 'package:invoice_pro/models/dashboard_models.dart';
import 'package:invoice_pro/models/invoice.dart';

enum PaymentMethod { cash, bankTransfer, card, jazzcash, easypaisa, other }

extension PaymentMethodX on PaymentMethod {
  String get storage => name;

  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.card:
        return 'Credit/Debit Card';
      case PaymentMethod.jazzcash:
        return 'JazzCash';
      case PaymentMethod.easypaisa:
        return 'Easypaisa';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  static PaymentMethod fromStorage(String? raw) {
    final value = raw?.trim() ?? '';
    for (final method in PaymentMethod.values) {
      if (method.name == value || method.label == value) return method;
    }
    return PaymentMethod.other;
  }
}

class Payment {
  const Payment({
    required this.id,
    required this.businessId,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.amountMinor,
    required this.method,
    required this.paidAt,
    this.notes = '',
    this.currencyCode = AppConstants.defaultCurrencyCode,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String businessId;
  final String invoiceId;
  final String invoiceNumber;
  final String customerId;
  final String customerName;
  final int amountMinor;
  final PaymentMethod method;
  final DateTime paidAt;
  final String notes;
  final String currencyCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Money get amount => Money.fromMinorUnits(amountMinor, currencyCode: currencyCode);

  factory Payment.fromInvoice({
    required String id,
    required Invoice invoice,
    required int amountMinor,
    required PaymentMethod method,
    required DateTime paidAt,
    String notes = '',
  }) {
    return Payment(
      id: id,
      businessId: invoice.businessId,
      invoiceId: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      customerId: invoice.customerId,
      customerName: invoice.customerName,
      amountMinor: amountMinor,
      method: method,
      paidAt: AppDateFormatter.startOfDay(paidAt),
      notes: notes.trim(),
      currencyCode: invoice.currencyCode,
    );
  }

  PaymentRecord toRecord() {
    return PaymentRecord(
      id: id,
      amount: amount,
      paidAt: paidAt,
      customerId: customerId,
      customerName: customerName,
      invoiceId: invoiceId,
      invoiceNumber: invoiceNumber,
      method: method.label,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'id': id,
      'businessId': businessId,
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      'customerName': customerName,
      'amountMinor': amountMinor,
      'currencyCode': currencyCode,
      'method': method.storage,
      'paidAt': Timestamp.fromDate(paidAt),
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Payment.fromMap(String id, Map<String, dynamic> data) {
    return Payment(
      id: data['id'] as String? ?? id,
      businessId: data['businessId'] as String? ?? '',
      invoiceId: data['invoiceId'] as String? ?? '',
      invoiceNumber: data['invoiceNumber'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      amountMinor: (data['amountMinor'] as num?)?.toInt() ?? 0,
      method: PaymentMethodX.fromStorage(data['method'] as String?),
      paidAt: AppUser.dateTimeFrom(data['paidAt']) ??
          AppUser.dateTimeFrom(data['date']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      notes: data['notes'] as String? ?? '',
      currencyCode: data['currencyCode'] as String? ?? AppConstants.defaultCurrencyCode,
      createdAt: AppUser.dateTimeFrom(data['createdAt']),
      updatedAt: AppUser.dateTimeFrom(data['updatedAt']),
    );
  }
}
