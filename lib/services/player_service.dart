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
    playerData.payday();
    await savePlayerData(playerData);
    return playerData;
  }

  // Fügt einen neuen Vermögenswert hinzu
  Future<PlayerData> addAsset(PlayerData playerData, Asset asset) async {
    playerData.addAsset(asset);
    await savePlayerData(playerData);
    return playerData;
  }

  // Fügt eine neue Verbindlichkeit hinzu
  Future<PlayerData> addLiability(
      PlayerData playerData, Liability liability) async {
    playerData.addLiability(liability);
    await savePlayerData(playerData);
    return playerData;
  }

  // Aktualisiert einen bestehenden Vermögenswert
  Future<PlayerData> updateAsset(
      PlayerData playerData, int index, Asset updatedAsset) async {
    playerData.updateAsset(index, updatedAsset);
    await savePlayerData(playerData);
    return playerData;
  }

  // Löscht einen Vermögenswert
  Future<PlayerData> deleteAsset(PlayerData playerData, int index) async {
    playerData.deleteAsset(index);
    await savePlayerData(playerData);
    return playerData;
  }

  // Aktualisiert eine bestehende Verbindlichkeit
  Future<PlayerData> updateLiability(
      PlayerData playerData, int index, Liability updatedLiability) async {
    playerData.updateLiability(index, updatedLiability);
    await savePlayerData(playerData);
    return playerData;
  }

  // Löscht eine Verbindlichkeit
  Future<PlayerData> deleteLiability(PlayerData playerData, int index) async {
    playerData.deleteLiability(index);
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
    playerData.sellAsset(index, sellPrice: sellPrice);
    await savePlayerData(playerData);
    return playerData;
  }
}
