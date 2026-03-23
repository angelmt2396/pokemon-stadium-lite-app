import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_pokemon_snapshot.dart';

class BattlePlayerSnapshot {
  const BattlePlayerSnapshot({
    required this.playerId,
    required this.activePokemonIndex,
    required this.activePokemon,
    required this.team,
  });

  final String playerId;
  final int activePokemonIndex;
  final BattlePokemonSnapshot activePokemon;
  final List<BattlePokemonSnapshot> team;

  BattlePlayerSnapshot copyWith({
    String? playerId,
    int? activePokemonIndex,
    BattlePokemonSnapshot? activePokemon,
    List<BattlePokemonSnapshot>? team,
  }) {
    return BattlePlayerSnapshot(
      playerId: playerId ?? this.playerId,
      activePokemonIndex: activePokemonIndex ?? this.activePokemonIndex,
      activePokemon: activePokemon ?? this.activePokemon,
      team: team ?? this.team,
    );
  }

  factory BattlePlayerSnapshot.fromJson(Map<String, dynamic> json) {
    return BattlePlayerSnapshot(
      playerId: json['playerId'] as String,
      activePokemonIndex: json['activePokemonIndex'] as int,
      activePokemon:
          BattlePokemonSnapshot.fromJson(json['activePokemon'] as Map<String, dynamic>),
      team: ((json['team'] as List<dynamic>? ?? const <dynamic>[]))
          .whereType<Map<String, dynamic>>()
          .map(BattlePokemonSnapshot.fromJson)
          .toList(),
    );
  }
}
