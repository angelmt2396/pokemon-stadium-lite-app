import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pokemon_stadium_lite_app/core/i18n/app_strings.dart';
import 'package:pokemon_stadium_lite_app/core/theme/app_colors.dart';
import 'package:pokemon_stadium_lite_app/core/theme/app_radii.dart';
import 'package:pokemon_stadium_lite_app/core/theme/app_spacing.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/app_scaffold.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/game_card.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/primary_button.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/status_chip.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_end_snapshot.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_flow_state.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_lobby_pokemon.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_pokemon_snapshot.dart';
import 'package:pokemon_stadium_lite_app/features/battle/presentation/battle_controller.dart';
import 'package:pokemon_stadium_lite_app/features/battle/presentation/battle_ui_state.dart';

const _matchFoundDuration = Duration(milliseconds: 1600);
const _teamAssignedDuration = Duration(milliseconds: 2200);
const _battleStartDuration = Duration(milliseconds: 1800);
const _turnActionDuration = Duration(milliseconds: 1700);
const _impactCueDuration = Duration(milliseconds: 1200);
const _turnPulseDuration = Duration(milliseconds: 1500);

enum _ArenaTarget { local, opponent }

enum _CinematicTone { info, success, warning, danger }

enum _CinematicType { matchFound, teamAssigned, battleStart, turnAction }

class _BattleCinematic {
  const _BattleCinematic({
    required this.id,
    required this.type,
    required this.tone,
    required this.title,
    required this.body,
    this.teamNames = const <String>[],
  });

  final String id;
  final _CinematicType type;
  final _CinematicTone tone;
  final String title;
  final String body;
  final List<String> teamNames;
}

class _ImpactCue {
  const _ImpactCue({
    required this.id,
    required this.target,
    required this.damage,
    required this.ko,
  });

  final String id;
  final _ArenaTarget target;
  final int damage;
  final bool ko;
}

