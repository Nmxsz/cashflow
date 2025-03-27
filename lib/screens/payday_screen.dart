import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../models/liability.dart';
import '../screens/home_screen.dart'; // Import für den homeScreenKey
import '../widgets/theme_toggle_button.dart'; // Import für ThemeToggleButton

class PaydayScreen extends StatelessWidget {
  const PaydayScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final playerData = playerProvider.playerData;

    if (playerData == null) {
      return const Scaffold(
        body: Center(
          child: Text('Keine Spielerdaten vorhanden'),
        ),
      );
    }

    // Berechne neue Werte nach dem Zahltag
    final newSavings = playerData.savings + playerData.cashflow;

    // Simuliere die Reduzierung der Verbindlichkeiten
    int reducedDebtAmount = 0;
    int remainingLiabilitiesValue = 0;

    // Berechne, wie viel Schulden durch die monatlichen Raten reduziert werden
    for (var liability in playerData.liabilities) {
      if (liability.totalDebt > liability.monthlyPayment) {
        // Normaler Fall: Es bleibt noch Schulden übrig
        reducedDebtAmount += liability.monthlyPayment;
        remainingLiabilitiesValue +=
            (liability.totalDebt - liability.monthlyPayment);
      } else if (liability.totalDebt > 0) {
        // Wenn die Verbindlichkeit vollständig bezahlt wird
        reducedDebtAmount += liability.totalDebt;
        // Diese Verbindlichkeit wird nicht mehr zu den verbleibenden Schulden gezählt
      }
    }

    // Berechne den Wert aller Vermögenswerte
    int assetsValue = 0;
    for (var asset in playerData.assets) {
      assetsValue += asset.cost;
    }

    // Berechne das neue Nettovermögen unter Berücksichtigung der reduzierten Schulden
    final newNetWorth = newSavings + assetsValue - remainingLiabilitiesValue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zahltag'),
        actions: [
          ThemeToggleButton(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (playerData.cashflow < 0)
              Card(
                color: Colors.red.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Bankrott!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Dein Cashflow ist negativ. Du kannst nicht mehr weiter spielen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aktueller Kontostand',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${playerData.savings} €',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    _buildInfoRow('Gehalt', '${playerData.salary} €'),
                    _buildInfoRow(
                        'Passives Einkommen', '${playerData.passiveIncome} €'),
                    _buildInfoRow('Ausgaben', '${playerData.totalExpenses} €'),
                    const Divider(),
                    _buildInfoRow(
                      'Cashflow',
                      '${playerData.cashflow} €',
                      valueColor:
                          playerData.cashflow >= 0 ? Colors.green : Colors.red,
                    ),
                    const Divider(),
                    _buildInfoRow('Nettovermögen', '$newNetWorth €'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (playerData.cashflow >= 0)
              ElevatedButton(
                onPressed: () async {
                  await playerProvider.processPayday();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  }
                },
                child: const Text('Zahltag verarbeiten'),
              ),
          ],
        ),
      ),
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
}
