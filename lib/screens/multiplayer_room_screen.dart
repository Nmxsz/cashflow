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
import '../widgets/theme_toggle_button.dart';

class MultiplayerRoomScreen extends StatefulWidget {
  const MultiplayerRoomScreen({Key? key}) : super(key: key);

  @override
  State<MultiplayerRoomScreen> createState() => _MultiplayerRoomScreenState();
}

class _MultiplayerRoomScreenState extends State<MultiplayerRoomScreen> {
  final TextEditingController _roomCodeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isCreatingRoom = false;
  String _loadingMessage = 'Bitte warten...';

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
    setState(() {
      _isCreatingRoom = true;
      _loadingMessage = 'Raum wird erstellt...';
    });

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
          SnackBar(content: Text('Raum mit Code $roomCode erstellt!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Erstellen des Raums: $e')));
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
                Navigator.of(context).pop();

                setState(() {
                  _isCreatingRoom = true;
                  _loadingMessage = 'Raum wird gesucht...';
                });

                final multiplayerProvider =
                    Provider.of<MultiplayerProvider>(context, listen: false);

                try {
                  final exists = await multiplayerProvider.roomExists(code);
                  if (exists) {
                    _showNameInputDialog(code);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Ungültiger Code oder Raum existiert nicht mehr')),
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

                setState(() {
                  _isCreatingRoom = true;
                  _loadingMessage = 'Trete Raum bei...';
                });

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
    // Keep the loading state active during navigation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameRoomScreen(
          roomCode: roomCode,
          playerName: playerName,
        ),
      ),
    ).then((_) {
      // Once navigation is complete (e.g., when returning from GameRoomScreen),
      // ensure we reset the loading state
      if (mounted) {
        setState(() => _isCreatingRoom = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Multiplayer'),
            actions: [
              ThemeToggleButton(),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isCreatingRoom ? null : _createRoom,
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
                  onPressed: _isCreatingRoom ? null : _joinRoom,
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
        ),
        // Loading Overlay
        if (_isCreatingRoom)
          Container(
            color: Colors.black54,
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _loadingMessage,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ),
          ),
      ],
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
  bool _isLoading = true;
  String _loadingMessage = 'Verbinde mit Raum...';
  late MultiplayerProvider _multiplayerProvider;

  @override
  void initState() {
    super.initState();
    _multiplayerProvider =
        Provider.of<MultiplayerProvider>(context, listen: false);

    // Listen for game start notifications
    _multiplayerProvider.onGameStarted.listen((_) {
      // Navigate to the overview when the game starts
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    });

    // Try to connect to the room
    _connectToRoom();
  }

  Future<void> _connectToRoom() async {
    try {
      // Prüfe, ob bereits verbunden
      if (!_multiplayerProvider.isInRoom) {
        // Erstelle einen temporären Spieler
        final player = PlayerData(
          id: const Uuid().v4(),
          name: widget.playerName,
          profession: '',
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
          _loadingMessage = widget.roomCode.length == 6
              ? 'Trete Raum bei...'
              : 'Verbinde mit Raum...';
        });

        // Versuche, einen Raum zu betreten oder mit einem existierenden zu verbinden
        if (widget.roomCode.length == 6) {
          await _multiplayerProvider.joinRoom(widget.roomCode, player);
        }
      }

      setState(() => _isLoading = false);

      // Zeige Erfolgsmeldung bei erfolgreicher Verbindung
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Raum verbunden'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler bei der Verbindung: $e')),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      // Die Verbindung wird jetzt in initState hergestellt
    }
  }

  @override
  void dispose() {
    // Wenn der Bildschirm geschlossen wird und das Spiel noch nicht gestartet wurde,
    // verlasse den Raum. Wenn das Spiel bereits läuft, behalte den Raum.
    if (_multiplayerProvider.isInRoom &&
        _multiplayerProvider.currentRoom?.status != GameRoomStatus.playing) {
      _multiplayerProvider.leaveRoom();
    }
    super.dispose();
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
                    const SnackBar(
                        content: Text('Spielerprofil aktualisiert!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Fehler beim Aktualisieren des Profils: $e')),
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
    return Stack(
      children: [
        Consumer<MultiplayerProvider>(
          builder: (context, multiplayerProvider, child) {
            final room = multiplayerProvider.currentRoom;
            final players = room?.players ?? _players;
            final isHost = multiplayerProvider.isHost;
            final canStart = room?.canStart ?? false;
            final error = multiplayerProvider.error;

            // Prüfe auf Spielstart-Status und navigiere, wenn nicht-Host und Spiel gestartet
            if (room?.status == GameRoomStatus.playing &&
                !isHost &&
                !_isGameStarted) {
              _isGameStarted = true; // Verhindert mehrfaches Navigieren

              // Setze Spielerdaten und navigiere zum HomeScreen
              final currentPlayer = multiplayerProvider.currentPlayer;
              if (currentPlayer != null) {
                Provider.of<PlayerProvider>(context, listen: false)
                    .setPlayerData(currentPlayer);
              }

              // Verzögerte Navigation, um Render-Fehler zu vermeiden
              Future.microtask(() {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              });
            }

            if (error != null) {
              // Zeige Fehler als Snackbar an
              Future.microtask(() {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error)),
                );
                multiplayerProvider.clearError();
              });
            }

            // Wenn wir jetzt verbunden sind und vorher geladen haben, aktualisiere Status
            if (multiplayerProvider.isInRoom && _isLoading) {
              Future.microtask(() {
                setState(() => _isLoading = false);
              });
            }

            return Scaffold(
              appBar: AppBar(
                title: const Text('Spielraum'),
                actions: [
                  if (canStart && isHost)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Spiel starten'),
                      onPressed: () async {
                        try {
                          await multiplayerProvider.startGame();
                          // Setze die Spielerdaten für den aktuellen Spieler
                          final currentPlayer =
                              multiplayerProvider.currentPlayer;
                          if (currentPlayer != null) {
                            Provider.of<PlayerProvider>(context, listen: false)
                                .setPlayerData(currentPlayer);
                          }

                          // Navigiere zum HomeScreen und entferne alle vorherigen Screens
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => const HomeScreen()),
                            (route) => false,
                          );

                          // Hier fügen wir die Logik hinzu, um alle Spieler zur Übersicht zu leiten
                          for (var player in _players) {
                            // Logik um sicherzustellen, dass alle Spieler zur Übersicht geleitet werden
                            // Dies könnte eine Methode sein, die die Spieler zur Übersicht leitet
                            // z.B. _navigateToOverview(player);
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Fehler beim Starten: $e')),
                          );
                        }
                      },
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
                            Clipboard.setData(ClipboardData(
                                text: room?.code ?? widget.roomCode));
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
                    child: players.isEmpty
                        ? const Center(child: Text('Keine Spieler vorhanden'))
                        : ListView.builder(
                            itemCount: players.length,
                            itemBuilder: (context, index) {
                              final player = players[index];
                              final isCurrentPlayer = player.id ==
                                  multiplayerProvider.currentPlayer?.id;

                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(player.name[0]),
                                  backgroundColor: isCurrentPlayer
                                      ? Colors.blue
                                      : Colors.white,
                                ),
                                title: Text(
                                  player.name,
                                  style: TextStyle(
                                    fontWeight: isCurrentPlayer
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  player.isReady
                                      ? 'Bereit'
                                      : 'Profil erstellen',
                                  style: TextStyle(
                                    color: player.isReady
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                trailing: isCurrentPlayer
                                    ? ElevatedButton.icon(
                                        icon: const Icon(Icons.edit),
                                        label: Text(player.isReady
                                            ? 'Profil bearbeiten'
                                            : 'Profil erstellen'),
                                        onPressed: () =>
                                            _showProfileSetupDialog(player),
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
                          if (canStart && isHost) const SizedBox(height: 8),
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
        ),
        // Loading Overlay
        if (_isLoading)
          Container(
            color: Colors.black54,
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _loadingMessage,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ),
          ),
      ],
    );
  }
}
