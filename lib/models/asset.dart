class Asset {
  String name;
  int cost;
  int downPayment;
  int monthlyIncome;
  
  Asset({
    required this.name,
    required this.cost,
    this.downPayment = 0,
    required this.monthlyIncome,
  });
  
  // Konvertiert den Vermögenswert in ein JSON-Objekt
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'cost': cost,
      'downPayment': downPayment,
      'monthlyIncome': monthlyIncome,
    };
  }
  
  // Erstellt ein Asset-Objekt aus einem JSON-Objekt
  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      name: json['name'] as String,
      cost: json['cost'] as int,
      downPayment: json['downPayment'] as int,
      monthlyIncome: json['monthlyIncome'] as int,
    );
  }
} 