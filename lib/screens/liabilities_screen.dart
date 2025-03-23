import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../providers/player_provider.dart';

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
  final List<String> _categories = [
    'Eigenheim-Hypothek',
    'BAföG-Darlehen',
    'Autokredite',
    'Kreditkarten',
    'Verbraucherkreditschulden',
    'Immobilien-Hypothek',
    'Geschäfte',
    'Bankdarlehen',
    'Sonstige'
  ];
  String _selectedCategory = 'Sonstige';

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
      _selectedCategory = 'Sonstige';
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
        monthlyPayment: _selectedCategory == 'Immobilien-Hypothek'
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
            const Text(
                'Möchtest du diese Verbindlichkeit vollständig abzahlen?'),
            const SizedBox(height: 12),
            Text('Gesamtschuld: ${liability.totalDebt} €'),
            Text('Monatliche Rate: ${liability.monthlyPayment} €'),
            const SizedBox(height: 12),
            if (liability.category == 'Bankdarlehen')
              const Text(
                'Hinweis: Bankdarlehen können nur teilweise abgezahlt werden.',
                style: TextStyle(color: Colors.orange),
              ),
            if (liability.category == 'Eigenheim-Hypothek')
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
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();

              // Aktualisiere die Spielerdaten
              final newSavings = playerData.savings - liability.totalDebt;

              // Berechne die neuen Ausgaben, aber nur für nicht-Immobilien-Hypotheken
              int newTotalExpenses = playerData.totalExpenses;
              if (liability.category != 'Immobilien-Hypothek') {
                // Finde die entsprechende Ausgabe
                final expenseIndex = playerData.expenses.indexWhere((expense) {
                  if (liability.category == 'Eigenheim-Hypothek') {
                    return expense.type == ExpenseType.homePayment;
                  } else if (liability.category == 'BAföG-Darlehen') {
                    return expense.type == ExpenseType.schoolLoan;
                  } else if (liability.category == 'Autokredite') {
                    return expense.type == ExpenseType.carLoan;
                  } else if (liability.category == 'Kreditkarten') {
                    return expense.type == ExpenseType.creditCard;
                  } else if (liability.category ==
                      'Verbraucherkreditschulden') {
                    return expense.type == ExpenseType.retail;
                  }
                  return false;
                });

                if (expenseIndex != -1) {
                  final expense = playerData.expenses[expenseIndex];
                  if (liability.category == 'Eigenheim-Hypothek') {
                    // Bei Hypotheken: Reduziere nur die Rate
                    final newAmount = expense.amount - liability.monthlyPayment;
                    if (newAmount > 0) {
                      // Aktualisiere die Ausgabe
                      playerProvider.updateExpense(
                          expenseIndex,
                          Expense(
                            name: expense.name,
                            amount: newAmount,
                            type: expense.type,
                          ));
                      newTotalExpenses =
                          playerData.totalExpenses - liability.monthlyPayment;
                    } else {
                      // Lösche die Ausgabe, wenn keine Rate mehr übrig ist
                      playerProvider.deleteExpense(expenseIndex);
                      newTotalExpenses =
                          playerData.totalExpenses - expense.amount;
                    }
                  } else {
                    // Bei anderen Verbindlichkeiten: Lösche die Ausgabe
                    playerProvider.deleteExpense(expenseIndex);
                    newTotalExpenses =
                        playerData.totalExpenses - expense.amount;
                  }
                }
              }

              final newCashflow = playerData.salary +
                  playerData.passiveIncome -
                  newTotalExpenses;

              if (liability.category == 'Bankdarlehen') {
                // Bei Bankdarlehen: Reduziere die Gesamtschuld und monatliche Rate
                final reducedDebt =
                    liability.totalDebt ~/ 2; // Reduziere um die Hälfte
                final reducedPayment = liability.monthlyPayment ~/ 2;

                final updatedLiability = Liability(
                  name: liability.name,
                  category: liability.category,
                  totalDebt: liability.totalDebt - reducedDebt,
                  monthlyPayment: liability.monthlyPayment - reducedPayment,
                );

                playerProvider.updateLiability(index, updatedLiability);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bankdarlehen teilweise zurückgezahlt!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                // Bei anderen Verbindlichkeiten: Lösche die Verbindlichkeit
                playerProvider.deleteLiability(index);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verbindlichkeit erfolgreich abgezahlt!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }

              // Aktualisiere die Spielerdaten
              playerProvider.updatePlayerStats(
                savings: newSavings,
                totalExpenses: newTotalExpenses,
                cashflow: newCashflow,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Abzahlen'),
          ),
        ],
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
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Kategorie',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedCategory,
                          items: _categories
                              .map((category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
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
                            if (value == null || value.isEmpty) {
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
                        if (_selectedCategory != 'Immobilien-Hypothek')
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
                        if (_selectedCategory == 'Immobilien-Hypothek')
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Monatliche Rate: 0 € (Rate ist bereits im Cashflow der Immobilie berücksichtigt)',
                              style: const TextStyle(color: Colors.grey),
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
