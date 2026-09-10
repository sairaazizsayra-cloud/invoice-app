import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/utils/date_formatter.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/models/app_user.dart';
import 'package:invoice_pro/models/dashboard_models.dart';

enum ExpenseCategory { rent, salary, electricity, transport, marketing, inventory, other }

extension ExpenseCategoryX on ExpenseCategory {
  String get storage => name;

  String get label {
    switch (this) {
      case ExpenseCategory.rent:
        return 'Rent';
      case ExpenseCategory.salary:
        return 'Salary';
      case ExpenseCategory.electricity:
        return 'Electricity';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.marketing:
        return 'Marketing';
      case ExpenseCategory.inventory:
        return 'Inventory';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  static ExpenseCategory fromStorage(String? raw) {
    final value = raw?.trim() ?? '';
    for (final category in ExpenseCategory.values) {
      if (category.name == value || category.label == value) return category;
    }
    return ExpenseCategory.other;
  }
}

class Expense {
  const Expense({
    required this.id,
    required this.businessId,
    required this.title,
    required this.amountMinor,
    required this.date,
    this.category = ExpenseCategory.other,
    this.description = '',
    this.currencyCode = AppConstants.defaultCurrencyCode,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String businessId;
  final String title;
  final ExpenseCategory category;
  final int amountMinor;
  final DateTime date;
  final String description;
  final String currencyCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get titleLower => title.trim().toLowerCase();

  Money get amount => Money.fromMinorUnits(amountMinor, currencyCode: currencyCode);

  bool matches(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return title.toLowerCase().contains(needle) ||
        category.label.toLowerCase().contains(needle) ||
        description.toLowerCase().contains(needle);
  }

  ExpenseRecord toRecord() {
    return ExpenseRecord(
      id: id,
      amount: amount,
      date: date,
      title: title,
      category: category.label,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'id': id,
      'businessId': businessId,
      'title': title.trim(),
      'titleLower': titleLower,
      'category': category.storage,
      'amountMinor': amountMinor,
      'currencyCode': currencyCode,
      'date': Timestamp.fromDate(AppDateFormatter.startOfDay(date)),
      'description': description.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title.trim(),
      'titleLower': titleLower,
      'category': category.storage,
      'amountMinor': amountMinor,
      'currencyCode': currencyCode,
      'date': Timestamp.fromDate(AppDateFormatter.startOfDay(date)),
      'description': description.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Expense.fromMap(String id, Map<String, dynamic> data) {
    return Expense(
      id: data['id'] as String? ?? id,
      businessId: data['businessId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      category: ExpenseCategoryX.fromStorage(data['category'] as String?),
      amountMinor: (data['amountMinor'] as num?)?.toInt() ?? 0,
      date: AppUser.dateTimeFrom(data['date']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      description: data['description'] as String? ?? '',
      currencyCode: data['currencyCode'] as String? ?? AppConstants.defaultCurrencyCode,
      createdAt: AppUser.dateTimeFrom(data['createdAt']),
      updatedAt: AppUser.dateTimeFrom(data['updatedAt']),
    );
  }
}
