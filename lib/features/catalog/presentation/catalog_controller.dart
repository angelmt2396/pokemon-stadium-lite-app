import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokemon_stadium_lite_app/features/catalog/data/catalog_repository.dart';
import 'package:pokemon_stadium_lite_app/features/catalog/domain/pokemon_detail.dart';
import 'package:pokemon_stadium_lite_app/features/catalog/domain/pokemon_list_item.dart';

final pokemonCatalogProvider = FutureProvider<List<PokemonListItem>>((ref) {
  return ref.watch(catalogRepositoryProvider).getCatalog();
});

final selectedPokemonIdProvider = StateProvider<int?>((ref) => null);

final effectiveSelectedPokemonIdProvider = Provider<int?>((ref) {
  final selectedPokemonId = ref.watch(selectedPokemonIdProvider);
  if (selectedPokemonId != null) {
    return selectedPokemonId;
  }

  final catalog = ref.watch(pokemonCatalogProvider);
  return catalog.maybeWhen(
    data: (pokemon) => pokemon.isEmpty ? null : pokemon.first.id,
    orElse: () => null,
  );
});

final selectedPokemonDetailProvider = FutureProvider<PokemonDetail?>((ref) async {
  final selectedPokemonId = ref.watch(effectiveSelectedPokemonIdProvider);
  if (selectedPokemonId == null) {
    return null;
  }

  return ref.watch(catalogRepositoryProvider).getPokemonDetail(selectedPokemonId);
});
