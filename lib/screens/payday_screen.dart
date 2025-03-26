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
                    _buildInfoRow(
                      'Gesamtvermögen',
                      '${playerData.netWorth} €',
                      valueColor:
                          playerData.netWorth >= 0 ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nach dem Zahltag werden folgende Änderungen vorgenommen:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      'Neuer Kontostand',
                      '$newSavings €',
                      valueColor: Colors.blue,
                    ),
                    _buildInfoRow(
                      'Reduzierte Schulden',
                      '$reducedDebtAmount €',
                      valueColor: Colors.green,
                    ),
                    _buildInfoRow(
                      'Neues Gesamtvermögen',
                      '$newNetWorth €',
                      valueColor: newNetWorth >= 0 ? Colors.green : Colors.red,
                      valueFontSize: 18.0,
                      labelFontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                // Zahltag durchführen
                await playerProvider.processPayday();

                if (!context.mounted) return;

                // Erfolgsmeldung anzeigen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Zahltag erfolgreich durchgeführt!'),
                    backgroundColor: Colors.green,
                  ),
                );

                // Zurück zum HomeScreen navigieren
                Navigator.pop(context);

                // Verzögerung, um sicherzustellen, dass die Navigation abgeschlossen ist
                await Future.delayed(const Duration(milliseconds: 100));

                // Scrolle den HomeScreen nach oben
                homeScreenKey.currentState?.scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: const Text(
                'Zahltag durchführen',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
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
