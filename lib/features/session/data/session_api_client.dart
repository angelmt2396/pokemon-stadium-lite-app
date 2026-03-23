import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokemon_stadium_lite_app/core/network/api_client.dart';
import 'package:pokemon_stadium_lite_app/features/session/domain/session_snapshot.dart';

class SessionApiClient {
  SessionApiClient(this._dio);

  final Dio _dio;

  Future<SessionSnapshot> createSession(String nickname) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/player-sessions',
      data: {'nickname': nickname},
    );

    return _mapSessionSnapshot(_unwrapData(response.data));
  }

  Future<SessionSnapshot> getCurrentSession(String sessionToken, {String? reconnectToken}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/player-sessions/me',
      options: Options(
        headers: {
          'Authorization': 'Bearer $sessionToken',
        },
      ),
    );

    return _mapSessionSnapshot(
      _unwrapData(response.data),
      sessionTokenOverride: sessionToken,
      reconnectTokenOverride: reconnectToken,
    );
  }

  Future<void> closeSession(String sessionToken) async {
    await _dio.delete<Map<String, dynamic>>(
      '/api/v1/player-sessions/me',
      options: Options(
        headers: {
          'Authorization': 'Bearer $sessionToken',
        },
      ),
    );
  }

  Map<String, dynamic> _unwrapData(Map<String, dynamic>? payload) {
    if (payload == null) {
      throw Exception('Respuesta vacía del backend.');
    }

    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }

    return payload;
  }

  SessionSnapshot _mapSessionSnapshot(
    Map<String, dynamic> json, {
    String? sessionTokenOverride,
    String? reconnectTokenOverride,
  }) {
    final sessionToken = sessionTokenOverride ?? json['sessionToken'] as String?;
    if (sessionToken == null || sessionToken.isEmpty) {
      throw Exception('El backend no devolvió un sessionToken válido.');
    }

    return SessionSnapshot(
      sessionToken: sessionToken,
      playerId: json['playerId'] as String,
      nickname: json['nickname'] as String,
      playerStatus: json['playerStatus'] as String,
      currentLobbyId: json['currentLobbyId'] as String?,
      currentBattleId: json['currentBattleId'] as String?,
      reconnectToken: reconnectTokenOverride ?? json['reconnectToken'] as String?,
    );
  }
}

final sessionApiClientProvider = Provider<SessionApiClient>((ref) {
  return SessionApiClient(ref.watch(dioProvider));
});
