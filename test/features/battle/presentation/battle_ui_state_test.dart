import 'package:flutter_test/flutter_test.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_flow_state.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_lobby_player.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_lobby_pokemon.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_lobby_status.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_player_snapshot.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_pokemon_snapshot.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_state_snapshot.dart';
import 'package:pokemon_stadium_lite_app/features/battle/presentation/battle_ui_state.dart';
import 'package:pokemon_stadium_lite_app/features/session/domain/session_snapshot.dart';

void main() {
  group('BattleUiState', () {
    test('marks matched lobby without team as auto-assign candidate', () {
      final uiState = BattleUiState.from(
        flowState: BattleFlowState(
          stage: BattleStage.matched,
          connectionStatus: BattleConnectionStatus.connected,
          actionPending: false,
          lobbyStatus: BattleLobbyStatus(
            lobbyId: 'lobby-1',
            status: 'waiting',
            players: [
              const BattleLobbyPlayer(
                playerId: 'player-a',
                nickname: 'Ash',
                ready: false,
                team: [],
              ),
              const BattleLobbyPlayer(
                playerId: 'player-b',
                nickname: 'Misty',
                ready: false,
                team: [],
              ),
            ],
          ),
          battleState: null,
          latestTurnResult: null,
          battleResult: null,
          searchStartedAt: null,
          errorMessage: null,
          infoMessage: null,
        ),
        session: const SessionSnapshot(
          sessionToken: 'token',
          playerId: 'player-a',
          nickname: 'Ash',
          playerStatus: 'in_lobby',
          currentLobbyId: 'lobby-1',
          currentBattleId: null,
          reconnectToken: 'reconnect',
        ),
      );

      expect(uiState.shouldAutoAssign, isTrue);
      expect(uiState.canAssignTeamManually, isTrue);
      expect(uiState.shouldAutoReady, isFalse);
      expect(uiState.matchedSignature, 'lobby-1:Misty');
    });

    test('marks full local team as auto-ready candidate', () {
      final uiState = BattleUiState.from(
        flowState: BattleFlowState(
          stage: BattleStage.matched,
          connectionStatus: BattleConnectionStatus.connected,
          actionPending: false,
          lobbyStatus: BattleLobbyStatus(
            lobbyId: 'lobby-2',
            status: 'waiting',
            players: [
              BattleLobbyPlayer(
                playerId: 'player-a',
                nickname: 'Ash',
                ready: false,
                team: const [
                  BattleLobbyPokemon(pokemonId: 1, name: 'Bulbasaur', sprite: 'sprite-1'),
                  BattleLobbyPokemon(pokemonId: 4, name: 'Charmander', sprite: 'sprite-4'),
                  BattleLobbyPokemon(pokemonId: 7, name: 'Squirtle', sprite: 'sprite-7'),
                ],
              ),
              const BattleLobbyPlayer(
                playerId: 'player-b',
                nickname: 'Brock',
                ready: false,
                team: [],
              ),
            ],
          ),
          battleState: null,
          latestTurnResult: null,
          battleResult: null,
          searchStartedAt: null,
          errorMessage: null,
          infoMessage: null,
        ),
        session: const SessionSnapshot(
          sessionToken: 'token',
          playerId: 'player-a',
          nickname: 'Ash',
          playerStatus: 'in_lobby',
          currentLobbyId: 'lobby-2',
          currentBattleId: null,
          reconnectToken: 'reconnect',
        ),
      );

      expect(uiState.shouldAutoAssign, isFalse);
      expect(uiState.shouldAutoReady, isTrue);
      expect(uiState.canReadyManually, isTrue);
      expect(uiState.assignedTeamSignature, 'lobby-2:1,4,7');
    });

    test('exposes paused overlay and local turn state from battle snapshot', () {
      final uiState = BattleUiState.from(
        flowState: BattleFlowState(
          stage: BattleStage.battling,
          connectionStatus: BattleConnectionStatus.connected,
          actionPending: false,
          lobbyStatus: null,
          battleState: BattleStateSnapshot(
            battleId: 'battle-1',
            lobbyId: 'lobby-3',
            status: 'paused',
            currentTurnPlayerId: 'player-a',
            winnerPlayerId: null,
            disconnectedPlayerId: 'player-b',
            reconnectDeadlineAt: DateTime.parse('2026-03-23T12:00:00Z'),
            finishReason: null,
            players: [
              BattlePlayerSnapshot(
                playerId: 'player-a',
                activePokemonIndex: 0,
                activePokemon: _pokemon(1, 'Bulbasaur'),
                team: [_pokemon(1, 'Bulbasaur')],
              ),
              BattlePlayerSnapshot(
                playerId: 'player-b',
                activePokemonIndex: 0,
                activePokemon: _pokemon(4, 'Charmander'),
                team: [_pokemon(4, 'Charmander')],
              ),
            ],
          ),
          latestTurnResult: null,
          battleResult: null,
          searchStartedAt: null,
          errorMessage: null,
          infoMessage: null,
        ),
        session: const SessionSnapshot(
          sessionToken: 'token',
          playerId: 'player-a',
          nickname: 'Ash',
          playerStatus: 'battling',
          currentLobbyId: 'lobby-3',
          currentBattleId: 'battle-1',
          reconnectToken: 'reconnect',
        ),
      );

      expect(uiState.isBattlePaused, isTrue);
      expect(uiState.overlay, BattleArenaOverlay.paused);
      expect(uiState.isLocalTurn, isTrue);
      expect(uiState.isSelfDisconnected, isFalse);
    });
  });
}

BattlePokemonSnapshot _pokemon(int id, String name) {
  return BattlePokemonSnapshot(
    pokemonId: id,
    name: name,
    sprite: 'sprite-$id',
    hp: 45,
    currentHp: 45,
    attack: 49,
    defense: 49,
    speed: 45,
    defeated: false,
  );
}
