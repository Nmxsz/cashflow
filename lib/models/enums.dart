enum AssetCategory {
  stocks('Aktien/Fonds/CDs'),
  realEstate('Immobilien'),
  business('Geschäfte');

  final String displayName;
  const AssetCategory(this.displayName);

  static AssetCategory fromString(String value) {
    return AssetCategory.values.firstWhere(
      (category) => category.displayName == value,
      orElse: () => AssetCategory.stocks,
    );
  }

  @override
  String toString() => displayName;
}

enum LiabilityCategory {
  homeMortgage('Eigenheim-Hypothek'),
  studentLoan('BAföG-Darlehen'),
  carLoan('Autokredite'),
  creditCard('Kreditkarten'),
  consumerDebt('Verbraucherkreditschulden'),
  propertyMortgage('Immobilien-Hypothek'),
  business('Geschäfte'),
  bankLoan('Bankdarlehen'),
  other('Sonstige');

  final String displayName;
  const LiabilityCategory(this.displayName);

  static LiabilityCategory fromString(String value) {
    return LiabilityCategory.values.firstWhere(
      (category) => category.displayName == value,
      orElse: () => LiabilityCategory.other,
    );
  }

  @override
  String toString() => displayName;
}

enum ExpenseType {
  taxes('Steuern'),
  homePayment('Hauszahlung'),
  schoolLoan('Studiendarlehen'),
  carLoan('Autokredit'),
  creditCard('Kreditkarte'),
  retail('Einzelhandel'),
  otherExpenses('Sonstige Ausgaben'),
  perChild('Pro Kind'),
  other('Sonstiges');

  final String displayName;
  const ExpenseType(this.displayName);

  static ExpenseType fromString(String value) {
    return ExpenseType.values.firstWhere(
      (type) => type.displayName == value,
      orElse: () => ExpenseType.other,
    );
  }

  @override
  String toString() => displayName;
}
