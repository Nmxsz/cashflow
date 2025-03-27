import 'package:flutter/material.dart';
import '../models/player_data.dart';

class PlayerStatsCard extends StatelessWidget {
  final PlayerData player;
  final bool showActions;

  const PlayerStatsCard({
    super.key,
    required this.player,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Finanzielle Übersicht',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatRow('Gehalt', '${player.salary}€'),
            _buildStatRow('Passives Einkommen', '${player.passiveIncome}€'),
            _buildStatRow('Gesamtausgaben', '${player.totalExpenses}€'),
            _buildStatRow('Cashflow', '${player.cashflow}€'),
            _buildStatRow('Ersparnisse', '${player.savings}€'),
            _buildStatRow('Nettovermögen', '${player.netWorth}€'),
            if (player.numberOfChildren > 0)
              _buildStatRow(
                  'Anzahl Kinder', player.numberOfChildren.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
