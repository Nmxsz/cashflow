import 'package:flutter/foundation.dart';
import 'index.dart';

enum GameRoomStatus { waiting, playing, finished }

class GameRoom {
  final String id;
  final String code;
  final PlayerData host;
  final List<PlayerData> players;
  final GameRoomStatus status;
  final int maxPlayers;
  final int currentPlayerIndex;
  final DateTime createdAt;
  final DateTime? startedAt;

  const GameRoom({
    required this.id,
    required this.code,
    required this.host,
    required this.players,
    this.status = GameRoomStatus.waiting,
    this.maxPlayers = 6,
    this.currentPlayerIndex = 0,
    required this.createdAt,
    this.startedAt,
  });

  bool get canStart =>
      players.length >= 1 &&
      status == GameRoomStatus.waiting &&
      players.every((player) => player.isReady);
  bool get isFull => players.length >= maxPlayers;
  PlayerData get currentPlayer => players[currentPlayerIndex];

  GameRoom copyWith({
    String? id,
    String? code,
    PlayerData? host,
    List<PlayerData>? players,
    GameRoomStatus? status,
    int? maxPlayers,
    int? currentPlayerIndex,
    DateTime? createdAt,
    DateTime? startedAt,
  }) {
    return GameRoom(
      id: id ?? this.id,
      code: code ?? this.code,
      host: host ?? this.host,
      players: players ?? this.players,
      status: status ?? this.status,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'host': host.toJson(),
      'players': players.map((p) => p.toJson()).toList(),
      'status': status.toString(),
      'maxPlayers': maxPlayers,
      'currentPlayerIndex': currentPlayerIndex,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
    };
  }

  factory GameRoom.fromJson(Map<String, dynamic> json) {
    return GameRoom(
      id: json['id'] as String,
      code: json['code'] as String,
      host: PlayerData.fromJson(json['host'] as Map<String, dynamic>),
      players: (json['players'] as List)
          .map((p) => PlayerData.fromJson(p as Map<String, dynamic>))
          .toList(),
      status: GameRoomStatus.values.firstWhere(
        (s) => s.toString() == json['status'],
      ),
      maxPlayers: json['maxPlayers'] as int,
      currentPlayerIndex: json['currentPlayerIndex'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameRoom && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
