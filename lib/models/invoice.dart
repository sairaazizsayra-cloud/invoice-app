import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/utils/date_formatter.dart';
import 'package:invoice_pro/core/utils/invoice_number.dart';
import 'package:invoice_pro/core/utils/line_amount_calculator.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/models/app_user.dart';
import 'package:invoice_pro/models/business.dart';
import 'package:invoice_pro/models/customer.dart';
import 'package:invoice_pro/models/dashboard_models.dart';
import 'package:invoice_pro/models/invoice_status.dart';

enum InvoicePaymentTerms { dueOnReceipt, net7, net15, net30, custom }

extension InvoicePaymentTermsX on InvoicePaymentTerms {
  String get storage => name;

  String get label {
    switch (this) {
      case InvoicePaymentTerms.dueOnReceipt:
        return 'Due on receipt';
      case InvoicePaymentTerms.net7:
        return 'Net 7';
      case InvoicePaymentTerms.net15:
        return 'Net 15';
      case InvoicePaymentTerms.net30:
        return 'Net 30';
      case InvoicePaymentTerms.custom:
        return 'Custom';
    }
  }

  int? get dueDays {
    switch (this) {
      case InvoicePaymentTerms.dueOnReceipt:
        return 0;
      case InvoicePaymentTerms.net7:
        return 7;
      case InvoicePaymentTerms.net15:
        return 15;
      case InvoicePaymentTerms.net30:
        return 30;
      case InvoicePaymentTerms.custom:
        return null;
    }
  }

  DateTime dueDateFrom(DateTime issueDate) {
    final days = dueDays ?? 0;
    final start = AppDateFormatter.startOfDay(issueDate);
    return DateTime(start.year, start.month, start.day + days);
  }

  static InvoicePaymentTerms fromStorage(String? raw) {
    for (final value in InvoicePaymentTerms.values) {
      if (value.name == raw) return value;
    }
    return InvoicePaymentTerms.dueOnReceipt;
  }
}

class InvoiceLine {
  const InvoiceLine({
    this.productId = '',
    required this.name,
    this.description = '',
    this.unit = AppConstants.defaultProductUnit,
    required this.quantity,
    required this.unitPriceMinor,
    this.discountMinor = 0,
    this.taxPercentMinor = 0,
    required this.lineSubtotalMinor,
    required this.lineTaxMinor,
    required this.lineTotalMinor,
  });

  final String productId;
  final String name;
  final String description;
  final String unit;
  final int quantity;
  final int unitPriceMinor;
  final int discountMinor;
  final int taxPercentMinor;
  final int lineSubtotalMinor;
  final int lineTaxMinor;
  final int lineTotalMinor;

  factory InvoiceLine.calculated({
    String productId = '',
    required String name,
    String description = '',
    String unit = AppConstants.defaultProductUnit,
    required int quantity,
    required int unitPriceMinor,
    int discountMinor = 0,
    int taxPercentMinor = 0,
    String currencyCode = AppConstants.defaultCurrencyCode,
  }) {
    final breakdown = LineAmountCalculator.calculate(
      unitPrice: Money.fromMinorUnits(unitPriceMinor, currencyCode: currencyCode),
      quantity: quantity,
      discountAmount: Money.fromMinorUnits(discountMinor, currencyCode: currencyCode),
      taxPercentMinor: taxPercentMinor,
    );
    return InvoiceLine(
      productId: productId,
      name: name,
      description: description,
      unit: unit,
      quantity: quantity,
      unitPriceMinor: unitPriceMinor,
      discountMinor: discountMinor,
      taxPercentMinor: taxPercentMinor,
      lineSubtotalMinor: breakdown.subtotal.minorUnits,
      lineTaxMinor: breakdown.tax.minorUnits,
      lineTotalMinor: breakdown.total.minorUnits,
    );
  }

  Money unitPrice({String currencyCode = AppConstants.defaultCurrencyCode}) {
    return Money.fromMinorUnits(unitPriceMinor, currencyCode: currencyCode);
  }

