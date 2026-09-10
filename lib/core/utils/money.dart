import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';

/// Immutable money value stored as integer minor units (paisa for PKR).
///
/// Never persist or calculate invoice totals using [double]. Parse user input
/// with [Money.parse] and convert to Firestore as [minorUnits].
@immutable
class Money implements Comparable<Money> {
  const Money._({
    required this.minorUnits,
    required this.currencyCode,
    required this.decimalDigits,
  });

  final int minorUnits;
  final String currencyCode;
  final int decimalDigits;

  static const String defaultCurrencyCode = AppConstants.defaultCurrencyCode;
  static const int defaultDecimalDigits = AppConstants.moneyDecimalDigits;

  static Money zero({
    String currencyCode = defaultCurrencyCode,
    int decimalDigits = defaultDecimalDigits,
  }) {
    return Money._(
      minorUnits: 0,
      currencyCode: currencyCode,
      decimalDigits: decimalDigits,
    );
  }

  factory Money.fromMinorUnits(
    int minorUnits, {
    String currencyCode = defaultCurrencyCode,
    int decimalDigits = defaultDecimalDigits,
  }) {
    return Money._(
      minorUnits: minorUnits,
      currencyCode: currencyCode,
      decimalDigits: decimalDigits,
    );
  }

  factory Money.fromMajorUnits(
    int majorUnits, {
    String currencyCode = defaultCurrencyCode,
    int decimalDigits = defaultDecimalDigits,
  }) {
    return Money._(
      minorUnits: majorUnits * _scaleFactor(decimalDigits),
      currencyCode: currencyCode,
      decimalDigits: decimalDigits,
    );
  }

  /// Parses a major-unit string such as `123.45`, `1,234.50`, or `99`.
  factory Money.parse(
    String raw, {
    String currencyCode = defaultCurrencyCode,
    int decimalDigits = defaultDecimalDigits,
  }) {
    final normalized = raw.trim().replaceAll(',', '');
    if (normalized.isEmpty) {
      throw const ValidationException('Amount is empty', debugCode: 'money.empty');
    }

    final negative = normalized.startsWith('-');
    final unsigned = negative ? normalized.substring(1) : normalized;
    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(unsigned)) {
      throw ValidationException('Invalid amount: $raw', debugCode: 'money.invalid');
    }

    final parts = unsigned.split('.');
    final major = int.parse(parts[0]);
    var fraction = parts.length == 2 ? parts[1] : '';

    if (fraction.length > decimalDigits) {
      fraction = _roundFractionDigits(fraction, decimalDigits);
    }
    fraction = fraction.padRight(decimalDigits, '0');

    final minor = fraction.isEmpty ? 0 : int.parse(fraction);
    final total = major * _scaleFactor(decimalDigits) + minor;
    return Money._(
      minorUnits: negative ? -total : total,
      currencyCode: currencyCode,
      decimalDigits: decimalDigits,
    );
  }

  bool get isZero => minorUnits == 0;
  bool get isNegative => minorUnits < 0;
  bool get isPositive => minorUnits > 0;

  Money operator +(Money other) {
    _assertCompatible(other);
    return _copyWith(minorUnits: minorUnits + other.minorUnits);
  }

  Money operator -(Money other) {
    _assertCompatible(other);
    return _copyWith(minorUnits: minorUnits - other.minorUnits);
  }

  Money operator -() => _copyWith(minorUnits: -minorUnits);

  Money timesQuantity(int quantity) {
    if (quantity < 0) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be zero or positive');
    }
    return _copyWith(minorUnits: minorUnits * quantity);
  }

  /// [percentMinor] is the percentage with two implied decimals: `17.00%` → `1700`.
  Money percentOf(int percentMinor) {
    final result = _multiplyDivideRound(minorUnits, percentMinor, 10000);
    return _copyWith(minorUnits: result);
  }

  String get formatted => format();

  String format({String? symbol, bool includeSymbol = true}) {
    final digits = decimalDigits;
    final absValue = minorUnits.abs();
    final scale = _scaleFactor(digits);
    final major = absValue ~/ scale;
    final fraction = (absValue % scale).toString().padLeft(digits, '0');
    final sign = minorUnits < 0 ? '-' : '';
    final grouped = NumberFormat('#,##0', 'en_PK').format(major);
    final amount = digits == 0 ? grouped : '$grouped.$fraction';
    if (!includeSymbol) {
      return '$sign$amount';
    }
    final prefix = symbol ?? _symbolFor(currencyCode);
    return '$sign$prefix$amount';
  }

  @override
  int compareTo(Money other) {
    _assertCompatible(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  @override
  bool operator ==(Object other) {
    return other is Money &&
        other.minorUnits == minorUnits &&
        other.currencyCode == currencyCode &&
        other.decimalDigits == decimalDigits;
  }

  @override
  int get hashCode => Object.hash(minorUnits, currencyCode, decimalDigits);

  @override
  String toString() => format();

  Money _copyWith({int? minorUnits}) {
    return Money._(
      minorUnits: minorUnits ?? this.minorUnits,
      currencyCode: currencyCode,
      decimalDigits: decimalDigits,
    );
  }

  void _assertCompatible(Money other) {
    if (other.currencyCode != currencyCode || other.decimalDigits != decimalDigits) {
      throw ArgumentError(
        'Cannot combine ${other.currencyCode}/${other.decimalDigits} '
        'with $currencyCode/$decimalDigits',
      );
    }
  }

  static int _scaleFactor(int decimalDigits) {
    var factor = 1;
    for (var i = 0; i < decimalDigits; i++) {
      factor *= 10;
    }
    return factor;
  }

  static String _roundFractionDigits(String fraction, int decimalDigits) {
    final keep = fraction.substring(0, decimalDigits);
    final nextDigit = int.parse(fraction[decimalDigits]);
    if (nextDigit < 5) {
      return keep;
    }
    final rounded = int.parse(keep) + 1;
    return rounded.toString().padLeft(decimalDigits, '0');
  }

  static int _multiplyDivideRound(int value, int multiplier, int divisor) {
    final product = BigInt.from(value) * BigInt.from(multiplier);
    final denominator = BigInt.from(divisor);
    final absNum = product.abs();
    final absDen = denominator.abs();
    final quotient = absNum ~/ absDen;
    final remainder = absNum % absDen;
    final rounded = remainder * BigInt.two >= absDen ? quotient + BigInt.one : quotient;
    final negative = product.isNegative != denominator.isNegative;
    final signed = negative ? -rounded : rounded;
    return signed.toInt();
  }

  static String _symbolFor(String currencyCode) {
    switch (currencyCode) {
      case 'PKR':
        return AppConstants.defaultCurrencySymbol;
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return '$currencyCode ';
    }
  }
}
