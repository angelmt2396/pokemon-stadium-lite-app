import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokemon_stadium_lite_app/core/socket/socket_client.dart';
import 'package:pokemon_stadium_lite_app/features/battle/data/battle_socket_client.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_flow_state.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_end_snapshot.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_player_snapshot.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_lobby_status.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_state_snapshot.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/turn_result_snapshot.dart';
import 'package:pokemon_stadium_lite_app/features/session/domain/session_snapshot.dart';
import 'package:pokemon_stadium_lite_app/features/session/presentation/session_controller.dart';
import 'package:pokemon_stadium_lite_app/features/session/domain/session_state.dart';

class BattleController extends AutoDisposeNotifier<BattleFlowState> {
  BattleSocketClient? _client;
  String? _sessionToken;
  String? _bootstrapKey;
  Timer? _searchTicker;
  bool _didRegisterSessionListener = false;

  @override
  BattleFlowState build() {
    ref.onDispose(_dispose);

    if (!_didRegisterSessionListener) {
      _didRegisterSessionListener = true;

      ref.listen<SessionState>(sessionControllerProvider, (previous, next) {
        final session = next.session;
        final nextBootstrapKey = session == null
            ? null
            : '${session.sessionToken}:${session.currentLobbyId}:${session.currentBattleId}:${session.reconnectToken}';

        if (_bootstrapKey != nextBootstrapKey) {
          _bootstrapKey = nextBootstrapKey;
          Future<void>.microtask(() => _bootstrap(session));
        }
      });

      final initialSession = ref.read(sessionControllerProvider).session;
      final initialBootstrapKey = initialSession == null
          ? null
          : '${initialSession.sessionToken}:${initialSession.currentLobbyId}:${initialSession.currentBattleId}:${initialSession.reconnectToken}';
      _bootstrapKey = initialBootstrapKey;
      Future<void>.microtask(() => _bootstrap(initialSession));
    }

    return const BattleFlowState.initial();
  }

  Duration? get searchElapsed {
    final startedAt = state.searchStartedAt;
    if (startedAt == null) {
      return null;
    }

    return DateTime.now().difference(startedAt);
  }

  Future<void> searchMatch() async {
    final session = ref.read(sessionControllerProvider).session;
    if (session == null) {
      return;
    }

    state = state.copyWith(
      actionPending: true,
      clearErrorMessage: true,
      infoMessage: 'Conectando arena...',
      clearInfoMessage: false,
    );

    try {
      final client = await _prepareClient(session);
      final ack = await client.searchMatch();
      final stage = _deriveStage(ack.lobbyStatus);

      _setSearchTicker(stage == BattleStage.searching);

      await ref.read(sessionControllerProvider.notifier).updateRuntimeSession(
            playerStatus: _playerStatusFromLobby(ack.lobbyStatus),
            currentLobbyId: ack.lobbyId,
            clearCurrentBattleId: true,
            reconnectToken: ack.reconnectToken,
          );

      state = state.copyWith(
        actionPending: false,
        stage: stage,
        lobbyStatus: ack.lobbyStatus,
        searchStartedAt: stage == BattleStage.searching ? DateTime.now() : null,
        clearSearchStartedAt: stage != BattleStage.searching,
        clearErrorMessage: true,
        infoMessage: stage == BattleStage.searching
            ? 'Buscando rival en la cola.'
            : 'Rival detectado. La siguiente fase asignará equipos.',
      );
    } catch (error) {
      state = state.copyWith(
        actionPending: false,
        clearInfoMessage: true,
        errorMessage: _normalizeError(error),
      );
    }
  }

  Future<void> cancelSearch() async {
    final session = ref.read(sessionControllerProvider).session;
    if (session == null || _client == null) {
      return;
    }

    state = state.copyWith(
      actionPending: true,
      clearErrorMessage: true,
    );

    try {
      final ack = await _client!.cancelSearch();
      _setSearchTicker(false);

      await ref.read(sessionControllerProvider.notifier).updateRuntimeSession(
            playerStatus: 'idle',
            clearCurrentLobbyId: true,
            clearCurrentBattleId: true,
          );

      state = state.copyWith(
        actionPending: false,
        stage: BattleStage.idle,
        clearLobbyStatus: true,
        clearBattleState: true,
        clearLatestTurnResult: true,
        clearBattleResult: true,
        clearSearchStartedAt: true,
        clearErrorMessage: true,
        infoMessage: ack.canceled ? 'La búsqueda fue cancelada.' : 'La arena volvió a espera.',
      );
    } catch (error) {
      state = state.copyWith(
        actionPending: false,
        errorMessage: _normalizeError(error),
      );
    }
  }

