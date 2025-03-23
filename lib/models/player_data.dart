import 'asset.dart';
import 'liability.dart';
import 'expense.dart';

class PlayerData {
  String name;
  String profession;
  int salary;
  int passiveIncome;
  int totalExpenses;
  int cashflow;
  int savings;
  int netWorth; // Gesamtvermögen des Spielers
  List<Asset> assets;
  List<Liability> liabilities;
  List<Expense> expenses;

  PlayerData({
    required this.name,
    required this.profession,
    required this.salary,
    this.passiveIncome = 0,
    required this.totalExpenses,
    required this.cashflow,
    this.savings = 0,
    this.netWorth = 0, // Standard-Initialwert
    List<Asset>? assets,
    List<Liability>? liabilities,
    List<Expense>? expenses,
  })  : assets = assets ?? [],
        liabilities = liabilities ?? [],
        expenses = expenses ?? [];

  // Berechnet den aktualisierten Cashflow basierend auf Einkommen und Ausgaben
  void calculateCashflow() {
    cashflow = salary + passiveIncome - totalExpenses;
  }

  // Aktualisiert das Spielerguthaben an jedem Zahltag und reduziert Verbindlichkeiten
  void payday() {
    // Erhöhe Ersparnisse um den Cashflow
    savings += cashflow;

    // Liste der zu entfernenden Verbindlichkeiten
    List<Liability> liabilitiesToRemove = [];

    // Reduziere die Schulden für jede Verbindlichkeit
    for (int i = 0; i < liabilities.length; i++) {
      Liability liability = liabilities[i];

      // Reduziere die Gesamtschuld um die monatliche Rate
      if (liability.totalDebt > liability.monthlyPayment) {
        // Normaler Fall: Es gibt noch mehr Schulden als die monatliche Rate
        liability.totalDebt -= liability.monthlyPayment;
      } else if (liability.totalDebt > 0) {
        // Wenn weniger als eine Rate übrig ist, setze auf 0
        liability.totalDebt = 0;
        // Markiere diese Verbindlichkeit zum Entfernen
        liabilitiesToRemove.add(liability);
      }
    }

    // Entferne vollständig bezahlte Verbindlichkeiten
    if (liabilitiesToRemove.isNotEmpty) {
      for (var liability in liabilitiesToRemove) {
        // Vor dem Entfernen die monatliche Rate aus den Gesamtausgaben abziehen
        totalExpenses -= liability.monthlyPayment;
        liabilities.remove(liability);
      }

      // Aktualisiere den Cashflow, da sich die Ausgaben geändert haben
      calculateCashflow();
    }

    // Aktualisiere das Gesamtvermögen
    calculateNetWorth();
  }

  // Berechnet das Gesamtvermögen des Spielers
  void calculateNetWorth() {
    int assetsValue = 0;
    for (var asset in assets) {
      assetsValue += asset.cost;
    }

    int liabilitiesValue = 0;
    for (var liability in liabilities) {
      liabilitiesValue += liability.totalDebt;
    }

    netWorth = savings + assetsValue - liabilitiesValue;
  }

  // Fügt einen Vermögenswert hinzu und aktualisiert passives Einkommen
  void addAsset(Asset asset) {
    assets.add(asset);
    passiveIncome += asset.monthlyIncome ?? 0; // Null-Check mit Standardwert 0

    // Bei Immobilien und Geschäften nur die Anzahlung abziehen
    if (asset.category == 'Immobilien' || asset.category == 'Geschäfte') {
      savings -= asset.downPayment;
    } else {
      // Bei anderen Assets (z.B. Aktien) die vollen Kosten abziehen
      savings -= asset.cost;
    }

    calculateCashflow();
    calculateNetWorth(); // Aktualisiere Gesamtvermögen nach Vermögenswert-Hinzufügung
  }

  // Fügt eine Verbindlichkeit hinzu und aktualisiert die Ausgaben
  void addLiability(Liability liability) {
    liabilities.add(liability);
    totalExpenses += liability.monthlyPayment;
    calculateCashflow();
    calculateNetWorth(); // Aktualisiere Gesamtvermögen nach Verbindlichkeits-Hinzufügung
  }

  // Bearbeitet einen bestehenden Vermögenswert
  void updateAsset(int index, Asset updatedAsset) {
    if (index >= 0 && index < assets.length) {
      // Entferne den Einfluss des alten Assets
      Asset oldAsset = assets[index];
      passiveIncome -=
          oldAsset.monthlyIncome ?? 0; // Null-Check mit Standardwert 0

      // Füge den Einfluss des neuen Assets hinzu
      passiveIncome +=
          updatedAsset.monthlyIncome ?? 0; // Null-Check mit Standardwert 0

      // Passe das Guthaben an, falls sich die Kosten geändert haben
      if (updatedAsset.cost != oldAsset.cost) {
        savings -= (updatedAsset.cost - oldAsset.cost);
      }

      // Aktualisiere das Asset in der Liste
      assets[index] = updatedAsset;

      // Aktualisiere Cashflow und Nettovermögen
      calculateCashflow();
      calculateNetWorth();
    }
  }

