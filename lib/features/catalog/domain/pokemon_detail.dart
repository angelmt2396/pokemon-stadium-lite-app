class PokemonDetail {
  const PokemonDetail({
    required this.id,
    required this.name,
    required this.sprite,
    required this.type,
    required this.hp,
    required this.attack,
    required this.defense,
    required this.speed,
  });

  final int id;
  final String name;
  final String sprite;
  final List<String> type;
  final int hp;
  final int attack;
  final int defense;
  final int speed;

  factory PokemonDetail.fromJson(Map<String, dynamic> json) {
    return PokemonDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      sprite: json['sprite'] as String,
      type: ((json['type'] as List<dynamic>? ?? const <dynamic>[]))
          .map((type) => type.toString())
          .toList(),
      hp: json['hp'] as int,
      attack: json['attack'] as int,
      defense: json['defense'] as int,
      speed: json['speed'] as int,
    );
  }
}
