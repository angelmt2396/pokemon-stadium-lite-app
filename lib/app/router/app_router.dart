import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pokemon_stadium_lite_app/features/battle/presentation/battle_screen.dart';
import 'package:pokemon_stadium_lite_app/features/catalog/presentation/catalog_screen.dart';
import 'package:pokemon_stadium_lite_app/features/home/presentation/home_screen.dart';
import 'package:pokemon_stadium_lite_app/features/session/presentation/bootstrap_screen.dart';
import 'package:pokemon_stadium_lite_app/features/session/presentation/login_screen.dart';
import 'package:pokemon_stadium_lite_app/features/session/presentation/session_controller.dart';
import 'package:pokemon_stadium_lite_app/features/session/domain/session_state.dart';

final _routerRefreshProvider = Provider<ValueNotifier<int>>((ref) {
  final notifier = ValueNotifier<int>(0);

  ref.listen<SessionState>(
    sessionControllerProvider,
    (_, _) => notifier.value++,
  );

  ref.onDispose(notifier.dispose);
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(_routerRefreshProvider);

  return GoRouter(
    initialLocation: '/bootstrap',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final sessionState = ref.read(sessionControllerProvider);
      final location = state.matchedLocation;

      if (sessionState.status == SessionStatus.booting) {
        return location == '/bootstrap' ? null : '/bootstrap';
      }

      final isAuthenticated = sessionState.status == SessionStatus.authenticated;

      if (!isAuthenticated && location != '/login') {
        return '/login';
      }

      if (isAuthenticated && (location == '/bootstrap' || location == '/login')) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/bootstrap',
        builder: (context, state) => const BootstrapScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/catalog',
        builder: (context, state) => const CatalogScreen(),
      ),
      GoRoute(
        path: '/battle',
        builder: (context, state) => const BattleScreen(),
      ),
    ],
  );
});
