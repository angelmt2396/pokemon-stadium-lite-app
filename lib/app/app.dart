import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokemon_stadium_lite_app/features/session/presentation/session_controller.dart';
import 'package:pokemon_stadium_lite_app/core/i18n/app_locale_controller.dart';
import 'package:pokemon_stadium_lite_app/core/i18n/app_strings.dart';
import 'package:pokemon_stadium_lite_app/app/router/app_router.dart';
import 'package:pokemon_stadium_lite_app/app/theme/app_theme.dart';

class PokemonStadiumLiteApp extends ConsumerStatefulWidget {
  const PokemonStadiumLiteApp({super.key});

  @override
  ConsumerState<PokemonStadiumLiteApp> createState() => _PokemonStadiumLiteAppState();
}

class _PokemonStadiumLiteAppState extends ConsumerState<PokemonStadiumLiteApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    unawaited(
      ref.read(sessionControllerProvider.notifier).syncCurrentSessionSilently(force: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(appLocaleControllerProvider);
    final strings = ref.watch(appStringsProvider);

    return MaterialApp.router(
      title: strings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: locale,
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
