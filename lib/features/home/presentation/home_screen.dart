import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pokemon_stadium_lite_app/core/theme/app_spacing.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/app_scaffold.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/game_card.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/primary_button.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/status_chip.dart';
import 'package:pokemon_stadium_lite_app/features/session/presentation/session_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionControllerProvider);
    final controller = ref.read(sessionControllerProvider.notifier);
    final session = sessionState.session;
    final theme = Theme.of(context);

    return AppScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Elige tu próximo movimiento',
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => controller.logout(),
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            GameCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: StatusChip(label: 'SESIÓN ACTIVA', tone: StatusChipTone.info),
                      ),
                      const StatusChip(label: 'EN LÍNEA', tone: StatusChipTone.dark),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    session?.nickname ?? 'Entrenador',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    session?.hasActiveBattle == true ? 'Tienes una arena activa.' : 'Todo listo para jugar.',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Modo catálogo',
              onPressed: () => context.push('/catalog'),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: session?.hasActiveBattle == true ? 'Reanudar combate' : 'Ir a batalla',
              onPressed: () => context.push('/battle'),
            ),
          ],
        ),
      ),
    );
  }
}
