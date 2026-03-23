import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokemon_stadium_lite_app/features/catalog/data/catalog_api_client.dart';
import 'package:pokemon_stadium_lite_app/features/catalog/domain/pokemon_detail.dart';
import 'package:pokemon_stadium_lite_app/features/catalog/domain/pokemon_list_item.dart';

class CatalogRepository {
  CatalogRepository(this._apiClient);

  final CatalogApiClient _apiClient;

  Future<List<PokemonListItem>> getCatalog() => _apiClient.getCatalog();

  Future<PokemonDetail> getPokemonDetail(int id) => _apiClient.getPokemonDetail(id);
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(catalogApiClientProvider));
});
