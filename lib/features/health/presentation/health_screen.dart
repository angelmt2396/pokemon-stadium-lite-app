import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pokemon_stadium_lite_app/core/i18n/app_strings.dart';
import 'package:pokemon_stadium_lite_app/core/network/network_error.dart';
import 'package:pokemon_stadium_lite_app/core/theme/app_colors.dart';
import 'package:pokemon_stadium_lite_app/core/theme/app_radii.dart';
import 'package:pokemon_stadium_lite_app/core/theme/app_spacing.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/app_scaffold.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/game_card.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/primary_button.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/status_chip.dart';
import 'package:pokemon_stadium_lite_app/features/health/presentation/health_controller.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(height: AppSpacing.sm),
            const StatusChip(label: 'HEALTH', tone: StatusChipTone.success),
            const SizedBox(height: AppSpacing.md),
            Text(strings.healthTitle, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(strings.healthSubtitle, style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.lg),
            GameCard(
              child: health.when(
                data: (snapshot) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusChip(
                          label: snapshot.status.toUpperCase(),
                          tone: snapshot.status == 'ok'
                              ? StatusChipTone.success
                              : StatusChipTone.warning,
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.monitor_heart_rounded,
                          color: AppColors.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      snapshot.status == 'ok'
                          ? strings.healthy
                          : strings.unhealthy,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      snapshot.service,
                      style: theme.textTheme.bodyLarge,
                    ),
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
                        snapshot.status == 'ok'
                            ? strings.readyToPlay
                            : strings.healthUnavailable,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.healthUnavailable,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      normalizeNetworkError(
                        error,
                        isEs: strings.isEs,
                        fallbackMessage: strings.healthUnavailable,
                      ),
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: strings.retry,
                      onPressed: () => ref.invalidate(backendHealthProvider),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
