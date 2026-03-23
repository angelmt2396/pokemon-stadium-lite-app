import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_lobby_pokemon.dart';

class BattleLobbyPlayer {
  const BattleLobbyPlayer({
    required this.playerId,
    required this.nickname,
    required this.ready,
    required this.team,
  });

  final String playerId;
  final String nickname;
  final bool ready;
  final List<BattleLobbyPokemon> team;

  factory BattleLobbyPlayer.fromJson(Map<String, dynamic> json) {
    return BattleLobbyPlayer(
      playerId: json['playerId'] as String,
      nickname: json['nickname'] as String,
      ready: json['ready'] as bool? ?? false,
      team: ((json['team'] as List<dynamic>? ?? const <dynamic>[]))
          .whereType<Map<String, dynamic>>()
          .map(BattleLobbyPokemon.fromJson)
          .toList(),
    );
  }
}
