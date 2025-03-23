import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../services/player_service.dart';
import '../providers/player_provider.dart';
import '../providers/theme_provider.dart';
import 'profile_setup_screen.dart';
import 'assets_screen.dart';
import 'liabilities_screen.dart';
import 'expenses_screen.dart';
import 'payday_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'credit':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LiabilitiesScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final playerData = playerProvider.playerData;

        if (playerData == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Willkommen bei Cashflow Tracker!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Du hast noch kein Profil eingerichtet.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileSetupScreen(),
                      ),
                    );
                  },
                  child: const Text('Profil einrichten'),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Cashflow Tracker'),
            actions: [
              IconButton(
                icon: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    return Icon(
                      isDark ? Icons.light_mode : Icons.dark_mode,
                      color: isDark ? Colors.yellow : Colors.grey[800],
                    );
                  },
                ),
                onPressed: () {
                  Provider.of<ThemeProvider>(context, listen: false)
                      .toggleTheme();
                },
                tooltip: 'Theme wechseln',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  playerProvider.resetPlayerData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profil zurückgesetzt')),
                  );
                },
                tooltip: 'Profil zurücksetzen',
              ),
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
                        Text('Kredit'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
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
                          style:
                              const TextStyle(fontSize: 18, color: Colors.grey),
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
                        _buildInfoRow('Ersparnis', '${playerData.savings} €'),
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
                            builder: (context) => const LiabilitiesScreen()),
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
                  ],
                ),
              ],
            ),
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
