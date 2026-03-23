import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokemon_stadium_lite_app/features/session/data/session_repository.dart';
import 'package:pokemon_stadium_lite_app/features/session/domain/session_state.dart';

class SessionController extends Notifier<SessionState> {
  bool _didBootstrap = false;

  @override
  SessionState build() {
    if (!_didBootstrap) {
      _didBootstrap = true;
      Future<void>.microtask(_restoreSession);
    }

    return const SessionState.booting();
  }

  Future<void> _restoreSession() async {
    final repository = ref.read(sessionRepositoryProvider);
    final session = await repository.restore();

    if (session == null) {
      state = const SessionState.unauthenticated();
      return;
    }

    state = SessionState.authenticated(session);
  }

  Future<void> login(String nickname) async {
    final trimmed = nickname.trim();
    if (trimmed.isEmpty) {
      state = const SessionState.unauthenticated(
        errorMessage: 'Ingresa un nickname para continuar.',
      );
      return;
    }

    state = state.copyWith(clearError: true);

    try {
      final session = await ref.read(sessionRepositoryProvider).login(trimmed);
      state = SessionState.authenticated(session);
    } catch (error) {
      state = SessionState.unauthenticated(
        errorMessage: error is Exception ? error.toString().replaceFirst('Exception: ', '') : 'No se pudo iniciar sesión.',
      );
    }
  }

  Future<void> logout() async {
    final session = state.session;
    if (session == null) {
      state = const SessionState.unauthenticated();
      return;
    }

    try {
      await ref.read(sessionRepositoryProvider).logout(session);
      state = const SessionState.unauthenticated();
    } catch (error) {
      state = state.copyWith(
        errorMessage: error is Exception ? error.toString().replaceFirst('Exception: ', '') : 'No se pudo cerrar sesión.',
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> updateRuntimeSession({
    String? playerStatus,
    String? currentLobbyId,
    bool clearCurrentLobbyId = false,
    String? currentBattleId,
    bool clearCurrentBattleId = false,
    String? reconnectToken,
    bool clearReconnectToken = false,
  }) async {
    final currentSession = state.session;
    if (currentSession == null) {
      return;
    }

    final updatedSession = currentSession.copyWith(
      playerStatus: playerStatus,
      currentLobbyId: currentLobbyId,
      clearCurrentLobbyId: clearCurrentLobbyId,
      currentBattleId: currentBattleId,
      clearCurrentBattleId: clearCurrentBattleId,
      reconnectToken: reconnectToken,
      clearReconnectToken: clearReconnectToken,
    );

    await ref.read(sessionRepositoryProvider).persist(updatedSession);
    state = SessionState.authenticated(updatedSession);
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
