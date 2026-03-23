import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokemon_stadium_lite_app/core/i18n/app_strings.dart';
import 'package:pokemon_stadium_lite_app/core/theme/app_colors.dart';
import 'package:pokemon_stadium_lite_app/core/theme/app_radii.dart';
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

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  static const _heroPokemon = <_LoginHeroPokemon>[
    _LoginHeroPokemon(
      name: 'Pikachu',
      spriteUrl:
          'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/showdown/25.gif',
      glowColor: Color(0x66FCD34D),
      chipColor: Color(0xFFFFF2D8),
      chipInk: Color(0xFFB45309),
    ),
    _LoginHeroPokemon(
      name: 'Bulbasaur',
      spriteUrl:
          'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/showdown/1.gif',
      glowColor: Color(0x664ADE80),
      chipColor: Color(0xFFD9FAE8),
      chipInk: Color(0xFF047857),
    ),
    _LoginHeroPokemon(
      name: 'Charmander',
      spriteUrl:
          'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/showdown/4.gif',
      glowColor: Color(0x66FB923C),
      chipColor: Color(0xFFFFEDD5),
      chipInk: Color(0xFFC2410C),
    ),
    _LoginHeroPokemon(
      name: 'Squirtle',
      spriteUrl:
          'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/showdown/7.gif',
      glowColor: Color(0x665BC0EB),
      chipColor: Color(0xFFE0F7FF),
      chipInk: Color(0xFF0F5F77),
    ),
  ];

  final _nicknameController = TextEditingController();
  late final AnimationController _floatSlowController;
  late final AnimationController _floatFastController;
  late final Animation<double> _floatSlowAnimation;
  late final Animation<double> _floatFastAnimation;
  Timer? _visualSwapTimer;
  int _activeVisualIndex = 0;

  _LoginHeroPokemon get _activeVisual => _heroPokemon[_activeVisualIndex];
  _LoginHeroPokemon get _secondaryVisual =>
      _heroPokemon[(_activeVisualIndex + 1) % _heroPokemon.length];

  @override
  void initState() {
    super.initState();
    _floatSlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4600),
    )..repeat(reverse: true);
    _floatFastController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat(reverse: true);
    _floatSlowAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _floatSlowController, curve: Curves.easeInOut),
    );
    _floatFastAnimation = Tween<double>(begin: 0, end: -7).animate(
      CurvedAnimation(parent: _floatFastController, curve: Curves.easeInOut),
    );
    _visualSwapTimer = Timer.periodic(const Duration(milliseconds: 4200), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _activeVisualIndex = (_activeVisualIndex + 1) % _heroPokemon.length;
      });
    });
  }

  @override
  void dispose() {
    _visualSwapTimer?.cancel();
    _floatSlowController.dispose();
    _floatFastController.dispose();
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
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.94, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: ((value - 0.94) / 0.06).clamp(0, 1),
                    child: child,
                  ),
                );
              },
              child: Container(
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
                      color: AppColors.primaryDark.withValues(alpha: 0.22),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -22,
                      right: -18,
                      child: Container(
                        width: 108,
                        height: 108,
                        decoration: const BoxDecoration(
                          color: AppColors.haloBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -28,
                      left: -8,
                      child: Container(
                        width: 124,
                        height: 124,
                        decoration: const BoxDecoration(
                          color: AppColors.haloAmber,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.welcome,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          strings.appTitle,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontSize: 56,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          strings.loginSubtitle,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 20,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            StatusChip(label: strings.online, tone: StatusChipTone.info),
                            const SizedBox(width: AppSpacing.sm),
                            StatusChip(label: strings.pvp, tone: StatusChipTone.warning),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _LoginHeroVisual(
                          activeVisual: _activeVisual,
                          secondaryVisual: _secondaryVisual,
                          floatSlowAnimation: _floatSlowAnimation,
                          floatFastAnimation: _floatFastAnimation,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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

class _LoginHeroPokemon {
  const _LoginHeroPokemon({
    required this.name,
    required this.spriteUrl,
    required this.glowColor,
    required this.chipColor,
    required this.chipInk,
  });

  final String name;
  final String spriteUrl;
  final Color glowColor;
  final Color chipColor;
  final Color chipInk;
}

class _LoginHeroVisual extends StatelessWidget {
  const _LoginHeroVisual({
    required this.activeVisual,
    required this.secondaryVisual,
    required this.floatSlowAnimation,
    required this.floatFastAnimation,
  });

  final _LoginHeroPokemon activeVisual;
  final _LoginHeroPokemon secondaryVisual;
  final Animation<double> floatSlowAnimation;
  final Animation<double> floatFastAnimation;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;

        if (compact) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ROSTER LIVE',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.8,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: Text(
                          activeVisual.name,
                          key: ValueKey<String>('mobile-${activeVisual.name}'),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _HeroPokemonBadge(
                  visual: activeVisual,
                  animation: floatSlowAnimation,
                  size: 82,
                  compact: true,
                ),
              ],
            ),
          );
        }

        return SizedBox(
          height: 176,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.3),
                        Colors.white.withValues(alpha: 0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(34),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          activeVisual.glowColor,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                top: 18,
                child: _HeroPokemonBadge(
                  visual: activeVisual,
                  animation: floatSlowAnimation,
                  size: 96,
                  compact: false,
                ),
              ),
              Positioned(
                left: 4,
                bottom: 6,
                child: _HeroPokemonMini(
                  visual: secondaryVisual,
                  animation: floatFastAnimation,
                ),
              ),
              Positioned(
                right: 2,
                bottom: 8,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: activeVisual.chipColor.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    activeVisual.name,
                    style: TextStyle(
                      color: activeVisual.chipInk,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroPokemonBadge extends StatelessWidget {
  const _HeroPokemonBadge({
    required this.visual,
    required this.animation,
    required this.size,
    required this.compact,
  });

  final _LoginHeroPokemon visual;
  final Animation<double> animation;
  final double size;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, animation.value),
          child: child,
        );
      },
      child: Container(
        padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: compact ? 0.72 : 0.56),
          borderRadius: BorderRadius.circular(compact ? 18 : 22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(compact ? 16 : 18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: size * 0.74,
                height: size * 0.74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      visual.glowColor,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: Image.network(
                  visual.spriteUrl,
                  key: ValueKey<String>(visual.name),
                  width: compact ? 58 : 74,
                  height: compact ? 58 : 74,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.catching_pokemon_rounded,
                    size: compact ? 38 : 46,
                    color: Colors.white70,
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

class _HeroPokemonMini extends StatelessWidget {
  const _HeroPokemonMini({
    required this.visual,
    required this.animation,
  });

  final _LoginHeroPokemon visual;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, animation.value),
          child: Transform.rotate(
            angle: animation.value / 120,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.68)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Image.network(
          visual.spriteUrl,
          key: ValueKey<String>('mini-${visual.name}'),
          width: 30,
          height: 30,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.catching_pokemon_rounded,
            size: 22,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}
