import 'package:flutter_test/flutter_test.dart';
import 'package:cashflow/models/expense.dart';

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
    });

    test('should handle all expense types', () {
      final testCases = [
        (ExpenseType.taxes, 'taxes'),
        (ExpenseType.homePayment, 'homePayment'),
        (ExpenseType.schoolLoan, 'schoolLoan'),
        (ExpenseType.carLoan, 'carLoan'),
        (ExpenseType.creditCard, 'creditCard'),
        (ExpenseType.retail, 'retail'),
        (ExpenseType.otherExpenses, 'otherExpenses'),
        (ExpenseType.perChild, 'perChild'),
        (ExpenseType.other, 'other'),
      ];

      for (var testCase in testCases) {
        final expense = Expense(
          name: 'Test ${testCase.$2}',
          amount: 100,
          type: testCase.$1,
        );

        final json = expense.toJson();
        expect(json['type'], testCase.$2);

        final recreatedExpense = Expense.fromJson(json);
        expect(recreatedExpense.type, testCase.$1);
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
    });
  });
}
