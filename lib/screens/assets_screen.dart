import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../providers/player_provider.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({Key? key}) : super(key: key);

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _downPaymentController = TextEditingController();
  final TextEditingController _monthlyIncomeController = TextEditingController();
  
  // Flag, ob wir im Bearbeitungsmodus sind
  bool _editMode = false;
  int _editingIndex = -1;

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _downPaymentController.dispose();
    _monthlyIncomeController.dispose();
    super.dispose();
  }

  // Setzt die Formularfelder zurück
  void _resetForm() {
    setState(() {
      _editMode = false;
      _editingIndex = -1;
      _nameController.clear();
      _costController.clear();
      _downPaymentController.clear();
      _monthlyIncomeController.clear();
    });
  }

  // Füllt das Formular mit den Daten des zu bearbeitenden Assets
  void _prepareForEditing(Asset asset, int index) {
    setState(() {
      _editMode = true;
      _editingIndex = index;
      _nameController.text = asset.name;
      _costController.text = asset.cost.toString();
      _downPaymentController.text = asset.downPayment.toString();
      _monthlyIncomeController.text = asset.monthlyIncome.toString();
    });
  }

  // Speichert das Asset (neu oder bearbeitet)
  void _saveAsset() {
    if (_formKey.currentState?.validate() ?? false) {
      final asset = Asset(
        name: _nameController.text,
        cost: int.parse(_costController.text),
        downPayment: int.parse(_downPaymentController.text.isEmpty 
            ? '0' 
            : _downPaymentController.text),
        monthlyIncome: int.parse(_monthlyIncomeController.text),
      );

      if (_editMode && _editingIndex >= 0) {
        // Asset aktualisieren
        Provider.of<PlayerProvider>(context, listen: false)
            .updateAsset(_editingIndex, asset);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vermögenswert erfolgreich aktualisiert!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Neues Asset hinzufügen
        Provider.of<PlayerProvider>(context, listen: false).addAsset(asset);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vermögenswert erfolgreich hinzugefügt!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Formular zurücksetzen
      _resetForm();
    }
  }

  // Löscht ein Asset
  void _deleteAsset(int index) {
    // Bestätigungsdialog anzeigen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vermögenswert löschen'),
        content: const Text('Möchtest du diesen Vermögenswert wirklich löschen? Du erhältst keinen Erlös zurück.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<PlayerProvider>(context, listen: false).deleteAsset(index);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Vermögenswert erfolgreich gelöscht!'),
                  backgroundColor: Colors.red,
                ),
              );
              // Falls wir gerade dieses Asset bearbeiten, Formular zurücksetzen
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

  // Verkauft ein Asset und erhält den Erlös
  void _sellAsset(int index, Asset asset) {
    final TextEditingController sellPriceController = TextEditingController(text: asset.cost.toString());
    
    // Bestätigungsdialog anzeigen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vermögenswert verkaufen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Für wie viel möchtest du ${asset.name} verkaufen?'),
            const SizedBox(height: 16),
            TextFormField(
              controller: sellPriceController,
              decoration: const InputDecoration(
                labelText: 'Verkaufspreis (€)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 8),
            Text(
              'Anschaffungspreis: ${asset.cost} €',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
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
              final sellPrice = int.tryParse(sellPriceController.text) ?? asset.cost;
              Navigator.of(context).pop();
              
              // Berechne Gewinn oder Verlust
              final profit = sellPrice - asset.cost;
              String profitText = '';
              Color profitColor = Colors.green;
              
              if (profit > 0) {
                profitText = ' (Gewinn: $profit €)';
              } else if (profit < 0) {
                profitText = ' (Verlust: ${profit.abs()} €)';
                profitColor = Colors.red;
              }
              
              Provider.of<PlayerProvider>(context, listen: false).sellAsset(index, sellPrice);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${asset.name} für $sellPrice €$profitText verkauft!'),
                  backgroundColor: profitColor,
                ),
              );
              // Falls wir gerade dieses Asset bearbeiten, Formular zurücksetzen
              if (_editMode && _editingIndex == index) {
                _resetForm();
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Verkaufen'),
          ),
        ],
      ),
    ).then((_) {
      // Stellen Sie sicher, dass der Controller aufgeräumt wird
      sellPriceController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vermögenswerte'),
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

          // Berechne den Gesamtwert aller Vermögenswerte
          int totalAssetsValue = 0;
          for (var asset in playerData.assets) {
            totalAssetsValue += asset.cost;
          }

          return Column(
            children: [
              // Liste der vorhandenen Vermögenswerte
              Expanded(
                child: playerData.assets.isEmpty
                    ? const Center(
                        child: Text('Keine Vermögenswerte vorhanden'),
                      )
                    : Column(
                        children: [
                          // Übersicht-Karte für den Gesamtwert
                          Card(
                            margin: const EdgeInsets.all(16),
                            color: Colors.green.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Gesamt-Vermögenswert:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '$totalAssetsValue €',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Liste der Vermögenswerte
                          Expanded(
                            child: ListView.builder(
                              itemCount: playerData.assets.length,
                              itemBuilder: (context, index) {
                                final asset = playerData.assets[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: ListTile(
                                    title: Text(asset.name),
                                    subtitle: Text(
                                      'Kosten: ${asset.cost} € | Einkommen: ${asset.monthlyIncome} €',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => _prepareForEditing(asset, index),
                                          tooltip: 'Bearbeiten',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.sell, color: Colors.green),
                                          onPressed: () => _sellAsset(index, asset),
                                          tooltip: 'Verkaufen',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteAsset(index),
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

              // Formular zum Hinzufügen/Bearbeiten von Vermögenswerten
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
                            ? 'Vermögenswert bearbeiten' 
                            : 'Neuen Vermögenswert hinzufügen',
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
                          controller: _costController,
                          decoration: const InputDecoration(
                            labelText: 'Kosten (€)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Bitte gib die Kosten ein';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _downPaymentController,
                          decoration: const InputDecoration(
                            labelText: 'Anzahlung (€) (optional)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _monthlyIncomeController,
                          decoration: const InputDecoration(
                            labelText: 'Monatliches Einkommen (€)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Bitte gib das monatliche Einkommen ein';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _saveAsset,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _editMode ? Colors.blue : Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            _editMode ? 'Vermögenswert aktualisieren' : 'Vermögenswert hinzufügen',
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