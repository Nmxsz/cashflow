import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../services/player_service.dart';
import '../providers/player_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/theme_toggle_button.dart';
import 'profile_setup_screen.dart';
import 'assets_screen.dart';
import 'liabilities_screen.dart';
import 'expenses_screen.dart';
import 'payday_screen.dart';
import 'multiplayer_room_screen.dart';
import 'schnickschnack_screen.dart';
import 'package:uuid/uuid.dart';
import '../widgets/bankruptcy_dialog.dart';
import '../providers/multiplayer_provider.dart';
import 'player_overview_screen.dart';
import '../widgets/feature_footer.dart';

// Global key für den Zugriff auf den HomeScreen-State
final GlobalKey<_HomeScreenState> homeScreenKey = GlobalKey<_HomeScreenState>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'credit':
        _showBankLoanDialog(context);
        break;
      case 'buy_property':
        _showBuyPropertyDialog(context);
        break;
      case 'add_money':
        _showAddMoneyDialog(context);
        break;
      case 'schnickschnack':
        _showSchnickschnackDialog(context);
        break;
      case 'babyparty':
        _showBabypartyDialog(context);
        break;
    }
  }

  void _showBuyPropertyDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _costController = TextEditingController();
    final _mortgageController = TextEditingController();
    final _downPaymentController = TextEditingController();
    final _cashflowController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Immobilie kaufen'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name der Immobilie',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte geben Sie einen Namen ein';
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
                      return 'Bitte geben Sie die Kosten ein';
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
                    if (value == null || value.isEmpty) {
                      return 'Bitte geben Sie die Anzahlung ein';
                    }
                    final downPayment = int.parse(value);
                    final cost = int.parse(_costController.text);
                    if (downPayment >= cost) {
                      return 'Anzahlung muss kleiner als die Kosten sein';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    // Aktualisiere die Hypothek automatisch
                    if (value.isNotEmpty && _costController.text.isNotEmpty) {
                      final downPayment = int.parse(value);
                      final cost = int.parse(_costController.text);
                      _mortgageController.text =
                          (cost - downPayment).toString();
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mortgageController,
                  decoration: const InputDecoration(
                    labelText: 'Hypothek (€)',
                    border: OutlineInputBorder(),
                    helperText:
                        'Wird automatisch aus Kosten - Anzahlung berechnet',
                  ),
                  enabled: false,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cashflowController,
                  decoration: const InputDecoration(
                    labelText: 'Cashflow pro Monat (€)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte geben Sie den Cashflow ein';
                    }
                    return null;
                  },
                ),
              ],
            ),
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
                final cost = int.parse(_costController.text);
                final downPayment = int.parse(_downPaymentController.text);
                final mortgage = cost - downPayment;
                final cashflow = int.parse(_cashflowController.text);
                final name = _nameController.text;

                // Berechne die monatliche Rate (1% der Hypothek)
                const monthlyPayment = 0;

                final playerProvider =
                    Provider.of<PlayerProvider>(context, listen: false);

                // Prüfe, ob genügend Ersparnisse für die Anzahlung vorhanden sind
                if (playerProvider.playerData!.savings < downPayment) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Nicht genügend Ersparnisse für die Anzahlung!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Füge Vermögenswert hinzu
                playerProvider.addAsset(Asset(
                  name: name,
                  cost: cost,
                  category: AssetCategory.realEstate,
                  monthlyIncome: cashflow,
                  downPayment: downPayment,
                ));

                // Füge Hypothek hinzu
                playerProvider.addLiability(Liability(
                  name: 'Hypothek: $name',
                  category: LiabilityCategory.propertyMortgage,
                  totalDebt: mortgage,
                  monthlyPayment: monthlyPayment,
                ));

                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Immobilie erfolgreich gekauft!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Kaufen'),
          ),
        ],
      ),
    );
  }

  void _showAddMoneyDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _amountController = TextEditingController();
    final _reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Geld hinzufügen'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Betrag (€)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte geben Sie einen Betrag ein';
                  }
                  if (int.parse(value) <= 0) {
                    return 'Der Betrag muss größer als 0 sein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Grund',
                  border: OutlineInputBorder(),
                  helperText: 'z.B. Geschenk, Bonus, Verkauf, etc.',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte geben Sie einen Grund ein';
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
              if (_formKey.currentState?.validate() ?? false) {
                final amount = int.parse(_amountController.text);
                final reason = _reasonController.text;

                final playerProvider =
                    Provider.of<PlayerProvider>(context, listen: false);
                final currentSavings = playerProvider.playerData!.savings;

                // Aktualisiere die Ersparnisse
                playerProvider.updatePlayerStats(
                  savings: currentSavings + amount,
                );

                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$amount € hinzugefügt (Grund: $reason)'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }

  void _showBankLoanDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _amountController = TextEditingController();
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final isBankrupt = playerProvider.playerData!.cashflow < 0;

    if (isBankrupt) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Du bist bankrott und kannst kein Darlehen aufnehmen!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bankdarlehen aufnehmen'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Darlehensbetrag',
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
                final monthlyPayment =
                    (amount * 0.1).round(); // 10% monatliche Rate

                // Berechne den neuen Cashflow
                final newCashflow = playerProvider.playerData!.salary +
                    playerProvider.playerData!.passiveIncome -
                    (playerProvider.playerData!.totalExpenses + monthlyPayment);

                // Prüfe auf Bankrott
                if (playerProvider.wouldCauseBankruptcy(newCashflow)) {
                  Navigator.of(context).pop(); // Schließe den aktuellen Dialog
                  showDialog(
                    context: context,
                    builder: (context) => BankruptcyDialog(
                      onConfirm: () {
                        // Füge das Darlehen hinzu
                        playerProvider.addLiability(Liability(
                          name: 'Bankdarlehen',
                          category: LiabilityCategory.bankLoan,
                          totalDebt: amount,
                          monthlyPayment: monthlyPayment,
                        ));
                        Navigator.of(context).pop();
                      },
                      onCancel: () => Navigator.of(context).pop(),
                    ),
                  );
                } else {
                  // Füge das Darlehen direkt hinzu
                  playerProvider.addLiability(Liability(
                    name: 'Bankdarlehen',
                    category: LiabilityCategory.bankLoan,
                    totalDebt: amount,
                    monthlyPayment: monthlyPayment,
                  ));
                  Navigator.of(context).pop();
                }
              }
            },
            child: const Text('Darlehen aufnehmen'),
          ),
        ],
      ),
    );
  }

  void _showSchnickschnackDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _costController = TextEditingController();
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schnickschnack kaufen'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name des Schnickschnacks',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte geben Sie einen Namen ein';
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
                    return 'Bitte geben Sie die Kosten ein';
                  }
                  if (int.parse(value) <= 0) {
                    return 'Der Betrag muss größer als 0 sein';
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
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                final name = _nameController.text;
                final cost = int.parse(_costController.text);

                try {
                  // Erstelle den neuen Schnickschnack
                  final newItem = Schnickschnack(
                    id: const Uuid().v4(),
                    name: name,
                    cost: cost,
                    purchaseDate: DateTime.now(),
                  );

                  // Füge den Schnickschnack hinzu
                  await playerProvider.addSchnickschnack(newItem);

                  // Schließe den Dialog
                  Navigator.of(context).pop();

                  // Zeige Erfolgsmeldung
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$name für $cost € gekauft'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  // Zeige Fehlermeldung
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Fehler beim Kauf: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Kaufen'),
          ),
        ],
      ),
    );
  }

  void _showBabypartyDialog(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final playerData = playerProvider.playerData!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Babyparty! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Du bekommst ein Kind!'),
            const SizedBox(height: 16),
            Text('Aktuelle Anzahl Kinder: ${playerData.numberOfChildren}'),
            Text('Kosten pro Kind: ${playerData.costPerChild} €'),
            Text('Zusätzliche monatliche Kosten: ${playerData.costPerChild} €'),
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
              playerProvider.addChild();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Herzlichen Glückwunsch! Ein neues Kind wurde geboren! 🎉'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Kind hinzufügen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final playerData = playerProvider.playerData;
        if (playerData == null) {
          return Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/CashflowIMG.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                  backgroundColor: Theme.of(context).cardColor.withOpacity(0.9),
                  title: Row(
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 150,
                            width: 150,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('Cashflow'),
                    ],
                  ),
                actions: const [
                  ThemeToggleButton(),
                ],
              ),
              body: Center(
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Card(
                          margin: const EdgeInsets.all(16),
                          color: Theme.of(context).cardColor.withOpacity(0.9),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Willkommen bei Cashflow Tracker!',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Wähle deinen Spielmodus:',
                                  style: TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 30),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ProfileSetupScreen(
                                          player: PlayerData(
                                            id: const Uuid().v4(),
                                            name: '',
                                            profession: '',
                                            salary: 0,
                                            savings: 0,
                                            assets: [],
                                            liabilities: [],
                                            expenses: [],
                                            totalExpenses: 0,
                                            cashflow: 0,
                                            costPerChild: 0,
                                          ),
                                          onProfileSaved: (player) {
                                            Provider.of<PlayerProvider>(context,
                                                    listen: false)
                                                .setPlayerData(player);
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Singleplayer'),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const MultiplayerRoomScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text('Multiplayer'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (playerProvider.playerData == null) const FeatureFooter(),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Cashflow Tracker'),
            actions: [
              Consumer<MultiplayerProvider>(
                builder: (context, multiplayerProvider, child) {
                  if (!multiplayerProvider.isInRoom)
                    return const SizedBox.shrink();

                  return IconButton(
                    icon: const Icon(Icons.people),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Spieler auswählen'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: multiplayerProvider
                                  .currentRoom!.players.length,
                              itemBuilder: (context, index) {
                                final player = multiplayerProvider
                                    .currentRoom!.players[index];
                                return ListTile(
                                  title: Text(player.name),
                                  subtitle: Text(player.profession),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PlayerOverviewScreen(
                                          playerId: player.id,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Schließen'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  playerProvider.resetPlayerData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profil zurückgesetzt')),
                  );
                },
                tooltip: 'Neues Spiel',
              ),
              const ThemeToggleButton(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'Menü öffnen',
                onSelected: (action) => _handleMenuAction(context, action),
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'credit',
                    child: Row(
                      children: [
                        Icon(Icons.credit_card),
                        SizedBox(width: 8),
                        Text('Kredit aufnehmen'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'buy_property',
                    child: Row(
                      children: [
                        Icon(Icons.home),
                        SizedBox(width: 8),
                        Text('Immobilie kaufen'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'add_money',
                    child: Row(
                      children: [
                        Icon(Icons.add_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Geld hinzufügen'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'schnickschnack',
                    child: Row(
                      children: [
                        Icon(Icons.shopping_cart),
                        SizedBox(width: 8),
                        Text('Schnickschnack kaufen'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'babyparty',
                    child: Row(
                      children: [
                        Icon(Icons.child_care),
                        SizedBox(width: 8),
                        Text('Babyparty!'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profilübersicht
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                playerData.name,
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                playerData.profession,
                                style: const TextStyle(
                                    fontSize: 18, color: Colors.grey),
                              ),
                              const Divider(),
                              _buildInfoRow('Gehalt', '${playerData.salary} €'),
                              _buildInfoRow('Passives Einkommen',
                                  '${playerData.passiveIncome} €'),
                              _buildInfoRow(
                                  'Ausgaben', '${playerData.totalExpenses} €'),
                              const Divider(),
                              _buildInfoRow(
                                'Cashflow',
                                '${playerData.cashflow} €',
                                valueColor: playerData.cashflow >= 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              _buildInfoRow(
                                  'Ersparnis', '${playerData.savings} €'),
                              const Divider(),
                              _buildInfoRow(
                                'Gesamtvermögen',
                                '${playerData.netWorth} €',
                                valueColor: playerData.netWorth >= 0
                                    ? Colors.green
                                    : Colors.red,
                                valueFontSize: 18.0,
                                labelFontWeight: FontWeight.bold,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Aktionen
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        children: [
                          _buildActionCard(
                            context,
                            'Vermögenswerte',
                            Icons.trending_up,
                            Colors.green,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const AssetsScreen()),
                            ),
                          ),
                          _buildActionCard(
                            context,
                            'Verbindlichkeiten',
                            Icons.trending_down,
                            Colors.red,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const LiabilitiesScreen()),
                            ),
                          ),
                          _buildActionCard(
                            context,
                            'Ausgaben',
                            Icons.money_off,
                            Colors.orange,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ExpensesScreen()),
                            ),
                          ),
                          _buildActionCard(
                            context,
                            'Zahltag',
                            Icons.payment,
                            Colors.blue,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const PaydayScreen()),
                            ),
                          ),
                          _buildActionCard(
                            context,
                            'Schnickschnack',
                            Icons.shopping_bag,
                            Colors.purple,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const SchnickschnackScreen()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    double? valueFontSize,
    FontWeight? labelFontWeight,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: labelFontWeight ?? FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize ?? 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}