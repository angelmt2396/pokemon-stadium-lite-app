class BattlePokemonSnapshot {
  const BattlePokemonSnapshot({
    required this.pokemonId,
    required this.name,
    required this.sprite,
    required this.hp,
    required this.currentHp,
    required this.attack,
    required this.defense,
    required this.speed,
    required this.defeated,
  });

  final int pokemonId;
  final String name;
  final String sprite;
  final int hp;
  final int currentHp;
  final int attack;
  final int defense;
  final int speed;
  final bool defeated;

  BattlePokemonSnapshot copyWith({
    int? pokemonId,
    String? name,
    String? sprite,
    int? hp,
    int? currentHp,
    int? attack,
    int? defense,
    int? speed,
    bool? defeated,
  }) {
    return BattlePokemonSnapshot(
      pokemonId: pokemonId ?? this.pokemonId,
      name: name ?? this.name,
      sprite: sprite ?? this.sprite,
      hp: hp ?? this.hp,
      currentHp: currentHp ?? this.currentHp,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      speed: speed ?? this.speed,
      defeated: defeated ?? this.defeated,
    );
  }

  factory BattlePokemonSnapshot.fromJson(Map<String, dynamic> json) {
    return BattlePokemonSnapshot(
      pokemonId: json['pokemonId'] as int,
      name: json['name'] as String,
      sprite: json['sprite'] as String,
      hp: json['hp'] as int,
      currentHp: json['currentHp'] as int,
      attack: json['attack'] as int,
      defense: json['defense'] as int,
      speed: json['speed'] as int,
      defeated: json['defeated'] as bool? ?? false,
    );
  }
}
