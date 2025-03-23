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
  final TextEditingController _monthlyPaymentController = TextEditingController();
  
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
    });
  }

  // Füllt das Formular mit den Daten der zu bearbeitenden Verbindlichkeit
  void _prepareForEditing(Liability liability, int index) {
    setState(() {
      _editMode = true;
      _editingIndex = index;
      _nameController.text = liability.name;
      _totalDebtController.text = liability.totalDebt.toString();
      _monthlyPaymentController.text = liability.monthlyPayment.toString();
    });
  }

  // Speichert die Verbindlichkeit (neu oder bearbeitet)
  void _saveLiability() {
    if (_formKey.currentState?.validate() ?? false) {
      final liability = Liability(
        name: _nameController.text,
        totalDebt: int.parse(_totalDebtController.text),
        monthlyPayment: int.parse(_monthlyPaymentController.text),
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
        Provider.of<PlayerProvider>(context, listen: false).addLiability(liability);
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
        content: const Text('Möchtest du diese Verbindlichkeit wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<PlayerProvider>(context, listen: false).deleteLiability(index);
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: ListTile(
                                    title: Text(liability.name),
                                    subtitle: Text(
                                      'Schulden: ${liability.totalDebt} € | Monatliche Rate: ${liability.monthlyPayment} €',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => _prepareForEditing(liability, index),
                                          tooltip: 'Bearbeiten',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteLiability(index),
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
                        TextFormField(
                          controller: _totalDebtController,
                          decoration: const InputDecoration(
                            labelText: 'Gesamtschuld (€)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Bitte gib die Gesamtschuld ein';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _monthlyPaymentController,
                          decoration: const InputDecoration(
                            labelText: 'Monatliche Rate (€)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Bitte gib die monatliche Rate ein';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _saveLiability,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _editMode ? Colors.blue : Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            _editMode ? 'Verbindlichkeit aktualisieren' : 'Verbindlichkeit hinzufügen',
                            style: const TextStyle(fontSize: 16, color: Colors.white),
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