  Money discount({String currencyCode = AppConstants.defaultCurrencyCode}) {
    return Money.fromMinorUnits(discountMinor, currencyCode: currencyCode);
  }

  Money lineTotal({String currencyCode = AppConstants.defaultCurrencyCode}) {
    return Money.fromMinorUnits(lineTotalMinor, currencyCode: currencyCode);
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'description': description,
      'unit': unit,
      'quantity': quantity,
      'unitPriceMinor': unitPriceMinor,
      'discountMinor': discountMinor,
      'taxPercentMinor': taxPercentMinor,
      'lineSubtotalMinor': lineSubtotalMinor,
      'lineTaxMinor': lineTaxMinor,
      'lineTotalMinor': lineTotalMinor,
    };
  }

  factory InvoiceLine.fromMap(Map<String, dynamic> data) {
    return InvoiceLine(
      productId: data['productId'] as String? ?? '',
      name: data['name'] as String? ?? 'Item',
      description: data['description'] as String? ?? '',
      unit: data['unit'] as String? ?? AppConstants.defaultProductUnit,
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      unitPriceMinor: (data['unitPriceMinor'] as num?)?.toInt() ?? 0,
      discountMinor: (data['discountMinor'] as num?)?.toInt() ?? 0,
      taxPercentMinor: (data['taxPercentMinor'] as num?)?.toInt() ?? 0,
      lineSubtotalMinor: (data['lineSubtotalMinor'] as num?)?.toInt() ?? 0,
      lineTaxMinor: (data['lineTaxMinor'] as num?)?.toInt() ?? 0,
      lineTotalMinor: (data['lineTotalMinor'] as num?)?.toInt() ?? 0,
    );
  }
}

