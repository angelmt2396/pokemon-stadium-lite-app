import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pokemon_stadium_lite_app/core/theme/app_colors.dart';
import 'package:pokemon_stadium_lite_app/core/theme/app_spacing.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/app_scaffold.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/game_card.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/primary_button.dart';
import 'package:pokemon_stadium_lite_app/core/widgets/status_chip.dart';
import 'package:pokemon_stadium_lite_app/features/catalog/domain/pokemon_detail.dart';
import 'package:pokemon_stadium_lite_app/features/catalog/domain/pokemon_list_item.dart';
import 'package:pokemon_stadium_lite_app/features/catalog/presentation/catalog_controller.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final catalog = ref.watch(pokemonCatalogProvider);
    final selectedPokemonId = ref.watch(effectiveSelectedPokemonIdProvider);
    final selectedPokemonDetail = ref.watch(selectedPokemonDetailProvider);

    return AppScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(height: AppSpacing.sm),
            const StatusChip(label: 'CATÁLOGO', tone: StatusChipTone.info),
            const SizedBox(height: AppSpacing.md),
            Text('Pokédex', style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Explora el catálogo real del backend y revisa stats, tipos y sprites antes de entrar a combate.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            GameCard(
              child: _CatalogDetailPanel(detail: selectedPokemonDetail),
            ),
            const SizedBox(height: AppSpacing.lg),
            GameCard(
              child: catalog.when(
                data: (pokemon) => _CatalogList(
                  pokemon: pokemon,
                  selectedPokemonId: selectedPokemonId,
                ),
                loading: () => const _CatalogPlaceholder(),
                error: (error, _) => _CatalogErrorState(
                  message: error.toString().replaceFirst('Exception: ', ''),
                  onRetry: () {
                    ref.invalidate(pokemonCatalogProvider);
                    ref.invalidate(selectedPokemonDetailProvider);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogDetailPanel extends StatelessWidget {
  const _CatalogDetailPanel({required this.detail});

  final AsyncValue<PokemonDetail?> detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return detail.when(
      data: (pokemon) {
        if (pokemon == null) {
          return const _CatalogPlaceholder();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${pokemon.id.toString().padLeft(3, '0')}',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        pokemon.name,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 34,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: pokemon.type
                            .map((type) => StatusChip(
                                  label: type.toUpperCase(),
                                  tone: StatusChipTone.warning,
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _PokemonSpriteCard(sprite: pokemon.sprite, size: 128),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _StatCard(label: 'HP', value: pokemon.hp),
                _StatCard(label: 'Attack', value: pokemon.attack),
                _StatCard(label: 'Defense', value: pokemon.defense),
                _StatCard(label: 'Speed', value: pokemon.speed),
              ],
            ),
          ],
        );
      },
      loading: () => const _CatalogPlaceholder(),
      error: (error, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No se pudo cargar el detalle.', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            error.toString().replaceFirst('Exception: ', ''),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _CatalogList extends ConsumerWidget {
  const _CatalogList({
    required this.pokemon,
    required this.selectedPokemonId,
  });

  final List<PokemonListItem> pokemon;
  final int? selectedPokemonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (pokemon.isEmpty) {
      return const Text('El catálogo llegó vacío.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Roster disponible', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        ...pokemon.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => ref.read(selectedPokemonIdProvider.notifier).state = entry.id,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: selectedPokemonId == entry.id
                        ? AppColors.info
                        : AppColors.border,
                    width: selectedPokemonId == entry.id ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    _PokemonSpriteCard(sprite: entry.sprite, size: 72),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${entry.id.toString().padLeft(3, '0')}',
                            style: theme.textTheme.labelMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            entry.name,
                            style: theme.textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                    if (selectedPokemonId == entry.id)
                      const Icon(Icons.radio_button_checked_rounded, color: AppColors.info)
                    else
                      const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CatalogPlaceholder extends StatelessWidget {
  const _CatalogPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: EdgeInsets.only(bottom: index == 2 ? 0 : AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x140F172A)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 120, color: const Color(0xFFE2E8F0)),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 86, color: const Color(0xFFF1F5F9)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogErrorState extends StatelessWidget {
  const _CatalogErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('No se pudo cargar el catálogo.', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(message, style: theme.textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(label: 'Intentar de nuevo', onPressed: onRetry),
      ],
    );
  }
}

class _PokemonSpriteCard extends StatelessWidget {
  const _PokemonSpriteCard({
    required this.sprite,
    required this.size,
  });

  final String sprite;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Image.network(
        sprite,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.catching_pokemon_rounded),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 140,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('$value', style: theme.textTheme.titleLarge),
        ],
      ),
    );
  }
}
