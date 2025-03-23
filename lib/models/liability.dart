class Liability {
  String name;
  int totalDebt;
  int monthlyPayment;
  
  Liability({
    required this.name,
    required this.totalDebt,
    required this.monthlyPayment,
  });
  
  // Konvertiert die Verbindlichkeit in ein JSON-Objekt
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'totalDebt': totalDebt,
      'monthlyPayment': monthlyPayment,
    };
  }
  
  // Erstellt ein Liability-Objekt aus einem JSON-Objekt
  factory Liability.fromJson(Map<String, dynamic> json) {
    return Liability(
      name: json['name'] as String,
      totalDebt: json['totalDebt'] as int,
      monthlyPayment: json['monthlyPayment'] as int,
    );
  }
} 