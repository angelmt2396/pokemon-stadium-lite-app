import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokemon_stadium_lite_app/core/network/network_error.dart';
import 'package:pokemon_stadium_lite_app/features/session/data/session_api_client.dart';
import 'package:pokemon_stadium_lite_app/features/session/data/session_local_data_source.dart';
import 'package:pokemon_stadium_lite_app/features/session/domain/session_snapshot.dart';

class SessionRepository {
  SessionRepository(this._apiClient, this._localDataSource);

  final SessionApiClient _apiClient;
  final SessionLocalDataSource _localDataSource;

  Future<SessionSnapshot> login(String nickname) async {
    final session = await _apiClient.createSession(nickname.trim());
    await _localDataSource.write(session);
    return session;
  }

  Future<SessionSnapshot?> restore() async {
    final persisted = await _localDataSource.read();
    if (persisted == null) {
      return null;
    }

    try {
      final session = await _apiClient.getCurrentSession(
        persisted.sessionToken,
        reconnectToken: persisted.reconnectToken,
      );
      await _localDataSource.write(session);
      return session;
    } catch (_) {
      await _localDataSource.clear();
      return null;
    }
  }

  Future<void> logout(SessionSnapshot session) async {
    try {
      await _apiClient.closeSession(session.sessionToken);
    } catch (error) {
      if (!isUnauthorizedNetworkError(error)) {
        rethrow;
      }
    }
    await _localDataSource.clear();
  }

  Future<void> persist(SessionSnapshot session) async {
    await _localDataSource.write(session);
  }
}

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(
    ref.watch(sessionApiClientProvider),
    ref.watch(sessionLocalDataSourceProvider),
  );
});