  void dismissError() {
    state = state.copyWith(clearErrorMessage: true);
  }

  Future<void> attack() async {
    final session = ref.read(sessionControllerProvider).session;
    final battleState = state.battleState;
    if (session == null || battleState == null) {
      return;
    }

    if (battleState.currentTurnPlayerId != session.playerId) {
      state = state.copyWith(errorMessage: 'Aún no es tu turno.');
      return;
    }

    state = state.copyWith(
      actionPending: true,
      clearErrorMessage: true,
      infoMessage: 'Enviando ataque...',
    );

    try {
      final client = await _prepareClient(session);
      final ack = await client.attack(battleState.battleId);
      state = state.copyWith(
        actionPending: false,
        infoMessage: ack.accepted
            ? 'Ataque enviado. Esperando resolución.'
            : 'El backend rechazó el ataque.',
      );
    } catch (error) {
      state = state.copyWith(
        actionPending: false,
        errorMessage: _normalizeError(error),
      );
    }
  }

  Future<void> dismissBattleResult() async {
    await ref.read(sessionControllerProvider.notifier).updateRuntimeSession(
          playerStatus: 'idle',
          clearCurrentLobbyId: true,
          clearCurrentBattleId: true,
        );

    state = state.copyWith(
      stage: BattleStage.idle,
      clearLobbyStatus: true,
      clearBattleState: true,
      clearLatestTurnResult: true,
      clearBattleResult: true,
      clearSearchStartedAt: true,
      infoMessage: 'La arena quedó lista para una nueva búsqueda.',
    );
  }

  Future<void> assignTeam() async {
    final session = ref.read(sessionControllerProvider).session;
    final lobbyId = state.lobbyStatus?.lobbyId;
    if (session == null || lobbyId == null) {
      return;
    }

    state = state.copyWith(
      actionPending: true,
      clearErrorMessage: true,
      infoMessage: 'Asignando equipos aleatorios...',
    );

    try {
      final client = await _prepareClient(session);
      final ack = await client.assignPokemon(lobbyId);

      state = state.copyWith(
        actionPending: false,
        stage: _deriveStage(ack.lobbyStatus),
        lobbyStatus: ack.lobbyStatus,
        clearErrorMessage: true,
        infoMessage: 'Equipo asignado. Marca listo para iniciar combate.',
      );
    } catch (error) {
      state = state.copyWith(
        actionPending: false,
        errorMessage: _normalizeError(error),
      );
    }
  }

  Future<void> markReady() async {
    final session = ref.read(sessionControllerProvider).session;
    final lobbyId = state.lobbyStatus?.lobbyId;
    if (session == null || lobbyId == null) {
      return;
    }

    state = state.copyWith(
      actionPending: true,
      clearErrorMessage: true,
      infoMessage: 'Sincronizando ready state...',
    );

    try {
      final client = await _prepareClient(session);
      final ack = await client.markReady(lobbyId);
      await _applyReadyAck(ack);
    } catch (error) {
      state = state.copyWith(
        actionPending: false,
        errorMessage: _normalizeError(error),
      );
    }
  }

