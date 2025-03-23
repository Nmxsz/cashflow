import 'enums.dart';

class Liability {
  String name;
  LiabilityCategory category;
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
      'category': category.toString(),
      'totalDebt': totalDebt,
      'monthlyPayment': monthlyPayment,
    };
  }

  // Erstellt ein Liability-Objekt aus einem JSON-Objekt
  factory Liability.fromJson(Map<String, dynamic> json) {
    return Liability(
      name: json['name'] as String,
      category: LiabilityCategory.fromString(
          json['category'] as String? ?? 'Sonstige'),
      totalDebt: json['totalDebt'] as int,
      monthlyPayment: json['monthlyPayment'] as int,
    );
  }

  bool get isPropertyMortgage => category == LiabilityCategory.propertyMortgage;
  bool get isHomeMortgage => category == LiabilityCategory.homeMortgage;
  bool get isStudentLoan => category == LiabilityCategory.studentLoan;
  bool get isCarLoan => category == LiabilityCategory.carLoan;
  bool get isCreditCard => category == LiabilityCategory.creditCard;
  bool get isConsumerDebt => category == LiabilityCategory.consumerDebt;
  bool get isBusiness => category == LiabilityCategory.business;
  bool get isBankLoan => category == LiabilityCategory.bankLoan;
}
