import 'package:flutter/material.dart';
import 'package:pokemon_stadium_lite_app/core/theme/app_colors.dart';
import 'package:pokemon_stadium_lite_app/core/theme/app_radii.dart';
import 'package:pokemon_stadium_lite_app/core/theme/app_shadows.dart';

class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.panel,
      ),
      child: child,
    );
  }
}
