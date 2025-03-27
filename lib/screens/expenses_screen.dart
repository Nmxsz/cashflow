import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../providers/player_provider.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/bankruptcy_dialog.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ausgaben'),
        actions: [
          ThemeToggleButton(),
        ],
      ),
      body: Consumer<PlayerProvider>(
        builder: (context, playerProvider, child) {
          final playerData = playerProvider.playerData;

          if (playerData == null) {
            return const Center(
              child: Text('Keine Spielerdaten vorhanden'),
            );
          }

          // Verwende die Gesamtausgaben direkt aus playerData
          int totalMonthlyExpenses = playerData.totalExpenses;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Übersicht',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        _buildInfoRow(
                            'Monatliches Gehalt', '${playerData.salary} €'),
                        _buildInfoRow('Passives Einkommen',
                            '${playerData.passiveIncome} €'),
                        _buildInfoRow(
                          'Monatliche Ausgaben',
                          '$totalMonthlyExpenses €',
                          valueColor: Colors.red,
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'Cashflow',
                          '${playerData.salary + playerData.passiveIncome - totalMonthlyExpenses} €',
                          valueColor: (playerData.salary +
                                      playerData.passiveIncome -
                                      totalMonthlyExpenses) >=
                                  0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Einzelne Ausgaben',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // Liste der Verbindlichkeiten
                if (playerData.liabilities.isNotEmpty) ...[
                  const Text(
                    'Verbindlichkeiten:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...playerData.liabilities
                      .map((liability) => _buildExpenseItem(
                            liability.name,
                            liability.monthlyPayment,
                            Icons.trending_down,
                            Colors.red,
                            playerData,
                          ))
                      .toList(),
                  const SizedBox(height: 16),
                ],

                // Liste der sonstigen Ausgaben
                if (playerData.expenses.isNotEmpty) ...[
                  const Text(
                    'Sonstige Ausgaben:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...playerData.expenses
                      .map((expense) => _buildExpenseItem(
                            expense.name,
                            expense.amount,
                            Icons.money_off,
                            Colors.orange,
                            playerData,
                          ))
                      .toList(),
                ],

                if (playerData.liabilities.isEmpty &&
                    playerData.expenses.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Text(
                        'Keine Ausgaben vorhanden',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(String title, int amount, IconData icon, Color color,
      PlayerData playerData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: Text(
          title == 'Kinder Ausgaben'
              ? '${amount * playerData.numberOfChildren} € (${playerData.numberOfChildren} Kinder)'
              : '$amount €',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _amountController = TextEditingController();
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final isBankrupt = playerProvider.playerData!.cashflow < 0;

    if (isBankrupt) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Du bist bankrott und kannst keine neuen Ausgaben hinzufügen!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Neue Ausgabe hinzufügen'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name der Ausgabe',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte gib einen Namen ein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Betrag',
                  suffixText: '€',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte gib einen Betrag ein';
                  }
                  final amount = int.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Bitte gib einen gültigen Betrag ein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ExpenseType>(
                value: ExpenseType.other,
                decoration: const InputDecoration(
                  labelText: 'Ausgabentyp',
                ),
                items: ExpenseType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (value) {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                final amount = int.parse(_amountController.text);

                // Berechne den neuen Cashflow
                final newCashflow = playerProvider.playerData!.salary +
                    playerProvider.playerData!.passiveIncome -
                    (playerProvider.playerData!.totalExpenses + amount);

                // Prüfe auf Bankrott
                if (playerProvider.wouldCauseBankruptcy(newCashflow)) {
                  Navigator.of(context).pop(); // Schließe den aktuellen Dialog
                  showDialog(
                    context: context,
                    builder: (context) => BankruptcyDialog(
                      onConfirm: () {
                        // Füge die Ausgabe hinzu
                        playerProvider.addExpense(Expense(
                          name: _nameController.text,
                          amount: amount,
                          type: ExpenseType.other,
                        ));
                        Navigator.of(context).pop();
                      },
                      onCancel: () => Navigator.of(context).pop(),
                    ),
                  );
                } else {
                  // Füge die Ausgabe direkt hinzu
                  playerProvider.addExpense(Expense(
                    name: _nameController.text,
                    amount: amount,
                    type: ExpenseType.other,
                  ));
                  Navigator.of(context).pop();
                }
              }
            },
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }

  // Gruppiert Bankdarlehen zu einem Eintrag
  List<Liability> _groupBankLoans(List<Liability> liabilities) {
    final bankLoans = liabilities
        .where((l) => l.category == LiabilityCategory.bankLoan)
        .toList();
    if (bankLoans.isEmpty) return liabilities;

    // Berechne die Gesamtsumme der Bankdarlehen
    final totalDebt =
        bankLoans.fold<int>(0, (sum, loan) => sum + loan.totalDebt);
    final totalPayment =
        bankLoans.fold<int>(0, (sum, loan) => sum + loan.monthlyPayment);

    // Erstelle einen zusammengefassten Eintrag für Bankdarlehen
    final groupedBankLoan = Liability(
      name: 'Bankdarlehen',
      category: LiabilityCategory.bankLoan,
      totalDebt: totalDebt,
      monthlyPayment: totalPayment,
    );

    // Füge den zusammengefassten Eintrag hinzu und entferne die einzelnen Bankdarlehen
    return liabilities
        .where((l) => l.category != LiabilityCategory.bankLoan)
        .toList()
      ..add(groupedBankLoan);
  }
}
