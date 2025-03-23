import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../providers/player_provider.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _professionController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _totalExpensesController = TextEditingController();
  final List<TextEditingController> _expenseControllers = [];
  final List<String> _expenseNames = [
    'Steuern',
    'Hypothek/Miete',
    'Autokredit',
    'Kreditkarte',
    'Sonstige Kredite',
    'Sonstige Ausgaben',
    'Pro Kind',
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Initialisiere Controller für die einzelnen Ausgaben
    for (int i = 0; i < _expenseNames.length; i++) {
      _expenseControllers.add(TextEditingController());
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _professionController.dispose();
    _salaryController.dispose();
    _totalExpensesController.dispose();
    
    for (var controller in _expenseControllers) {
      controller.dispose();
    }
    
    super.dispose();
  }
  
  void _calculateTotalExpenses() {
    int total = 0;
    
    for (var controller in _expenseControllers) {
      if (controller.text.isNotEmpty) {
        total += int.parse(controller.text);
      }
    }
    
    setState(() {
      _totalExpensesController.text = total.toString();
    });
  }
  
  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final List<Expense> expenses = [];
      
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
      
      // Erstelle Spielerdaten
      final playerData = PlayerData(
        name: _nameController.text,
        profession: _professionController.text,
        salary: int.parse(_salaryController.text),
        totalExpenses: int.parse(_totalExpensesController.text),
        cashflow: int.parse(_salaryController.text) - int.parse(_totalExpensesController.text),
        expenses: expenses,
      );
      
      // Speichere Spielerdaten im Provider
      Provider.of<PlayerProvider>(context, listen: false).setPlayerData(playerData);
      
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Persönliche Informationen
            const Text(
              'Persönliche Informationen',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
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
              controller: _salaryController,
              decoration: const InputDecoration(
                labelText: 'Monatliches Gehalt (€)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bitte gib dein Gehalt ein';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Ausgaben
            const Text(
              'Ausgaben',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            // Einzelne Ausgabenposten
            for (int i = 0; i < _expenseNames.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: TextFormField(
                  controller: _expenseControllers[i],
                  decoration: InputDecoration(
                    labelText: '${_expenseNames[i]} (€)',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => _calculateTotalExpenses(),
                ),
              ),
            
            // Gesamtausgaben
            TextFormField(
              controller: _totalExpensesController,
              decoration: const InputDecoration(
                labelText: 'Gesamtausgaben (€)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              readOnly: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bitte gib mindestens eine Ausgabe ein';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Speichern-Button
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: const Text(
                'Profil speichern',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 