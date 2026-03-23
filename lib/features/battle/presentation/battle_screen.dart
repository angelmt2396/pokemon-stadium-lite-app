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
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_player_snapshot.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_pokemon_snapshot.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/turn_result_snapshot.dart';
import 'package:pokemon_stadium_lite_app/features/battle/presentation/battle_controller.dart';
import 'package:pokemon_stadium_lite_app/features/session/presentation/session_controller.dart';

class BattleScreen extends ConsumerWidget {
  const BattleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(battleControllerProvider);
    final controller = ref.read(battleControllerProvider.notifier);
    final session = ref.watch(sessionControllerProvider).session;
    final strings = ref.watch(appStringsProvider);
    final lobbyStatus = state.lobbyStatus;
    final battleState = state.battleState;
    final battleResult = state.battleResult;
    final latestTurnResult = state.latestTurnResult;
    final localPlayer = session == null || lobbyStatus == null
        ? null
        : lobbyStatus.findPlayer(session.playerId);
    final opponent = session == null || lobbyStatus == null
        ? null
        : lobbyStatus.findOpponent(session.playerId);
    final localBattlePlayer = session == null || battleState == null
        ? null
        : battleState.findPlayer(session.playerId);
    final opponentBattlePlayer = session == null || battleState == null
        ? null
        : battleState.findOpponent(session.playerId);
    final isLocalTurn = session != null &&
        battleState != null &&
        battleState.currentTurnPlayerId == session.playerId;
    final isBattlePaused = state.isBattlePaused;
    final isSelfDisconnected =
        battleState?.disconnectedPlayerId != null &&
        battleState?.disconnectedPlayerId == session?.playerId;
    final searchElapsed = controller.searchElapsed;
    final localCanAssignTeam = state.stage == BattleStage.matched &&
        !state.actionPending &&
        localPlayer != null &&
        localPlayer.team.isEmpty &&
        (lobbyStatus?.players.length ?? 0) == 2;
    final localCanReady = state.stage == BattleStage.matched &&
        !state.actionPending &&
        localPlayer != null &&
        localPlayer.team.length == 3 &&
        !localPlayer.ready;

