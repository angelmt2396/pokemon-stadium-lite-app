import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_lobby_player.dart';

class BattleLobbyStatus {
  const BattleLobbyStatus({
    required this.lobbyId,
    required this.status,
    required this.players,
  });

  final String lobbyId;
  final String status;
  final List<BattleLobbyPlayer> players;

  BattleLobbyPlayer? findPlayer(String playerId) {
    for (final player in players) {
      if (player.playerId == playerId) {
        return player;
      }
    }

    return null;
  }

  BattleLobbyPlayer? findOpponent(String playerId) {
    for (final player in players) {
      if (player.playerId != playerId) {
        return player;
      }
    }

    return null;
  }

  factory BattleLobbyStatus.fromJson(Map<String, dynamic> json) {
    return BattleLobbyStatus(
      lobbyId: json['lobbyId'] as String,
      status: json['status'] as String,
      players: ((json['players'] as List<dynamic>? ?? const <dynamic>[]))
          .whereType<Map<String, dynamic>>()
          .map(BattleLobbyPlayer.fromJson)
          .toList(),
    );
  }
}