  // Löscht einen Vermögenswert
  void deleteAsset(int index) {
    if (index >= 0 && index < assets.length) {
      Asset asset = assets[index];

      // Entferne den Einfluss des Assets
      passiveIncome -=
          asset.monthlyIncome ?? 0; // Null-Check mit Standardwert 0

      // Füge den Vermögenswert wieder zum Guthaben hinzu (optional, je nach Spieldesign)
      // savings += asset.cost;

      // Entferne den Vermögenswert aus der Liste
      assets.removeAt(index);

      // Aktualisiere Cashflow und Nettovermögen
      calculateCashflow();
      calculateNetWorth();
    }
  }

  // Bearbeitet eine bestehende Verbindlichkeit
  void updateLiability(int index, Liability updatedLiability) {
    if (index >= 0 && index < liabilities.length) {
      // Entferne den Einfluss der alten Verbindlichkeit
      Liability oldLiability = liabilities[index];
      totalExpenses -= oldLiability.monthlyPayment;

      // Füge den Einfluss der neuen Verbindlichkeit hinzu
      totalExpenses += updatedLiability.monthlyPayment;

      // Aktualisiere die Verbindlichkeit in der Liste
      liabilities[index] = updatedLiability;

      // Aktualisiere Cashflow und Nettovermögen
      calculateCashflow();
      calculateNetWorth();
    }
  }

  // Löscht eine Verbindlichkeit
  void deleteLiability(int index) {
    if (index >= 0 && index < liabilities.length) {
      Liability liability = liabilities[index];

      // Entferne den Einfluss der Verbindlichkeit
      totalExpenses -= liability.monthlyPayment;

      // Entferne die Verbindlichkeit aus der Liste
      liabilities.removeAt(index);

      // Aktualisiere Cashflow und Nettovermögen
      calculateCashflow();
      calculateNetWorth();
    }
  }

  // Verkauft einen Vermögenswert und fügt den Erlös dem Guthaben hinzu
  void sellAsset(int index, {required int sellPrice}) {
    if (index >= 0 && index < assets.length) {
      Asset asset = assets[index];

      // Entferne den Einfluss des Assets
      passiveIncome -=
          asset.monthlyIncome ?? 0; // Null-Check mit Standardwert 0

      // Füge den Verkaufserlös zum Guthaben hinzu
      savings += sellPrice;

      // Entferne den Vermögenswert aus der Liste
      assets.removeAt(index);

      // Aktualisiere Cashflow und Nettovermögen
      calculateCashflow();
      calculateNetWorth();
    }
  }

  // Konvertiert die Spielerdaten in ein JSON-Objekt
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'profession': profession,
      'salary': salary,
      'passiveIncome': passiveIncome,
      'totalExpenses': totalExpenses,
      'cashflow': cashflow,
      'savings': savings,
      'netWorth': netWorth,
      'assets': assets.map((asset) => asset.toJson()).toList(),
      'liabilities':
          liabilities.map((liability) => liability.toJson()).toList(),
      'expenses': expenses.map((expense) => expense.toJson()).toList(),
    };
  }

  // Erstellt ein PlayerData-Objekt aus einem JSON-Objekt
  factory PlayerData.fromJson(Map<String, dynamic> json) {
    PlayerData playerData = PlayerData(
      name: json['name'] as String,
      profession: json['profession'] as String,
      salary: json['salary'] as int,
      passiveIncome: json['passiveIncome'] as int,
      totalExpenses: json['totalExpenses'] as int,
      cashflow: json['cashflow'] as int,
      savings: json['savings'] as int,
      netWorth: json['netWorth'] as int? ??
          0, // Fallback für alte Daten ohne netWorth
      assets: (json['assets'] as List<dynamic>)
          .map((e) => Asset.fromJson(e as Map<String, dynamic>))
          .toList(),
      liabilities: (json['liabilities'] as List<dynamic>)
          .map((e) => Liability.fromJson(e as Map<String, dynamic>))
          .toList(),
      expenses: (json['expenses'] as List<dynamic>?)
              ?.map((e) => Expense.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

    // Aktualisiere das Nettovermögen, falls es nicht in den JSON-Daten enthalten war
    playerData.calculateNetWorth();

    return playerData;
  }
}
