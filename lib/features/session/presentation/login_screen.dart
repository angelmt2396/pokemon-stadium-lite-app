import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokemon_stadium_lite_app/core/i18n/app_strings.dart';
import 'package:pokemon_stadium_lite_app/core/theme/app_colors.dart';
import 'package:pokemon_stadium_lite_app/core/theme/app_spacing.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/app_scaffold.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/game_card.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/language_toggle.dart';
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
    final strings = ref.watch(appStringsProvider);

    return AppScaffold(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Align(
              alignment: Alignment.centerRight,
              child: LanguageToggle(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              strings.welcome,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              strings.appTitle,
              style: theme.textTheme.headlineLarge?.copyWith(fontSize: 56),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              strings.loginSubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                StatusChip(label: strings.online, tone: StatusChipTone.info),
                const SizedBox(width: AppSpacing.sm),
                StatusChip(label: strings.pvp, tone: StatusChipTone.warning),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            GameCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.access,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.mutedInk,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(strings.loginTitle, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _nicknameController,
                    onChanged: (_) => controller.clearError(),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => controller.login(_nicknameController.text),
                    decoration: InputDecoration(
                      labelText: strings.nickname,
                      hintText: strings.nicknameHint,
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
                    label: strings.loginButton,
                    onPressed: () {
                      controller.login(_nicknameController.text);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    strings.dismissKeyboardHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.subtleInk,
                    ),
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
