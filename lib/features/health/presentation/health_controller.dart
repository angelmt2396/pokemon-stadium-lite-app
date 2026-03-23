import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokemon_stadium_lite_app/features/health/data/health_api_client.dart';

final backendHealthProvider = FutureProvider<HealthSnapshot>((ref) async {
  return ref.watch(healthApiClientProvider).fetchHealth();
});

