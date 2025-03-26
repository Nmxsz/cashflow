class Schnickschnack {
  final String id;
  final String name;
  final int cost;
  final DateTime purchaseDate;

  Schnickschnack({
    required this.id,
    required this.name,
    required this.cost,
    required this.purchaseDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cost': cost,
      'purchaseDate': purchaseDate.toIso8601String(),
    };
  }

  factory Schnickschnack.fromJson(Map<String, dynamic> json) {
    return Schnickschnack(
      id: json['id'] as String,
      name: json['name'] as String,
      cost: json['cost'] as int,
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
    );
  }
}
