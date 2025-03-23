class Liability {
  String name;
  String category;
  int totalDebt;
  int monthlyPayment;

  Liability({
    required this.name,
    required this.category,
    required this.totalDebt,
    required this.monthlyPayment,
  });

  // Konvertiert die Verbindlichkeit in ein JSON-Objekt
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'totalDebt': totalDebt,
      'monthlyPayment': monthlyPayment,
    };
  }

  // Erstellt ein Liability-Objekt aus einem JSON-Objekt
  factory Liability.fromJson(Map<String, dynamic> json) {
    return Liability(
      name: json['name'] as String,
      category: json['category'] as String? ??
          'Sonstige', // Fallback für ältere Daten
      totalDebt: json['totalDebt'] as int,
      monthlyPayment: json['monthlyPayment'] as int,
    );
  }
}
