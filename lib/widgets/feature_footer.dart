import 'package:flutter/material.dart';

class FeatureFooter extends StatelessWidget {
  const FeatureFooter({Key? key}) : super(key: key);

  void _showFeaturesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Features'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFeatureItem(
                'Singleplayer',
                'Spiele alleine und entwickle deine Finanzstrategie',
                Icons.person,
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                'Multiplayer',
                'Spiele mit Freunden und vergleiche deine Strategien',
                Icons.people,
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                'Vordefinierte Berufe',
                'Wähle aus verschiedenen Karriereoptionen mit unterschiedlichen Startbedingungen',
                Icons.work,
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                'Zahltag',
                'Führe regelmäßige Gehaltszahlungen durch und plane deine Finanzen',
                Icons.payment,
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                'Kredit aufnehmen',
                'Nimm Bankdarlehen auf für Investitionen oder Notfälle',
                Icons.credit_card,
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                'Immobilien kaufen',
                'Investiere in Immobilien und generiere passives Einkommen',
                Icons.home,
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                'Spieleransicht Multiplayer',
                'Verfolge die Entwicklung und Strategien anderer Spieler',
                Icons.visibility,
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                'Dark Mode',
                'Wähle zwischen hellem und dunklem Design für optimale Lesbarkeit',
                Icons.dark_mode,
              ),
            ],
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
  }

  Widget _buildFeatureItem(String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Center(
        child: TextButton.icon(
          onPressed: () => _showFeaturesDialog(context),
          icon: const Icon(Icons.info_outline),
          label: const Text('Features anzeigen'),
        ),
      ),
    );
  }
}
