import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/index.dart';
import '../models/game_room.dart';
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

  void _createRoomWithName(String playerName) async {
    setState(() => _isCreatingRoom = true);

    final multiplayerProvider =
        Provider.of<MultiplayerProvider>(context, listen: false);
    
    // Benutze die öffentliche Methode, die für Abwärtskompatibilität beibehalten wird
    final roomCode = multiplayerProvider.generateUniqueRoomCode();

    // Erstelle einen temporären Spieler für die Raumerstellung
    final player = PlayerData(
      id: const Uuid().v4(),
      name: playerName,
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

    // Erstelle den Raum sofort in der Datenbank mit dem generierten Code
    try {
      await multiplayerProvider.createRoom(player, roomCode: roomCode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Raum mit Code $roomCode erstellt!'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Erstellen des Raums: $e'))
      );
      setState(() => _isCreatingRoom = false);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raum erstellt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Dein Raum wurde erstellt mit dem Code:'),
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
            const SizedBox(height: 16),
            const Text('Teile diesen Code mit deinen Mitspielern.'),
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
    
    setState(() => _isCreatingRoom = false);
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
          keyboardType: TextInputType.text,
          maxLength: 6,
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              final code = _roomCodeController.text.toUpperCase();
              if (code.length == 6) {
                setState(() => _isCreatingRoom = true);
                Navigator.of(context).pop();
                
                final multiplayerProvider =
                    Provider.of<MultiplayerProvider>(context, listen: false);
                
                try {
                  final exists = await multiplayerProvider.roomExists(code);
                  if (exists) {
                    _showNameInputDialog(code);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Ungültiger Code oder Raum existiert nicht mehr')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fehler: $e')),
                  );
                } finally {
                  setState(() => _isCreatingRoom = false);
                }
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
  late MultiplayerProvider _multiplayerProvider;

  @override
  void initState() {
    super.initState();
    _multiplayerProvider = Provider.of<MultiplayerProvider>(context, listen: false);
    
    // Zeige Erfolgsmeldung bei erfolgreicher Firebase-Verbindung
    Future.delayed(Duration.zero, () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Raum verbunden'),
          duration: Duration(seconds: 3),
        ),
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      // Füge den Spieler hinzu und zeige Profil-Setup
      //_addPlayer();
    }
  }

  @override
  void dispose() {
    // Wenn der Bildschirm geschlossen wird, verlasse den Raum
    if (_multiplayerProvider.isInRoom) {
      _multiplayerProvider.leaveRoom();
    }
    super.dispose();
  }

  void _addPlayer() async {
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
    
    setState(() {
      _players = [player];
    });
    
    // Prüfe, ob der Raum bereits existiert oder einem Raum beigetreten werden soll
    try {
      if (widget.roomCode.length == 6) {
        // Wenn Beitritt zu bestehendem Raum
        if (!_multiplayerProvider.isInRoom) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Betrete Raum...')),
          );
          
          await _multiplayerProvider.joinRoom(widget.roomCode, player);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Raum mit Code ${widget.roomCode} beigetreten!')),
          );
        }
      } else if (!_multiplayerProvider.isInRoom) {
        // Wenn Raum nicht existiert - dieser Fall sollte für die Raumerstellung nicht mehr vorkommen,
        // da der Raum bereits in _createRoomWithName erstellt wurde
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verbinde mit bestehendem Raum...')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler bei der Verbindung: $e')),
      );
    }
    
    // Dann zeige das Profil-Setup
    _showProfileSetupDialog(player);
  }

  void _showProfileSetupDialog(PlayerData player) {
    Future.delayed(Duration.zero, () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileSetupScreen(
            player: player,
            onProfileSaved: (updatedPlayer) async {
              setState(() {
                _players = [updatedPlayer];
              });
              
              // Aktualisiere den Spieler im bestehenden Raum
              if (_multiplayerProvider.isInRoom) {
                try {
                  await _multiplayerProvider.updatePlayerInRoom(updatedPlayer);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Spielerprofil aktualisiert!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fehler beim Aktualisieren des Profils: $e')),
                  );
                }
              }
              
              Navigator.pop(context); // Navigiere zurück zum GameRoom
            },
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MultiplayerProvider>(
      builder: (context, multiplayerProvider, child) {
        final room = multiplayerProvider.currentRoom;
        final players = room?.players ?? _players;
        final isHost = multiplayerProvider.isHost;
        final canStart = room?.canStart ?? false;
        final error = multiplayerProvider.error;
        
        if (error != null) {
          // Zeige Fehler als Snackbar an
          Future.microtask(() {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error)),
            );
            multiplayerProvider.clearError();
          });
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Spielraum'),
            actions: [
              if (canStart && isHost)
                TextButton.icon(
                  onPressed: () async {
                    try {
                      await multiplayerProvider.startGame();
                      // Setze die Spielerdaten für den aktuellen Spieler
                      final currentPlayer = multiplayerProvider.currentPlayer;
                      if (currentPlayer != null) {
                        Provider.of<PlayerProvider>(context, listen: false)
                            .setPlayerData(currentPlayer);
                      }
                      
                      // Navigiere zum HomeScreen und entferne alle vorherigen Screens
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                        (route) => false,
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Fehler beim Starten: $e')),
                      );
                    }
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
                          'Raumcode: ${room?.code ?? widget.roomCode}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Spieler: ${players.length}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: room?.code ?? widget.roomCode));
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
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    final isCurrentPlayer = player.id == multiplayerProvider.currentPlayer?.id;
                    print(isCurrentPlayer);
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(player.name[0]),
                        backgroundColor: isCurrentPlayer ? Colors.blue : Colors.white,
                      ),
                      title: Text(
                        player.name,
                        style: TextStyle(
                          fontWeight: isCurrentPlayer ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        player.salary > 0 ? 'Bereit' : 'Profil erstellen',
                        style: TextStyle(
                          color: player.salary > 0 ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: isCurrentPlayer && player.salary == 0
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
              if (room?.status == GameRoomStatus.waiting)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        isHost 
                            ? 'Warte auf weitere Spieler...' 
                            : 'Warte auf den Host...',
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (canStart && isHost)
                        const SizedBox(height: 8),
                      if (canStart && isHost)
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
      },
    );
  }
}
