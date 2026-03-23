import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_end_snapshot.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_flow_state.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_lobby_player.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_player_snapshot.dart';
import 'package:pokemon_stadium_lite_app/features/battle/presentation/battle_controller.dart';
import 'package:pokemon_stadium_lite_app/features/session/domain/session_snapshot.dart';
import 'package:pokemon_stadium_lite_app/features/session/presentation/session_controller.dart';

enum BattleArenaOverlay { none, paused, result }

class BattleUiState {
  const BattleUiState({
    required this.flowState,
    required this.session,
    required this.localLobbyPlayer,
    required this.opponentLobbyPlayer,
    required this.localBattlePlayer,
    required this.opponentBattlePlayer,
    required this.isLocalTurn,
    required this.isBattlePaused,
    required this.isSelfDisconnected,
    required this.canAssignTeamManually,
    required this.canReadyManually,
    required this.shouldAutoAssign,
    required this.shouldAutoReady,
    required this.matchedSignature,
    required this.assignedTeamSignature,
    required this.battleStartSignature,
    required this.turnResultSignature,
    required this.resultSignature,
    required this.overlay,
  });

  final BattleFlowState flowState;
  final SessionSnapshot? session;
  final BattleLobbyPlayer? localLobbyPlayer;
  final BattleLobbyPlayer? opponentLobbyPlayer;
  final BattlePlayerSnapshot? localBattlePlayer;
  final BattlePlayerSnapshot? opponentBattlePlayer;
  final bool isLocalTurn;
  final bool isBattlePaused;
  final bool isSelfDisconnected;
  final bool canAssignTeamManually;
  final bool canReadyManually;
  final bool shouldAutoAssign;
  final bool shouldAutoReady;
  final String? matchedSignature;
  final String? assignedTeamSignature;
  final String? battleStartSignature;
  final String? turnResultSignature;
  final String? resultSignature;
  final BattleArenaOverlay overlay;

  String? get opponentNickname =>
      opponentLobbyPlayer?.nickname;

  bool get didWin =>
      session != null &&
      flowState.battleResult != null &&
      flowState.battleResult!.winnerPlayerId == session!.playerId;

  BattleEndSnapshot? get battleResult => flowState.battleResult;

  static BattleUiState from({
    required BattleFlowState flowState,
    required SessionSnapshot? session,
  }) {
    final lobbyStatus = flowState.lobbyStatus;
    final battleState = flowState.battleState;
    final localLobbyPlayer =
        session == null || lobbyStatus == null ? null : lobbyStatus.findPlayer(session.playerId);
    final opponentLobbyPlayer =
        session == null || lobbyStatus == null ? null : lobbyStatus.findOpponent(session.playerId);
    final localBattlePlayer =
        session == null || battleState == null ? null : battleState.findPlayer(session.playerId);
    final opponentBattlePlayer =
        session == null || battleState == null ? null : battleState.findOpponent(session.playerId);
    final isLocalTurn = session != null &&
        battleState != null &&
        battleState.currentTurnPlayerId == session.playerId;
    final isBattlePaused =
        battleState?.status == 'paused' || battleState?.reconnectDeadlineAt != null;
    final isSelfDisconnected =
        session != null && battleState?.disconnectedPlayerId == session.playerId;
    final hasTwoPlayers = (lobbyStatus?.players.length ?? 0) == 2;
    final inMatchedLobby = flowState.stage == BattleStage.matched && lobbyStatus != null;
    final canAssignTeamManually = inMatchedLobby &&
        !flowState.actionPending &&
        hasTwoPlayers &&
        localLobbyPlayer != null &&
        localLobbyPlayer.team.isEmpty &&
        !localLobbyPlayer.ready;
    final canReadyManually = inMatchedLobby &&
        !flowState.actionPending &&
        localLobbyPlayer != null &&
        localLobbyPlayer.team.length == 3 &&
        !localLobbyPlayer.ready;
    final shouldAutoAssign = canAssignTeamManually;
    final shouldAutoReady = canReadyManually;

    final matchedSignature = inMatchedLobby && hasTwoPlayers && opponentLobbyPlayer != null
        ? '${lobbyStatus.lobbyId}:${opponentLobbyPlayer.nickname}'
        : null;
    final assignedTeamSignature = inMatchedLobby && localLobbyPlayer != null && localLobbyPlayer.team.length == 3
        ? '${lobbyStatus.lobbyId}:${localLobbyPlayer.team.map((pokemon) => pokemon.pokemonId).join(",")}'
        : null;
    final battleStartSignature = battleState == null
        ? null
        : '${battleState.battleId}:${battleState.players.map((player) => '${player.playerId}:${player.activePokemon.pokemonId}').join("|")}';
    final turnResult = flowState.latestTurnResult;
    final turnResultSignature = turnResult == null
        ? null
        : '${turnResult.battleId}:${turnResult.attackerPlayerId}:${turnResult.defenderPlayerId}:${turnResult.damage}:${turnResult.defenderRemainingHp}:${turnResult.defenderDefeated}:${turnResult.nextTurnPlayerId ?? "none"}';
    final result = flowState.battleResult;
    final resultSignature = result == null
        ? null
        : '${result.battleId}:${result.winnerPlayerId ?? "none"}:${result.reason ?? "standard"}';

    return BattleUiState(
      flowState: flowState,
      session: session,
      localLobbyPlayer: localLobbyPlayer,
      opponentLobbyPlayer: opponentLobbyPlayer,
      localBattlePlayer: localBattlePlayer,
      opponentBattlePlayer: opponentBattlePlayer,
      isLocalTurn: isLocalTurn,
      isBattlePaused: isBattlePaused,
      isSelfDisconnected: isSelfDisconnected,
      canAssignTeamManually: canAssignTeamManually,
      canReadyManually: canReadyManually,
      shouldAutoAssign: shouldAutoAssign,
      shouldAutoReady: shouldAutoReady,
      matchedSignature: matchedSignature,
      assignedTeamSignature: assignedTeamSignature,
      battleStartSignature: battleStartSignature,
      turnResultSignature: turnResultSignature,
      resultSignature: resultSignature,
      overlay: result != null
          ? BattleArenaOverlay.result
          : isBattlePaused
              ? BattleArenaOverlay.paused
              : BattleArenaOverlay.none,
    );
  }
}

final battleUiStateProvider = Provider.autoDispose<BattleUiState>((ref) {
  final flowState = ref.watch(battleControllerProvider);
  final session = ref.watch(sessionControllerProvider).session;
  return BattleUiState.from(flowState: flowState, session: session);
});
