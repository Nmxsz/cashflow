import 'package:flutter/foundation.dart';
import '../models/index.dart';
import '../services/player_service.dart';

class PlayerProvider extends ChangeNotifier {
  PlayerData? _playerData;
  final PlayerService _playerService = PlayerService();

  PlayerData? get playerData => _playerData;

  // Lädt die Spielerdaten beim Start der App
  Future<void> loadPlayerData() async {
    _playerData = await _playerService.loadPlayerData();
    notifyListeners();
  }

  // Speichert neue Spielerdaten
  Future<void> setPlayerData(PlayerData playerData) async {
    _playerData = playerData;
    await _playerService.savePlayerData(playerData);
    notifyListeners();
  }

  // Aktualisiert die Spielerdaten
  Future<void> updatePlayerData() async {
    if (_playerData != null) {
      await _playerService.savePlayerData(_playerData!);
      notifyListeners();
    }
  }

  // Fügt einen neuen Vermögenswert hinzu
  Future<void> addAsset(Asset asset) async {
    if (_playerData != null) {
      _playerData = await _playerService.addAsset(_playerData!, asset);
      notifyListeners();
    }
  }

  // Fügt eine neue Verbindlichkeit hinzu
  Future<void> addLiability(Liability liability) async {
    if (playerData == null) return;

    playerData!.liabilities.add(liability);
    await _playerService.savePlayerData(playerData!);
    notifyListeners();
  }

  // Fügt eine neue Ausgabe hinzu
  Future<void> addExpense(Expense expense) async {
    if (playerData == null) return;

    playerData!.expenses.add(expense);
    playerData!.totalExpenses += expense.amount;
    playerData!.cashflow = playerData!.salary +
        playerData!.passiveIncome -
        playerData!.totalExpenses;

    await _playerService.savePlayerData(playerData!);
    notifyListeners();
  }

  // Verarbeitet einen Zahltag
  Future<void> processPayday() async {
    if (_playerData != null) {
      _playerData = await _playerService.processPayday(_playerData!);
      notifyListeners();
    }
  }

  // Aktualisiert einen bestehenden Vermögenswert
  Future<void> updateAsset(int index, Asset updatedAsset) async {
    if (_playerData != null) {
      _playerData =
          await _playerService.updateAsset(_playerData!, index, updatedAsset);
      notifyListeners();
    }
  }

  // Löscht einen Vermögenswert
  Future<void> deleteAsset(int index) async {
    if (_playerData != null) {
      _playerData = await _playerService.deleteAsset(_playerData!, index);
      notifyListeners();
    }
  }

  // Aktualisiert eine bestehende Verbindlichkeit
  Future<void> updateLiability(int index, Liability updatedLiability) async {
    if (_playerData != null) {
      _playerData = await _playerService.updateLiability(
          _playerData!, index, updatedLiability);
      notifyListeners();
    }
  }

  // Löscht eine Verbindlichkeit
  Future<void> deleteLiability(int index) async {
    if (_playerData != null) {
      _playerData = await _playerService.deleteLiability(_playerData!, index);
      notifyListeners();
    }
  }

  // Verkauft einen Vermögenswert und erhält den Erlös
  Future<void> sellAsset(int index, int sellPrice) async {
    if (_playerData != null) {
      _playerData =
          await _playerService.sellAsset(_playerData!, index, sellPrice);
      notifyListeners();
    }
  }

  // Aktualisiert die Spielerstatistiken
  Future<void> updatePlayerStats({
    int? savings,
    int? totalExpenses,
    int? cashflow,
  }) async {
    if (_playerData != null) {
      if (savings != null) _playerData!.savings = savings;
      if (totalExpenses != null) _playerData!.totalExpenses = totalExpenses;
      if (cashflow != null) _playerData!.cashflow = cashflow;

      // Berechne das neue Nettovermögen
      _playerData!.calculateNetWorth();

      await _playerService.savePlayerData(_playerData!);
      notifyListeners();
    }
  }

  // Aktualisiert eine bestehende Ausgabe
  Future<void> updateExpense(int index, Expense updatedExpense) async {
    if (_playerData != null) {
      _playerData = await _playerService.updateExpense(
          _playerData!, index, updatedExpense);
      notifyListeners();
    }
  }

  // Löscht eine Ausgabe
  Future<void> deleteExpense(int index) async {
    if (_playerData != null) {
      _playerData = await _playerService.deleteExpense(_playerData!, index);
      notifyListeners();
    }
  }

  // Setzt die Spielerdaten zurück
  Future<void> resetPlayerData() async {
    await _playerService.deletePlayerData();
    _playerData = null;
    notifyListeners();
  }
}
