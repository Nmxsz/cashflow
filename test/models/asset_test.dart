import 'package:flutter_test/flutter_test.dart';
import 'package:cashflow/models/index.dart';

void main() {
  group('Asset', () {
    test('should create Asset with required values', () {
      final asset = Asset(
        name: 'Test Asset',
        category: AssetCategory.realEstate,
        cost: 5000,
      );

      expect(asset.name, 'Test Asset');
      expect(asset.category, AssetCategory.realEstate);
      expect(asset.cost, 5000);
      expect(asset.downPayment, 0);
      expect(asset.monthlyIncome, null);
      expect(asset.shares, null);
      expect(asset.costPerShare, null);
    });

    test('should create Asset with all values', () {
      final asset = Asset(
        name: 'Test Stock',
        category: AssetCategory.stocks,
        cost: 1000,
        downPayment: 0,
        monthlyIncome: 50,
        shares: 10,
        costPerShare: 100,
      );

      expect(asset.name, 'Test Stock');
      expect(asset.category, AssetCategory.stocks);
      expect(asset.cost, 1000);
      expect(asset.downPayment, 0);
      expect(asset.monthlyIncome, 50);
      expect(asset.shares, 10);
      expect(asset.costPerShare, 100);
    });

    test('should convert to and from JSON', () {
      final originalAsset = Asset(
        name: 'Test Asset',
        category: AssetCategory.realEstate,
        cost: 5000,
        downPayment: 1000,
        monthlyIncome: 200,
      );

      final json = originalAsset.toJson();
      final recreatedAsset = Asset.fromJson(json);

      expect(recreatedAsset.name, originalAsset.name);
      expect(recreatedAsset.category, originalAsset.category);
      expect(recreatedAsset.cost, originalAsset.cost);
      expect(recreatedAsset.downPayment, originalAsset.downPayment);
      expect(recreatedAsset.monthlyIncome, originalAsset.monthlyIncome);
      expect(recreatedAsset.shares, originalAsset.shares);
      expect(recreatedAsset.costPerShare, originalAsset.costPerShare);
    });

    test('should handle stock specific properties', () {
      final stockAsset = Asset(
        name: 'Test Stock',
        category: AssetCategory.stocks,
        cost: 1000,
        shares: 10,
        costPerShare: 100,
      );

      expect(stockAsset.isStock, true);
      expect(stockAsset.isRealEstate, false);
      expect(stockAsset.isBusiness, false);

      final json = stockAsset.toJson();
      final recreatedAsset = Asset.fromJson(json);

      expect(recreatedAsset.shares, 10);
      expect(recreatedAsset.costPerShare, 100);
      expect(recreatedAsset.cost, 1000);
      expect(recreatedAsset.category, AssetCategory.stocks);
      expect(recreatedAsset.isStock, true);
    });

    test('should handle category helper methods', () {
      final realEstateAsset = Asset(
        name: 'Test Property',
        category: AssetCategory.realEstate,
        cost: 5000,
      );

      expect(realEstateAsset.isStock, false);
      expect(realEstateAsset.isRealEstate, true);
      expect(realEstateAsset.isBusiness, false);

      final businessAsset = Asset(
        name: 'Test Business',
        category: AssetCategory.business,
        cost: 10000,
      );

      expect(businessAsset.isStock, false);
      expect(businessAsset.isRealEstate, false);
      expect(businessAsset.isBusiness, true);
    });
  });
}
