import 'package:flutter/material.dart';
import 'package:pokemon_stadium_lite_app/core/theme/app_colors.dart';
import 'package:pokemon_stadium_lite_app/core/theme/app_radii.dart';

enum StatusChipTone { success, info, warning, dark }

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusChipTone.info,
  });

  final String label;
  final StatusChipTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = switch (tone) {
      StatusChipTone.success => (const Color(0xFFD9FAE8), const Color(0xFF047857)),
      StatusChipTone.info => (const Color(0xFFE0F7FF), const Color(0xFF0F5F77)),
      StatusChipTone.warning => (const Color(0xFFFFF2D8), const Color(0xFFB45309)),
      StatusChipTone.dark => (AppColors.primaryDark, Colors.white),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