  Future<void> _bootstrap(SessionSnapshot? session) async {
    _setSearchTicker(false);

    if (session == null) {
      _client?.dispose();
      _client = null;
      _sessionToken = null;
      state = const BattleFlowState.initial();
      return;
    }

    if ((session.currentLobbyId != null || session.currentBattleId != null) &&
        session.reconnectToken != null) {
      state = state.copyWith(
        stage: BattleStage.reconnecting,
        connectionStatus: BattleConnectionStatus.connecting,
        clearErrorMessage: true,
        infoMessage: 'Rehidratando sala activa...',
      );

      try {
        final client = await _prepareClient(session);
        final ack = await client.reconnectPlayer(session.reconnectToken!);
        final battleState = ack.battleState;
        final stage = battleState != null ? BattleStage.battling : _deriveStage(ack.lobbyStatus);
        _setSearchTicker(stage == BattleStage.searching);

        await ref.read(sessionControllerProvider.notifier).updateRuntimeSession(
              playerStatus: _playerStatusFromLobby(ack.lobbyStatus),
              currentLobbyId: ack.lobbyId,
              currentBattleId: battleState?.battleId,
              clearCurrentBattleId: battleState == null,
            );

        state = state.copyWith(
          stage: stage,
          connectionStatus: BattleConnectionStatus.connected,
          lobbyStatus: ack.lobbyStatus,
          battleState: battleState,
          clearBattleState: battleState == null,
          clearLatestTurnResult: true,
          clearBattleResult: true,
          searchStartedAt: stage == BattleStage.searching ? DateTime.now() : null,
          clearSearchStartedAt: stage != BattleStage.searching,
          clearErrorMessage: true,
          infoMessage: stage == BattleStage.matched
              ? 'Sala recuperada. Esperando siguiente paso.'
              : stage == BattleStage.searching
                  ? 'Volviste a la cola activa.'
                  : battleState?.reconnectDeadlineAt != null
                      ? 'La batalla sigue pausada mientras se resuelve una reconexión.'
                      : 'Se restauró una batalla activa.',
        );
      } catch (error) {
        state = state.copyWith(
          stage: BattleStage.idle,
          connectionStatus: BattleConnectionStatus.disconnected,
          clearLobbyStatus: true,
          clearBattleState: true,
          clearLatestTurnResult: true,
          clearBattleResult: true,
          clearSearchStartedAt: true,
          errorMessage: _normalizeError(error),
          clearInfoMessage: true,
        );
      }

      return;
    }

    state = const BattleFlowState.initial();
  }

  Future<BattleSocketClient> _prepareClient(SessionSnapshot session) async {
    if (_client == null || _sessionToken != session.sessionToken) {
      _client?.dispose();
      _client = BattleSocketClient(
        sessionToken: session.sessionToken,
        socketFactory: ref.read(socketFactoryProvider),
      );
      _sessionToken = session.sessionToken;
      _bindClient(_client!, session.playerId);
    }

    state = state.copyWith(connectionStatus: BattleConnectionStatus.connecting);
    await _client!.ensureConnected();
    state = state.copyWith(connectionStatus: BattleConnectionStatus.connected);
    return _client!;
  }

  void _bindClient(BattleSocketClient client, String currentPlayerId) {
    client.bind(
      onConnected: () {
        state = state.copyWith(connectionStatus: BattleConnectionStatus.connected);
      },
      onDisconnected: () {
        state = state.copyWith(connectionStatus: BattleConnectionStatus.disconnected);
      },
      onConnectError: (message) {
        state = state.copyWith(
          connectionStatus: BattleConnectionStatus.disconnected,
          errorMessage: message,
        );
      },
      onSearchStatus: (event) {
        if (event.status == 'searching') {
          _setSearchTicker(true);
          state = state.copyWith(
            stage: BattleStage.searching,
            clearBattleState: true,
            clearLatestTurnResult: true,
            clearBattleResult: true,
            searchStartedAt: state.searchStartedAt ?? DateTime.now(),
            clearErrorMessage: true,
            infoMessage: 'Buscando rival en la cola.',
          );
          return;
        }

        _setSearchTicker(false);
        state = state.copyWith(
          stage: BattleStage.idle,
          clearLobbyStatus: true,
          clearBattleState: true,
          clearLatestTurnResult: true,
          clearBattleResult: true,
          clearSearchStartedAt: true,
          clearErrorMessage: true,
          infoMessage: event.canceled ? 'La búsqueda fue cancelada.' : 'La arena quedó libre.',
        );
      },
      onLobbyStatus: (status) {
        final stage = _deriveStage(status);
        _setSearchTicker(stage == BattleStage.searching);
        state = state.copyWith(
          stage: stage,
          lobbyStatus: status,
          clearBattleState: stage != BattleStage.battling,
          clearLatestTurnResult: stage == BattleStage.battling ? false : true,
          clearBattleResult: true,
          searchStartedAt: stage == BattleStage.searching ? state.searchStartedAt ?? DateTime.now() : null,
          clearSearchStartedAt: stage != BattleStage.searching,
          clearErrorMessage: true,
          infoMessage: stage == BattleStage.matched
              ? 'Rival detectado. La siguiente fase asignará equipos.'
              : state.infoMessage,
        );
        unawaited(
          ref.read(sessionControllerProvider.notifier).updateRuntimeSession(
                playerStatus: _playerStatusFromLobby(status),
                currentLobbyId: status.lobbyId,
                clearCurrentBattleId: true,
              ),
        );
      },
      onMatchFound: (status) {
        _setSearchTicker(false);
        state = state.copyWith(
          stage: BattleStage.matched,
          lobbyStatus: status,
          clearBattleState: true,
          clearLatestTurnResult: true,
          clearBattleResult: true,
          clearSearchStartedAt: true,
          clearErrorMessage: true,
          infoMessage: 'Rival encontrado. La siguiente fase asignará equipos.',
        );
        unawaited(
          ref.read(sessionControllerProvider.notifier).updateRuntimeSession(
                playerStatus: 'in_lobby',
                currentLobbyId: status.lobbyId,
                clearCurrentBattleId: true,
              ),
        );
      },
      onBattleStart: (battleState) {
        _setSearchTicker(false);
        unawaited(_applyBattleStart(battleState));
      },
      onBattlePause: (battleState) {
        unawaited(_applyBattlePause(battleState, currentPlayerId));
      },
      onBattleResume: (battleState) {
        unawaited(_applyBattleResume(battleState));
      },
      onTurnResult: (result) {
        _applyTurnResult(result);
      },
      onBattleEnd: (result) {
        unawaited(_applyBattleEnd(result));
      },
    );
  }

