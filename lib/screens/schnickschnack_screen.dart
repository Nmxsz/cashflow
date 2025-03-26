import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../models/schnickschnack.dart';
import '../widgets/theme_toggle_button.dart';

class SchnickschnackScreen extends StatelessWidget {
  const SchnickschnackScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schnickschnack'),
        actions: [
          const ThemeToggleButton(),
        ],
      ),
      body: Consumer<PlayerProvider>(
        builder: (context, playerProvider, child) {
          final schnickschnackItems =
              playerProvider.playerData!.schnickschnackItems;

          if (schnickschnackItems.isEmpty) {
            return const Center(
              child: Text(
                'Noch kein Schnickschnack gekauft',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          // Sortiere nach Kaufdatum (neueste zuerst)
          final sortedItems = List<Schnickschnack>.from(schnickschnackItems)
            ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

          // Berechne die Gesamtkosten
          final totalCost =
              sortedItems.fold<int>(0, (sum, item) => sum + item.cost);

          return Column(
            children: [
              // Gesamtkosten
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Gesamtausgaben für Schnickschnack:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$totalCost €',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Liste der Schnickschnack-Objekte
              Expanded(
                child: ListView.builder(
                  itemCount: sortedItems.length,
                  itemBuilder: (context, index) {
                    final item = sortedItems[index];
                    // Einfache Datumsformatierung mit Uhrzeit
                    final date = item.purchaseDate;
                    final formattedDate =
                        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} um ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} Uhr';

                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      onDismissed: (direction) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${item.name} entfernt')),
                        );
                        playerProvider.removeSchnickschnack(item);
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: 3,
                        child: ListTile(
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Gekauft am $formattedDate',
                          ),
                          trailing: Text(
                            '${item.cost} €',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
