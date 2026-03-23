import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokemon_stadium_lite_app/core/theme/app_colors.dart';
import 'package:pokemon_stadium_lite_app/core/theme/app_spacing.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/app_scaffold.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/game_card.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/primary_button.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/status_chip.dart';
import 'package:pokemon_stadium_lite_app/features/session/presentation/session_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _nicknameController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionControllerProvider);
    final controller = ref.read(sessionControllerProvider.notifier);
    final theme = Theme.of(context);

    return AppScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Text(
              'BIENVENIDO',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'PokeAlbo',
              style: theme.textTheme.headlineLarge?.copyWith(fontSize: 56),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ingresa tu nickname para continuar.',
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Row(
              children: [
                StatusChip(label: 'ONLINE', tone: StatusChipTone.info),
                SizedBox(width: AppSpacing.sm),
                StatusChip(label: 'PVP', tone: StatusChipTone.warning),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            GameCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACCESO',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.mutedInk,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Entrar', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _nicknameController,
                    onChanged: (_) => controller.clearError(),
                    decoration: const InputDecoration(
                      labelText: 'Nickname',
                      hintText: 'Ej. Ash',
                    ),
                  ),
                  if (sessionState.errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFFECDD3)),
                      ),
                      child: Text(
                        sessionState.errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: 'Entrar al juego',
                    onPressed: () {
                      controller.login(_nicknameController.text);
                    },
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