class Invoice {
  const Invoice({
    required this.id,
    required this.businessId,
    required this.invoiceNumber,
    required this.invoiceSequence,
    required this.customerId,
    required this.customerName,
    this.customerCompany = '',
    this.customerEmail = '',
    this.customerPhone = '',
    this.customerAddress = '',
    this.customerCity = '',
    required this.businessName,
    this.businessAddress = '',
    this.businessCity = '',
    this.businessPhone = '',
    this.businessEmail = '',
    this.businessTaxNumber = '',
    this.businessLogoUrl,
    this.currencyCode = AppConstants.defaultCurrencyCode,
    this.status = InvoiceStatus.draft,
    this.paymentTerms = InvoicePaymentTerms.dueOnReceipt,
    required this.issueDate,
    required this.dueDate,
    this.notes = '',
    this.paymentInstructions = '',
    this.termsAndConditions = '',
    this.subtotalMinor = 0,
    this.discountMinor = 0,
    this.taxMinor = 0,
    this.totalMinor = 0,
    this.paidMinor = 0,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String businessId;
  final String invoiceNumber;
  final int invoiceSequence;
  final String customerId;
  final String customerName;
  final String customerCompany;
  final String customerEmail;
  final String customerPhone;
  final String customerAddress;
  final String customerCity;
  final String businessName;
  final String businessAddress;
  final String businessCity;
  final String businessPhone;
  final String businessEmail;
  final String businessTaxNumber;
  final String? businessLogoUrl;
  final String currencyCode;
  final InvoiceStatus status;
  final InvoicePaymentTerms paymentTerms;
  final DateTime issueDate;
  final DateTime dueDate;
  final String notes;
  final String paymentInstructions;
  final String termsAndConditions;
  final int subtotalMinor;
  final int discountMinor;
  final int taxMinor;
  final int totalMinor;
  final int paidMinor;
  final List<InvoiceLine> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Money get subtotal => Money.fromMinorUnits(subtotalMinor, currencyCode: currencyCode);
  Money get discount => Money.fromMinorUnits(discountMinor, currencyCode: currencyCode);
  Money get tax => Money.fromMinorUnits(taxMinor, currencyCode: currencyCode);
  Money get total => Money.fromMinorUnits(totalMinor, currencyCode: currencyCode);
  Money get paid => Money.fromMinorUnits(paidMinor, currencyCode: currencyCode);
  Money get outstanding => total - paid;

  bool get isDraft => status == InvoiceStatus.draft;
  bool get isCancelled => status == InvoiceStatus.cancelled;
  bool get isPaid => status == InvoiceStatus.paid || !outstanding.isPositive && !isDraft && !isCancelled;
  bool get hasNumber => invoiceNumber.trim().isNotEmpty;

  bool get canEdit =>
      paidMinor == 0 &&
      (status == InvoiceStatus.draft || status == InvoiceStatus.unpaid || status == InvoiceStatus.sent);

  bool get canDelete => status == InvoiceStatus.draft || status == InvoiceStatus.cancelled;

  bool get canCancel =>
      paidMinor == 0 && status != InvoiceStatus.cancelled && status != InvoiceStatus.paid;

  bool get canMarkSent => status == InvoiceStatus.unpaid;

  bool get canIssue => status == InvoiceStatus.draft;

  bool get canRecordPayment => !isDraft && !isCancelled && outstanding.isPositive;

  static InvoiceStatus statusAfterPaid({
    required int paidMinor,
    required int totalMinor,
    required InvoiceStatus current,
  }) {
    if (current == InvoiceStatus.cancelled || current == InvoiceStatus.draft) {
      return current;
    }
    if (totalMinor > 0 && paidMinor >= totalMinor) return InvoiceStatus.paid;
    if (paidMinor > 0) return InvoiceStatus.partiallyPaid;
    if (current == InvoiceStatus.sent) return InvoiceStatus.sent;
    return InvoiceStatus.unpaid;
  }

  Invoice withPaidMinor(int paidMinor) {
    final next = paidMinor < 0 ? 0 : paidMinor;
    return copyWith(
      paidMinor: next,
      status: statusAfterPaid(paidMinor: next, totalMinor: totalMinor, current: status),
    );
  }

  Invoice applyPaymentAmount(int amountMinor) => withPaidMinor(paidMinor + amountMinor);

  Invoice revertPaymentAmount(int amountMinor) => withPaidMinor(paidMinor - amountMinor);

  InvoiceStatus displayStatus(DateTime now) {
    if (isCancelled || isDraft || status == InvoiceStatus.paid) return status;
    if (isOverdue(now)) return InvoiceStatus.overdue;
    return status;
  }

  bool isOverdue(DateTime now) {
    if (isCancelled || isDraft) return false;
    if (status == InvoiceStatus.paid || !outstanding.isPositive) return false;
    return AppDateFormatter.startOfDay(dueDate).isBefore(AppDateFormatter.startOfDay(now));
  }

  bool matches(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return invoiceNumber.toLowerCase().contains(needle) ||
        customerName.toLowerCase().contains(needle) ||
        customerCompany.toLowerCase().contains(needle) ||
        notes.toLowerCase().contains(needle) ||
        items.any((line) => line.name.toLowerCase().contains(needle));
  }

  factory Invoice.draft({
    required String id,
    required Business business,
    Customer? customer,
    DateTime? now,
    InvoicePaymentTerms paymentTerms = InvoicePaymentTerms.dueOnReceipt,
  }) {
    final issue = AppDateFormatter.startOfDay(now ?? DateTime.now());
    return Invoice(
      id: id,
      businessId: business.id,
      invoiceNumber: '',
      invoiceSequence: 0,
      customerId: customer?.id ?? '',
      customerName: customer?.name ?? '',
      customerCompany: customer?.company ?? '',
      customerEmail: customer?.email ?? '',
      customerPhone: customer?.phone ?? '',
      customerAddress: customer?.address ?? '',
      customerCity: customer?.city ?? '',
      businessName: business.name,
      businessAddress: business.address,
      businessCity: business.city,
      businessPhone: business.phone,
      businessEmail: business.email,
      businessTaxNumber: business.taxNumber,
      businessLogoUrl: business.logoUrl,
      currencyCode: business.currencyCode,
      status: InvoiceStatus.draft,
      paymentTerms: paymentTerms,
      issueDate: issue,
      dueDate: paymentTerms.dueDateFrom(issue),
      paymentInstructions: business.paymentInstructions,
      termsAndConditions: business.termsAndConditions,
    );
  }

  static String previewNumber(Business business) {
    return InvoiceNumberFormatter.format(
      number: business.invoiceNextNumber,
      prefix: business.invoicePrefix,
    );
  }

  Invoice withCustomer(Customer customer) {
    return copyWith(
      customerId: customer.id,
      customerName: customer.name,
      customerCompany: customer.company,
      customerEmail: customer.email,
      customerPhone: customer.phone,
      customerAddress: customer.address,
      customerCity: customer.city,
    );
  }

  Invoice withBusinessSnapshot(Business business) {
    return copyWith(
      businessName: business.name,
      businessAddress: business.address,
      businessCity: business.city,
      businessPhone: business.phone,
      businessEmail: business.email,
      businessTaxNumber: business.taxNumber,
      businessLogoUrl: business.logoUrl,
      currencyCode: business.currencyCode,
      paymentInstructions: business.paymentInstructions,
      termsAndConditions: business.termsAndConditions,
    );
  }

  Invoice withItems(List<InvoiceLine> nextItems) {
    var subtotal = 0;
    var discountTotal = 0;
    var taxTotal = 0;
    var grandTotal = 0;
    for (final line in nextItems) {
      subtotal += line.lineSubtotalMinor;
      discountTotal += line.discountMinor;
      taxTotal += line.lineTaxMinor;
      grandTotal += line.lineTotalMinor;
    }
    return copyWith(
      items: nextItems,
      subtotalMinor: subtotal,
      discountMinor: discountTotal,
      taxMinor: taxTotal,
      totalMinor: grandTotal,
    );
  }

  Invoice copyWith({
    String? invoiceNumber,
    int? invoiceSequence,
    String? customerId,
    String? customerName,
    String? customerCompany,
    String? customerEmail,
    String? customerPhone,
    String? customerAddress,
    String? customerCity,
    String? businessName,
    String? businessAddress,
    String? businessCity,
    String? businessPhone,
    String? businessEmail,
    String? businessTaxNumber,
    String? businessLogoUrl,
    bool clearLogo = false,
    String? currencyCode,
    InvoiceStatus? status,
    InvoicePaymentTerms? paymentTerms,
    DateTime? issueDate,
    DateTime? dueDate,
    String? notes,
    String? paymentInstructions,
    String? termsAndConditions,
    int? subtotalMinor,
    int? discountMinor,
    int? taxMinor,
    int? totalMinor,
    int? paidMinor,
    List<InvoiceLine>? items,
  }) {
    return Invoice(
      id: id,
      businessId: businessId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceSequence: invoiceSequence ?? this.invoiceSequence,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerCompany: customerCompany ?? this.customerCompany,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      customerCity: customerCity ?? this.customerCity,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      businessCity: businessCity ?? this.businessCity,
      businessPhone: businessPhone ?? this.businessPhone,
      businessEmail: businessEmail ?? this.businessEmail,
      businessTaxNumber: businessTaxNumber ?? this.businessTaxNumber,
      businessLogoUrl: clearLogo ? null : (businessLogoUrl ?? this.businessLogoUrl),
      currencyCode: currencyCode ?? this.currencyCode,
      status: status ?? this.status,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      paymentInstructions: paymentInstructions ?? this.paymentInstructions,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      subtotalMinor: subtotalMinor ?? this.subtotalMinor,
      discountMinor: discountMinor ?? this.discountMinor,
      taxMinor: taxMinor ?? this.taxMinor,
      totalMinor: totalMinor ?? this.totalMinor,
      paidMinor: paidMinor ?? this.paidMinor,
      items: items ?? this.items,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  InvoiceRecord toRecord() {
    return InvoiceRecord(
      id: id,
      number: invoiceNumber,
      customerId: customerId,
      customerName: customerName,
      status: status,
      total: total,
      paid: paid,
      issueDate: issueDate,
      dueDate: dueDate,
      lines: [
        for (final line in items)
          InvoiceLineRecord(
            productId: line.productId,
            name: line.name,
            lineTotal: line.lineTotal(currencyCode: currencyCode),
            quantity: line.quantity,
          ),
      ],
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      ..._bodyMap(),
      'id': id,
      'businessId': businessId,
      'invoiceNumber': invoiceNumber,
      'invoiceSequence': invoiceSequence,
      'paidMinor': paidMinor,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      ..._bodyMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toSettlementMap() {
    return {
      'paidMinor': paidMinor,
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _bodyMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerCompany': customerCompany,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'customerCity': customerCity,
      'businessName': businessName,
      'businessAddress': businessAddress,
      'businessCity': businessCity,
      'businessPhone': businessPhone,
      'businessEmail': businessEmail,
      'businessTaxNumber': businessTaxNumber,
      'businessLogoUrl': businessLogoUrl,
      'currencyCode': currencyCode,
      'status': status.name,
      'paymentTerms': paymentTerms.storage,
      'issueDate': Timestamp.fromDate(issueDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'notes': notes,
      'paymentInstructions': paymentInstructions,
      'termsAndConditions': termsAndConditions,
      'subtotalMinor': subtotalMinor,
      'discountMinor': discountMinor,
      'taxMinor': taxMinor,
      'totalMinor': totalMinor,
      'items': [for (final line in items) line.toMap()],
      // Denormalized for efficient product-in-use checks (array-contains).
      'lineProductIds': {
        for (final line in items)
          if (line.productId.trim().isNotEmpty) line.productId.trim(),
      }.toList(),
    };
  }

  factory Invoice.fromMap(String id, Map<String, dynamic> data) {
    final rawItems = data['items'] ?? data['lines'];
    final items = <InvoiceLine>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          items.add(InvoiceLine.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    return Invoice(
      id: data['id'] as String? ?? id,
      businessId: data['businessId'] as String? ?? '',
      invoiceNumber: data['invoiceNumber'] as String? ?? id,
      invoiceSequence: (data['invoiceSequence'] as num?)?.toInt() ?? 0,
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      customerCompany: data['customerCompany'] as String? ?? '',
      customerEmail: data['customerEmail'] as String? ?? '',
      customerPhone: data['customerPhone'] as String? ?? '',
      customerAddress: data['customerAddress'] as String? ?? '',
      customerCity: data['customerCity'] as String? ?? '',
      businessName: data['businessName'] as String? ?? '',
      businessAddress: data['businessAddress'] as String? ?? '',
      businessCity: data['businessCity'] as String? ?? '',
      businessPhone: data['businessPhone'] as String? ?? '',
      businessEmail: data['businessEmail'] as String? ?? '',
      businessTaxNumber: data['businessTaxNumber'] as String? ?? '',
      businessLogoUrl: data['businessLogoUrl'] as String?,
      currencyCode: data['currencyCode'] as String? ?? AppConstants.defaultCurrencyCode,
      status: InvoiceStatusX.fromStorage(data['status'] as String?),
      paymentTerms: InvoicePaymentTermsX.fromStorage(data['paymentTerms'] as String?),
      issueDate: AppUser.dateTimeFrom(data['issueDate']) ??
          AppUser.dateTimeFrom(data['invoiceDate']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      dueDate: AppUser.dateTimeFrom(data['dueDate']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      notes: data['notes'] as String? ?? '',
      paymentInstructions: data['paymentInstructions'] as String? ?? '',
      termsAndConditions: data['termsAndConditions'] as String? ?? '',
      subtotalMinor: (data['subtotalMinor'] as num?)?.toInt() ?? 0,
      discountMinor: (data['discountMinor'] as num?)?.toInt() ?? 0,
      taxMinor: (data['taxMinor'] as num?)?.toInt() ?? 0,
      totalMinor: (data['totalMinor'] as num?)?.toInt() ?? 0,
      paidMinor: (data['paidMinor'] as num?)?.toInt() ?? 0,
      items: items,
      createdAt: AppUser.dateTimeFrom(data['createdAt']),
      updatedAt: AppUser.dateTimeFrom(data['updatedAt']),
    );
  }
}
