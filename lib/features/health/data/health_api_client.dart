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
    try {
      final response = await _ref.read(dioProvider).get('/health');
      final data = response.data['data'] as Map<String, dynamic>;

      return HealthSnapshot(
        status: data['status'] as String? ?? 'unknown',
        service: data['service'] as String? ?? 'unknown',
      );
    } catch (error) {
      throw Exception(
        error is Exception
            ? error.toString().replaceFirst('Exception: ', '')
            : 'No se pudo consultar el health endpoint.',
      );
    }
  }
}

final healthApiClientProvider = Provider<HealthApiClient>(HealthApiClient.new);

