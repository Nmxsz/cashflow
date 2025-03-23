import 'package:flutter_test/flutter_test.dart';
import 'package:cashflow/models/index.dart';

void main() {
  group('Expense', () {
    test('should create Expense with all values', () {
      final expense = Expense(
        name: 'Test Expense',
        amount: 100,
        type: ExpenseType.other,
      );

      expect(expense.name, 'Test Expense');
      expect(expense.amount, 100);
      expect(expense.type, ExpenseType.other);
      expect(expense.isOtherExpenses, false);
      expect(expense.isOther, true);
    });

    test('should convert to and from JSON', () {
      final originalExpense = Expense(
        name: 'Test Expense',
        amount: 100,
        type: ExpenseType.taxes,
      );

      final json = originalExpense.toJson();
      final recreatedExpense = Expense.fromJson(json);

      expect(recreatedExpense.name, originalExpense.name);
      expect(recreatedExpense.amount, originalExpense.amount);
      expect(recreatedExpense.type, originalExpense.type);
      expect(recreatedExpense.isTaxes, true);
    });

    test('should handle all expense types', () {
      final testCases = [
        (
          ExpenseType.taxes,
          true,
          false,
          false,
          false,
          false,
          false,
          false,
          false
        ),
        (
          ExpenseType.homePayment,
          false,
          true,
          false,
          false,
          false,
          false,
          false,
          false
        ),
        (
          ExpenseType.schoolLoan,
          false,
          false,
          true,
          false,
          false,
          false,
          false,
          false
        ),
        (
          ExpenseType.carLoan,
          false,
          false,
          false,
          true,
          false,
          false,
          false,
          false
        ),
        (
          ExpenseType.creditCard,
          false,
          false,
          false,
          false,
          true,
          false,
          false,
          false
        ),
        (
          ExpenseType.retail,
          false,
          false,
          false,
          false,
          false,
          true,
          false,
          false
        ),
        (
          ExpenseType.otherExpenses,
          false,
          false,
          false,
          false,
          false,
          false,
          true,
          false
        ),
        (
          ExpenseType.perChild,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          true
        ),
      ];

      for (var testCase in testCases) {
        final expense = Expense(
          name: 'Test ${testCase.$1}',
          amount: 100,
          type: testCase.$1,
        );

        expect(expense.isTaxes, testCase.$2);
        expect(expense.isHomePayment, testCase.$3);
        expect(expense.isSchoolLoan, testCase.$4);
        expect(expense.isCarLoan, testCase.$5);
        expect(expense.isCreditCard, testCase.$6);
        expect(expense.isRetail, testCase.$7);
        expect(expense.isOtherExpenses, testCase.$8);
        expect(expense.isPerChild, testCase.$9);
      }
    });

    test('should default to other type if invalid type in JSON', () {
      final json = {
        'name': 'Test Expense',
        'amount': 100,
        'type': 'invalidType',
      };

      final expense = Expense.fromJson(json);
      expect(expense.type, ExpenseType.other);
      expect(expense.isOther, true);
    });
  });
}
