class PokemonListItem {
  const PokemonListItem({
    required this.id,
    required this.name,
    required this.sprite,
  });

  final int id;
  final String name;
  final String sprite;

  factory PokemonListItem.fromJson(Map<String, dynamic> json) {
    return PokemonListItem(
      id: json['id'] as int,
      name: json['name'] as String,
      sprite: json['sprite'] as String,
    );
  }
}
