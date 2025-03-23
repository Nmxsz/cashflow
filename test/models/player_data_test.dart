import 'package:flutter_test/flutter_test.dart';
import 'package:cashflow/models/index.dart';

void main() {
  group('PlayerData', () {
    test('should create PlayerData with default values', () {
      final playerData = PlayerData();

      expect(playerData.salary, 0);
      expect(playerData.savings, 0);
      expect(playerData.passiveIncome, 0);
      expect(playerData.totalExpenses, 0);
      expect(playerData.cashflow, 0);
      expect(playerData.netWorth, 0);
      expect(playerData.assets, isEmpty);
      expect(playerData.liabilities, isEmpty);
      expect(playerData.expenses, isEmpty);
    });

    test('should correctly calculate net worth', () {
      final playerData = PlayerData()
        ..savings = 1000
        ..assets.add(Asset(
          name: 'Test Asset',
          category: 'Immobilien',
          cost: 5000,
          downPayment: 1000,
        ))
        ..liabilities.add(Liability(
          name: 'Test Liability',
          category: 'Bankdarlehen',
          totalDebt: 2000,
          monthlyPayment: 100,
        ));

      playerData.calculateNetWorth();

      // NetWorth = Savings + Asset Values - Total Liabilities
      expect(playerData.netWorth, 1000 + 5000 - 2000);
    });

    test('should process payday correctly', () {
      final playerData = PlayerData()
        ..salary = 2000
        ..passiveIncome = 500
        ..totalExpenses = 1500
        ..savings = 1000;

      playerData.payday();

      // After payday, savings should increase by (salary + passive income - expenses)
      expect(playerData.savings, 1000 + (2000 + 500 - 1500));
      expect(playerData.cashflow, 2000 + 500 - 1500);
    });

    test('should convert to and from JSON', () {
      final originalData = PlayerData()
        ..salary = 2000
        ..savings = 5000
        ..passiveIncome = 500
        ..totalExpenses = 1500
        ..cashflow = 1000
        ..netWorth = 10000
        ..assets.add(Asset(
          name: 'Test Asset',
          category: 'Immobilien',
          cost: 5000,
          downPayment: 1000,
        ))
        ..liabilities.add(Liability(
          name: 'Test Liability',
          category: 'Bankdarlehen',
          totalDebt: 2000,
          monthlyPayment: 100,
        ))
        ..expenses.add(Expense(
          name: 'Test Expense',
          amount: 200,
          type: ExpenseType.other,
        ));

      final json = originalData.toJson();
      final recreatedData = PlayerData.fromJson(json);

      expect(recreatedData.salary, originalData.salary);
      expect(recreatedData.savings, originalData.savings);
      expect(recreatedData.passiveIncome, originalData.passiveIncome);
      expect(recreatedData.totalExpenses, originalData.totalExpenses);
      expect(recreatedData.cashflow, originalData.cashflow);
      expect(recreatedData.netWorth, originalData.netWorth);
      expect(recreatedData.assets.length, originalData.assets.length);
      expect(recreatedData.liabilities.length, originalData.liabilities.length);
      expect(recreatedData.expenses.length, originalData.expenses.length);
    });
  });
}
