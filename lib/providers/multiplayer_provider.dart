import 'package:flutter/foundation.dart';
import '../models/game_room.dart';
import '../models/player_data.dart';
import '../services/firebase_service.dart';
import 'dart:math';

class MultiplayerProvider with ChangeNotifier {
  GameRoom? _currentRoom;
  bool _isConnecting = false;
  String? _error;
  final Set<String> _activeRoomCodes = {};
  final Random _random = Random();
  final FirebaseService _firebaseService = FirebaseService();
  String? _currentPlayerId;

  GameRoom? get currentRoom => _currentRoom;
  bool get isConnecting => _isConnecting;
  String? get error => _error;
  bool get isInRoom => _currentRoom != null;
  bool get isHost => _currentRoom?.host.id == _currentPlayerId;
  PlayerData? get currentPlayer => _currentRoom?.players.firstWhere(
        (p) => p.id == _currentPlayerId,
        orElse: () => _currentRoom!.host,
      );

  bool isRoomActive(String code) => _activeRoomCodes.contains(code);

  String generateUniqueRoomCode() {
    // Diese Methode wird nur für die Abwärtskompatibilität beibehalten.
    // Stattdessen sollte die neue _generateRoomCode() Methode verwendet werden,
    // gefolgt von einem Aufruf von createRoom().
    final code = generateRoomCode();
    _activeRoomCodes.add(code);
    notifyListeners();
    return code;
  }

  void removeRoom(String code) {
    _activeRoomCodes.remove(code);
    notifyListeners();
  }

  // Generiere einen zufälligen 6-stelligen Code
  String generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  // Prüfe, ob ein Raum existiert
  Future<bool> roomExists(String code) async {
    try {
      return await _firebaseService.roomExists(code);
    } catch (e) {
      _error = 'Fehler beim Prüfen des Raums: $e';
      notifyListeners();
      return false;
    }
  }

  // Erstelle einen neuen Raum
  Future<void> createRoom(PlayerData host, {String? roomCode}) async {
    try {
      _isConnecting = true;
      _error = null;
      notifyListeners();

      final actualRoomCode = roomCode ?? generateRoomCode();
      final room = GameRoom(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        code: actualRoomCode,
        host: host,
        players: [host],
        createdAt: DateTime.now(),
      );

      await _firebaseService.createRoom(room);
      _currentRoom = room;
      _currentPlayerId = host.id;

      // Starte Listener für Raumänderungen
      _startRoomListener(actualRoomCode);

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

      // Prüfe, ob der Raum existiert
      final roomExists = await _firebaseService.roomExists(roomCode);
      if (!roomExists) {
        throw Exception('Raum nicht gefunden oder Code ungültig');
      }

      // Hole den Raum
      final room = await _firebaseService.getRoomByCode(roomCode);
      if (room == null) {
        throw Exception('Raum nicht gefunden');
      }

      if (room.isFull) {
        throw Exception('Raum ist voll');
      }

      // Füge den Spieler zum Raum hinzu
      await _firebaseService.addPlayerToRoom(roomCode, player);
      
      // Aktualisiere lokalen Zustand
      _currentRoom = room;
      _currentPlayerId = player.id;

      // Starte Listener für Raumänderungen
      _startRoomListener(roomCode);

      _isConnecting = false;
      notifyListeners();
    } catch (e) {
      _error = 'Fehler beim Beitreten des Raums: $e';
      _isConnecting = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // Starte Listener für Raumänderungen
  void _startRoomListener(String roomCode) {
    _firebaseService.roomStream(roomCode).listen((room) {
      if (room != null) {
        _currentRoom = room;
        notifyListeners();
      } else {
        // Raum wurde gelöscht
        _currentRoom = null;
        _error = 'Der Raum existiert nicht mehr';
        notifyListeners();
      }
    }, onError: (e) {
      _error = 'Fehler bei der Verbindung: $e';
      notifyListeners();
    });
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

      final updatedRoom = _currentRoom!.copyWith(
        status: GameRoomStatus.playing,
        startedAt: DateTime.now(),
      );
      
      await _firebaseService.updateRoom(updatedRoom);
      _currentRoom = updatedRoom;
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
      if (_currentRoom == null || _currentPlayerId == null) return;

      final roomCode = _currentRoom!.code;
      
      // Entferne den Spieler aus dem Raum
      await _firebaseService.removePlayerFromRoom(roomCode, _currentPlayerId!);
      
      _currentRoom = null;
      _currentPlayerId = null;
      notifyListeners();
    } catch (e) {
      _error = 'Fehler beim Verlassen des Raums: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Aktualisiere einen Spieler im Raum
  Future<void> updatePlayerInRoom(PlayerData updatedPlayer) async {
    try {
      if (_currentRoom == null || _currentPlayerId == null) return;
      
      final roomCode = _currentRoom!.code;
      
      // Aktualisiere den Spieler im Raum
      final updatedPlayers = _currentRoom!.players.map((player) {
        return player.id == updatedPlayer.id ? updatedPlayer : player;
      }).toList();
      
      // Aktualisiere Host, falls es der Host ist
      final updatedHost = _currentRoom!.host.id == updatedPlayer.id ? updatedPlayer : _currentRoom!.host;
      
      final updatedRoom = _currentRoom!.copyWith(
        players: updatedPlayers,
        host: updatedHost,
      );
      
      await _firebaseService.updateRoom(updatedRoom);
      _currentRoom = updatedRoom;
      notifyListeners();
    } catch (e) {
      _error = 'Fehler beim Aktualisieren des Spielers: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Aktualisiere den Spielstatus
  void updateGameState(GameRoom newRoom) async {
    try {
      await _firebaseService.updateRoom(newRoom);
      _currentRoom = newRoom;
      notifyListeners();
    } catch (e) {
      _error = 'Fehler beim Aktualisieren des Spiels: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
