import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_lobby_status.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_end_snapshot.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_state_snapshot.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/turn_result_snapshot.dart';

enum BattleStage {
  idle,
  reconnecting,
  searching,
  matched,
  battling,
  result,
}

enum BattleConnectionStatus {
  disconnected,
  connecting,
  connected,
}

class BattleFlowState {
  const BattleFlowState({
    required this.stage,
    required this.connectionStatus,
    required this.actionPending,
    required this.lobbyStatus,
    required this.battleState,
    required this.latestTurnResult,
    required this.battleResult,
    required this.searchStartedAt,
    required this.errorMessage,
    required this.infoMessage,
  });

  const BattleFlowState.initial()
      : stage = BattleStage.idle,
        connectionStatus = BattleConnectionStatus.disconnected,
        actionPending = false,
        lobbyStatus = null,
        battleState = null,
        latestTurnResult = null,
        battleResult = null,
        searchStartedAt = null,
        errorMessage = null,
        infoMessage = null;

  final BattleStage stage;
  final BattleConnectionStatus connectionStatus;
  final bool actionPending;
  final BattleLobbyStatus? lobbyStatus;
  final BattleStateSnapshot? battleState;
  final TurnResultSnapshot? latestTurnResult;
  final BattleEndSnapshot? battleResult;
  final DateTime? searchStartedAt;
  final String? errorMessage;
  final String? infoMessage;

  bool get isSearching => stage == BattleStage.searching;
  bool get canSearch => !actionPending && stage == BattleStage.idle;
  bool get canCancelSearch => !actionPending && stage == BattleStage.searching;
  bool get canAttack => !actionPending && stage == BattleStage.battling;

  BattleFlowState copyWith({
    BattleStage? stage,
    BattleConnectionStatus? connectionStatus,
    bool? actionPending,
    BattleLobbyStatus? lobbyStatus,
    bool clearLobbyStatus = false,
    BattleStateSnapshot? battleState,
    bool clearBattleState = false,
    TurnResultSnapshot? latestTurnResult,
    bool clearLatestTurnResult = false,
    BattleEndSnapshot? battleResult,
    bool clearBattleResult = false,
    DateTime? searchStartedAt,
    bool clearSearchStartedAt = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? infoMessage,
    bool clearInfoMessage = false,
  }) {
    return BattleFlowState(
      stage: stage ?? this.stage,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      actionPending: actionPending ?? this.actionPending,
      lobbyStatus: clearLobbyStatus ? null : lobbyStatus ?? this.lobbyStatus,
      battleState: clearBattleState ? null : battleState ?? this.battleState,
      latestTurnResult: clearLatestTurnResult
          ? null
          : latestTurnResult ?? this.latestTurnResult,
      battleResult: clearBattleResult ? null : battleResult ?? this.battleResult,
      searchStartedAt:
          clearSearchStartedAt ? null : searchStartedAt ?? this.searchStartedAt,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      infoMessage: clearInfoMessage ? null : infoMessage ?? this.infoMessage,
    );
  }
}
