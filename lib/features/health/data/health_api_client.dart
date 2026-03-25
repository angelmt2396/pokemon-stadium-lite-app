import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokemon_stadium_lite_app/core/network/api_client.dart';

class HealthSnapshot {
  const HealthSnapshot({
    required this.status,
    required this.service,
  });

  final String status;
  final String service;
}

class HealthApiClient {
  HealthApiClient(this._ref);

  final Ref _ref;

  Future<HealthSnapshot> fetchHealth() async {
    final response = await _ref.read(dioProvider).get<Map<String, dynamic>>('/health');
    final payload = response.data;
    if (payload == null) {
      throw Exception('Respuesta vacía del backend.');
    }

    final data = payload['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('El backend no devolvió un health válido.');
    }

    return HealthSnapshot(
      status: data['status'] as String? ?? 'unknown',
      service: data['service'] as String? ?? 'unknown',
    );
  }
}

final healthApiClientProvider = Provider<HealthApiClient>(HealthApiClient.new);
