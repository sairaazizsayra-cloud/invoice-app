import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/utils/money.dart';

class AppValidators {
  AppValidators._();

  static final RegExp _email = RegExp(
    r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
  );

  static final RegExp _pkMobile = RegExp(r'^(?:\+92|0092|0)?3\d{9}$');
  static final RegExp _hasLetter = RegExp(r'[A-Za-z]');
  static final RegExp _hasDigit = RegExp(r'\d');

  static String? required(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? AppStrings.requiredField;
    }
    return null;
  }

  static String? name(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    if (value!.trim().length < 2) return AppStrings.nameTooShort;
    return null;
  }

  static String? optionalName(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length < 2) return AppStrings.nameTooShort;
    return null;
  }

  static String? email(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    if (!_email.hasMatch(value!.trim())) return AppStrings.invalidEmail;
    return null;
  }

  static String? optionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!_email.hasMatch(value.trim())) return AppStrings.invalidEmail;
    return null;
  }

  static String? phone(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    final digits = value!.replaceAll(RegExp(r'[\s-]'), '');
    if (!_pkMobile.hasMatch(digits)) return AppStrings.invalidPhone;
    return null;
  }

  static String? optionalPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return phone(value);
  }

  static String? password(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    if (value!.length < 8) return AppStrings.passwordTooShort;
    if (!_hasLetter.hasMatch(value)) return AppStrings.passwordNeedsLetter;
    if (!_hasDigit.hasMatch(value)) return AppStrings.passwordNeedsNumber;
    return null;
  }

  static String? confirmPassword(String? value, String? original) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    if (value != original) return AppStrings.passwordsDoNotMatch;
    return null;
  }

  static String? amount(String? value, {bool allowZero = false}) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    try {
      final money = Money.parse(value!);
      if (!allowZero && !money.isPositive) return AppStrings.amountMustBePositive;
      if (allowZero && money.isNegative) return AppStrings.invalidAmount;
      return null;
    } catch (_) {
      return AppStrings.invalidAmount;
    }
  }

  static String? paymentAmount(String? value, {required Money maximum}) {
    final error = amount(value);
    if (error != null) return error;
    try {
      final money = Money.parse(value!);
      if (money.minorUnits > maximum.minorUnits) {
        return AppStrings.paymentExceedsOutstanding;
      }
      return null;
    } catch (_) {
      return AppStrings.invalidAmount;
    }
  }

  static String? optionalWebsite(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim();
    final withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    final uri = Uri.tryParse(withScheme);
    if (uri == null || uri.host.isEmpty || !uri.host.contains('.')) {
      return AppStrings.invalidWebsite;
    }
    return null;
  }

  static String? taxPercent(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    try {
      final parsed = Money.parse(value!);
      if (parsed.isNegative || parsed.minorUnits > 10000) {
        return AppStrings.invalidTaxPercent;
      }
      return null;
    } catch (_) {
      return AppStrings.invalidTaxPercent;
    }
  }

  static String? invoicePrefix(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    final trimmed = value!.trim();
    if (!RegExp(r'^[A-Za-z0-9-]{2,10}$').hasMatch(trimmed)) {
      return AppStrings.invalidInvoicePrefix;
    }
    return null;
  }

  static String? optionalSku(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!RegExp(r'^[A-Za-z0-9-]{2,24}$').hasMatch(value.trim())) {
      return AppStrings.invalidSku;
    }
    return null;
  }

  static String? nonNegativeInt(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? AppStrings.requiredField : null;
    }
    if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
      return AppStrings.invalidStock;
    }
    return null;
  }

  static String? positiveInt(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    if (!RegExp(r'^\d+$').hasMatch(value!.trim())) {
      return AppStrings.invalidQuantity;
    }
    if (int.parse(value.trim()) < 1) return AppStrings.quantityMustBePositive;
    return null;
  }
}
