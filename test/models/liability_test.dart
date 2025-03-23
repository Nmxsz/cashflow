import 'package:flutter_test/flutter_test.dart';
import 'package:cashflow/models/liability.dart';

void main() {
  group('Liability', () {
    test('should create Liability with all values', () {
      final liability = Liability(
        name: 'Test Liability',
        category: 'Bankdarlehen',
        totalDebt: 5000,
        monthlyPayment: 100,
      );

      expect(liability.name, 'Test Liability');
      expect(liability.category, 'Bankdarlehen');
      expect(liability.totalDebt, 5000);
      expect(liability.monthlyPayment, 100);
    });

    test('should create property mortgage with zero monthly payment', () {
      final mortgage = Liability(
        name: 'Hypothek: Test Immobilie',
        category: 'Immobilien-Hypothek',
        totalDebt: 45000,
        monthlyPayment: 0,
      );

      expect(mortgage.name, 'Hypothek: Test Immobilie');
      expect(mortgage.category, 'Immobilien-Hypothek');
      expect(mortgage.totalDebt, 45000);
      expect(mortgage.monthlyPayment, 0);
    });

    test('should convert to and from JSON', () {
      final originalLiability = Liability(
        name: 'Test Liability',
        category: 'Bankdarlehen',
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
      final categories = [
        'Eigenheim-Hypothek',
        'BAföG-Darlehen',
        'Autokredite',
        'Kreditkarten',
        'Verbraucherkreditschulden',
        'Immobilien-Hypothek',
        'Geschäfte',
        'Bankdarlehen',
        'Sonstige'
      ];

      for (var category in categories) {
        final liability = Liability(
          name: 'Test $category',
          category: category,
          totalDebt: 1000,
          monthlyPayment: category == 'Immobilien-Hypothek' ? 0 : 50,
        );

        expect(liability.category, category);
        if (category == 'Immobilien-Hypothek') {
          expect(liability.monthlyPayment, 0);
        } else {
          expect(liability.monthlyPayment, 50);
        }
      }
    });
  });
}
