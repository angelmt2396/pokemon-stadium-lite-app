import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokemon_stadium_lite_app/core/network/api_client.dart';
import 'package:pokemon_stadium_lite_app/features/catalog/domain/pokemon_detail.dart';
import 'package:pokemon_stadium_lite_app/features/catalog/domain/pokemon_list_item.dart';

class CatalogApiClient {
  CatalogApiClient(this._dio);

  final Dio _dio;

  Future<List<PokemonListItem>> getCatalog() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/pokemon');
    final data = _unwrapData(response.data);

    if (data is! List<dynamic>) {
      throw Exception('El backend no devolvió una lista válida de Pokémon.');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(PokemonListItem.fromJson)
        .toList();
  }

  Future<PokemonDetail> getPokemonDetail(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/pokemon/$id');
    final data = _unwrapData(response.data);

    if (data is! Map<String, dynamic>) {
      throw Exception('El backend no devolvió un detalle válido de Pokémon.');
    }

    return PokemonDetail.fromJson(data);
  }

  dynamic _unwrapData(Map<String, dynamic>? payload) {
    if (payload == null) {
      throw Exception('Respuesta vacía del backend.');
    }

    return payload['data'] ?? payload;
  }
}

final catalogApiClientProvider = Provider<CatalogApiClient>((ref) {
  return CatalogApiClient(ref.watch(dioProvider));
});
