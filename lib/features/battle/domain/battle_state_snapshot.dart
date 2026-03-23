import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_player_snapshot.dart';

class BattleStateSnapshot {
  const BattleStateSnapshot({
    required this.battleId,
    required this.lobbyId,
    required this.status,
    required this.currentTurnPlayerId,
    required this.winnerPlayerId,
    required this.disconnectedPlayerId,
    required this.reconnectDeadlineAt,
    required this.finishReason,
    required this.players,
  });

  final String battleId;
  final String lobbyId;
  final String status;
  final String? currentTurnPlayerId;
  final String? winnerPlayerId;
  final String? disconnectedPlayerId;
  final DateTime? reconnectDeadlineAt;
  final String? finishReason;
  final List<BattlePlayerSnapshot> players;

  BattleStateSnapshot copyWith({
    String? battleId,
    String? lobbyId,
    String? status,
    String? currentTurnPlayerId,
    bool clearCurrentTurnPlayerId = false,
    String? winnerPlayerId,
    bool clearWinnerPlayerId = false,
    String? disconnectedPlayerId,
    bool clearDisconnectedPlayerId = false,
    DateTime? reconnectDeadlineAt,
    bool clearReconnectDeadlineAt = false,
    String? finishReason,
    bool clearFinishReason = false,
    List<BattlePlayerSnapshot>? players,
  }) {
    return BattleStateSnapshot(
      battleId: battleId ?? this.battleId,
      lobbyId: lobbyId ?? this.lobbyId,
      status: status ?? this.status,
      currentTurnPlayerId: clearCurrentTurnPlayerId
          ? null
          : currentTurnPlayerId ?? this.currentTurnPlayerId,
      winnerPlayerId:
          clearWinnerPlayerId ? null : winnerPlayerId ?? this.winnerPlayerId,
      disconnectedPlayerId: clearDisconnectedPlayerId
          ? null
          : disconnectedPlayerId ?? this.disconnectedPlayerId,
      reconnectDeadlineAt: clearReconnectDeadlineAt
          ? null
          : reconnectDeadlineAt ?? this.reconnectDeadlineAt,
      finishReason: clearFinishReason ? null : finishReason ?? this.finishReason,
      players: players ?? this.players,
    );
  }

  BattlePlayerSnapshot? findPlayer(String playerId) {
    for (final player in players) {
      if (player.playerId == playerId) {
        return player;
      }
    }
    return null;
  }

  BattlePlayerSnapshot? findOpponent(String playerId) {
    for (final player in players) {
      if (player.playerId != playerId) {
        return player;
      }
    }
    return null;
  }

  factory BattleStateSnapshot.fromJson(Map<String, dynamic> json) {
    return BattleStateSnapshot(
      battleId: json['battleId'] as String,
      lobbyId: json['lobbyId'] as String,
      status: json['status'] as String,
      currentTurnPlayerId: json['currentTurnPlayerId'] as String?,
      winnerPlayerId: json['winnerPlayerId'] as String?,
      disconnectedPlayerId: json['disconnectedPlayerId'] as String?,
      reconnectDeadlineAt: switch (json['reconnectDeadlineAt']) {
        final String value => DateTime.tryParse(value),
        _ => null,
      },
      finishReason: json['finishReason'] as String?,
      players: ((json['players'] as List<dynamic>? ?? const <dynamic>[]))
          .whereType<Map<String, dynamic>>()
          .map(BattlePlayerSnapshot.fromJson)
          .toList(),
    );
  }
}