    return AppScaffold(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                StatusChip(label: strings.battleChip, tone: StatusChipTone.warning),
                StatusChip(
                  label: switch (state.connectionStatus) {
                    BattleConnectionStatus.connected => strings.connectedChip,
                    BattleConnectionStatus.connecting => strings.connectingChip,
                    BattleConnectionStatus.disconnected => strings.offlineChip,
                  },
                  tone: switch (state.connectionStatus) {
                    BattleConnectionStatus.connected => StatusChipTone.success,
                    BattleConnectionStatus.connecting => StatusChipTone.info,
                    BattleConnectionStatus.disconnected => StatusChipTone.dark,
                  },
                ),
                if (state.stage == BattleStage.searching)
                  StatusChip(
                    label: strings.searchingChip,
                    tone: StatusChipTone.info,
                  ),
                if (state.stage == BattleStage.matched)
                  StatusChip(
                    label: strings.matchedChip,
                    tone: StatusChipTone.success,
                  ),
                if (state.stage == BattleStage.battling)
                  StatusChip(
                    label: strings.battleLiveChip,
                    tone: StatusChipTone.warning,
                  ),
                if (state.stage == BattleStage.battling && isBattlePaused)
                  StatusChip(
                    label: strings.pausedChip,
                    tone: StatusChipTone.dark,
                  ),
                if (state.stage == BattleStage.result)
                  StatusChip(
                    label: battleResult != null &&
                            battleResult.winnerPlayerId == session?.playerId
                        ? strings.victoryChip
                        : strings.defeatChip,
                    tone: battleResult != null &&
                            battleResult.winnerPlayerId == session?.playerId
                        ? StatusChipTone.success
                        : StatusChipTone.dark,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _titleForState(state, strings),
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _subtitleForState(
                state,
                strings: strings,
                opponentNickname: opponent?.nickname,
                sessionPlayerId: session?.playerId,
                battleResult: battleResult,
              ),
              style: theme.textTheme.bodyLarge,
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              GameCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.danger),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
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
            const SizedBox(height: AppSpacing.lg),
            GameCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          strings.battleRoom,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      StatusChip(
                        label: switch (state.stage) {
                          BattleStage.idle => strings.inactiveChip,
                          BattleStage.reconnecting => strings.reconnecting,
                          BattleStage.searching => strings.inQueueChip,
                          BattleStage.matched => strings.rivalFoundChip,
                          BattleStage.battling => strings.activeBattleChip,
                          BattleStage.result => strings.resultReadyChip,
                        },
                        tone: switch (state.stage) {
                          BattleStage.idle => StatusChipTone.dark,
                          BattleStage.reconnecting => StatusChipTone.info,
                          BattleStage.searching => StatusChipTone.info,
                          BattleStage.matched => StatusChipTone.success,
                          BattleStage.battling => StatusChipTone.warning,
                          BattleStage.result => StatusChipTone.success,
                        },
                      ),
                    ],
                  ),
                  if (searchElapsed != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '${strings.queueTimeLabel}: ${_formatDuration(searchElapsed)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  if (state.stage == BattleStage.battling && battleState != null)
                    _ActiveBattleHud(
                      localPlayer: localBattlePlayer,
                      opponentPlayer: opponentBattlePlayer,
                      isLocalTurn: isLocalTurn,
                      isPaused: isBattlePaused,
                      isSelfDisconnected: isSelfDisconnected,
                      reconnectDeadlineAt: battleState.reconnectDeadlineAt,
                      latestTurnResult: latestTurnResult,
                      strings: strings,
                    )
                  else if (state.stage == BattleStage.result && battleResult != null)
                    _BattleResultPanel(
                      result: battleResult,
                      sessionPlayerId: session?.playerId,
                      onDismiss: controller.dismissBattleResult,
                      strings: strings,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadii.lg),
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
                        children: [
                          _BattleFighterCard(
                            label: strings.localPlayerLabel,
                            name: localPlayer?.nickname ??
                                session?.nickname ??
                                strings.trainerFallback,
                            subtitle: localPlayer == null
                                ? strings.localSearchReadySubtitle
                                : localPlayer.ready
                                    ? strings.localReadySubtitle
                                    : localPlayer.team.isEmpty
                                        ? strings.localNoTeamSubtitle
                                        : strings.localAssignedTeamSubtitle(localPlayer.team.length),
                            chips: [
                              if (localPlayer?.ready == true)
                                StatusChip(
                                  label: strings.readyChip,
                                  tone: StatusChipTone.success,
                                ),
                            ],
                            team: localPlayer?.team ?? const [],
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                            child: StatusChip(
                              label: strings.versusLabel,
                              tone: StatusChipTone.info,
                            ),
                          ),
                          _BattleFighterCard(
                            label: strings.rivalLabel,
                            name: opponent?.nickname ?? strings.waitingPlaceholder,
                            subtitle: opponent == null
                                ? strings.queueOpenSubtitle
                                : opponent.ready
                                    ? strings.rivalReadySubtitle
                                    : strings.rivalDetectedSubtitle,
                            chips: [
                              if (opponent?.ready == true)
                                StatusChip(
                                  label: strings.readyChip,
                                  tone: StatusChipTone.success,
                                ),
                            ],
                            team: opponent?.team ?? const [],
                          ),
                          if (state.stage == BattleStage.matched) ...[
                            const SizedBox(height: AppSpacing.lg),
                            _BattleStartPanel(
                              localPlayer: localBattlePlayer,
                              opponentPlayer: opponentBattlePlayer,
                              isLocalTurn: isLocalTurn,
                              strings: strings,
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (state.infoMessage != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        state.infoMessage!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  if (state.stage == BattleStage.idle)
                    PrimaryButton(
                      label: strings.searchRival,
                      onPressed: state.canSearch ? controller.searchMatch : null,
                    ),
                  if (state.stage == BattleStage.searching)
                    PrimaryButton(
                      label: strings.cancelSearch,
                      onPressed: state.canCancelSearch
                          ? controller.cancelSearch
                          : null,
                    ),
                  if (state.stage == BattleStage.matched)
                    Column(
                      children: [
                        if (localCanAssignTeam)
                          PrimaryButton(
                            label: strings.assignTeam,
                            onPressed: controller.assignTeam,
                          ),
                        if (localCanAssignTeam)
                          const SizedBox(height: AppSpacing.sm),
                        PrimaryButton(
                          label: localCanReady
                              ? strings.markReady
                              : localPlayer?.ready == true
                                  ? strings.waitingRival
                                  : strings.needTeam,
                          onPressed: localCanReady ? controller.markReady : null,
                        ),
                      ],
                    ),
                  if (state.stage == BattleStage.battling)
                    PrimaryButton(
                      label: isBattlePaused
                          ? strings.battlePaused
                          : state.actionPending
                          ? strings.attacking
                          : isLocalTurn
                              ? strings.attack
                              : strings.waitingTurn,
                      onPressed: state.canAttack && isLocalTurn
                          ? controller.attack
                          : null,
                    ),
                  if (state.stage == BattleStage.reconnecting)
                    PrimaryButton(label: strings.reconnecting),
                  if (state.stage == BattleStage.result)
                    PrimaryButton(
                      label: strings.closeResult,
                      onPressed: battleResult == null
                          ? null
                          : controller.dismissBattleResult,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BattleFighterCard extends StatelessWidget {
  const _BattleFighterCard({
    required this.label,
    required this.name,
    required this.subtitle,
    required this.team,
    this.chips = const [],
  });

  final String label;
  final String name;
  final String subtitle;
  final List<Widget> chips;
  final List<BattleLobbyPokemon> team;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
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
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
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

class _BattleStartPanel extends StatelessWidget {
  const _BattleStartPanel({
    required this.localPlayer,
    required this.opponentPlayer,
    required this.isLocalTurn,
    required this.strings,
  });

  final BattlePlayerSnapshot? localPlayer;
  final BattlePlayerSnapshot? opponentPlayer;
  final bool isLocalTurn;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localPokemon = localPlayer?.activePokemon;
    final opponentPokemon = opponentPlayer?.activePokemon;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              StatusChip(label: strings.battleReadyChip, tone: StatusChipTone.warning),
              StatusChip(
                label: isLocalTurn ? strings.yourTurn : strings.rivalTurn,
                tone: isLocalTurn ? StatusChipTone.success : StatusChipTone.dark,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            strings.battleStarted,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            localPokemon == null || opponentPokemon == null
                ? strings.waitingActivePokemonHydration
                : strings.battleOpening(localPokemon.name, opponentPokemon.name),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ActiveBattleHud extends StatelessWidget {
  const _ActiveBattleHud({
    required this.localPlayer,
    required this.opponentPlayer,
    required this.isLocalTurn,
    required this.isPaused,
    required this.isSelfDisconnected,
    required this.reconnectDeadlineAt,
    required this.latestTurnResult,
    required this.strings,
  });

  final BattlePlayerSnapshot? localPlayer;
  final BattlePlayerSnapshot? opponentPlayer;
  final bool isLocalTurn;
  final bool isPaused;
  final bool isSelfDisconnected;
  final DateTime? reconnectDeadlineAt;
  final TurnResultSnapshot? latestTurnResult;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.gameNavyTop, AppColors.gameNavyBottom],
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
                    label: isLocalTurn ? strings.yourTurn : strings.rivalTurn,
                    tone: isLocalTurn ? StatusChipTone.success : StatusChipTone.dark,
                  ),
                  if (latestTurnResult != null)
                    StatusChip(
                      label: strings.turnResolvedChip,
                      tone: StatusChipTone.warning,
                    ),
                  if (isPaused)
                    StatusChip(
                      label: strings.battlePausedChip,
                      tone: StatusChipTone.dark,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _ActivePokemonPanel(
                label: strings.rivalLabel,
                pokemon: opponentPlayer?.activePokemon,
                alignEnd: true,
                strings: strings,
                damageContext: latestTurnResult?.defenderPokemonId ==
                        opponentPlayer?.activePokemon.pokemonId
                    ? latestTurnResult
                    : null,
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(
                  child: StatusChip(label: strings.versusLabel, tone: StatusChipTone.info),
                ),
              ),
              _ActivePokemonPanel(
                label: strings.yourPokemonLabel,
                pokemon: localPlayer?.activePokemon,
                alignEnd: false,
                strings: strings,
                damageContext:
                    latestTurnResult?.defenderPokemonId == localPlayer?.activePokemon.pokemonId
                        ? latestTurnResult
                        : null,
              ),
              if (latestTurnResult != null) ...[
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
                        latestTurnResult!.defenderDefeated
                            ? strings.finalBlow
                            : strings.damageApplied,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        strings.damageSummary(
                          defeated: latestTurnResult!.defenderDefeated,
                          damage: latestTurnResult!.damage,
                          remainingHp: latestTurnResult!.defenderRemainingHp,
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      if (latestTurnResult!.autoSwitchedPokemon?.pokemon != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          strings.autoSwitchSummary(
                            latestTurnResult!.autoSwitchedPokemon!.pokemon!.name,
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
        if (isPaused)
          Positioned.fill(
            child: _BattlePauseOverlay(
              isSelfDisconnected: isSelfDisconnected,
              reconnectDeadlineAt: reconnectDeadlineAt,
              strings: strings,
            ),
          ),
      ],
    );
  }
}

class _BattlePauseOverlay extends StatelessWidget {
  const _BattlePauseOverlay({
    required this.isSelfDisconnected,
    required this.reconnectDeadlineAt,
    required this.strings,
  });

  final bool isSelfDisconnected;
  final DateTime? reconnectDeadlineAt;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusChip(
                label: isSelfDisconnected ? strings.reconnecting : strings.waitingOpponent,
                tone: isSelfDisconnected
                    ? StatusChipTone.warning
                    : StatusChipTone.info,
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
    _startTicker();
  }

  @override
  void didUpdateWidget(covariant _ReconnectCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deadlineAt != widget.deadlineAt) {
      _startTicker();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTicker() {
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
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
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

class _ActivePokemonPanel extends StatelessWidget {
  const _ActivePokemonPanel({
    required this.label,
    required this.pokemon,
    required this.alignEnd,
    required this.strings,
    this.damageContext,
  });

  final String label;
  final BattlePokemonSnapshot? pokemon;
  final bool alignEnd;
  final AppStrings strings;
  final TurnResultSnapshot? damageContext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hpRatio = pokemon == null || pokemon!.hp == 0
        ? 0.0
        : (pokemon!.currentHp / pokemon!.hp).clamp(0, 1).toDouble();

    final tookDamage = damageContext != null;
    final ko = damageContext?.defenderDefeated ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tookDamage
            ? AppColors.danger.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: tookDamage
              ? AppColors.danger.withValues(alpha: 0.48)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _PokemonVisual(
            sprite: pokemon?.sprite,
            pulseDanger: tookDamage,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            pokemon?.name ?? strings.offlineFallback,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            pokemon == null
                ? strings.waitingSnapshot
                : strings.hpCounter(pokemon!.currentHp, pokemon!.hp),
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          ),
          if (damageContext != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Text(
                strings.koLabel(damageContext!.damage, ko),
                key: ValueKey('${damageContext!.battleId}-${damageContext!.damage}-${ko ? 'ko' : 'hit'}'),
                style: TextStyle(
                  color: ko ? AppColors.warning : AppColors.danger,
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
    );
  }
}

class _PokemonVisual extends StatelessWidget {
  const _PokemonVisual({
    required this.sprite,
    this.pulseDanger = false,
  });

  final String? sprite;
  final bool pulseDanger;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      scale: pulseDanger ? 0.95 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 120,
        height: 120,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: pulseDanger
              ? AppColors.danger.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(24),
          boxShadow: pulseDanger
              ? [
                  BoxShadow(
                    color: AppColors.danger.withValues(alpha: 0.2),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ]
              : const [],
        ),
        child: sprite == null
            ? const Icon(
                Icons.catching_pokemon_rounded,
                size: 48,
                color: Colors.white70,
              )
            : Image.network(
                sprite!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.catching_pokemon_rounded,
                  size: 48,
                  color: Colors.white70,
                ),
              ),
      ),
    );
  }
}

class _BattleResultPanel extends StatelessWidget {
  const _BattleResultPanel({
    required this.result,
    required this.sessionPlayerId,
    required this.onDismiss,
    required this.strings,
  });

  final BattleEndSnapshot result;
  final String? sessionPlayerId;
  final VoidCallback onDismiss;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final won = sessionPlayerId != null && result.winnerPlayerId == sessionPlayerId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.gameNavyTop, AppColors.gameNavyBottom],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusChip(
            label: won ? strings.victoryChip : strings.defeatChip,
            tone: won ? StatusChipTone.success : StatusChipTone.dark,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            strings.battleResultTitle(won),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            strings.resultCopy(
              won: won,
              byDisconnect: result.reason == 'disconnect_timeout',
            ),
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: strings.closeResult,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

String _titleForState(BattleFlowState state, AppStrings strings) {
  return switch (state.stage) {
    BattleStage.idle => strings.battleIdleTitle,
    BattleStage.reconnecting => strings.battleReconnectingTitle,
    BattleStage.searching => strings.battleSearchingTitle,
    BattleStage.matched => strings.battleMatchedTitle,
    BattleStage.battling => strings.battleActiveTitle,
    BattleStage.result => strings.battleResult,
  };
}

String _subtitleForState(
  BattleFlowState state, {
  required AppStrings strings,
  required String? opponentNickname,
  required String? sessionPlayerId,
  required BattleEndSnapshot? battleResult,
}) {
  return switch (state.stage) {
    BattleStage.idle => strings.battleIdleSubtitle,
    BattleStage.reconnecting => strings.battleReconnectingSubtitle,
    BattleStage.searching => strings.battleSearchingSubtitle,
    BattleStage.matched => strings.matchedBattleIntro(opponentNickname),
    BattleStage.battling => state.isBattlePaused
        ? strings.battlePausedSubtitle
        : strings.activeBattleIntro(opponentNickname),
    BattleStage.result => battleResult == null
        ? strings.battleResultPendingSubtitle
        : battleResult.winnerPlayerId == sessionPlayerId
            ? strings.battleResultWonSubtitle
            : strings.battleResultLostSubtitle,
  };
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
