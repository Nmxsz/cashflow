import 'package:flutter_test/flutter_test.dart';
import 'package:cashflow/models/index.dart';

void main() {
  group('Liability', () {
    test('should create Liability with all values', () {
      final liability = Liability(
        name: 'Test Liability',
        category: LiabilityCategory.bankLoan,
        totalDebt: 5000,
        monthlyPayment: 100,
      );

      expect(liability.name, 'Test Liability');
      expect(liability.category, LiabilityCategory.bankLoan);
      expect(liability.totalDebt, 5000);
      expect(liability.monthlyPayment, 100);
    });

    test('should create property mortgage with zero monthly payment', () {
      final mortgage = Liability(
        name: 'Hypothek: Test Immobilie',
        category: LiabilityCategory.propertyMortgage,
        totalDebt: 45000,
        monthlyPayment: 0,
      );

      expect(mortgage.name, 'Hypothek: Test Immobilie');
      expect(mortgage.category, LiabilityCategory.propertyMortgage);
      expect(mortgage.totalDebt, 45000);
      expect(mortgage.monthlyPayment, 0);
      expect(mortgage.isPropertyMortgage, true);
    });

    test('should convert to and from JSON', () {
      final originalLiability = Liability(
        name: 'Test Liability',
        category: LiabilityCategory.bankLoan,
        totalDebt: 5000,
        monthlyPayment: 100,
      );

      final json = originalLiability.toJson();
      final recreatedLiability = Liability.fromJson(json);

      expect(recreatedLiability.name, originalLiability.name);
      expect(recreatedLiability.category, originalLiability.category);
      expect(recreatedLiability.totalDebt, originalLiability.totalDebt);
      expect(
          recreatedLiability.monthlyPayment, originalLiability.monthlyPayment);
    });

    test('should handle different liability categories', () {
      final testCases = [
        (
          LiabilityCategory.homeMortgage,
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
          LiabilityCategory.studentLoan,
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
          LiabilityCategory.carLoan,
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
          LiabilityCategory.creditCard,
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
          LiabilityCategory.consumerDebt,
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
          LiabilityCategory.propertyMortgage,
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
          LiabilityCategory.business,
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
          LiabilityCategory.bankLoan,
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
        final liability = Liability(
          name: 'Test ${testCase.$1}',
          category: testCase.$1,
          totalDebt: 1000,
          monthlyPayment:
              testCase.$1 == LiabilityCategory.propertyMortgage ? 0 : 50,
        );

        expect(liability.category, testCase.$1);
        expect(liability.isHomeMortgage, testCase.$2);
        expect(liability.isStudentLoan, testCase.$3);
        expect(liability.isCarLoan, testCase.$4);
        expect(liability.isCreditCard, testCase.$5);
        expect(liability.isConsumerDebt, testCase.$6);
        expect(liability.isPropertyMortgage, testCase.$7);
        expect(liability.isBusiness, testCase.$8);
        expect(liability.isBankLoan, testCase.$9);

        if (liability.isPropertyMortgage) {
          expect(liability.monthlyPayment, 0);
        } else {
          expect(liability.monthlyPayment, 50);
        }
      }
    });
  });
}