  Future<void> _applyReadyAck(ReadyAck ack) async {
    if (ack.battleStart != null) {
      await _applyBattleStart(ack.battleStart!);
      return;
    }

    state = state.copyWith(
      actionPending: false,
      stage: _deriveStage(ack.lobbyStatus),
      lobbyStatus: ack.lobbyStatus,
      clearLatestTurnResult: true,
      clearBattleResult: true,
      clearErrorMessage: true,
      infoMessage: 'Esperando al rival para iniciar combate.',
    );
  }

  Future<void> _applyBattleStart(BattleStateSnapshot battleState) async {
    await ref.read(sessionControllerProvider.notifier).updateRuntimeSession(
          playerStatus: 'battling',
          currentLobbyId: battleState.lobbyId,
          currentBattleId: battleState.battleId,
        );

    state = state.copyWith(
      actionPending: false,
      stage: BattleStage.battling,
      battleState: battleState,
      clearLatestTurnResult: true,
      clearBattleResult: true,
      clearSearchStartedAt: true,
      clearErrorMessage: true,
      infoMessage: 'La batalla ya comenzó.',
    );
  }

  Future<void> _applyBattlePause(
    BattleStateSnapshot battleState,
    String currentPlayerId,
  ) async {
    await ref.read(sessionControllerProvider.notifier).updateRuntimeSession(
          playerStatus: battleState.status,
          currentLobbyId: battleState.lobbyId,
          currentBattleId: battleState.battleId,
        );

    final isSelfDisconnected = battleState.disconnectedPlayerId == currentPlayerId;
    state = state.copyWith(
      actionPending: false,
      stage: BattleStage.battling,
      battleState: battleState,
      clearLatestTurnResult: true,
      clearBattleResult: true,
      clearErrorMessage: true,
      infoMessage: isSelfDisconnected
          ? 'Tu conexión salió de la arena. Reingresa antes de que termine el contador.'
          : 'El rival se desconectó. La batalla está en pausa.',
    );
  }

  Future<void> _applyBattleResume(BattleStateSnapshot battleState) async {
    await ref.read(sessionControllerProvider.notifier).updateRuntimeSession(
          playerStatus: battleState.status,
          currentLobbyId: battleState.lobbyId,
          currentBattleId: battleState.battleId,
        );

    state = state.copyWith(
      actionPending: false,
      stage: BattleStage.battling,
      battleState: battleState.copyWith(
        clearReconnectDeadlineAt: true,
        clearDisconnectedPlayerId: true,
        clearFinishReason: true,
      ),
      clearLatestTurnResult: true,
      clearBattleResult: true,
      clearErrorMessage: true,
      infoMessage: 'La batalla se reanudó.',
    );
  }

