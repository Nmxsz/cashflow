import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/index.dart';
import '../providers/player_provider.dart';
import '../providers/multiplayer_provider.dart';
import 'package:provider/provider.dart';
import 'profile_setup_screen.dart';
import 'package:uuid/uuid.dart';
import 'home_screen.dart';

class MultiplayerRoomScreen extends StatefulWidget {
  const MultiplayerRoomScreen({Key? key}) : super(key: key);

  @override
  State<MultiplayerRoomScreen> createState() => _MultiplayerRoomScreenState();
}

class _MultiplayerRoomScreenState extends State<MultiplayerRoomScreen> {
  final TextEditingController _roomCodeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isCreatingRoom = false;

  @override
  void dispose() {
    _roomCodeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _createRoom() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raum erstellen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Gib deinen Namen ein',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
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
              if (_nameController.text.isNotEmpty) {
                Navigator.of(context).pop();
                _createRoomWithName(_nameController.text);
              }
            },
            child: const Text('Weiter'),
          ),
        ],
      ),
    );
  }

  void _createRoomWithName(String playerName) {
    setState(() => _isCreatingRoom = true);

    final multiplayerProvider =
        Provider.of<MultiplayerProvider>(context, listen: false);
    final roomCode = multiplayerProvider.generateUniqueRoomCode();

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
                  roomCode,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: roomCode));
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
              _navigateToGameRoom(roomCode: roomCode, playerName: playerName);
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
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              final code = _roomCodeController.text;
              final multiplayerProvider =
                  Provider.of<MultiplayerProvider>(context, listen: false);

              if (code.length == 6 && multiplayerProvider.isRoomActive(code)) {
                Navigator.of(context).pop();
                _showNameInputDialog(code);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Ungültiger oder inaktiver Raumcode')),
                );
              }
            },
            child: const Text('Weiter'),
          ),
        ],
      ),
    );
  }

  void _showNameInputDialog(String roomCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Spielername'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Gib deinen Namen ein',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty) {
                Navigator.of(context).pop();
                _navigateToGameRoom(
                    roomCode: roomCode, playerName: _nameController.text);
              }
            },
            child: const Text('Beitreten'),
          ),
        ],
      ),
    );
  }

  void _navigateToGameRoom(
      {required String roomCode, required String playerName}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameRoomScreen(
          roomCode: roomCode,
          playerName: playerName,
        ),
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
  final String roomCode;
  final String playerName;

  const GameRoomScreen({
    Key? key,
    required this.roomCode,
    required this.playerName,
  }) : super(key: key);

  @override
  State<GameRoomScreen> createState() => _GameRoomScreenState();
}

class _GameRoomScreenState extends State<GameRoomScreen> {
  List<PlayerData> _players = [];
  bool _isGameStarted = false;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      // Füge den Spieler hinzu und zeige Profil-Setup
      _addPlayer();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _addPlayer() {
    final player = PlayerData(
      id: const Uuid().v4(),
      name: widget.playerName,
      profession: 'Spieler',
      salary: 0,
      savings: 0,
      assets: [],
      liabilities: [],
      expenses: [],
      totalExpenses: 0,
      cashflow: 0,
      costPerChild: 0,
    );
    _players.add(player);
    _showProfileSetupDialog(player);
  }

  void _showProfileSetupDialog(PlayerData player) {
    Future.delayed(Duration.zero, () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileSetupScreen(
            player: player,
            onProfileSaved: (updatedPlayer) {
              setState(() {
                final index =
                    _players.indexWhere((p) => p.id == updatedPlayer.id);
                if (index != -1) {
                  _players[index] = updatedPlayer;
                }
              });
              Navigator.pop(context); // Navigiere zurück zum GameRoom
            },
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spielraum'),
        actions: [
          if (!_isGameStarted &&
              _players.isNotEmpty &&
              _players.every((p) => p.salary > 0))
            TextButton.icon(
              onPressed: () {
                setState(() => _isGameStarted = true);
                // Setze die Spielerdaten für alle Spieler und navigiere zum HomeScreen
                for (var player in _players) {
                  Provider.of<PlayerProvider>(context, listen: false)
                      .setPlayerData(player);
                }
                // Navigiere zum HomeScreen und entferne alle vorherigen Screens
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Raumcode: ${widget.roomCode}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Spieler: ${_players.length}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.roomCode));
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
                  subtitle: Text(
                    player.salary > 0 ? 'Bereit' : 'Profil erstellen',
                    style: TextStyle(
                      color: player.salary > 0 ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: player.salary == 0
                      ? ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Profil erstellen'),
                          onPressed: () => _showProfileSetupDialog(player),
                        )
                      : null,
                );
              },
            ),
          ),
          if (!_isGameStarted)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Warte auf weitere Spieler...',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (_players.isNotEmpty &&
                      _players.every((p) => p.salary > 0))
                    const SizedBox(height: 8),
                  if (_players.isNotEmpty &&
                      _players.every((p) => p.salary > 0))
                    Text(
                      'Alle Spieler sind bereit!',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
