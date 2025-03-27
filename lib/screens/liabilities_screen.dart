import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../providers/player_provider.dart';
import '../widgets/theme_toggle_button.dart';

class LiabilitiesScreen extends StatefulWidget {
  const LiabilitiesScreen({Key? key}) : super(key: key);

  @override
  State<LiabilitiesScreen> createState() => _LiabilitiesScreenState();
}

class _LiabilitiesScreenState extends State<LiabilitiesScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _totalDebtController = TextEditingController();
  final TextEditingController _monthlyPaymentController =
      TextEditingController();

  // Kategorien für Verbindlichkeiten
  final List<LiabilityCategory> _categories = LiabilityCategory.values;
  LiabilityCategory _selectedCategory = LiabilityCategory.other;

  // Flag, ob wir im Bearbeitungsmodus sind
  bool _editMode = false;
  int _editingIndex = -1;

  @override
  void dispose() {
    _nameController.dispose();
    _totalDebtController.dispose();
    _monthlyPaymentController.dispose();
    super.dispose();
  }

  // Setzt die Formularfelder zurück
  void _resetForm() {
    setState(() {
      _editMode = false;
      _editingIndex = -1;
      _nameController.clear();
      _totalDebtController.clear();
      _monthlyPaymentController.clear();
      _selectedCategory = LiabilityCategory.other;
    });
  }

  // Füllt das Formular mit den Daten der zu bearbeitenden Verbindlichkeit
  void _prepareForEditing(Liability liability, int index) {
    setState(() {
      _editMode = true;
      _editingIndex = index;
      _nameController.text = liability.name;
      _selectedCategory = liability.category;
      _totalDebtController.text = liability.totalDebt.toString();
      _monthlyPaymentController.text = liability.monthlyPayment.toString();
    });
  }

  // Speichert die Verbindlichkeit (neu oder bearbeitet)
  void _saveLiability() {
    if (_formKey.currentState?.validate() ?? false) {
      // Erstelle die Verbindlichkeit
      final liability = Liability(
        name: _nameController.text,
        category: _selectedCategory,
        totalDebt: int.parse(_totalDebtController.text),
        monthlyPayment: _selectedCategory == LiabilityCategory.propertyMortgage
            ? 0 // Keine monatliche Rate für Immobilien-Hypotheken
            : int.parse(_monthlyPaymentController.text),
      );

      if (_editMode && _editingIndex >= 0) {
        // Verbindlichkeit aktualisieren
        Provider.of<PlayerProvider>(context, listen: false)
            .updateLiability(_editingIndex, liability);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verbindlichkeit erfolgreich aktualisiert!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Neue Verbindlichkeit hinzufügen
        Provider.of<PlayerProvider>(context, listen: false)
            .addLiability(liability);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verbindlichkeit erfolgreich hinzugefügt!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Formular zurücksetzen
      _resetForm();
    }
  }

  // Löscht eine Verbindlichkeit
  void _deleteLiability(int index) {
    // Bestätigungsdialog anzeigen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verbindlichkeit löschen'),
        content:
            const Text('Möchtest du diese Verbindlichkeit wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<PlayerProvider>(context, listen: false)
                  .deleteLiability(index);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Verbindlichkeit erfolgreich gelöscht!'),
                  backgroundColor: Colors.red,
                ),
              );
              // Falls wir gerade diese Verbindlichkeit bearbeiten, Formular zurücksetzen
              if (_editMode && _editingIndex == index) {
                _resetForm();
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  // Zahlt eine Verbindlichkeit vollständig ab
  void _payOffLiability(Liability liability, int index) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final playerData = playerProvider.playerData;

    if (playerData == null) return;

    // Prüfe, ob genügend Ersparnisse vorhanden sind
    if (playerData.savings < liability.totalDebt) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nicht genügend Ersparnisse vorhanden!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Bestätigungsdialog anzeigen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verbindlichkeit abzahlen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Möchtest du diese Verbindlichkeit abzahlen?'),
            const SizedBox(height: 12),
            Text('Gesamtschuld: ${liability.totalDebt} €'),
            Text('Monatliche Rate: ${liability.monthlyPayment} €'),
            const SizedBox(height: 12),
            if (liability.category == LiabilityCategory.bankLoan) ...[
              const Text(
                'Hinweis: Bankdarlehen können nur in 1000€ Schritten zurückgezahlt werden.',
                style: TextStyle(color: Colors.orange),
              ),
              const SizedBox(height: 8),
              Text(
                'Maximale Rückzahlung: ${(liability.totalDebt ~/ 1000) * 1000} €',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
            if (liability.category == LiabilityCategory.homeMortgage)
              const Text(
                'Hinweis: Die monatliche Rate wird von den Ausgaben abgezogen.',
                style: TextStyle(color: Colors.blue),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          if (liability.category == LiabilityCategory.bankLoan)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showBankLoanRepaymentDialog(liability, index);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.green),
              child: const Text('Teilweise zurückzahlen'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _processFullRepayment(liability, index);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Vollständig zurückzahlen'),
          ),
        ],
      ),
    );
  }

  // Zeigt den Dialog für die Rückzahlung eines Bankdarlehens
  void _showBankLoanRepaymentDialog(Liability liability, int index) {
    final maxRepayment = (liability.totalDebt ~/ 1000) * 1000;
    final TextEditingController repaymentController = TextEditingController(
      text: maxRepayment.toString(),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bankdarlehen zurückzahlen'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verfügbare Schulden: ${liability.totalDebt} €'),
              const SizedBox(height: 8),
              Text(
                'Maximale Rückzahlung: $maxRepayment €',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: repaymentController,
                decoration: const InputDecoration(
                  labelText: 'Rückzahlungsbetrag (€)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte gib einen Betrag ein';
                  }
                  final amount = int.tryParse(value);
                  if (amount == null || amount < 1000) {
                    return 'Mindestbetrag: 1000€';
                  }
                  if (amount > maxRepayment) {
                    return 'Betrag zu hoch';
                  }
                  if (amount % 1000 != 0) {
                    final nextThousand = ((amount ~/ 1000) + 1) * 1000;
                    final prevThousand = (amount ~/ 1000) * 1000;
                    return 'Nur glatte Tausender erlaubt. Nächste Optionen: $prevThousand€ oder $nextThousand€';
                  }
                  return null;
                },
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
              if (formKey.currentState?.validate() ?? false) {
                final amount = int.tryParse(repaymentController.text);
                if (amount != null) {
                  Navigator.of(context).pop();
                  _processBankLoanRepayment(liability, index, amount);
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Zurückzahlen'),
          ),
        ],
      ),
    );
  }

  // Verarbeitet die Rückzahlung eines Bankdarlehens
  void _processBankLoanRepayment(
      Liability liability, int index, int repaymentAmount) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final playerData = playerProvider.playerData;

    if (playerData == null) return;

    // Prüfe, ob genügend Ersparnisse vorhanden sind
    if (playerData.savings < repaymentAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nicht genügend Ersparnisse vorhanden!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Berechne die neue monatliche Rate (100€ pro 1000€ zurückgezahlt)
    final reducedPayment = (repaymentAmount ~/ 1000) * 100;

    final updatedLiability = Liability(
      name: liability.name,
      category: liability.category,
      totalDebt: liability.totalDebt - repaymentAmount,
      monthlyPayment: liability.monthlyPayment - reducedPayment,
    );

    playerProvider.updateLiability(index, updatedLiability);

    // Aktualisiere die Spielerdaten
    playerProvider.updatePlayerStats(
      savings: playerData.savings - repaymentAmount,
      totalExpenses: playerData.totalExpenses - reducedPayment,
      cashflow: playerData.salary +
          playerData.passiveIncome -
          (playerData.totalExpenses - reducedPayment),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Bankdarlehen um $repaymentAmount€ zurückgezahlt! Monatliche Rate reduziert um ${reducedPayment}€'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Verarbeitet die vollständige Rückzahlung einer Verbindlichkeit
  void _processFullRepayment(Liability liability, int index) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final playerData = playerProvider.playerData;

    if (playerData == null) return;

    // Prüfe, ob genügend Ersparnisse vorhanden sind
    if (playerData.savings < liability.totalDebt) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nicht genügend Ersparnisse vorhanden!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Berechne die neuen Ausgaben
    int newTotalExpenses = playerData.totalExpenses;
    if (liability.category != LiabilityCategory.propertyMortgage) {
      final expenseIndex = playerData.expenses.indexWhere((expense) {
        if (liability.category == LiabilityCategory.homeMortgage) {
          return expense.type == ExpenseType.homePayment;
        } else if (liability.category == LiabilityCategory.studentLoan) {
          return expense.type == ExpenseType.schoolLoan;
        } else if (liability.category == LiabilityCategory.carLoan) {
          return expense.type == ExpenseType.carLoan;
        } else if (liability.category == LiabilityCategory.creditCard) {
          return expense.type == ExpenseType.creditCard;
        } else if (liability.category == LiabilityCategory.consumerDebt) {
          return expense.type == ExpenseType.retail;
        }
        return false;
      });

      if (expenseIndex != -1) {
        final expense = playerData.expenses[expenseIndex];
        if (liability.category == LiabilityCategory.homeMortgage) {
          final newAmount = expense.amount - liability.monthlyPayment;
          if (newAmount > 0) {
            playerProvider.updateExpense(
              expenseIndex,
              Expense(
                name: expense.name,
                amount: newAmount,
                type: expense.type,
              ),
            );
            newTotalExpenses =
                playerData.totalExpenses - liability.monthlyPayment;
          } else {
            playerProvider.deleteExpense(expenseIndex);
            newTotalExpenses = playerData.totalExpenses - expense.amount;
          }
        } else {
          playerProvider.deleteExpense(expenseIndex);
          newTotalExpenses = playerData.totalExpenses - expense.amount;
        }
      }
    }

    // Aktualisiere die Spielerdaten
    playerProvider.updatePlayerStats(
      savings: playerData.savings - liability.totalDebt,
      totalExpenses: newTotalExpenses,
      cashflow: playerData.salary + playerData.passiveIncome - newTotalExpenses,
    );

    // Lösche die Verbindlichkeit
    playerProvider.deleteLiability(index);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verbindlichkeit erfolgreich abgezahlt!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verbindlichkeiten'),
        actions: [
          if (_editMode)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: _resetForm,
              tooltip: 'Bearbeitung abbrechen',
            ),
          const ThemeToggleButton(),
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

          // Berechne die Gesamtschulden
          int totalDebt = 0;
          for (var liability in playerData.liabilities) {
            totalDebt += liability.totalDebt;
          }

          return Column(
            children: [
              // Liste der vorhandenen Verbindlichkeiten
              Expanded(
                child: playerData.liabilities.isEmpty
                    ? const Center(
                        child: Text('Keine Verbindlichkeiten vorhanden'),
                      )
                    : Column(
                        children: [
                          // Übersicht-Karte für die Gesamtschulden
                          Card(
                            margin: const EdgeInsets.all(16),
                            color: Colors.red.shade800,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Gesamtschulden:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '$totalDebt €',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Liste der Verbindlichkeiten
                          Expanded(
                            child: ListView.builder(
                              itemCount: playerData.liabilities.length,
                              itemBuilder: (context, index) {
                                final liability = playerData.liabilities[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: ListTile(
                                    title: Text(liability.name),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Kategorie: ${liability.category}'),
                                        Text(
                                            'Schulden: ${liability.totalDebt} € | Monatliche Rate: ${liability.monthlyPayment} €'),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Abzahlen-Button
                                        IconButton(
                                          icon: const Icon(Icons.payment,
                                              color: Colors.green),
                                          onPressed: () => _payOffLiability(
                                              liability, index),
                                          tooltip: 'Abzahlen',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.blue),
                                          onPressed: () => _prepareForEditing(
                                              liability, index),
                                          tooltip: 'Bearbeiten',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () =>
                                              _deleteLiability(index),
                                          tooltip: 'Löschen',
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),

              // Formular zum Hinzufügen/Bearbeiten von Verbindlichkeiten
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _editMode
                              ? 'Verbindlichkeit bearbeiten'
                              : 'Neue Verbindlichkeit hinzufügen',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Bitte gib einen Namen ein';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        // Kategorieauswahl
                        DropdownButtonFormField<LiabilityCategory>(
                          decoration: const InputDecoration(
                            labelText: 'Kategorie',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedCategory,
                          items: _categories
                              .map((category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category.toString()),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Bitte wähle eine Kategorie aus';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _totalDebtController,
                          decoration: const InputDecoration(
                            labelText: 'Gesamtschuld (€)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Bitte gib die Gesamtschuld ein';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        if (_selectedCategory !=
                            LiabilityCategory.propertyMortgage)
                          TextFormField(
                            controller: _monthlyPaymentController,
                            decoration: const InputDecoration(
                              labelText: 'Monatliche Rate (€)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Bitte gib die monatliche Rate ein';
                              }
                              return null;
                            },
                          ),
                        if (_selectedCategory ==
                            LiabilityCategory.propertyMortgage)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Monatliche Rate: 0 € (Rate ist bereits im Cashflow der Immobilie berücksichtigt)',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),

                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _saveLiability,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _editMode ? Colors.blue : Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            _editMode
                                ? 'Verbindlichkeit aktualisieren'
                                : 'Verbindlichkeit hinzufügen',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