  void _applyTurnResult(TurnResultSnapshot result) {
    final currentBattleState = state.battleState;
    if (currentBattleState == null) {
      state = state.copyWith(latestTurnResult: result);
      return;
    }

    final updatedPlayers = currentBattleState.players
        .map((player) => _updatePlayerFromTurnResult(player, result))
        .toList();

    state = state.copyWith(
      actionPending: false,
      latestTurnResult: result,
      battleState: currentBattleState.copyWith(
        status: result.battleStatus,
        currentTurnPlayerId: result.nextTurnPlayerId,
        clearDisconnectedPlayerId: true,
        clearReconnectDeadlineAt: true,
        clearFinishReason: true,
        players: updatedPlayers,
      ),
      clearErrorMessage: true,
      infoMessage: 'El turno se resolvió.',
    );
  }

  Future<void> _applyBattleEnd(BattleEndSnapshot result) async {
    await ref.read(sessionControllerProvider.notifier).updateRuntimeSession(
          playerStatus: 'idle',
          clearCurrentLobbyId: true,
          clearCurrentBattleId: true,
        );

    state = state.copyWith(
      actionPending: false,
      stage: BattleStage.result,
      battleResult: result,
      clearSearchStartedAt: true,
      clearErrorMessage: true,
      infoMessage: 'El combate terminó.',
    );
  }

  BattlePlayerSnapshot _updatePlayerFromTurnResult(
    BattlePlayerSnapshot player,
    TurnResultSnapshot result,
  ) {
    var updatedPlayer = player;

    if (player.playerId == result.defenderPlayerId) {
      final updatedTeam = player.team.map((pokemon) {
        if (pokemon.pokemonId != result.defenderPokemonId) {
          return pokemon;
        }

        return pokemon.copyWith(
          currentHp: result.defenderRemainingHp,
          defeated: result.defenderDefeated,
        );
      }).toList();

      final updatedActivePokemon =
          player.activePokemon.pokemonId == result.defenderPokemonId
              ? player.activePokemon.copyWith(
                  currentHp: result.defenderRemainingHp,
                  defeated: result.defenderDefeated,
                )
              : player.activePokemon;

      updatedPlayer = player.copyWith(
        activePokemon: updatedActivePokemon,
        team: updatedTeam,
      );
    }

    final autoSwitched = result.autoSwitchedPokemon;
    if (autoSwitched != null &&
        autoSwitched.playerId == player.playerId &&
        autoSwitched.pokemon != null) {
      final switchedTeam = [...updatedPlayer.team];
      if (autoSwitched.activePokemonIndex >= 0 &&
          autoSwitched.activePokemonIndex < switchedTeam.length) {
        switchedTeam[autoSwitched.activePokemonIndex] = autoSwitched.pokemon!;
      }
      updatedPlayer = updatedPlayer.copyWith(
        activePokemonIndex: autoSwitched.activePokemonIndex,
        activePokemon: autoSwitched.pokemon!,
        team: switchedTeam,
      );
    }

    return updatedPlayer;
  }

  BattleStage _deriveStage(BattleLobbyStatus lobbyStatus) {
    if (lobbyStatus.status == 'battling') {
      return BattleStage.battling;
    }

    if (lobbyStatus.players.length >= 2) {
      return BattleStage.matched;
    }

    return BattleStage.searching;
  }

  String _playerStatusFromLobby(BattleLobbyStatus lobbyStatus) {
    if (lobbyStatus.status == 'battling') {
      return 'battling';
    }

    if (lobbyStatus.players.length >= 2) {
      return 'in_lobby';
    }

    return 'searching';
  }

  String _normalizeError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _setSearchTicker(bool enabled) {
    _searchTicker?.cancel();
    _searchTicker = null;

    if (!enabled) {
      return;
    }

    _searchTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith();
    });
  }

  void _dispose() {
    _searchTicker?.cancel();
    _client?.dispose();
  }
}

final battleControllerProvider =
    AutoDisposeNotifierProvider<BattleController, BattleFlowState>(BattleController.new);
