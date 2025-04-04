import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/professions.dart';
import '../models/index.dart';
import '../models/profession.dart';
import '../providers/player_provider.dart';
import '../widgets/theme_toggle_button.dart';
import 'package:uuid/uuid.dart';

class ProfileSetupScreen extends StatefulWidget {
  final PlayerData player;
  final Function(PlayerData) onProfileSaved;

  const ProfileSetupScreen({
    Key? key,
    required this.player,
    required this.onProfileSaved,
  }) : super(key: key);

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
    'Bankdarlehen Zahlung',
  ];

  late List<TextEditingController> _expenseControllers;
  final TextEditingController _totalExpensesController =
      TextEditingController();

  String? _selectedProfession;

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

    // Fülle die Textfelder nur wenn es ein bestehendes Profil ist
    if (widget.player.id.isNotEmpty) {
      _nameController.text = widget.player.name;
      _professionController.text = widget.player.profession;
      _costPerChildController.text = widget.player.costPerChild.toString();
      _salaryController.text = widget.player.salary.toString();
      _savingsController.text = widget.player.savings.toString();

      // Fülle die Ausgaben
      for (var expense in widget.player.expenses) {
        final index = _expenseNames.indexWhere((name) => name == expense.name);
        if (index != -1) {
          _expenseControllers[index].text = expense.amount.toString();
        }
      }

      // Fülle die Verbindlichkeiten
      for (var liability in widget.player.liabilities) {
        final index =
            _liabilityTypes.indexWhere((type) => type.$1 == liability.name);
        if (index != -1) {
          _liabilityAmountControllers[index].text =
              liability.totalDebt.toString();
          _liabilityPaymentControllers[index].text =
              liability.monthlyPayment.toString();
        }
      }

      // Berechne die Gesamtausgaben
      _calculateTotalExpenses();
    }
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
      8: _liabilityTypes[7].$1, // Bankdarlehen Zahlung -> Bankdarlehen
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

  // Function to apply predefined profession data
  void _applyProfessionData(PredefinedProfession profession) {
    setState(() {
      _professionController.text = profession.name;
      _salaryController.text = profession.salary.toString();
      _costPerChildController.text = profession.costPerChild.toString();
      _savingsController.text = profession.savings.toString();

      // Set expenses
      _expenseControllers[0].text = profession.taxes.toString(); // Steuern
      _expenseControllers[1].text =
          profession.homePayment.toString(); // Eigenheim
      _expenseControllers[2].text = profession.bafogPayment.toString(); // BAföG
      _expenseControllers[3].text = profession.carPayment.toString(); // Auto
      _expenseControllers[4].text =
          profession.creditCardPayment.toString(); // Kreditkarte
      _expenseControllers[5].text =
          profession.consumerPayment.toString(); // Verbraucherkredit
      _expenseControllers[6].text =
          profession.otherExpenses.toString(); // Sonstige
      // Don't set children expenses initially
      _expenseControllers[7].text = '0'; // Kinder

      // Set liabilities
      _liabilityAmountControllers[0].text =
          profession.homeTotal.toString(); // Eigenheim
      _liabilityPaymentControllers[0].text = profession.homePayment.toString();
      _liabilityAmountControllers[1].text =
          profession.bafogTotal.toString(); // BAföG
      _liabilityPaymentControllers[1].text = profession.bafogPayment.toString();
      _liabilityAmountControllers[2].text =
          profession.carTotal.toString(); // Auto
      _liabilityPaymentControllers[2].text = profession.carPayment.toString();
      _liabilityAmountControllers[3].text =
          profession.creditCardTotal.toString(); // Kreditkarte
      _liabilityPaymentControllers[3].text =
          profession.creditCardPayment.toString();
      _liabilityAmountControllers[4].text =
          profession.consumerTotal.toString(); // Verbraucherkredit
      _liabilityPaymentControllers[4].text =
          profession.consumerPayment.toString();

      _calculateTotalExpenses();
    });
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
                type = ExpenseType.schoolLoan;
                break;
              case 3:
                type = ExpenseType.carLoan;
                break;
              case 4:
                type = ExpenseType.creditCard;
                break;
              case 5:
                type = ExpenseType.retail;
                break;
              case 6:
                type = ExpenseType.otherExpenses;
                break;
              case 7:
                type = ExpenseType.perChild;
                break;
              case 8:
                type = ExpenseType.bankLoan;
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
        id: widget.player.id,
        name: _nameController.text,
        profession: _professionController.text,
        salary: salary,
        passiveIncome: passiveIncome,
        totalExpenses: totalExpenses,
        cashflow: monthlyCashflow,
        savings: totalSavings,
        costPerChild: costPerChild,
        expenses: expenses,
        liabilities: liabilities,
        isReady: true,
      );

      // Rufe nur den Callback auf
      widget.onProfileSaved(playerData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil einrichten'),
        actions: [
          const ThemeToggleButton(),
        ],
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
              DropdownButtonFormField<String>(
                value: _selectedProfession,
                decoration: const InputDecoration(
                  labelText: 'Beruf auswählen',
                  border: OutlineInputBorder(),
                ),
                items: predefinedProfessions.map((profession) {
                  return DropdownMenuItem(
                    value: profession.name,
                    child: Text(profession.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProfession = value;
                    if (value != null) {
                      final profession = predefinedProfessions.firstWhere(
                        (p) => p.name == value,
                      );
                      _applyProfessionData(profession);
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _professionController,
                decoration: const InputDecoration(
                  labelText: 'Beruf (manuell)',
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