class BattleScreen extends ConsumerStatefulWidget {
  const BattleScreen({super.key});

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen>
    with WidgetsBindingObserver {
  final List<_BattleCinematic> _cinematicQueue = <_BattleCinematic>[];
  _BattleCinematic? _activeCinematic;
  _ImpactCue? _impactCue;
  _ArenaTarget? _turnPulseTarget;
  ProviderSubscription<BattleUiState>? _uiStateSubscription;
  Timer? _cinematicTimer;
  Timer? _impactCueTimer;
  Timer? _turnPulseTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _uiStateSubscription = ref.listenManual<BattleUiState>(
      battleUiStateProvider,
      (previous, next) {
        if (!mounted) {
          return;
        }

        _handleUiTransition(previous, next, ref.read(appStringsProvider));
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _uiStateSubscription?.close();
    _cinematicTimer?.cancel();
    _impactCueTimer?.cancel();
    _turnPulseTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    unawaited(ref.read(battleControllerProvider.notifier).handleAppResumed());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = ref.watch(appStringsProvider);
    final uiState = ref.watch(battleUiStateProvider);
    final flowState = uiState.flowState;
    final controller = ref.read(battleControllerProvider.notifier);
    final searchElapsed = controller.searchElapsed;

    return AppScaffold(
      child: Stack(
        children: [
          SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        strings.battleScreenTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    StatusChip(
                      label: _connectionLabel(flowState.connectionStatus, strings),
                      tone: switch (flowState.connectionStatus) {
                        BattleConnectionStatus.connected => StatusChipTone.success,
                        BattleConnectionStatus.connecting => StatusChipTone.warning,
                        BattleConnectionStatus.disconnected => StatusChipTone.dark,
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _BattleHeroCard(
                  uiState: uiState,
                  strings: strings,
                ),
                if (flowState.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  GameCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.danger),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            flowState.errorMessage!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        IconButton(
                          onPressed: controller.dismissError,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _buildStageCard(
                    uiState: uiState,
                    strings: strings,
                    searchElapsed: searchElapsed,
                  ),
                ),
                if (flowState.infoMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  GameCard(
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: uiState.overlay == BattleArenaOverlay.none
                              ? AppColors.info
                              : AppColors.warning,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            flowState.infoMessage!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _BattleActionPanel(
                  uiState: uiState,
                  strings: strings,
                  onSearch: controller.searchMatch,
                  onCancelSearch: controller.cancelSearch,
                  onAssignTeam: controller.assignTeam,
                  onMarkReady: controller.markReady,
                  onAttack: controller.attack,
                  onDismissResult: controller.dismissBattleResult,
                ),
              ],
            ),
          ),
          if (_activeCinematic != null && uiState.overlay == BattleArenaOverlay.none)
            Positioned.fill(
              child: IgnorePointer(
                child: _BattleCinematicOverlay(
                  cinematic: _activeCinematic!,
                ),
              ),
            ),
          if (uiState.overlay == BattleArenaOverlay.paused)
            Positioned.fill(
              child: _BattlePauseFullscreenOverlay(
                strings: strings,
                isSelfDisconnected: uiState.isSelfDisconnected,
                reconnectDeadlineAt: uiState.flowState.battleState?.reconnectDeadlineAt,
              ),
            ),
          if (uiState.overlay == BattleArenaOverlay.result && uiState.battleResult != null)
            Positioned.fill(
              child: _BattleResultFullscreenOverlay(
                result: uiState.battleResult!,
                didWin: uiState.didWin,
                strings: strings,
                onDismiss: controller.dismissBattleResult,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStageCard({
    required BattleUiState uiState,
    required AppStrings strings,
    required Duration? searchElapsed,
  }) {
    final flowState = uiState.flowState;
    final cardKey = ValueKey<String>(
      '${flowState.stage.name}:${uiState.matchedSignature ?? "none"}:${uiState.battleStartSignature ?? "none"}:${uiState.resultSignature ?? "none"}',
    );

    if (flowState.stage == BattleStage.battling || flowState.stage == BattleStage.result) {
      return _BattleArenaCard(
        key: cardKey,
        uiState: uiState,
        strings: strings,
        impactCue: _impactCue,
        turnPulseTarget: _turnPulseTarget,
      );
    }

    return _BattleLobbyCard(
      key: cardKey,
      uiState: uiState,
      strings: strings,
      searchElapsed: searchElapsed,
    );
  }

  void _handleUiTransition(
    BattleUiState? previous,
    BattleUiState next,
    AppStrings strings,
  ) {
    if (previous?.matchedSignature != next.matchedSignature && next.matchedSignature != null) {
      _enqueueCinematic(
        _BattleCinematic(
          id: 'match:${next.matchedSignature}',
          type: _CinematicType.matchFound,
          tone: _CinematicTone.success,
          title: strings.rivalLockedTitle(next.opponentNickname ?? strings.waitingPlaceholder),
          body: strings.rivalLockedBody,
        ),
      );
    }

    if (previous?.assignedTeamSignature != next.assignedTeamSignature &&
        next.assignedTeamSignature != null &&
        next.localLobbyPlayer != null) {
      _enqueueCinematic(
        _BattleCinematic(
          id: 'team:${next.assignedTeamSignature}',
          type: _CinematicType.teamAssigned,
          tone: _CinematicTone.info,
          title: strings.teamAssignedTitle(
            next.localLobbyPlayer!.team.map((pokemon) => pokemon.name).toList(),
          ),
          body: strings.teamAssignedBody(
            next.localLobbyPlayer!.team.map((pokemon) => pokemon.name).toList(),
          ),
          teamNames: next.localLobbyPlayer!.team.map((pokemon) => pokemon.name).toList(),
        ),
      );
    }

    if (previous?.battleStartSignature != next.battleStartSignature &&
        next.battleStartSignature != null &&
        next.localBattlePlayer != null &&
        next.opponentBattlePlayer != null) {
      _enqueueCinematic(
        _BattleCinematic(
          id: 'start:${next.battleStartSignature}',
          type: _CinematicType.battleStart,
          tone: _CinematicTone.warning,
          title: strings.battleStartTitle(
            next.localBattlePlayer!.activePokemon.name,
            next.opponentBattlePlayer!.activePokemon.name,
          ),
          body: strings.battleStartBody,
        ),
      );
      _showTurnPulse(
        next.isLocalTurn ? _ArenaTarget.local : _ArenaTarget.opponent,
      );
    }

    final previousTurnPlayerId = previous?.flowState.battleState?.currentTurnPlayerId;
    final nextTurnPlayerId = next.flowState.battleState?.currentTurnPlayerId;
    if (nextTurnPlayerId != null && previousTurnPlayerId != nextTurnPlayerId && next.session != null) {
      _showTurnPulse(
        nextTurnPlayerId == next.session!.playerId ? _ArenaTarget.local : _ArenaTarget.opponent,
      );
    }

    if (previous?.turnResultSignature != next.turnResultSignature &&
        next.turnResultSignature != null &&
        next.flowState.latestTurnResult != null &&
        next.session != null) {
      final result = next.flowState.latestTurnResult!;
      final localAttacker = result.attackerPlayerId == next.session!.playerId;
      final target =
          result.defenderPlayerId == next.session!.playerId ? _ArenaTarget.local : _ArenaTarget.opponent;
      final defenderName = target == _ArenaTarget.local
          ? next.localBattlePlayer?.activePokemon.name ?? strings.offlineFallback
          : next.opponentBattlePlayer?.activePokemon.name ?? strings.offlineFallback;

      _showImpactCue(
        _ImpactCue(
          id: next.turnResultSignature!,
          target: target,
          damage: result.damage,
          ko: result.defenderDefeated,
        ),
      );

      _enqueueCinematic(
        _BattleCinematic(
          id: 'turn:${next.turnResultSignature}',
          type: _CinematicType.turnAction,
          tone: result.defenderDefeated ? _CinematicTone.danger : _CinematicTone.warning,
          title: strings.turnActionTitle(
            localAttacker: localAttacker,
            ko: result.defenderDefeated,
          ),
          body: strings.turnActionBody(
            localAttacker: localAttacker,
            defenderName: defenderName,
            damage: result.damage,
            ko: result.defenderDefeated,
          ),
        ),
      );
    }
  }

  void _enqueueCinematic(_BattleCinematic cinematic) {
    final alreadyActive = _activeCinematic?.id == cinematic.id;
    final alreadyQueued = _cinematicQueue.any((item) => item.id == cinematic.id);
    if (alreadyActive || alreadyQueued) {
      return;
    }

    setState(() {
      _cinematicQueue.add(cinematic);
    });
    _showNextCinematicIfNeeded();
  }

  void _showNextCinematicIfNeeded() {
    if (_activeCinematic != null || _cinematicQueue.isEmpty || !mounted) {
      return;
    }

    final next = _cinematicQueue.removeAt(0);
    setState(() {
      _activeCinematic = next;
    });

    _cinematicTimer?.cancel();
    _cinematicTimer = Timer(_cinematicDuration(next.type), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _activeCinematic = null;
      });
      _showNextCinematicIfNeeded();
    });
  }

  void _showImpactCue(_ImpactCue cue) {
    _impactCueTimer?.cancel();
    setState(() {
      _impactCue = cue;
    });
    _impactCueTimer = Timer(_impactCueDuration, () {
      if (!mounted || _impactCue?.id != cue.id) {
        return;
      }

      setState(() {
        _impactCue = null;
      });
    });
  }

  void _showTurnPulse(_ArenaTarget target) {
    _turnPulseTimer?.cancel();
    setState(() {
      _turnPulseTarget = target;
    });
    _turnPulseTimer = Timer(_turnPulseDuration, () {
      if (!mounted || _turnPulseTarget != target) {
        return;
      }

      setState(() {
        _turnPulseTarget = null;
      });
    });
  }

  Duration _cinematicDuration(_CinematicType type) {
    return switch (type) {
      _CinematicType.matchFound => _matchFoundDuration,
      _CinematicType.teamAssigned => _teamAssignedDuration,
      _CinematicType.battleStart => _battleStartDuration,
      _CinematicType.turnAction => _turnActionDuration,
    };
  }
}

class _BattleHeroCard extends StatelessWidget {
  const _BattleHeroCard({
    required this.uiState,
    required this.strings,
  });

  final BattleUiState uiState;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flowState = uiState.flowState;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.gameNavyBottom,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -12,
            child: Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.haloBlue,
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: -28,
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.haloAmber,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  StatusChip(
                    label: strings.battleChip,
                    tone: StatusChipTone.warning,
                  ),
                  StatusChip(
                    label: _stageChipLabel(flowState.stage, strings, uiState.didWin),
                    tone: _stageChipTone(flowState.stage, uiState.didWin),
                  ),
                  if (flowState.stage == BattleStage.battling)
                    StatusChip(
                      label: uiState.isLocalTurn
                          ? strings.attackWindowOpen
                          : strings.attackWindowClosed,
                      tone: uiState.isLocalTurn
                          ? StatusChipTone.success
                          : StatusChipTone.dark,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _titleForState(uiState, strings),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _subtitleForState(uiState, strings),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BattleLobbyCard extends StatelessWidget {
  const _BattleLobbyCard({
    super.key,
    required this.uiState,
    required this.strings,
    required this.searchElapsed,
  });

  final BattleUiState uiState;
  final AppStrings strings;
  final Duration? searchElapsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localPlayer = uiState.localLobbyPlayer;
    final opponent = uiState.opponentLobbyPlayer;

    return GameCard(
      key: key,
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.gameNavyTop,
              AppColors.gameNavyBottom,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                StatusChip(
                  label: strings.arenaLiveLabel,
                  tone: StatusChipTone.info,
                ),
                if (searchElapsed != null)
                  StatusChip(
                    label: '${strings.queueTimeLabel} ${_formatDuration(searchElapsed!)}',
                    tone: StatusChipTone.warning,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _TrainerLobbyCard(
              label: strings.localPlayerLabel,
              name: uiState.session?.nickname ?? strings.trainerFallback,
              subtitle: localPlayer == null
                  ? strings.localSearchReadySubtitle
                  : localPlayer.ready
                      ? strings.localReadySubtitle
                      : localPlayer.team.isEmpty
                          ? strings.localNoTeamSubtitle
                          : strings.localAssignedTeamSubtitle(localPlayer.team.length),
              team: localPlayer?.team ?? const <BattleLobbyPokemon>[],
              chips: [
                if (localPlayer?.ready == true)
                  StatusChip(label: strings.readyChip, tone: StatusChipTone.success),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: StatusChip(label: strings.versusLabel, tone: StatusChipTone.info),
              ),
            ),
            _TrainerLobbyCard(
              label: strings.rivalLabel,
              name: opponent?.nickname ?? strings.waitingPlaceholder,
              subtitle: opponent == null
                  ? strings.queueOpenSubtitle
                  : opponent.ready
                      ? strings.rivalReadySubtitle
                      : strings.rivalDetectedSubtitle,
              team: opponent?.team ?? const <BattleLobbyPokemon>[],
              chips: [
                if (opponent?.ready == true)
                  StatusChip(label: strings.readyChip, tone: StatusChipTone.success),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Text(
                _lobbyHint(uiState, strings),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerLobbyCard extends StatelessWidget {
  const _TrainerLobbyCard({
    required this.label,
    required this.name,
    required this.subtitle,
    required this.team,
    this.chips = const <Widget>[],
  });

  final String label;
  final String name;
  final String subtitle;
  final List<BattleLobbyPokemon> team;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: chips,
            ),
          ],
          if (team.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: team
                  .map(
                    (pokemon) => _TeamSlot(
                      name: pokemon.name,
                      sprite: pokemon.sprite,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _TeamSlot extends StatelessWidget {
  const _TeamSlot({
    required this.name,
    required this.sprite,
  });

  final String name;
  final String sprite;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Image.network(
              sprite,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.catching_pokemon_rounded, color: Colors.white70),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BattleArenaCard extends StatelessWidget {
  const _BattleArenaCard({
    super.key,
    required this.uiState,
    required this.strings,
    required this.impactCue,
    required this.turnPulseTarget,
  });

  final BattleUiState uiState;
  final AppStrings strings;
  final _ImpactCue? impactCue;
  final _ArenaTarget? turnPulseTarget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final turnResult = uiState.flowState.latestTurnResult;
    final localImpactCue = impactCue?.target == _ArenaTarget.local ? impactCue : null;
    final opponentImpactCue = impactCue?.target == _ArenaTarget.opponent ? impactCue : null;
    final localTurnPulse = turnPulseTarget == _ArenaTarget.local;
    final opponentTurnPulse = turnPulseTarget == _ArenaTarget.opponent;

    return GameCard(
      key: key,
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.gameNavyTop,
              AppColors.gameNavyBottom,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                StatusChip(
                  label: strings.arenaLiveLabel,
                  tone: StatusChipTone.warning,
                ),
                StatusChip(
                  label: uiState.isLocalTurn ? strings.yourTurn : strings.rivalTurn,
                  tone: uiState.isLocalTurn ? StatusChipTone.success : StatusChipTone.dark,
                ),
                if (turnResult != null)
                  StatusChip(
                    label: strings.turnResolvedChip,
                    tone: StatusChipTone.info,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _ArenaPokemonCard(
              label: strings.rivalLabel,
              pokemon: uiState.opponentBattlePlayer?.activePokemon,
              hpText: uiState.opponentBattlePlayer?.activePokemon == null
                  ? strings.waitingSnapshot
                  : strings.hpCounter(
                      uiState.opponentBattlePlayer!.activePokemon.currentHp,
                      uiState.opponentBattlePlayer!.activePokemon.hp,
                    ),
              isActiveTurn: !uiState.isLocalTurn,
              pulseTurnChange: opponentTurnPulse,
              impactCue: opponentImpactCue,
              alignEnd: true,
              strings: strings,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Text(
                    strings.versusLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            _ArenaPokemonCard(
              label: strings.yourPokemonLabel,
              pokemon: uiState.localBattlePlayer?.activePokemon,
              hpText: uiState.localBattlePlayer?.activePokemon == null
                  ? strings.waitingSnapshot
                  : strings.hpCounter(
                      uiState.localBattlePlayer!.activePokemon.currentHp,
                      uiState.localBattlePlayer!.activePokemon.hp,
                    ),
              isActiveTurn: uiState.isLocalTurn,
              pulseTurnChange: localTurnPulse,
              impactCue: localImpactCue,
              alignEnd: false,
              strings: strings,
            ),
            if (turnResult != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      turnResult.defenderDefeated ? strings.finalBlow : strings.damageApplied,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      strings.damageSummary(
                        defeated: turnResult.defenderDefeated,
                        damage: turnResult.damage,
                        remainingHp: turnResult.defenderRemainingHp,
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    if (turnResult.autoSwitchedPokemon?.pokemon != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        strings.autoSwitchSummary(
                          turnResult.autoSwitchedPokemon!.pokemon!.name,
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ArenaPokemonCard extends StatefulWidget {
  const _ArenaPokemonCard({
    required this.label,
    required this.pokemon,
    required this.hpText,
    required this.isActiveTurn,
    required this.pulseTurnChange,
    required this.impactCue,
    required this.alignEnd,
    required this.strings,
  });

  final String label;
  final BattlePokemonSnapshot? pokemon;
  final String hpText;
  final bool isActiveTurn;
  final bool pulseTurnChange;
  final _ImpactCue? impactCue;
  final bool alignEnd;
  final AppStrings strings;

  @override
  State<_ArenaPokemonCard> createState() => _ArenaPokemonCardState();
}

class _ArenaPokemonCardState extends State<_ArenaPokemonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12, end: 12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(covariant _ArenaPokemonCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.impactCue?.id != widget.impactCue?.id && widget.impactCue != null) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pokemon = widget.pokemon;
    final hpRatio = pokemon == null || pokemon.hp == 0
        ? 0.0
        : (pokemon.currentHp / pokemon.hp).clamp(0, 1).toDouble();
    final receivedImpact = widget.impactCue != null;
    final isKnockedOut = widget.impactCue?.ko ?? pokemon?.defeated ?? false;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 240),
        scale: widget.pulseTurnChange ? 1.02 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: receivedImpact
                ? AppColors.danger.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: widget.isActiveTurn
                  ? AppColors.info.withValues(alpha: 0.72)
                  : receivedImpact
                      ? AppColors.danger.withValues(alpha: 0.52)
                      : Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: [
              if (widget.isActiveTurn || widget.pulseTurnChange)
                BoxShadow(
                  color: AppColors.info.withValues(alpha: 0.22),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              if (receivedImpact)
                BoxShadow(
                  color: AppColors.danger.withValues(alpha: 0.2),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                widget.alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                widget.label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _PokemonPortrait(
                sprite: pokemon?.sprite,
                emphasized: widget.isActiveTurn || widget.pulseTurnChange,
                danger: receivedImpact || isKnockedOut,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                pokemon?.name ?? widget.strings.offlineFallback,
                textAlign: widget.alignEnd ? TextAlign.right : TextAlign.left,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.hpText,
                textAlign: widget.alignEnd ? TextAlign.right : TextAlign.left,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              if (widget.impactCue != null) ...[
                const SizedBox(height: AppSpacing.sm),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    widget.impactCue!.ko
                        ? 'K.O.'
                        : '-${widget.impactCue!.damage} ${widget.strings.isEs ? "PS" : "HP"}',
                    key: ValueKey<String>(widget.impactCue!.id),
                    style: TextStyle(
                      color: widget.impactCue!.ko ? AppColors.warning : AppColors.danger,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: LinearProgressIndicator(
                  value: hpRatio,
                  minHeight: 12,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    hpRatio > 0.5
                        ? AppColors.success
                        : hpRatio > 0.2
                            ? AppColors.warning
                            : AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PokemonPortrait extends StatelessWidget {
  const _PokemonPortrait({
    required this.sprite,
    required this.emphasized,
    required this.danger,
  });

  final String? sprite;
  final bool emphasized;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      width: 124,
      height: 124,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: danger
            ? AppColors.danger.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (emphasized)
            BoxShadow(
              color: AppColors.info.withValues(alpha: 0.2),
              blurRadius: 24,
              spreadRadius: 3,
            ),
          if (danger)
            BoxShadow(
              color: AppColors.danger.withValues(alpha: 0.18),
              blurRadius: 22,
              spreadRadius: 2,
            ),
        ],
      ),
      child: sprite == null
          ? const Icon(
              Icons.catching_pokemon_rounded,
              size: 52,
              color: Colors.white70,
            )
          : Image.network(
              sprite!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.catching_pokemon_rounded,
                size: 52,
                color: Colors.white70,
              ),
            ),
    );
  }
}

class _BattleActionPanel extends StatelessWidget {
  const _BattleActionPanel({
    required this.uiState,
    required this.strings,
    required this.onSearch,
    required this.onCancelSearch,
    required this.onAssignTeam,
    required this.onMarkReady,
    required this.onAttack,
    required this.onDismissResult,
  });

  final BattleUiState uiState;
  final AppStrings strings;
  final Future<void> Function() onSearch;
  final Future<void> Function() onCancelSearch;
  final Future<void> Function() onAssignTeam;
  final Future<void> Function() onMarkReady;
  final Future<void> Function() onAttack;
  final Future<void> Function() onDismissResult;

  @override
  Widget build(BuildContext context) {
    final flowState = uiState.flowState;

    return GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.chooseMove,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          if (flowState.stage == BattleStage.idle)
            PrimaryButton(
              label: strings.searchRival,
              onPressed: flowState.canSearch ? onSearch : null,
            ),
          if (flowState.stage == BattleStage.searching)
            PrimaryButton(
              label: strings.cancelSearch,
              onPressed: flowState.canCancelSearch ? onCancelSearch : null,
            ),
          if (flowState.stage == BattleStage.reconnecting)
            PrimaryButton(
              label: strings.reconnecting,
            ),
          if (flowState.stage == BattleStage.matched) ...[
            if (uiState.canAssignTeamManually)
              PrimaryButton(
                label: strings.assignTeam,
                onPressed: onAssignTeam,
              ),
            if (uiState.canAssignTeamManually) const SizedBox(height: AppSpacing.sm),
            if (uiState.canReadyManually)
              PrimaryButton(
                label: strings.markReady,
                onPressed: onMarkReady,
              ),
            if (!uiState.canAssignTeamManually && !uiState.canReadyManually)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  _matchedActionCopy(uiState, strings),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
          ],
          if (flowState.stage == BattleStage.battling)
            PrimaryButton(
              label: uiState.isBattlePaused
                  ? strings.battlePaused
                  : flowState.actionPending
                      ? strings.attacking
                      : uiState.isLocalTurn
                          ? strings.attack
                          : strings.waitingTurn,
              onPressed: flowState.canAttack && uiState.isLocalTurn ? onAttack : null,
            ),
          if (flowState.stage == BattleStage.result)
            PrimaryButton(
              label: strings.closeResult,
              onPressed: uiState.battleResult == null ? null : onDismissResult,
            ),
        ],
      ),
    );
  }
}

class _BattleCinematicOverlay extends StatelessWidget {
  const _BattleCinematicOverlay({
    required this.cinematic,
  });

  final _BattleCinematic cinematic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (background, accent) = switch (cinematic.tone) {
      _CinematicTone.info => (AppColors.primaryDark.withValues(alpha: 0.86), AppColors.info),
      _CinematicTone.success => (AppColors.primaryDark.withValues(alpha: 0.86), AppColors.success),
      _CinematicTone.warning => (AppColors.primaryDark.withValues(alpha: 0.88), AppColors.warning),
      _CinematicTone.danger => (AppColors.primaryDark.withValues(alpha: 0.9), AppColors.danger),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Container(
        key: ValueKey<String>(cinematic.id),
        color: background,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadii.xl),
              border: Border.all(color: accent.withValues(alpha: 0.48)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.18),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    cinematic.type.name.toUpperCase(),
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  cinematic.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  cinematic.body,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                    height: 1.45,
                  ),
                ),
                if (cinematic.teamNames.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: cinematic.teamNames
                        .map(
                          (name) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                            ),
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BattlePauseFullscreenOverlay extends StatelessWidget {
  const _BattlePauseFullscreenOverlay({
    required this.strings,
    required this.isSelfDisconnected,
    required this.reconnectDeadlineAt,
  });

  final AppStrings strings;
  final bool isSelfDisconnected;
  final DateTime? reconnectDeadlineAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: AppColors.primaryDark.withValues(alpha: 0.78),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusChip(
                label: isSelfDisconnected ? strings.reconnecting : strings.waitingOpponent,
                tone: isSelfDisconnected ? StatusChipTone.warning : StatusChipTone.info,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                isSelfDisconnected
                    ? strings.selfDisconnectedTitle
                    : strings.waitingOpponent,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                isSelfDisconnected
                    ? strings.selfDisconnectedBody
                    : strings.opponentDisconnectedBody,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ReconnectCountdown(
                deadlineAt: reconnectDeadlineAt,
                strings: strings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BattleResultFullscreenOverlay extends StatelessWidget {
  const _BattleResultFullscreenOverlay({
    required this.result,
    required this.didWin,
    required this.strings,
    required this.onDismiss,
  });

  final BattleEndSnapshot result;
  final bool didWin;
  final AppStrings strings;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: AppColors.primaryDark.withValues(alpha: 0.84),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: didWin
                  ? const [Color(0xFF0F3B2E), Color(0xFF14532D)]
                  : const [Color(0xFF3F0A1D), Color(0xFF111827)],
            ),
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(
              color: didWin
                  ? AppColors.success.withValues(alpha: 0.5)
                  : AppColors.danger.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: (didWin ? AppColors.success : AppColors.danger)
                    .withValues(alpha: 0.22),
                blurRadius: 28,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusChip(
                label: didWin ? strings.victoryChip : strings.defeatChip,
                tone: didWin ? StatusChipTone.success : StatusChipTone.dark,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                strings.battleResultTitle(didWin),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                strings.resultCopy(
                  won: didWin,
                  byDisconnect: result.reason == 'disconnect_timeout',
                ),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: strings.closeResult,
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReconnectCountdown extends StatefulWidget {
  const _ReconnectCountdown({
    required this.deadlineAt,
    required this.strings,
  });

  final DateTime? deadlineAt;
  final AppStrings strings;

  @override
  State<_ReconnectCountdown> createState() => _ReconnectCountdownState();
}

class _ReconnectCountdownState extends State<_ReconnectCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _restartTicker();
  }

  @override
  void didUpdateWidget(covariant _ReconnectCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deadlineAt != widget.deadlineAt) {
      _restartTicker();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _restartTicker() {
    _timer?.cancel();
    if (widget.deadlineAt == null) {
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deadline = widget.deadlineAt;
    final remaining = deadline == null
        ? Duration.zero
        : deadline.difference(DateTime.now());
    final clamped = remaining.isNegative ? Duration.zero : remaining;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.strings.reconnectCountdown,
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _formatDuration(clamped),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

String _matchedActionCopy(BattleUiState uiState, AppStrings strings) {
  if (uiState.shouldAutoAssign || uiState.flowState.actionPending) {
    return strings.autoAssigningInfo;
  }

  if (uiState.shouldAutoReady || uiState.flowState.actionPending) {
    return strings.autoReadyInfo;
  }

  return strings.lobbyStandbyInfo;
}

String _connectionLabel(
  BattleConnectionStatus connectionStatus,
  AppStrings strings,
) {
  return switch (connectionStatus) {
    BattleConnectionStatus.connected => strings.connectedChip,
    BattleConnectionStatus.connecting => strings.connectingChip,
    BattleConnectionStatus.disconnected => strings.offlineChip,
  };
}

String _stageChipLabel(
  BattleStage stage,
  AppStrings strings,
  bool didWin,
) {
  return switch (stage) {
    BattleStage.idle => strings.inactiveChip,
    BattleStage.reconnecting => strings.reconnecting,
    BattleStage.searching => strings.searchingChip,
    BattleStage.matched => strings.matchedChip,
    BattleStage.battling => strings.battleLiveChip,
    BattleStage.result => didWin ? strings.victoryChip : strings.defeatChip,
  };
}

StatusChipTone _stageChipTone(BattleStage stage, bool didWin) {
  return switch (stage) {
    BattleStage.idle => StatusChipTone.dark,
    BattleStage.reconnecting => StatusChipTone.warning,
    BattleStage.searching => StatusChipTone.warning,
    BattleStage.matched => StatusChipTone.success,
    BattleStage.battling => StatusChipTone.warning,
    BattleStage.result => didWin ? StatusChipTone.success : StatusChipTone.dark,
  };
}

String _titleForState(BattleUiState uiState, AppStrings strings) {
  final state = uiState.flowState;
  return switch (state.stage) {
    BattleStage.idle => strings.battleIdleTitle,
    BattleStage.reconnecting => strings.battleReconnectingTitle,
    BattleStage.searching => strings.battleSearchingTitle,
    BattleStage.matched => strings.battleMatchedTitle,
    BattleStage.battling => uiState.isBattlePaused ? strings.battlePaused : strings.battleActiveTitle,
    BattleStage.result => strings.battleResultTitle(uiState.didWin),
  };
}

String _subtitleForState(BattleUiState uiState, AppStrings strings) {
  final state = uiState.flowState;
  final opponentNickname = uiState.opponentNickname;
  return switch (state.stage) {
    BattleStage.idle => strings.battleIdleSubtitle,
    BattleStage.reconnecting => strings.battleReconnectingSubtitle,
    BattleStage.searching => strings.battleSearchingSubtitle,
    BattleStage.matched => strings.matchedBattleIntro(opponentNickname),
    BattleStage.battling => uiState.isBattlePaused
        ? strings.battlePausedSubtitle
        : strings.activeBattleIntro(opponentNickname),
    BattleStage.result => state.battleResult == null
        ? strings.battleResultPendingSubtitle
        : state.battleResult!.winnerPlayerId == uiState.session?.playerId
            ? strings.battleResultWonSubtitle
            : strings.battleResultLostSubtitle,
  };
}

String _lobbyHint(BattleUiState uiState, AppStrings strings) {
  final stage = uiState.flowState.stage;
  if (stage == BattleStage.searching) {
    return strings.battleSearchingSubtitle;
  }

  if (stage == BattleStage.reconnecting) {
    return strings.battleReconnectingSubtitle;
  }

  if (uiState.canAssignTeamManually) {
    return strings.needTeam;
  }

  if (uiState.canReadyManually) {
    return strings.teamAssignedInfo;
  }

  return _matchedActionCopy(uiState, strings);
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
