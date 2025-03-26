import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/index.dart';

class PlayerService {
  static const String _playerDataKey = 'player_data';

  // Speichert die Spielerdaten in SharedPreferences
  Future<void> savePlayerData(PlayerData playerData) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = jsonEncode(playerData.toJson());
    await prefs.setString(_playerDataKey, jsonData);
  }

  // Lädt die Spielerdaten aus SharedPreferences
  Future<PlayerData?> loadPlayerData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_playerDataKey);

    if (jsonData == null) {
      return null;
    }

    try {
      final Map<String, dynamic> data = jsonDecode(jsonData);
      return PlayerData.fromJson(data);
    } catch (e) {
      print('Fehler beim Laden der Spielerdaten: $e');
      return null;
    }
  }

  // Löscht die Spielerdaten aus SharedPreferences
  Future<void> deletePlayerData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_playerDataKey);
  }

  // Aktualisiert die Spielerdaten an einem Zahltag
  Future<PlayerData> processPayday(PlayerData playerData) async {
    // Reduziere die Hypotheken für Immobilien
    for (var asset in playerData.assets) {
      if (asset.category == 'Immobilien') {
        // Finde die zugehörige Hypothek
        final mortgageIndex = playerData.liabilities.indexWhere(
          (liability) => liability.name == 'Hypothek: ${asset.name}',
        );

        if (mortgageIndex >= 0) {
          // Berechne die monatliche Rate (1% der ursprünglichen Hypothek)
          final liability = playerData.liabilities[mortgageIndex];
          final monthlyPayment = (asset.cost - asset.downPayment) * 0.01;

          // Reduziere die Hypothek um die monatliche Rate
          final newTotalDebt = liability.totalDebt - monthlyPayment.toInt();

          if (newTotalDebt <= 0) {
            // Hypothek ist abbezahlt
            playerData.liabilities.removeAt(mortgageIndex);
          } else {
            // Aktualisiere die Hypothek
            playerData.liabilities[mortgageIndex] = Liability(
              name: liability.name,
              category: liability.category,
              totalDebt: newTotalDebt,
              monthlyPayment: 0, // Bleibt 0, da im Cashflow berücksichtigt
            );
          }
        }
      }
    }

    // Normaler Zahltag-Prozess
    playerData.processPayday();
    await savePlayerData(playerData);
    return playerData;
  }

  // Fügt einen neuen Vermögenswert hinzu
  Future<PlayerData> addAsset(PlayerData playerData, Asset asset) async {
    // Füge den Vermögenswert zur Liste hinzu
    playerData.addAsset(asset);

    // Bei Immobilien wird nur die Anzahlung von den Ersparnissen abgezogen
    if (asset.category == 'Immobilien') {
      playerData.savings -= asset.downPayment;
    } else {
      // Bei anderen Assets werden die gesamten Kosten abgezogen
      playerData.savings -= asset.cost;
    }

    await savePlayerData(playerData);
    return playerData;
  }

  // Fügt eine neue Verbindlichkeit hinzu
  Future<PlayerData> addLiability(
      PlayerData playerData, Liability liability) async {
    // Füge die Verbindlichkeit zur Liste hinzu
    playerData.addLiability(liability);

    // Nur für nicht-Immobilien-Hypotheken: Füge eine entsprechende Ausgabe hinzu
    if (liability.category != 'Immobilien-Hypothek') {
      // Bestimme den Ausgabentyp basierend auf der Kategorie
      ExpenseType expenseType;
      switch (liability.category) {
        case 'Eigenheim-Hypothek':
          expenseType = ExpenseType.homePayment;
          break;
        case 'BAföG-Darlehen':
          expenseType = ExpenseType.schoolLoan;
          break;
        case 'Autokredite':
          expenseType = ExpenseType.carLoan;
          break;
        case 'Kreditkarten':
          expenseType = ExpenseType.creditCard;
          break;
        case 'Verbraucherkreditschulden':
          expenseType = ExpenseType.retail;
          break;
        default:
          expenseType = ExpenseType.other;
      }

      // Füge die monatliche Rate als Ausgabe hinzu
      final expense = Expense(
        name: liability.name,
        amount: liability.monthlyPayment,
        type: expenseType,
      );
      playerData.expenses.add(expense);

      // Aktualisiere die Gesamtausgaben und den Cashflow
      playerData.totalExpenses += expense.amount;
      playerData.cashflow = playerData.salary +
          playerData.passiveIncome -
          playerData.totalExpenses;
    }

    await savePlayerData(playerData);
    return playerData;
  }

  // Aktualisiert einen bestehenden Vermögenswert
  Future<PlayerData> updateAsset(
      PlayerData playerData, int index, Asset updatedAsset) async {
    playerData.assets[index] = updatedAsset;
    playerData.updateCashflow();
    await savePlayerData(playerData);
    return playerData;
  }

  // Löscht einen Vermögenswert
  Future<PlayerData> deleteAsset(PlayerData playerData, int index) async {
    playerData.removeAsset(playerData.assets[index]);
    await savePlayerData(playerData);
    return playerData;
  }

  // Aktualisiert eine bestehende Verbindlichkeit
  Future<PlayerData> updateLiability(
      PlayerData playerData, int index, Liability updatedLiability) async {
    playerData.liabilities[index] = updatedLiability;
    playerData.updateCashflow();
    await savePlayerData(playerData);
    return playerData;
  }

  // Löscht eine Verbindlichkeit
  Future<PlayerData> deleteLiability(PlayerData playerData, int index) async {
    playerData.removeLiability(playerData.liabilities[index]);
    await savePlayerData(playerData);
    return playerData;
  }

  // Aktualisiert eine bestehende Ausgabe
  Future<PlayerData> updateExpense(
      PlayerData playerData, int index, Expense updatedExpense) async {
    playerData.expenses[index] = updatedExpense;
    await savePlayerData(playerData);
    return playerData;
  }

  // Löscht eine Ausgabe
  Future<PlayerData> deleteExpense(PlayerData playerData, int index) async {
    playerData.expenses.removeAt(index);
    await savePlayerData(playerData);
    return playerData;
  }

  // Verkauft einen Vermögenswert
  Future<PlayerData> sellAsset(
      PlayerData playerData, int index, int sellPrice) async {
    final asset = playerData.assets[index];

    // Berechne den tatsächlichen Gewinn basierend auf der Asset-Kategorie
    int profit = sellPrice;

    if (asset.category == AssetCategory.realEstate) {
      // Bei Immobilien: Verkaufspreis minus verbleibende Hypothek
      final mortgageIndex = playerData.liabilities.indexWhere(
        (liability) => liability.name == 'Hypothek: ${asset.name}',
      );

      if (mortgageIndex >= 0) {
        // Ziehe die verbleibende Hypothek vom Verkaufspreis ab
        final remainingMortgage =
            playerData.liabilities[mortgageIndex].totalDebt;
        // Der Gewinn ist: Verkaufspreis minus verbleibende Hypothek minus ursprüngliche Anzahlung
        profit = sellPrice - remainingMortgage - asset.downPayment;
      } else {
        // Falls keine Hypothek gefunden wurde (unwahrscheinlich), berechne den Gewinn normal
        profit = sellPrice - asset.cost;
      }
    } else {
      // Bei anderen Assets: Der Gewinn ist Verkaufspreis minus ursprüngliche Kosten
      profit = sellPrice - asset.cost;
    }

    // Aktualisiere die Ersparnisse:
    // Bei Immobilien: Anzahlung + Gewinn
    // Bei anderen Assets: Verkaufspreis
    if (asset.category == AssetCategory.realEstate) {
      playerData.savings += asset.downPayment + profit;
    } else {
      playerData.savings += sellPrice;
    }

    // Entferne das Asset aus der Liste
    playerData.removeAsset(asset);

    await savePlayerData(playerData);
    return playerData;
  }

  // Fügt einen neuen Schnickschnack hinzu
  Future<PlayerData> addSchnickschnack(
      PlayerData playerData, Schnickschnack item) async {
    // Prüfen, ob genügend Ersparnisse vorhanden sind
    if (playerData.savings < item.cost) {
      throw Exception('Nicht genügend Ersparnisse für den Kauf');
    }

    // Füge den Schnickschnack zur Liste hinzu
    playerData.schnickschnackItems.add(item);

    // Reduziere die Ersparnisse
    playerData.savings -= item.cost;

    await savePlayerData(playerData);
    return playerData;
  }

  // Entfernt einen Schnickschnack
  Future<PlayerData> removeSchnickschnack(
      PlayerData playerData, Schnickschnack item) async {
    playerData.schnickschnackItems.remove(item);
    await savePlayerData(playerData);
    return playerData;
  }
}
