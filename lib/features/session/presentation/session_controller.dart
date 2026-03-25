import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokemon_stadium_lite_app/core/i18n/app_strings.dart';
import 'package:pokemon_stadium_lite_app/core/network/network_error.dart';
import 'package:pokemon_stadium_lite_app/features/session/data/session_repository.dart';
import 'package:pokemon_stadium_lite_app/features/session/domain/session_snapshot.dart';
import 'package:pokemon_stadium_lite_app/features/session/domain/session_state.dart';

class SessionController extends Notifier<SessionState> {
  static const _activeSessionSyncInterval = Duration(seconds: 5);

  bool _didBootstrap = false;
  Timer? _activeSessionSyncTimer;
  bool _syncInFlight = false;

  @override
  SessionState build() {
    ref.onDispose(_dispose);

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
      _setSessionState(const SessionState.unauthenticated());
      return;
    }

    _setSessionState(SessionState.authenticated(session));
  }

  Future<void> login(String nickname) async {
    final trimmed = nickname.trim();
    final strings = ref.read(appStringsProvider);
    if (trimmed.isEmpty) {
      state = SessionState.unauthenticated(
        errorMessage: strings.nicknameRequired,
      );
      return;
    }

    state = state.copyWith(clearError: true);

    try {
      final session = await ref.read(sessionRepositoryProvider).login(trimmed);
      _setSessionState(SessionState.authenticated(session));
    } catch (error) {
      _setSessionState(SessionState.unauthenticated(
        errorMessage: normalizeNetworkError(
          error,
          isEs: strings.isEs,
          fallbackMessage: strings.loginFailed,
        ),
      ));
    }
  }

  Future<void> logout() async {
    final session = state.session;
    final strings = ref.read(appStringsProvider);
    if (session == null) {
      _setSessionState(const SessionState.unauthenticated());
      return;
    }

    try {
      await ref.read(sessionRepositoryProvider).logout(session);
      _setSessionState(const SessionState.unauthenticated());
    } catch (error) {
      state = state.copyWith(
        errorMessage: normalizeNetworkError(
          error,
          isEs: strings.isEs,
          fallbackMessage: strings.logoutFailed,
        ),
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<SessionSnapshot?> recoverExpiredSession() async {
    final currentSession = state.session;
    final strings = ref.read(appStringsProvider);
    if (currentSession == null) {
      return null;
    }

    try {
      final refreshedSession = await ref
          .read(sessionRepositoryProvider)
          .login(currentSession.nickname);
      _setSessionState(SessionState.authenticated(refreshedSession));
      return refreshedSession;
    } catch (error) {
      _setSessionState(SessionState.unauthenticated(
        errorMessage: normalizeNetworkError(
          error,
          isEs: strings.isEs,
          fallbackMessage: strings.loginFailed,
        ),
      ));
      return null;
    }
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
    _setSessionState(SessionState.authenticated(updatedSession));
  }

  Future<void> syncCurrentSessionSilently({bool force = false}) async {
    final currentSession = state.session;
    if (currentSession == null ||
        (!force && !currentSession.hasActiveBattle) ||
        _syncInFlight) {
      return;
    }

    _syncInFlight = true;
    try {
      final refreshedSession = await ref
          .read(sessionRepositoryProvider)
          .sync(currentSession);

      if (!_sameSession(state.session, refreshedSession)) {
        _setSessionState(SessionState.authenticated(refreshedSession));
      } else {
        _configureActiveSessionSync(refreshedSession);
      }
    } catch (_) {
      _configureActiveSessionSync(state.session);
    } finally {
      _syncInFlight = false;
    }
  }

  void _setSessionState(SessionState nextState) {
    state = nextState;
    _configureActiveSessionSync(nextState.session);
  }

  void _configureActiveSessionSync(SessionSnapshot? session) {
    final shouldSync = session?.hasActiveBattle == true;
    if (!shouldSync) {
      _activeSessionSyncTimer?.cancel();
      _activeSessionSyncTimer = null;
      return;
    }

    if (_activeSessionSyncTimer != null) {
      return;
    }

    _activeSessionSyncTimer = Timer.periodic(_activeSessionSyncInterval, (_) {
      unawaited(syncCurrentSessionSilently());
    });

    unawaited(syncCurrentSessionSilently());
  }

  bool _sameSession(SessionSnapshot? left, SessionSnapshot right) {
    return left?.sessionToken == right.sessionToken &&
        left?.playerId == right.playerId &&
        left?.nickname == right.nickname &&
        left?.playerStatus == right.playerStatus &&
        left?.currentLobbyId == right.currentLobbyId &&
        left?.currentBattleId == right.currentBattleId &&
        left?.reconnectToken == right.reconnectToken;
  }

  void _dispose() {
    _activeSessionSyncTimer?.cancel();
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
