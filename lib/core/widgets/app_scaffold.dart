import 'package:flutter/material.dart';
import 'package:pokemon_stadium_lite_app/core/theme/app_colors.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.scaffoldTop,
              AppColors.scaffoldBottom,
            ],
          ),
        ),
        child: SafeArea(child: child),
      ),
    );
  }
}
