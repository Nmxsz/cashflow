import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/index.dart';
import '../providers/player_provider.dart';
import 'package:provider/provider.dart';

class MultiplayerRoomScreen extends StatefulWidget {
  const MultiplayerRoomScreen({Key? key}) : super(key: key);

  @override
  State<MultiplayerRoomScreen> createState() => _MultiplayerRoomScreenState();
}

class _MultiplayerRoomScreenState extends State<MultiplayerRoomScreen> {
  final TextEditingController _roomCodeController = TextEditingController();
  bool _isCreatingRoom = false;

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  void _createRoom() {
    setState(() => _isCreatingRoom = true);
    // TODO: Implementiere Raumerstellung
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raum erstellt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Teile diesen Code mit deinen Mitspielern:'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ABC123', // Beispiel-Code
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: 'ABC123'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code kopiert!')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToGameRoom(isHost: true);
            },
            child: const Text('Zum Raum'),
          ),
        ],
      ),
    );
  }

  void _joinRoom() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raum beitreten'),
        content: TextField(
          controller: _roomCodeController,
          decoration: const InputDecoration(
            labelText: 'Raumcode eingeben',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Validiere Raumcode
              Navigator.of(context).pop();
              _navigateToGameRoom(isHost: false);
            },
            child: const Text('Beitreten'),
          ),
        ],
      ),
    );
  }

  void _navigateToGameRoom({required bool isHost}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameRoomScreen(isHost: isHost),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiplayer'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _createRoom,
              icon: const Icon(Icons.add),
              label: const Text('Raum erstellen'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _joinRoom,
              icon: const Icon(Icons.login),
              label: const Text('Raum beitreten'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameRoomScreen extends StatefulWidget {
  final bool isHost;

  const GameRoomScreen({
    Key? key,
    required this.isHost,
  }) : super(key: key);

  @override
  State<GameRoomScreen> createState() => _GameRoomScreenState();
}

class _GameRoomScreenState extends State<GameRoomScreen> {
  final List<PlayerData> _players = []; // Beispiel-Spielerliste
  bool _isGameStarted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spielraum'),
        actions: [
          if (widget.isHost && !_isGameStarted && _players.length >= 2)
            TextButton.icon(
              onPressed: () {
                setState(() => _isGameStarted = true);
                // TODO: Starte das Spiel
              },
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text(
                'Spiel starten',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Raumcode: ABC123',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: 'ABC123'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code kopiert!')),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _players.length,
              itemBuilder: (context, index) {
                final player = _players[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(player.name[0]),
                  ),
                  title: Text(player.name),
                  subtitle: Text(player.profession),
                  trailing: Text(
                    '${player.netWorth} €',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          if (!_isGameStarted)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Warte auf weitere Spieler...',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
