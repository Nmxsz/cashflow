import 'asset.dart';
import 'liability.dart';
import 'expense.dart';

class PlayerData {
  final String id;
  String name;
  String profession;
  int salary;
  int totalExpenses;
  int cashflow;
  int costPerChild;
  int savings;
  int passiveIncome;
  List<Asset> assets;
  List<Liability> liabilities;
  List<Expense> expenses;

  PlayerData({
    required this.id,
    required this.name,
    required this.profession,
    required this.salary,
    required this.totalExpenses,
    required this.cashflow,
    required this.costPerChild,
    this.savings = 0,
    this.passiveIncome = 0,
    this.assets = const [],
    this.liabilities = const [],
    this.expenses = const [],
  });

  // Berechne das Nettovermögen
  int get netWorth {
    final totalAssets = assets.fold<int>(
        0, (sum, asset) => sum + (asset.cost - asset.downPayment));
    final totalLiabilities =
        liabilities.fold<int>(0, (sum, liability) => sum + liability.totalDebt);
    return totalAssets - totalLiabilities + savings;
  }

  // Berechnet den aktualisierten Cashflow basierend auf Einkommen und Ausgaben
  void updateCashflow() {
    // Berechne das passive Einkommen aus den Assets
    passiveIncome = assets.fold<int>(
      0,
      (sum, asset) => sum + (asset.monthlyIncome ?? 0),
    );

    // Berechne die monatlichen Ausgaben
    totalExpenses =
        expenses.fold<int>(0, (sum, expense) => sum + expense.amount);

    // Berechne den Cashflow (Einkommen - Ausgaben)
    cashflow = salary + passiveIncome - totalExpenses;
  }

  // Berechnet die Zahltag-Aktionen
  void processPayday() {
    // Reduziere die Schulden für jede Verbindlichkeit
    List<Liability> liabilitiesToRemove = [];
    for (var liability in liabilities) {
      if (liability.totalDebt > liability.monthlyPayment) {
        liability.totalDebt -= liability.monthlyPayment;
      } else if (liability.totalDebt > 0) {
        liability.totalDebt = 0;
        liabilitiesToRemove.add(liability);
      }
    }

    // Entferne vollständig bezahlte Verbindlichkeiten
    if (liabilitiesToRemove.isNotEmpty) {
      for (var liability in liabilitiesToRemove) {
        expenses.removeWhere((e) => e.name == 'Zinsen für ${liability.name}');
        liabilities.remove(liability);
      }
    }

    // Aktualisiere Cashflow und füge Einkommen zu Ersparnissen hinzu
    updateCashflow();
    savings += salary + passiveIncome - totalExpenses;
  }

  // Fügt einen Vermögenswert hinzu
  void addAsset(Asset asset) {
    assets.add(asset);
    updateCashflow();
  }

  // Entfernt einen Vermögenswert
  void removeAsset(Asset asset) {
    assets.remove(asset);
    updateCashflow();
  }

  // Fügt eine Verbindlichkeit hinzu
  void addLiability(Liability liability) {
    liabilities.add(liability);
    updateCashflow();
  }

  // Entfernt eine Verbindlichkeit
  void removeLiability(Liability liability) {
    liabilities.remove(liability);
    updateCashflow();
  }

  // Fügt eine Ausgabe hinzu
  void addExpense(Expense expense) {
    expenses.add(expense);
    updateCashflow();
  }

  // Entfernt eine Ausgabe
  void removeExpense(Expense expense) {
    expenses.remove(expense);
    updateCashflow();
  }

  PlayerData copyWith({
    String? id,
    String? name,
    String? profession,
    int? salary,
    int? totalExpenses,
    int? cashflow,
    int? costPerChild,
    int? savings,
    int? passiveIncome,
    List<Asset>? assets,
    List<Liability>? liabilities,
    List<Expense>? expenses,
  }) {
    return PlayerData(
      id: id ?? this.id,
      name: name ?? this.name,
      profession: profession ?? this.profession,
      salary: salary ?? this.salary,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      cashflow: cashflow ?? this.cashflow,
      costPerChild: costPerChild ?? this.costPerChild,
      savings: savings ?? this.savings,
      passiveIncome: passiveIncome ?? this.passiveIncome,
      assets: assets ?? this.assets,
      liabilities: liabilities ?? this.liabilities,
      expenses: expenses ?? this.expenses,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profession': profession,
      'salary': salary,
      'totalExpenses': totalExpenses,
      'cashflow': cashflow,
      'costPerChild': costPerChild,
      'savings': savings,
      'passiveIncome': passiveIncome,
      'assets': assets.map((a) => a.toJson()).toList(),
      'liabilities': liabilities.map((l) => l.toJson()).toList(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
    };
  }

  factory PlayerData.fromJson(Map<String, dynamic> json) {
    return PlayerData(
      id: json['id'] as String,
      name: json['name'] as String,
      profession: json['profession'] as String,
      salary: json['salary'] as int,
      totalExpenses: json['totalExpenses'] as int,
      cashflow: json['cashflow'] as int,
      costPerChild: json['costPerChild'] as int,
      savings: json['savings'] as int,
      passiveIncome: json['passiveIncome'] as int,
      assets: (json['assets'] as List)
          .map((a) => Asset.fromJson(a as Map<String, dynamic>))
          .toList(),
      liabilities: (json['liabilities'] as List)
          .map((l) => Liability.fromJson(l as Map<String, dynamic>))
          .toList(),
      expenses: (json['expenses'] as List)
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerData && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
