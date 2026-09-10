import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_pro/models/expense.dart';

void main() {
  group('Expense', () {
    test('reads a Firestore-shaped map with integer money', () {
      final expense = Expense.fromMap('exp_1', {
        'businessId': 'biz_1',
        'title': 'Shop rent',
        'category': 'rent',
        'amountMinor': 20000,
        'currencyCode': 'PKR',
        'date': DateTime(2026, 9, 1),
        'description': 'September rent',
      });

      expect(expense.title, 'Shop rent');
      expect(expense.category, ExpenseCategory.rent);
      expect(expense.amount.minorUnits, 20000);
      expect(expense.matches('rent'), isTrue);
      expect(expense.matches('fuel'), isFalse);
      expect(expense.toRecord().category, 'Rent');
    });

    test('maps every FYP expense category', () {
      expect(ExpenseCategoryX.fromStorage('Salary'), ExpenseCategory.salary);
      expect(ExpenseCategory.electricity.label, 'Electricity');
      expect(ExpenseCategory.transport.label, 'Transport');
      expect(ExpenseCategory.marketing.label, 'Marketing');
      expect(ExpenseCategory.inventory.label, 'Inventory');
      expect(ExpenseCategoryX.fromStorage('unknown'), ExpenseCategory.other);
    });
  });
}
