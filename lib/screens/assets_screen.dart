import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../providers/player_provider.dart';
import '../widgets/theme_toggle_button.dart';

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
  final TextEditingController _monthlyIncomeController =
      TextEditingController();
  final TextEditingController _sharesController = TextEditingController();
  final TextEditingController _costPerShareController = TextEditingController();

  // Kategorien für Assets
  final List<AssetCategory> _categories = AssetCategory.values;
  AssetCategory _selectedCategory = AssetCategory.stocks;

  // Flag, ob wir im Bearbeitungsmodus sind
  bool _editMode = false;
  int _editingIndex = -1;

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _downPaymentController.dispose();
    _monthlyIncomeController.dispose();
    _sharesController.dispose();
    _costPerShareController.dispose();
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
      _sharesController.clear();
      _costPerShareController.clear();
      _selectedCategory = AssetCategory.stocks;
    });
  }

  // Füllt das Formular mit den Daten des zu bearbeitenden Assets
  void _prepareForEditing(Asset asset, int index) {
    setState(() {
      _editMode = true;
      _editingIndex = index;
      _nameController.text = asset.name;
      _selectedCategory = asset.category;
      _costController.text = asset.cost.toString();
      _downPaymentController.text = asset.downPayment.toString();

      // Kategorie-spezifische Felder
      if (asset.monthlyIncome != null) {
        _monthlyIncomeController.text = asset.monthlyIncome.toString();
      } else {
        _monthlyIncomeController.clear();
      }

      if (asset.shares != null) {
        _sharesController.text = asset.shares.toString();
      } else {
        _sharesController.clear();
      }

      if (asset.costPerShare != null) {
        _costPerShareController.text = asset.costPerShare.toString();
      } else {
        _costPerShareController.clear();
      }
    });
    _showAssetForm(context);
  }

  // Berechnet die Kosten basierend auf der Kategorie und den Eingaben
  void _calculateCost() {
    if (_selectedCategory == AssetCategory.stocks) {
      // Für Aktien: Kosten = Anzahl der Anteile * Kosten pro Anteil
      final shares = int.tryParse(_sharesController.text) ?? 0;
      final costPerShare = int.tryParse(_costPerShareController.text) ?? 0;

      // Aktualisiere den Wert im Controller, auch wenn das Feld nicht angezeigt wird
      _costController.text = (shares * costPerShare).toString();
    }
  }

  // Speichert das Asset (neu oder bearbeitet)
  void _saveAsset() {
    if (_formKey.currentState?.validate() ?? false) {
      // Erstelle das Asset-Objekt basierend auf der Kategorie
      Asset asset;

      if (_selectedCategory == AssetCategory.stocks) {
        final shares = int.tryParse(_sharesController.text) ?? 0;
        final costPerShare = int.tryParse(_costPerShareController.text) ?? 0;

        asset = Asset(
          name: _nameController.text,
          category: _selectedCategory,
          cost: int.parse(_costController.text),
          downPayment: 0, // Keine Anzahlung bei Aktien
          // Kein monatliches Einkommen für Aktien/Fonds/CDs
          shares: shares,
          costPerShare: costPerShare,
        );
      } else {
        // Für Immobilien und Geschäfte
        asset = Asset(
          name: _nameController.text,
          category: _selectedCategory,
          cost: int.parse(_costController.text),
          downPayment: int.parse(_downPaymentController.text.isEmpty
              ? '0'
              : _downPaymentController.text),
          monthlyIncome: int.parse(_monthlyIncomeController.text),
        );
      }

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
        content: const Text(
            'Möchtest du diesen Vermögenswert wirklich löschen? Du erhältst keinen Erlös zurück.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<PlayerProvider>(context, listen: false)
                  .deleteAsset(index);
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
    // Unterschiedliche Dialoge je nach Kategorie
    if (asset.category == AssetCategory.stocks &&
        asset.shares != null &&
        asset.costPerShare != null) {
      // Für Aktien/Fonds/CDs: Verkaufspreis pro Anteil eingeben
      final TextEditingController sellPricePerShareController =
          TextEditingController(text: asset.costPerShare.toString());

      // Gesamtverkaufswert als ValueNotifier, um den Wert aktuell zu halten
      final ValueNotifier<int> totalSellPriceNotifier =
          ValueNotifier<int>(asset.shares! * asset.costPerShare!);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Aktien verkaufen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Zu welchem Preis pro Anteil möchtest du ${asset.name} verkaufen?'),
              const SizedBox(height: 16),
              TextFormField(
                controller: sellPricePerShareController,
                decoration: const InputDecoration(
                  labelText: 'Preis pro Anteil (€)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  // Aktualisiere den Gesamtpreis bei Änderung
                  final pricePerShare = int.tryParse(value) ?? 0;
                  totalSellPriceNotifier.value = asset.shares! * pricePerShare;
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Anzahl der Anteile:'),
                  Text('${asset.shares}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Gesamtverkaufswert:'),
                  ValueListenableBuilder<int>(
                    valueListenable: totalSellPriceNotifier,
                    builder: (context, totalSellPrice, _) {
                      return Text(
                        '$totalSellPrice €',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ursprünglicher Preis pro Anteil:'),
                  Text('${asset.costPerShare} €'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ursprünglicher Gesamtwert:'),
                  Text('${asset.cost} €'),
                ],
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
                final sellPricePerShare =
                    int.tryParse(sellPricePerShareController.text) ??
                        asset.costPerShare!;
                final totalSellPrice = asset.shares! * sellPricePerShare;
                Navigator.of(context).pop();

                // Berechne Gewinn oder Verlust
                final profit = totalSellPrice - asset.cost;
                String profitText = '';
                Color profitColor = Colors.green;

                if (profit > 0) {
                  profitText = ' (Gewinn: $profit €)';
                } else if (profit < 0) {
                  profitText = ' (Verlust: ${profit.abs()} €)';
                  profitColor = Colors.red;
                }

                Provider.of<PlayerProvider>(context, listen: false)
                    .sellAsset(index, totalSellPrice);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${asset.name} für $totalSellPrice €$profitText verkauft!'),
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
        // Stellen Sie sicher, dass die Controller aufgeräumt werden
        sellPricePerShareController.dispose();
        totalSellPriceNotifier.dispose();
      });
    } else if (asset.category == AssetCategory.realEstate) {
      // Für Immobilien: Verkaufspreis eingeben und Hypothek berücksichtigen
      final TextEditingController sellPriceController =
          TextEditingController(text: asset.cost.toString());

      // Finde die zugehörige Hypothek
      final playerProvider =
          Provider.of<PlayerProvider>(context, listen: false);
      final relatedMortgage = playerProvider.playerData?.liabilities.indexWhere(
        (liability) => liability.name == 'Hypothek: ${asset.name}',
      );

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Immobilie verkaufen'),
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
              if (relatedMortgage != null && relatedMortgage >= 0)
                Text(
                  'Verbleibende Hypothek: ${playerProvider.playerData!.liabilities[relatedMortgage].totalDebt} €',
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
                final sellPrice =
                    int.tryParse(sellPriceController.text) ?? asset.cost;
                Navigator.of(context).pop();

                // Berechne Gewinn oder Verlust unter Berücksichtigung der Hypothek
                int profit = sellPrice;
                int remainingMortgage = 0;

                if (relatedMortgage != null && relatedMortgage >= 0) {
                  remainingMortgage = playerProvider
                      .playerData!.liabilities[relatedMortgage].totalDebt;
                  profit = sellPrice - remainingMortgage - asset.downPayment;

                  // Lösche nur die Hypothek, keine Ausgabe da diese im Cashflow bereits berücksichtigt ist
                  playerProvider.deleteLiability(relatedMortgage);
                }

                String profitText = '';
                Color profitColor = Colors.green;

                if (profit > 0) {
                  profitText =
                      ' (Gewinn nach Abzug der Hypothek und Anzahlung: $profit €)';
                } else if (profit < 0) {
                  profitText =
                      ' (Verlust nach Abzug der Hypothek und Anzahlung: ${profit.abs()} €)';
                  profitColor = Colors.red;
                }

                playerProvider.sellAsset(index, sellPrice);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${asset.name} für $sellPrice € verkauft! Verbleibende Hypothek: $remainingMortgage €.$profitText'),
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
    } else {
      // Originaler Dialog für andere Asset-Typen
      final TextEditingController sellPriceController =
          TextEditingController(text: asset.cost.toString());

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
                final sellPrice =
                    int.tryParse(sellPriceController.text) ?? asset.cost;
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

                Provider.of<PlayerProvider>(context, listen: false)
                    .sellAsset(index, sellPrice);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${asset.name} für $sellPrice €$profitText verkauft!'),
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
  }

  // Baut die kategorieabhängigen Formularfelder
  Widget _buildCategorySpecificFields() {
    if (_selectedCategory == AssetCategory.stocks) {
      return Column(
        children: [
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Anzahl der Anteile
              Expanded(
                child: TextFormField(
                  controller: _sharesController,
                  decoration: const InputDecoration(
                    labelText: 'Anzahl der Anteile',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte gib die Anzahl ein';
                    }
                    return null;
                  },
                  onChanged: (_) => _calculateCost(),
                ),
              ),
              const SizedBox(width: 12),
              // Kosten pro Anteil
              Expanded(
                child: TextFormField(
                  controller: _costPerShareController,
                  decoration: const InputDecoration(
                    labelText: 'Kosten pro Anteil (€)',
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
                  onChanged: (_) => _calculateCost(),
                ),
              ),
            ],
          ),
          // Gesamtkosten-Feld entfernt - wird intern berechnet
        ],
      );
    } else {
      // Für Immobilien und Geschäfte
      return Column(
        children: [
          const SizedBox(height: 12),
          TextFormField(
            controller: _costController,
            decoration: const InputDecoration(
              labelText: 'Gesamtkosten (€)',
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
              labelText: 'Anzahlung (€)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              // Anzahlung ist für diese Kategorien erforderlich
              if (value == null || value.isEmpty) {
                return 'Bitte gib die Anzahlung ein';
              }
              return null;
            },
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
        ],
      );
    }
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

          // Berechne den Gesamtwert aller Vermögenswerte
          int totalAssetsValue = 0;
          for (var asset in playerData.assets) {
            totalAssetsValue += asset.cost;
          }

          return Column(
            children: [
              // Übersicht-Karte für den Gesamtwert
              Card(
                margin: const EdgeInsets.all(16),
                color: Colors.green.shade800,
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
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$totalAssetsValue €',
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

              // Liste der Vermögenswerte
              Expanded(
                child: playerData.assets.isEmpty
                    ? const Center(
                        child: Text('Keine Vermögenswerte vorhanden'),
                      )
                    : ListView.builder(
                        itemCount: playerData.assets.length,
                        itemBuilder: (context, index) {
                          final asset = playerData.assets[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(asset.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Kategorie: ${asset.category}'),
                                  if (asset.category == AssetCategory.stocks &&
                                      asset.shares != null &&
                                      asset.costPerShare != null)
                                    Text(
                                        '${asset.shares} Anteile zu je ${asset.costPerShare} € (Gesamt: ${asset.cost} €)'),
                                  if (asset.category == AssetCategory.stocks &&
                                      (asset.shares == null ||
                                          asset.costPerShare == null))
                                    Text('Gesamtwert: ${asset.cost} €'),
                                  if (asset.category != AssetCategory.stocks)
                                    Text(
                                        'Kosten: ${asset.cost} € | Einkommen: ${asset.monthlyIncome} €'),
                                  if (asset.category != AssetCategory.stocks &&
                                      asset.downPayment > 0)
                                    Text('Anzahlung: ${asset.downPayment} €'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () =>
                                        _prepareForEditing(asset, index),
                                    tooltip: 'Bearbeiten',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.sell,
                                        color: Colors.green),
                                    onPressed: () => _sellAsset(index, asset),
                                    tooltip: 'Verkaufen',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteAsset(index),
                                    tooltip: 'Löschen',
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _resetForm();
          _showAssetForm(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Zeigt das Formular in einem Bottom Sheet an
  void _showAssetForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
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
                    DropdownButtonFormField<AssetCategory>(
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
                            // Zurücksetzen der spezifischen Felder
                            if (_selectedCategory == AssetCategory.stocks) {
                              _downPaymentController.text = '0';
                              _monthlyIncomeController.text = '0';
                            } else {
                              _sharesController.clear();
                              _costPerShareController.clear();
                            }
                          });
                        }
                      },
                    ),
                    _buildCategorySpecificFields(),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _saveAsset();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _editMode ? Colors.blue : Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _editMode
                            ? 'Vermögenswert aktualisieren'
                            : 'Vermögenswert hinzufügen',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
