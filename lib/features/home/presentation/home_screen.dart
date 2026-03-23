import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pokemon_stadium_lite_app/core/i18n/app_strings.dart';
import 'package:pokemon_stadium_lite_app/core/theme/app_colors.dart';
import 'package:pokemon_stadium_lite_app/core/theme/app_spacing.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/app_scaffold.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/game_card.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/language_toggle.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/primary_button.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/status_chip.dart';
import 'package:pokemon_stadium_lite_app/features/health/presentation/health_controller.dart';
import 'package:pokemon_stadium_lite_app/features/session/presentation/session_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionControllerProvider);
    final controller = ref.read(sessionControllerProvider.notifier);
    final session = sessionState.session;
    final theme = Theme.of(context);
    final strings = ref.watch(appStringsProvider);
    final health = ref.watch(backendHealthProvider);

    return AppScaffold(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.chooseMove,
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                const LanguageToggle(),
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  onPressed: () => controller.logout(),
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
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
                    color: AppColors.primaryDark.withValues(alpha: 0.18),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatusChip(
                          label: strings.activeSession,
                          tone: StatusChipTone.info,
                        ),
                      ),
                      StatusChip(label: strings.online, tone: StatusChipTone.warning),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    session?.nickname ?? 'Entrenador',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    session?.hasActiveBattle == true
                        ? strings.activeArena
                        : strings.readyToPlay,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GameCard(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 430;

                  final summary = health.when(
                    data: (snapshot) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.backendHealth,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          snapshot.status == 'ok'
                              ? strings.healthy
                              : strings.unhealthy,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    loading: () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.backendHealth,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const Text('...'),
                      ],
                    ),
                    error: (_, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.backendHealth,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          strings.healthUnavailable,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );

                  if (stacked) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        summary,
                        const SizedBox(height: AppSpacing.md),
                        PrimaryButton(
                          label: strings.openHealth,
                          onPressed: () => context.push('/health'),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: summary),
                      const SizedBox(width: AppSpacing.md),
                      Flexible(
                        child: PrimaryButton(
                          label: strings.openHealth,
                          onPressed: () => context.push('/health'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: strings.catalogMode,
              onPressed: () => context.push('/catalog'),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: session?.hasActiveBattle == true
                  ? strings.resumeBattle
                  : strings.goToBattle,
              onPressed: () => context.push('/battle'),
            ),
          ],
        ),
      ),
    );
  }
}
