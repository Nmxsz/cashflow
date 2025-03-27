import 'enums.dart';

class Expense {
  String name;
  int amount;
  ExpenseType type;

  Expense({
    required this.name,
    required this.amount,
    required this.type,
  });

  // Konvertiert die Ausgabe in ein JSON-Objekt
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'type': type.toString(),
    };
  }

  // Erstellt ein Expense-Objekt aus einem JSON-Objekt
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      name: json['name'] as String,
      amount: json['amount'] as int,
      type: ExpenseType.fromString(json['type'] as String? ?? 'Sonstiges'),
    );
  }

  bool get isTaxes => type == ExpenseType.taxes;
  bool get isHomePayment => type == ExpenseType.homePayment;
  bool get isSchoolLoan => type == ExpenseType.schoolLoan;
  bool get isCarLoan => type == ExpenseType.carLoan;
  bool get isCreditCard => type == ExpenseType.creditCard;
  bool get isRetail => type == ExpenseType.retail;
  bool get isOtherExpenses => type == ExpenseType.otherExpenses;
  bool get isPerChild => type == ExpenseType.perChild;
  bool get isBankLoan => type == ExpenseType.bankLoan;
  bool get isOther => type == ExpenseType.other;
}
