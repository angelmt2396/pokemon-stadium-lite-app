import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokemon_stadium_lite_app/app/router/app_router.dart';
import 'package:pokemon_stadium_lite_app/app/theme/app_theme.dart';

class PokemonStadiumLiteApp extends ConsumerWidget {
  const PokemonStadiumLiteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Pokemon Stadium Lite',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
