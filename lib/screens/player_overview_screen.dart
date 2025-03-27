import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/multiplayer_provider.dart';
import '../models/player_data.dart';
import '../widgets/player_stats_card.dart';

class PlayerOverviewScreen extends StatelessWidget {
  final String playerId;

  const PlayerOverviewScreen({
    super.key,
    required this.playerId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spieler Übersicht'),
      ),
      body: Consumer<MultiplayerProvider>(
        builder: (context, multiplayerProvider, child) {
          final currentRoom = multiplayerProvider.currentRoom;
          if (currentRoom == null) {
            return const Center(child: Text('Kein aktiver Raum'));
          }

          final player = currentRoom.players.firstWhere(
            (p) => p.id == playerId,
            orElse: () => currentRoom.host,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${player.name} - ${player.profession}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                PlayerStatsCard(
                  player: player,
                  showActions: false,
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  'Vermögenswerte',
                  player.assets.map((a) => '${a.name}: ${a.cost}€').toList(),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  'Verbindlichkeiten',
                  player.liabilities
                      .map((l) => '${l.name}: ${l.totalDebt}€')
                      .toList(),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  'Ausgaben',
                  player.expenses
                      .map((e) => '${e.name}: ${e.amount}€')
                      .toList(),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  'Schnickschnack',
                  player.schnickschnackItems
                      .map((s) => '${s.name}: ${s.cost}€')
                      .toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<String> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Text('Keine Einträge')
            else
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(item),
                  )),
          ],
        ),
      ),
    );
  }
}
