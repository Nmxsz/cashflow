import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_room.dart';
import '../models/player_data.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _roomsCollection = 'gameRooms';

  // Singleton-Pattern für den FirebaseService
  static final FirebaseService _instance = FirebaseService._internal();
  
  factory FirebaseService() {
    return _instance;
  }
  
  FirebaseService._internal();

  // Raum in Firestore erstellen
  Future<String> createRoom(GameRoom room) async {
    try {
      await _firestore.collection(_roomsCollection).doc(room.code).set(room.toJson());
      return room.code;
    } catch (e) {
      throw Exception('Fehler beim Erstellen des Raums: $e');
    }
  }

  // Raum anhand des Codes abrufen
  Future<GameRoom?> getRoomByCode(String code) async {
    try {
      final snapshot = await _firestore.collection(_roomsCollection).doc(code).get();
      if (snapshot.exists) {
        return GameRoom.fromJson(snapshot.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Fehler beim Abrufen des Raums: $e');
    }
  }

  // Prüfen, ob ein Raum existiert
  Future<bool> roomExists(String code) async {
    try {
      final snapshot = await _firestore.collection(_roomsCollection).doc(code).get();
      return snapshot.exists;
    } catch (e) {
      throw Exception('Fehler beim Prüfen des Raums: $e');
    }
  }

  // Spieler zum Raum hinzufügen
  Future<void> addPlayerToRoom(String roomCode, PlayerData player) async {
    try {
      final roomSnap = await _firestore.collection(_roomsCollection).doc(roomCode).get();
      if (!roomSnap.exists) {
        throw Exception('Raum existiert nicht');
      }

      final room = GameRoom.fromJson(roomSnap.data()!);
      if (room.isFull) {
        throw Exception('Raum ist voll');
      }

      // Spieler zur Liste hinzufügen
      final updatedPlayers = [...room.players, player];
      await _firestore.collection(_roomsCollection).doc(roomCode).update({
        'players': updatedPlayers.map((p) => p.toJson()).toList(),
      });
    } catch (e) {
      throw Exception('Fehler beim Hinzufügen des Spielers: $e');
    }
  }

  // Raum aktualisieren
  Future<void> updateRoom(GameRoom room) async {
    try {
      await _firestore.collection(_roomsCollection).doc(room.code).update(room.toJson());
    } catch (e) {
      throw Exception('Fehler beim Aktualisieren des Raums: $e');
    }
  }

  // Spieler aus dem Raum entfernen
  Future<void> removePlayerFromRoom(String roomCode, String playerId) async {
    try {
      final roomSnap = await _firestore.collection(_roomsCollection).doc(roomCode).get();
      if (!roomSnap.exists) {
        throw Exception('Raum existiert nicht');
      }

      final room = GameRoom.fromJson(roomSnap.data()!);
      
      // Spieler aus der Liste entfernen
      final updatedPlayers = room.players.where((p) => p.id != playerId).toList();
      
      // Wenn keine Spieler mehr übrig sind, Raum löschen
      if (updatedPlayers.isEmpty || room.host.id == playerId) {
        await _firestore.collection(_roomsCollection).doc(roomCode).delete();
        return;
      }
      
      await _firestore.collection(_roomsCollection).doc(roomCode).update({
        'players': updatedPlayers.map((p) => p.toJson()).toList(),
      });
    } catch (e) {
      throw Exception('Fehler beim Entfernen des Spielers: $e');
    }
  }

  // Raum löschen
  Future<void> deleteRoom(String roomCode) async {
    try {
      await _firestore.collection(_roomsCollection).doc(roomCode).delete();
    } catch (e) {
      throw Exception('Fehler beim Löschen des Raums: $e');
    }
  }

  // Stream für Echtzeit-Updates des Raums
  Stream<GameRoom?> roomStream(String roomCode) {
    return _firestore
        .collection(_roomsCollection)
        .doc(roomCode)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        try {
          return GameRoom.fromJson(snapshot.data()!);
        } catch (e) {
          print('Fehler beim Parsen des Raums: $e');
          return null;
        }
      }
      return null;
    });
  }
} 