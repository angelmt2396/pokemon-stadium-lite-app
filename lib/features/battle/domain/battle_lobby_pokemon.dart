class BattleLobbyPokemon {
  const BattleLobbyPokemon({
    required this.pokemonId,
    required this.name,
    required this.sprite,
  });

  final int pokemonId;
  final String name;
  final String sprite;

  factory BattleLobbyPokemon.fromJson(Map<String, dynamic> json) {
    return BattleLobbyPokemon(
      pokemonId: json['pokemonId'] as int,
      name: json['name'] as String,
      sprite: json['sprite'] as String,
    );
  }
}
