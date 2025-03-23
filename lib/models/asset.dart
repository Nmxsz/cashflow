class Asset {
  String name;
  String category; // "Aktien/Fonds/CDs", "Immobilien", "Geschäfte"
  int cost;
  int downPayment;
  int? monthlyIncome; // Optional für Aktien/Fonds/CDs

  // Nur für Aktien/Fonds/CDs
  int? shares; // Anzahl der Anteile
  int? costPerShare; // Kosten pro Anteil

  Asset({
    required this.name,
    required this.category,
    required this.cost,
    this.downPayment = 0,
    this.monthlyIncome, // Optional
    this.shares,
    this.costPerShare,
  });

  // Konvertiert den Vermögenswert in ein JSON-Objekt
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'cost': cost,
      'downPayment': downPayment,
      'monthlyIncome': monthlyIncome,
      'shares': shares,
      'costPerShare': costPerShare,
    };
  }

  // Erstellt ein Asset-Objekt aus einem JSON-Objekt
  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      name: json['name'] as String,
      category: json['category'] as String? ??
          'Aktien/Fonds/CDs', // Fallback für ältere Daten
      cost: json['cost'] as int,
      downPayment: json['downPayment'] as int? ?? 0,
      monthlyIncome: json['monthlyIncome'] as int?, // Kann null sein
      shares: json['shares'] as int?,
      costPerShare: json['costPerShare'] as int?,
    );
  }
}
