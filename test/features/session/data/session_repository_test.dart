import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pokemon_stadium_lite_app/features/session/data/session_api_client.dart';
import 'package:pokemon_stadium_lite_app/features/session/data/session_local_data_source.dart';
import 'package:pokemon_stadium_lite_app/features/session/data/session_repository.dart';
import 'package:pokemon_stadium_lite_app/features/session/domain/session_snapshot.dart';

class _MockSessionApiClient extends Mock implements SessionApiClient {}

class _MockSessionLocalDataSource extends Mock implements SessionLocalDataSource {}

void main() {
  late _MockSessionApiClient apiClient;
  late _MockSessionLocalDataSource localDataSource;
  late SessionRepository repository;

  const persistedSession = SessionSnapshot(
    sessionToken: 'expired-session-token',
    playerId: 'player-1',
    nickname: 'Ash',
    playerStatus: 'battling',
    currentLobbyId: 'lobby-1',
    currentBattleId: 'battle-1',
    reconnectToken: 'stale-reconnect-token',
  );

  const refreshedSession = SessionSnapshot(
    sessionToken: 'fresh-session-token',
    playerId: 'player-1',
    nickname: 'Ash',
    playerStatus: 'idle',
    currentLobbyId: null,
    currentBattleId: null,
    reconnectToken: 'fresh-reconnect-token',
  );

  setUp(() {
    apiClient = _MockSessionApiClient();
    localDataSource = _MockSessionLocalDataSource();
    repository = SessionRepository(apiClient, localDataSource);
  });

  test('restore recreates the session when the persisted token expired', () async {
    when(() => localDataSource.read()).thenAnswer((_) async => persistedSession);
    when(
      () => apiClient.getCurrentSession(
        persistedSession.sessionToken,
        reconnectToken: persistedSession.reconnectToken,
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/api/v1/player-sessions/me'),
        response: Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/api/v1/player-sessions/me'),
          statusCode: 401,
          data: const {
            'success': false,
            'message': 'Invalid or expired session token',
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );
    when(() => apiClient.createSession('Ash')).thenAnswer((_) async => refreshedSession);
    when(() => localDataSource.write(refreshedSession)).thenAnswer((_) async {});

    final result = await repository.restore();

    expect(result, refreshedSession);
    verify(() => apiClient.createSession('Ash')).called(1);
    verify(() => localDataSource.write(refreshedSession)).called(1);
    verifyNever(() => localDataSource.clear());
  });

  test('restore clears local state if token refresh also fails', () async {
    when(() => localDataSource.read()).thenAnswer((_) async => persistedSession);
    when(
      () => apiClient.getCurrentSession(
        persistedSession.sessionToken,
        reconnectToken: persistedSession.reconnectToken,
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/api/v1/player-sessions/me'),
        response: Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/api/v1/player-sessions/me'),
          statusCode: 401,
          data: const {
            'success': false,
            'message': 'Invalid or expired session token',
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );
    when(() => apiClient.createSession('Ash')).thenThrow(Exception('Nickname is already in use'));
    when(() => localDataSource.clear()).thenAnswer((_) async {});

    final result = await repository.restore();

    expect(result, isNull);
    verify(() => apiClient.createSession('Ash')).called(1);
    verify(() => localDataSource.clear()).called(1);
  });
}
