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
      'type': type.toString().split('.').last,
    };
  }
  
  // Erstellt ein Expense-Objekt aus einem JSON-Objekt
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      name: json['name'] as String,
      amount: json['amount'] as int,
      type: ExpenseType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ExpenseType.other,
      ),
    );
  }
}

enum ExpenseType {
  taxes,
  homePayment, 
  schoolLoan,
  carLoan,
  creditCard,
  retail,
  otherExpenses,
  perChild,
  other,
} 