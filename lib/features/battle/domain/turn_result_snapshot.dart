import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_pokemon_snapshot.dart';

class AutoSwitchedPokemonSnapshot {
  const AutoSwitchedPokemonSnapshot({
    required this.playerId,
    required this.activePokemonIndex,
    required this.pokemon,
  });

  final String playerId;
  final int activePokemonIndex;
  final BattlePokemonSnapshot? pokemon;

  factory AutoSwitchedPokemonSnapshot.fromJson(Map<String, dynamic> json) {
    return AutoSwitchedPokemonSnapshot(
      playerId: json['playerId'] as String,
      activePokemonIndex: json['activePokemonIndex'] as int,
      pokemon: switch (json['pokemon']) {
        final Map<String, dynamic> payload => BattlePokemonSnapshot.fromJson(payload),
        _ => null,
      },
    );
  }
}

class TurnResultSnapshot {
  const TurnResultSnapshot({
    required this.battleId,
    required this.attackerPlayerId,
    required this.defenderPlayerId,
    required this.attackerPokemonId,
    required this.defenderPokemonId,
    required this.damage,
    required this.defenderRemainingHp,
    required this.defenderDefeated,
    required this.autoSwitchedPokemon,
    required this.nextTurnPlayerId,
    required this.battleStatus,
  });

  final String battleId;
  final String attackerPlayerId;
  final String defenderPlayerId;
  final int attackerPokemonId;
  final int defenderPokemonId;
  final int damage;
  final int defenderRemainingHp;
  final bool defenderDefeated;
  final AutoSwitchedPokemonSnapshot? autoSwitchedPokemon;
  final String? nextTurnPlayerId;
  final String battleStatus;

  factory TurnResultSnapshot.fromJson(Map<String, dynamic> json) {
    return TurnResultSnapshot(
      battleId: json['battleId'] as String,
      attackerPlayerId: json['attackerPlayerId'] as String,
      defenderPlayerId: json['defenderPlayerId'] as String,
      attackerPokemonId: json['attackerPokemonId'] as int,
      defenderPokemonId: json['defenderPokemonId'] as int,
      damage: json['damage'] as int,
      defenderRemainingHp: json['defenderRemainingHp'] as int,
      defenderDefeated: json['defenderDefeated'] as bool? ?? false,
      autoSwitchedPokemon: switch (json['autoSwitchedPokemon']) {
        final Map<String, dynamic> payload => AutoSwitchedPokemonSnapshot.fromJson(payload),
        _ => null,
      },
      nextTurnPlayerId: json['nextTurnPlayerId'] as String?,
      battleStatus: json['battleStatus'] as String,
    );
  }
}
