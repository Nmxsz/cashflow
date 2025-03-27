import 'package:flutter/foundation.dart';
import '../models/index.dart';
import '../services/player_service.dart';

class PlayerProvider extends ChangeNotifier {
  PlayerData? _playerData;
  final PlayerService _playerService = PlayerService();
  bool _isBankrupt = false;

  PlayerData? get playerData => _playerData;
  bool get isBankrupt => _isBankrupt;

  // Lädt die Spielerdaten beim Start der App
  Future<void> loadPlayerData() async {
    _playerData = await _playerService.loadPlayerData();
    if (_playerData != null) {
      _isBankrupt = _playerData!.cashflow < 0;
    }
    notifyListeners();
  }

  // Speichert neue Spielerdaten
  Future<void> setPlayerData(PlayerData playerData) async {
    _playerData = playerData;
    _isBankrupt = playerData.cashflow < 0;
    await _playerService.savePlayerData(playerData);
    notifyListeners();
  }

  // Prüft, ob eine Aktion zu Bankrott führen würde
  bool wouldCauseBankruptcy(int newCashflow) {
    return newCashflow < 0;
  }

  // Setzt den Bankrott-Status
  void setBankruptcy(bool isBankrupt) {
    _isBankrupt = isBankrupt;
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

    // Berechne den neuen Cashflow
    final newCashflow = playerData!.salary +
        playerData!.passiveIncome -
        (playerData!.totalExpenses + liability.monthlyPayment);

    // Prüfe auf Bankrott
    if (wouldCauseBankruptcy(newCashflow)) {
      setBankruptcy(true);
    }

    // Wenn es sich um ein Bankdarlehen handelt, suche nach einem existierenden Bankdarlehen
    if (liability.category == LiabilityCategory.bankLoan) {
      final existingBankLoanIndex = playerData!.liabilities.indexWhere(
        (l) => l.category == LiabilityCategory.bankLoan,
      );

      if (existingBankLoanIndex != -1) {
        // Aktualisiere das existierende Bankdarlehen
        final existingLoan = playerData!.liabilities[existingBankLoanIndex];
        final updatedLoan = Liability(
          name: 'Bankdarlehen',
          category: LiabilityCategory.bankLoan,
          totalDebt: existingLoan.totalDebt + liability.totalDebt,
          monthlyPayment:
              existingLoan.monthlyPayment + liability.monthlyPayment,
        );
        playerData!.liabilities[existingBankLoanIndex] = updatedLoan;
      } else {
        // Füge ein neues Bankdarlehen hinzu
        playerData!.liabilities.add(liability);
      }
    } else {
      // Für alle anderen Verbindlichkeiten: normaler Prozess
      playerData!.liabilities.add(liability);
    }

    await _playerService.savePlayerData(playerData!);
    notifyListeners();
  }

  // Fügt eine neue Ausgabe hinzu
  Future<void> addExpense(Expense expense) async {
    if (playerData == null) return;

    // Berechne den neuen Cashflow
    final newCashflow = playerData!.salary +
        playerData!.passiveIncome -
        (playerData!.totalExpenses + expense.amount);

    // Prüfe auf Bankrott
    if (wouldCauseBankruptcy(newCashflow)) {
      setBankruptcy(true);
    }

    playerData!.expenses.add(expense);
    playerData!.totalExpenses += expense.amount;
    playerData!.cashflow = newCashflow;

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

  // Fügt einen neuen Schnickschnack hinzu
  Future<void> addSchnickschnack(Schnickschnack item) async {
    if (_playerData != null) {
      try {
        // Füge den Schnickschnack hinzu und aktualisiere die Ersparnisse
        _playerData!.addSchnickschnack(item);

        // Speichere die aktualisierten Daten
        await _playerService.savePlayerData(_playerData!);

        // Benachrichtige die Listener
        notifyListeners();
      } catch (e) {
        print('Fehler beim Hinzufügen von Schnickschnack: $e');
        rethrow; // Werfe den Fehler weiter, damit er im UI behandelt werden kann
      }
    }
  }

  // Entfernt einen Schnickschnack
  Future<void> removeSchnickschnack(Schnickschnack item) async {
    if (_playerData != null) {
      _playerData =
          await _playerService.removeSchnickschnack(_playerData!, item);
      notifyListeners();
    }
  }

  // Fügt ein Kind hinzu
  Future<void> addChild() async {
    if (_playerData != null) {
      _playerData = await _playerService.addChild(_playerData!);
      notifyListeners();
    }
  }

  // Entfernt ein Kind
  Future<void> removeChild() async {
    if (_playerData != null) {
      _playerData = await _playerService.removeChild(_playerData!);
      notifyListeners();
    }
  }
}
