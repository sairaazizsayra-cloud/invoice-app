import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/core/utils/validators.dart';

void main() {
  group('Money', () {
    test('parses major units into minor units without floating-point drift', () {
      final tenCents = Money.parse('0.10');
      final twentyCents = Money.parse('0.20');
      expect((tenCents + twentyCents).minorUnits, 30);
      expect((tenCents + twentyCents).format(includeSymbol: false), '0.30');
    });

    test('formats PKR with grouping separators', () {
      final amount = Money.parse('12345.50');
      expect(amount.formatted, 'Rs 12,345.50');
    });

    test('multiplies quantity using integer arithmetic', () {
      final unit = Money.parse('33.33');
      expect(unit.timesQuantity(3).format(includeSymbol: false), '99.99');
    });

    test('applies percentage with half-away-from-zero rounding', () {
      final base = Money.parse('100.00');
      expect(base.percentOf(1700).format(includeSymbol: false), '17.00');
      expect(Money.parse('1.00').percentOf(50).minorUnits, 1);
    });

    test('subtracts without going through doubles', () {
      final total = Money.parse('100.00');
      final paid = Money.parse('40.10');
      expect((total - paid).format(includeSymbol: false), '59.90');
    });

    test('rejects invalid input', () {
      expect(() => Money.parse('abc'), throwsA(isA<Exception>()));
    });
  });

  group('AppValidators', () {
    test('accepts a valid email and rejects an invalid one', () {
      expect(AppValidators.email('owner@business.pk'), isNull);
      expect(AppValidators.email('not-an-email'), isNotNull);
      expect(AppValidators.email(''), isNotNull);
    });

    test('accepts Pakistani mobile numbers', () {
      expect(AppValidators.phone('03001234567'), isNull);
      expect(AppValidators.phone('+92 300 1234567'), isNull);
      expect(AppValidators.phone('0211234567'), isNotNull);
    });

    test('enforces password rules', () {
      expect(AppValidators.password('short1'), isNotNull);
      expect(AppValidators.password('password'), isNotNull);
      expect(AppValidators.password('12345678'), isNotNull);
      expect(AppValidators.password('Secure123'), isNull);
    });

    test('confirms matching passwords', () {
      expect(AppValidators.confirmPassword('Secure123', 'Secure123'), isNull);
      expect(AppValidators.confirmPassword('Secure123', 'other'), isNotNull);
    });

    test('validates amounts', () {
      expect(AppValidators.amount('10.50'), isNull);
      expect(AppValidators.amount('0'), isNotNull);
      expect(AppValidators.amount('0', allowZero: true), isNull);
      expect(AppValidators.amount('-1'), isNotNull);
    });

    test('accepts optional websites and tax rates used on the business profile', () {
      expect(AppValidators.optionalWebsite(''), isNull);
      expect(AppValidators.optionalWebsite('business.pk'), isNull);
      expect(AppValidators.optionalWebsite('not a website'), isNotNull);
      expect(AppValidators.taxPercent('17'), isNull);
      expect(AppValidators.taxPercent('101'), isNotNull);
      expect(AppValidators.invoicePrefix('INV-'), isNull);
      expect(AppValidators.invoicePrefix('!'), isNotNull);
    });

    test('treats company as optional but still rejects a one-letter value', () {
      expect(AppValidators.optionalName(''), isNull);
      expect(AppValidators.optionalName('A'), isNotNull);
      expect(AppValidators.optionalName('Ali'), isNull);
    });

    test('validates SKU and stock used on products', () {
      expect(AppValidators.optionalSku(''), isNull);
      expect(AppValidators.optionalSku('RICE-10'), isNull);
      expect(AppValidators.optionalSku('!'), isNotNull);
      expect(AppValidators.nonNegativeInt('12', isRequired: true), isNull);
      expect(AppValidators.nonNegativeInt('0', isRequired: true), isNull);
      expect(AppValidators.nonNegativeInt('-1'), isNotNull);
    });
  });
}
