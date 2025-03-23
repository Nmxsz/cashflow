import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cashflow/services/player_service.dart';
import 'package:cashflow/models/index.dart';

void main() {
  group('PlayerService', () {
    late PlayerService playerService;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      playerService = PlayerService();
    });

    test('should save and load player data', () async {
      final playerData = PlayerData(
        id: 'uuid.v4()',
        name: 'Test Player',
        profession: 'Test Profession',
        salary: 2000,
        totalExpenses: 0,
        cashflow: 0,
        costPerChild: 0,
      )..savings = 5000;

      await playerService.savePlayerData(playerData);
      final loadedData = await playerService.loadPlayerData();

      expect(loadedData?.salary, 2000);
      expect(loadedData?.savings, 5000);
    });

    test('should process payday correctly', () async {
      final playerData = PlayerData(
        id: 'uuid.v4()',
        name: 'Test Player',
        profession: 'Test Profession',
        salary: 2000,
        totalExpenses: 1500,
        cashflow: 1000,
        costPerChild: 0,
      )
        ..passiveIncome = 500
        ..savings = 1000;

      final updatedData = await playerService.processPayday(playerData);

      expect(updatedData.savings, 2000); // 1000 + (2000 + 500 - 1500)
      expect(updatedData.cashflow, 1000); // 2000 + 500 - 1500
    });

    test('should add asset and update savings', () async {
      final playerData = PlayerData(
        id: 'uuid.v4()',
        name: 'Test Player',
        profession: 'Test Profession',
        salary: 0,
        totalExpenses: 0,
        cashflow: 0,
        costPerChild: 0,
      )..savings = 10000;

      final asset = Asset(
        name: 'Test Property',
        category: AssetCategory.realEstate,
        cost: 50000,
        downPayment: 5000,
      );

      final updatedData = await playerService.addAsset(playerData, asset);

      expect(updatedData.assets.length, 1);
      expect(updatedData.savings, 5000); // 10000 - 5000 (only downPayment)
    });

    test('should add liability without expense for property mortgage',
        () async {
      final playerData = PlayerData(
        id: 'uuid.v4()',
        name: 'Test Player',
        profession: 'Test Profession',
        salary: 0,
        totalExpenses: 1000,
        cashflow: 1000,
        costPerChild: 0,
      );

      final mortgage = Liability(
        name: 'Hypothek: Test Property',
        category: LiabilityCategory.propertyMortgage,
        totalDebt: 45000,
        monthlyPayment: 0,
      );

      final updatedData =
          await playerService.addLiability(playerData, mortgage);

      expect(updatedData.liabilities.length, 1);
      expect(updatedData.totalExpenses, 1000); // unchanged
      expect(updatedData.cashflow, 1000); // unchanged
    });

    test('should add liability with expense for other types', () async {
      final playerData = PlayerData(
        id: 'uuid.v4()',
        name: 'Test Player',
        profession: 'Test Profession',
        salary: 3000,
        totalExpenses: 1000,
        cashflow: 2000,
        costPerChild: 0,
      );

      final liability = Liability(
        name: 'Test Loan',
        category: LiabilityCategory.bankLoan,
        totalDebt: 5000,
        monthlyPayment: 100,
      );

      final updatedData =
          await playerService.addLiability(playerData, liability);

      expect(updatedData.liabilities.length, 1);
      expect(updatedData.expenses.length, 1);
      expect(updatedData.totalExpenses, 1100); // 1000 + 100
      expect(updatedData.cashflow, 1900); // 3000 - 1100
    });

    test('should sell asset and calculate profit correctly', () async {
        final playerData = PlayerData(
        id: 'uuid.v4()',
        name: 'Test Player',
        profession: 'Test Profession',
        salary: 0,
        totalExpenses: 0,
        cashflow: 0,
        costPerChild: 0,
      )..savings = 5000;

      final asset = Asset(
        name: 'Test Property',
        category: AssetCategory.realEstate,
        cost: 50000,
        downPayment: 5000,
      );
      playerData.assets.add(asset);

      final mortgage = Liability(
        name: 'Hypothek: Test Property',
        category: LiabilityCategory.propertyMortgage,
        totalDebt: 45000,
        monthlyPayment: 0,
      );
      playerData.liabilities.add(mortgage);

      final updatedData = await playerService.sellAsset(playerData, 0, 60000);

      expect(updatedData.savings,
          15000); // 5000 + 5000 (down payment) + 10000 (profit)
      expect(updatedData.assets.isEmpty, true);
      expect(updatedData.liabilities.isEmpty, true);
    });

    test('should reduce mortgage on payday', () async {
      final playerData = PlayerData(
        id: 'uuid.v4()',
        name: 'Test Player',
        profession: 'Test Profession',
        salary: 0,
        totalExpenses: 0,
        cashflow: 0,
        costPerChild: 0,
      );

      final asset = Asset(
        name: 'Test Property',
        category: AssetCategory.realEstate,
        cost: 50000,
        downPayment: 5000,
      );
      playerData.assets.add(asset);

      final mortgage = Liability(
        name: 'Hypothek: Test Property',
        category: LiabilityCategory.propertyMortgage,
        totalDebt: 45000,
        monthlyPayment: 0,
      );
      playerData.liabilities.add(mortgage);

      final updatedData = await playerService.processPayday(playerData);

      expect(updatedData.liabilities[0].totalDebt,
          44550); // 45000 - (45000 * 0.01)
    });
  });
}
