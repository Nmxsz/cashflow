import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../providers/player_provider.dart';
import 'package:uuid/uuid.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _professionController = TextEditingController();
  final TextEditingController _costPerChildController = TextEditingController();
  final TextEditingController _savingsController = TextEditingController();

  // Einnahmen Controller
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _interestController = TextEditingController();
  final TextEditingController _dividendsController = TextEditingController();
  final TextEditingController _realEstateController = TextEditingController();

  // Verbindlichkeiten Controller und Namen
  final List<(String, LiabilityCategory)> _liabilityTypes = [
    ('Eigenheim-Hypothek', LiabilityCategory.homeMortgage),
    ('BAföG-Darlehen', LiabilityCategory.studentLoan),
    ('Autokredit', LiabilityCategory.carLoan),
    ('Kreditkarten', LiabilityCategory.creditCard),
    ('Verbraucherkreditschulden', LiabilityCategory.consumerDebt),
    ('Immobilien-Hypothek', LiabilityCategory.propertyMortgage),
    ('Geschäfte', LiabilityCategory.business),
    ('Bankdarlehen', LiabilityCategory.bankLoan),
  ];
  late List<TextEditingController> _liabilityAmountControllers;
  late List<TextEditingController> _liabilityPaymentControllers;

  // Ausgaben Controller
  final List<String> _expenseNames = [
    'Steuern',
    'Eigenheim-Hypothek / Miete',
    'BAföG Zahlung',
    'Auto Kredit Zahlung',
    'Kreditkarten Zahlung',
    'Verbraucherkredit Zahlung',
    'Sonstige Ausgaben',
    'Kinder Ausgaben',
  ];

  late List<TextEditingController> _expenseControllers;
  final TextEditingController _totalExpensesController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _expenseControllers = List.generate(
      _expenseNames.length,
      (index) => TextEditingController(),
    );
    _liabilityAmountControllers = List.generate(
      _liabilityTypes.length,
      (index) => TextEditingController(),
    );
    _liabilityPaymentControllers = List.generate(
      _liabilityTypes.length,
      (index) => TextEditingController(),
    );

    // Verbinde die Ausgaben-Controller mit den Verbindlichkeiten-Controllern
    _setupExpenseListeners();
  }

  // Verbindet die Ausgaben mit den entsprechenden monatlichen Raten der Verbindlichkeiten
  void _setupExpenseListeners() {
    // Map für die Zuordnung von Ausgaben zu Verbindlichkeiten
    final Map<int, String> expenseToLiabilityName = {
      1: _liabilityTypes[0].$1, // Eigenheimrate -> Eigenheim-Hypothek
      2: _liabilityTypes[1].$1, // BAföG-Darlehen -> BAföG-Darlehen
      3: _liabilityTypes[2].$1, // Auto Kredit Zahlung -> Autokredit
      4: _liabilityTypes[3].$1, // Kreditkarten Zahlung -> Kreditkarten
      5: _liabilityTypes[4]
          .$1, // Verbraucherkredit Zahlung -> Verbraucherkreditschulden
    };

    // Füge Listener für die relevanten Ausgaben-Controller hinzu
    expenseToLiabilityName.forEach((expenseIndex, liabilityName) {
      _expenseControllers[expenseIndex].addListener(() {
        final expenseAmount = _expenseControllers[expenseIndex].text;

        // Finde den Index der entsprechenden Verbindlichkeit
        final liabilityIndex =
            _liabilityTypes.indexWhere((t) => t.$1 == liabilityName);
        if (liabilityIndex != -1) {
          // Aktualisiere die monatliche Rate der Verbindlichkeit
          _liabilityPaymentControllers[liabilityIndex].text = expenseAmount;
        }
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _professionController.dispose();
    _costPerChildController.dispose();
    _savingsController.dispose();
    _salaryController.dispose();
    _interestController.dispose();
    _dividendsController.dispose();
    _realEstateController.dispose();
    for (var controller in _expenseControllers) {
      controller.dispose();
    }
    for (var controller in _liabilityAmountControllers) {
      controller.dispose();
    }
    for (var controller in _liabilityPaymentControllers) {
      controller.dispose();
    }
    _totalExpensesController.dispose();
    super.dispose();
  }

  // Berechnet die Gesamtausgaben
  void _calculateTotalExpenses() {
    int total = 0;
    for (var controller in _expenseControllers) {
      if (controller.text.isNotEmpty) {
        total += int.parse(controller.text);
      }
    }
    _totalExpensesController.text = total.toString();
  }

  // Berechnet das passive Einkommen
  int _calculatePassiveIncome() {
    int passiveIncome = 0;
    if (_interestController.text.isNotEmpty) {
      passiveIncome += int.parse(_interestController.text);
    }
    if (_dividendsController.text.isNotEmpty) {
      passiveIncome += int.parse(_dividendsController.text);
    }
    if (_realEstateController.text.isNotEmpty) {
      passiveIncome += int.parse(_realEstateController.text);
    }
    return passiveIncome;
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final List<Expense> expenses = [];
      final List<Liability> liabilities = [];

      // Erstelle Ausgaben
      for (int i = 0; i < _expenseNames.length; i++) {
        if (_expenseControllers[i].text.isNotEmpty) {
          final amount = int.parse(_expenseControllers[i].text);

          if (amount > 0) {
            ExpenseType type;

            switch (i) {
              case 0:
                type = ExpenseType.taxes;
                break;
              case 1:
                type = ExpenseType.homePayment;
                break;
              case 2:
                type = ExpenseType.carLoan;
                break;
              case 3:
                type = ExpenseType.creditCard;
                break;
              case 4:
                type = ExpenseType.retail;
                break;
              case 5:
                type = ExpenseType.otherExpenses;
                break;
              case 6:
                type = ExpenseType.perChild;
                break;
              default:
                type = ExpenseType.other;
            }

            expenses.add(Expense(
              name: _expenseNames[i],
              amount: amount,
              type: type,
            ));
          }
        }
      }

      // Erstelle Verbindlichkeiten
      for (int i = 0; i < _liabilityTypes.length; i++) {
        if (_liabilityAmountControllers[i].text.isNotEmpty &&
            _liabilityPaymentControllers[i].text.isNotEmpty) {
          final totalDebt = int.parse(_liabilityAmountControllers[i].text);
          final monthlyPayment =
              int.parse(_liabilityPaymentControllers[i].text);

          if (totalDebt > 0 && monthlyPayment > 0) {
            liabilities.add(Liability(
              name: _liabilityTypes[i].$1,
              category: _liabilityTypes[i].$2,
              totalDebt: totalDebt,
              monthlyPayment: monthlyPayment,
            ));
          }
        }
      }

      final int salary = int.parse(
          _salaryController.text.isEmpty ? '0' : _salaryController.text);
      final int passiveIncome = _calculatePassiveIncome();
      final int totalExpenses = int.parse(_totalExpensesController.text.isEmpty
          ? '0'
          : _totalExpensesController.text);
      final int costPerChild = int.parse(_costPerChildController.text.isEmpty
          ? '0'
          : _costPerChildController.text);

      // Berechne den monatlichen Cashflow
      final int monthlyCashflow = salary + passiveIncome - totalExpenses;

      // Füge den monatlichen Cashflow zu den Ersparnissen hinzu
      final int initialSavings = int.parse(
          _savingsController.text.isEmpty ? '0' : _savingsController.text);
      final int totalSavings = initialSavings + monthlyCashflow;

      // Erstelle Spielerdaten
      var uuid = Uuid();
      final playerData = PlayerData(
        id: uuid.v4(),
        name: _nameController.text,
        profession: _professionController.text,
        salary: salary,
        passiveIncome: passiveIncome,
        totalExpenses: totalExpenses,
        cashflow: monthlyCashflow,
        savings: totalSavings, // Verwende die aktualisierten Ersparnisse
        costPerChild: costPerChild,
        expenses: expenses,
        liabilities: liabilities,
      );

      // Speichere Spielerdaten im Provider
      Provider.of<PlayerProvider>(context, listen: false)
          .setPlayerData(playerData);

      // Navigiere zurück zum HomeScreen
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil einrichten'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Persönliche Daten
              const Text(
                'Persönliche Daten',
                style: TextStyle(
                  fontSize: 20,
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
                    return 'Bitte gib deinen Namen ein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _professionController,
                decoration: const InputDecoration(
                  labelText: 'Beruf',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte gib deinen Beruf ein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _costPerChildController,
                decoration: const InputDecoration(
                  labelText: 'Kosten pro Kind (€)',
                  border: OutlineInputBorder(),
                  helperText:
                      'Diese Kosten fallen zusätzlich an, wenn du ein Kind bekommst',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte gib die monatlichen Kosten pro Kind ein';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Einnahmen
              const Text(
                'Einnahmen',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _salaryController,
                decoration: const InputDecoration(
                  labelText: 'Lohn/Gehalt (€)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte gib dein monatliches Gehalt ein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _interestController,
                decoration: const InputDecoration(
                  labelText: 'Zinsen (€)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dividendsController,
                decoration: const InputDecoration(
                  labelText: 'Dividenden (€)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _realEstateController,
                decoration: const InputDecoration(
                  labelText: 'Immobilien/Geschäfte (€)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),

              const SizedBox(height: 24),

              // Ausgaben
              const Text(
                'Ausgaben',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(_expenseNames.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: _expenseControllers[index],
                    decoration: InputDecoration(
                      labelText: '${_expenseNames[index]} (€)',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _calculateTotalExpenses(),
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Vermögenswerte
              const Text(
                'Vermögenswerte',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _savingsController,
                decoration: const InputDecoration(
                  labelText: 'Ersparnisse (€)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),

              const SizedBox(height: 24),

              // Verbindlichkeiten
              const Text(
                'Verbindlichkeiten',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(_liabilityTypes.length, (index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _liabilityTypes[index].$1,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _liabilityAmountControllers[index],
                            decoration: const InputDecoration(
                              labelText: 'Gesamtschuld (€)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _liabilityPaymentControllers[index],
                            decoration: const InputDecoration(
                              labelText: 'Monatliche Rate (€)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            onChanged: (_) => _calculateTotalExpenses(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }),

              const SizedBox(height: 24),

              // Zusammenfassung
              const Text(
                'Zusammenfassung',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _totalExpensesController,
                decoration: const InputDecoration(
                  labelText: 'Gesamtausgaben (€)',
                  border: OutlineInputBorder(),
                ),
                enabled: false,
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Spiel starten',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
