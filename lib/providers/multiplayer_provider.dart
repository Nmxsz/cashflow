import 'package:flutter/foundation.dart';
import '../models/game_room.dart';
import '../models/player_data.dart';
import 'dart:math';

class MultiplayerProvider with ChangeNotifier {
  GameRoom? _currentRoom;
  bool _isConnecting = false;
  String? _error;

  GameRoom? get currentRoom => _currentRoom;
  bool get isConnecting => _isConnecting;
  String? get error => _error;
  bool get isInRoom => _currentRoom != null;
  bool get isHost => _currentRoom?.host == currentPlayer;
  PlayerData? get currentPlayer => _currentRoom?.players.firstWhere(
        (p) => p.id == _currentPlayerId,
        orElse: () => _currentRoom!.host,
      );
  String? _currentPlayerId;

  // Generiere einen zufälligen 6-stelligen Code
  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  // Erstelle einen neuen Raum
  Future<void> createRoom(PlayerData host) async {
    try {
      _isConnecting = true;
      _error = null;
      notifyListeners();

      // TODO: Implementiere die tatsächliche Raumerstellung mit Backend
      await Future.delayed(
          const Duration(seconds: 1)); // Simuliere Netzwerkverzögerung

      final roomCode = _generateRoomCode();
      _currentRoom = GameRoom(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        code: roomCode,
        host: host,
        players: [host],
        createdAt: DateTime.now(),
      );
      _currentPlayerId = host.id;

      _isConnecting = false;
      notifyListeners();
    } catch (e) {
      _error = 'Fehler beim Erstellen des Raums: $e';
      _isConnecting = false;
      notifyListeners();
      rethrow;
    }
  }

  // Trete einem Raum bei
  Future<void> joinRoom(String roomCode, PlayerData player) async {
    try {
      _isConnecting = true;
      _error = null;
      notifyListeners();

      // TODO: Implementiere den tatsächlichen Beitritt mit Backend
      await Future.delayed(
          const Duration(seconds: 1)); // Simuliere Netzwerkverzögerung

      // Simuliere einen Raumbeitritt
      if (_currentRoom == null) {
        throw Exception('Raum nicht gefunden');
      }
      if (_currentRoom!.isFull) {
        throw Exception('Raum ist voll');
      }

      final updatedPlayers = [..._currentRoom!.players, player];
      _currentRoom = _currentRoom!.copyWith(players: updatedPlayers);
      _currentPlayerId = player.id;

      _isConnecting = false;
      notifyListeners();
    } catch (e) {
      _error = 'Fehler beim Beitreten des Raums: $e';
      _isConnecting = false;
      notifyListeners();
      rethrow;
    }
  }

  // Starte das Spiel
  Future<void> startGame() async {
    try {
      if (_currentRoom == null) {
        throw Exception('Kein aktiver Raum');
      }
      if (!_currentRoom!.canStart) {
        throw Exception('Spiel kann noch nicht gestartet werden');
      }

      _currentRoom = _currentRoom!.copyWith(
        status: GameRoomStatus.playing,
        startedAt: DateTime.now(),
      );
      notifyListeners();
    } catch (e) {
      _error = 'Fehler beim Starten des Spiels: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Verlasse den Raum
  Future<void> leaveRoom() async {
    try {
      if (_currentRoom == null) return;

      // Wenn der Host den Raum verlässt, wird der Raum aufgelöst
      if (isHost) {
        // TODO: Informiere andere Spieler
        _currentRoom = null;
      } else {
        // Entferne den Spieler aus der Liste
        final updatedPlayers = _currentRoom!.players
            .where((p) => p.id != _currentPlayerId)
            .toList();
        _currentRoom = _currentRoom!.copyWith(players: updatedPlayers);
      }

      _currentPlayerId = null;
      notifyListeners();
    } catch (e) {
      _error = 'Fehler beim Verlassen des Raums: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Aktualisiere den Spielstatus
  void updateGameState(GameRoom newRoom) {
    _currentRoom = newRoom;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
