import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokemon_stadium_lite_app/core/i18n/app_locale_controller.dart';

class AppStrings {
  const AppStrings._(this.languageCode);

  final String languageCode;

  bool get isEs => languageCode == 'es';

  static AppStrings fromLocale(Locale locale) => AppStrings._(locale.languageCode);

  String get appTitle => isEs ? 'PokeAlbo' : 'PokeAlbo';
  String get welcome => isEs ? 'BIENVENIDO' : 'WELCOME';
  String get loginSubtitle => isEs
      ? 'Ingresa tu nickname para continuar.'
      : 'Enter your nickname to continue.';
  String get online => isEs ? 'EN LÍNEA' : 'ONLINE';
  String get pvp => 'PVP';
  String get access => isEs ? 'ACCESO' : 'ACCESS';
  String get loginTitle => isEs ? 'Entrar' : 'Login';
  String get nickname => isEs ? 'Nickname' : 'Nickname';
  String get nicknameHint => isEs ? 'Ej. Ash' : 'Ex. Ash';
  String get nicknameRequired =>
      isEs ? 'Ingresa un nickname para continuar.' : 'Enter a nickname to continue.';
  String get loginButton => isEs ? 'Entrar al juego' : 'Enter the game';
  String get loginFailed =>
      isEs ? 'No se pudo iniciar sesión.' : 'Could not start the session.';
  String get chooseMove => isEs ? 'Elige tu próximo movimiento' : 'Choose your next move';
  String get activeSession => isEs ? 'SESIÓN ACTIVA' : 'ACTIVE SESSION';
  String get readyToPlay => isEs ? 'Todo listo para jugar.' : 'Everything is ready to play.';
  String get activeArena => isEs ? 'Tienes una arena activa.' : 'You have an active arena.';
  String get catalogMode => isEs ? 'Modo catálogo' : 'Catalog mode';
  String get goToBattle => isEs ? 'Ir a batalla' : 'Go to battle';
  String get resumeBattle => isEs ? 'Reanudar combate' : 'Resume battle';
  String get logout => isEs ? 'Salir' : 'Logout';
  String get logoutFailed =>
      isEs ? 'No se pudo cerrar sesión.' : 'Could not close the session.';
  String get backendHealth => isEs ? 'Salud del backend' : 'Backend health';
  String get openHealth => isEs ? 'Ver estado del servidor' : 'View server status';
  String get healthTitle => isEs ? 'Estado del backend' : 'Backend status';
  String get healthSubtitle => isEs
      ? 'Verifica desde la app si el servidor está disponible antes de entrar a batalla.'
      : 'Check from the app whether the server is available before entering battle.';
  String get refresh => isEs ? 'Actualizar' : 'Refresh';
  String get healthy => isEs ? 'Servidor en línea' : 'Server online';
  String get unhealthy => isEs ? 'Problema detectado' : 'Issue detected';
  String get healthUnavailable => isEs ? 'No se pudo consultar el estado.' : 'Could not fetch health status.';
  String get battleRoom => isEs ? 'Sala de combate' : 'Battle room';
  String get battlePaused => isEs ? 'Batalla en pausa' : 'Battle paused';
  String get reconnecting => isEs ? 'Reconectando' : 'Reconnecting';
  String get waitingOpponent => isEs ? 'Esperando al rival' : 'Waiting for opponent';
  String get battleResult => isEs ? 'Resultado final' : 'Final result';
  String get battleChip => isEs ? 'BATTLE' : 'BATTLE';
  String get connectedChip => isEs ? 'CONNECTED' : 'CONNECTED';
  String get connectingChip => isEs ? 'CONNECTING' : 'CONNECTING';
  String get offlineChip => isEs ? 'OFFLINE' : 'OFFLINE';
  String get searchingChip => isEs ? 'SEARCHING' : 'SEARCHING';
  String get matchedChip => isEs ? 'MATCHED' : 'MATCHED';
  String get battleLiveChip => isEs ? 'BATTLE LIVE' : 'BATTLE LIVE';
  String get pausedChip => isEs ? 'PAUSED' : 'PAUSED';
  String get victoryChip => isEs ? 'VICTORY' : 'VICTORY';
  String get defeatChip => isEs ? 'DEFEAT' : 'DEFEAT';
  String get inactiveChip => isEs ? 'INACTIVE' : 'INACTIVE';
  String get inQueueChip => isEs ? 'IN QUEUE' : 'IN QUEUE';
  String get rivalFoundChip => isEs ? 'RIVAL FOUND' : 'RIVAL FOUND';
  String get activeBattleChip => isEs ? 'ACTIVE BATTLE' : 'ACTIVE BATTLE';
  String get resultReadyChip => isEs ? 'RESULT READY' : 'RESULT READY';
  String get battleReadyChip => isEs ? 'BATTLE READY' : 'BATTLE READY';
  String get turnResolvedChip => isEs ? 'TURN RESOLVED' : 'TURN RESOLVED';
  String get battlePausedChip => isEs ? 'BATTLE PAUSED' : 'BATTLE PAUSED';
  String get battleIdleSubtitle => isEs
      ? 'La arena está lista. Inicia matchmaking sólo cuando quieras entrar a la cola.'
      : 'The arena is ready. Start matchmaking only when you want to enter the queue.';
  String get battleReconnectingSubtitle => isEs
      ? 'La app está intentando rehidratar tu sala o batalla desde el backend.'
      : 'The app is trying to rehydrate your lobby or battle from the backend.';
  String get battleSearchingSubtitle => isEs
      ? 'Permaneces en cola hasta encontrar un rival compatible.'
      : 'You stay in queue until a compatible rival is found.';
  String get battlePausedSubtitle => isEs
      ? 'La arena está en pausa mientras se resuelve una reconexión.'
      : 'The arena is paused while a reconnect is being resolved.';
  String get battleResultPendingSubtitle => isEs
      ? 'El backend marcó el cierre de la batalla.'
      : 'The backend marked the battle as finished.';
  String get battleResultWonSubtitle => isEs
      ? 'La arena ya resolvió el resultado a tu favor.'
      : 'The arena already resolved the result in your favor.';
  String get battleResultLostSubtitle => isEs
      ? 'La arena cerró el resultado del lado rival.'
      : 'The arena closed the result on the rival side.';
  String get searchRival => isEs ? 'Buscar rival' : 'Search rival';
  String get cancelSearch => isEs ? 'Cancelar búsqueda' : 'Cancel search';
  String get assignTeam => isEs ? 'Asignar equipo' : 'Assign team';
  String get markReady => isEs ? 'Marcar listo' : 'Mark ready';
  String get waitingRival => isEs ? 'Esperando rival' : 'Waiting rival';
  String get needTeam => isEs ? 'Necesitas equipo para continuar' : 'You need a team to continue';
  String get attack => isEs ? 'Atacar' : 'Attack';
  String get attacking => isEs ? 'Atacando...' : 'Attacking...';
  String get waitingTurn => isEs ? 'Esperando turno' : 'Waiting turn';
  String get closeResult => isEs ? 'Cerrar resultado' : 'Close result';
  String get catalogTitle => isEs ? 'Pokédex' : 'Pokédex';
  String get catalogSubtitle => isEs
      ? 'Explora el catálogo real del backend y revisa stats, tipos y sprites antes de entrar a combate.'
      : 'Explore the live backend catalog and review stats, types and sprites before battle.';
  String get loadingCatalog => isEs ? 'Cargando catálogo...' : 'Loading catalog...';
  String get catalogEmpty => isEs ? 'El catálogo llegó vacío.' : 'The catalog came back empty.';
  String get catalogErrorTitle => isEs ? 'No se pudo cargar el catálogo.' : 'Could not load the catalog.';
  String get retry => isEs ? 'Intentar de nuevo' : 'Try again';
  String get availableRoster => isEs ? 'Roster disponible' : 'Available roster';
  String get noDetail => isEs ? 'Sin detalle seleccionado.' : 'No selected detail.';
  String get battleStarted => isEs ? 'La batalla ya comenzó.' : 'The battle already started.';
  String get damageApplied => isEs ? 'Daño aplicado' : 'Damage applied';
  String get finalBlow => isEs ? 'Golpe definitivo' : 'Final blow';
  String get yourTurn => isEs ? 'TU TURNO' : 'YOUR TURN';
  String get rivalTurn => isEs ? 'TURNO RIVAL' : 'RIVAL TURN';
  String get reconnectCountdown => isEs ? 'Tiempo restante' : 'Time remaining';
  String get offlineFallback => isEs ? 'Sin datos' : 'No data';
  String get dismissKeyboardHint => isEs
      ? 'Desliza para cerrar el teclado.'
      : 'Drag to dismiss the keyboard.';
  String get battleScreenTitle => isEs ? 'Batalla activa' : 'Active battle';
  String get battleIdleTitle => isEs ? 'Sala de batalla' : 'Battle room';
  String get battleReconnectingTitle =>
      isEs ? 'Recuperando sesión' : 'Recovering session';
  String get battleSearchingTitle => isEs ? 'Buscando rival' : 'Searching rival';
  String get battleMatchedTitle => isEs ? 'Rival encontrado' : 'Rival found';
  String get battleActiveTitle => isEs ? 'Batalla activa' : 'Battle active';
  String get battleSearchingInfo => isEs
      ? 'Rival detectado. La siguiente fase asignará equipos.'
      : 'Rival detected. The next phase will assign teams.';
  String get battleSearchCancelledInfo =>
      isEs ? 'La arena volvió a espera.' : 'The arena returned to standby.';
  String get attackSentInfo => isEs
      ? 'Ataque enviado. Esperando resolución.'
      : 'Attack sent. Waiting for turn resolution.';
  String get attackRejectedInfo =>
      isEs ? 'El backend rechazó el ataque.' : 'The backend rejected the attack.';
  String get battleReadyForNewSearch => isEs
      ? 'La arena quedó lista para una nueva búsqueda.'
      : 'The arena is ready for a new search.';
  String get assigningTeams =>
      isEs ? 'Asignando equipos aleatorios...' : 'Assigning random teams...';
  String get teamAssignedInfo => isEs
      ? 'Equipo asignado. Marca listo para iniciar combate.'
      : 'Team assigned. Mark ready to start the battle.';
  String get syncingReady =>
      isEs ? 'Sincronizando ready state...' : 'Syncing ready state...';
  String get battleRecoveredWaiting => isEs
      ? 'Sala recuperada. Esperando siguiente paso.'
      : 'Lobby recovered. Waiting for the next step.';
  String get battleReturnedToQueue =>
      isEs ? 'Volviste a la cola activa.' : 'You returned to the active queue.';
  String get battleRecoveredPaused => isEs
      ? 'La batalla sigue pausada mientras se resuelve una reconexión.'
      : 'The battle is still paused while a reconnect is being resolved.';
  String get battleRecoveredActive =>
      isEs ? 'Se restauró una batalla activa.' : 'An active battle was restored.';
  String get battleArenaFreed =>
      isEs ? 'La arena quedó libre.' : 'The arena is now free.';
  String get battlePauseSelfInfo => isEs
      ? 'Tu conexión salió de la arena. Reingresa antes de que termine el contador.'
      : 'Your connection left the arena. Rejoin before the countdown expires.';
  String get battleResumedInfo =>
      isEs ? 'La batalla se reanudó.' : 'The battle resumed.';
  String get battleFinishedInfo =>
      isEs ? 'El combate terminó.' : 'The battle is finished.';
  String get socketConnectFailed =>
      isEs ? 'No se pudo conectar al socket.' : 'Could not connect to the socket.';
  String get socketConnectTimeout =>
      isEs ? 'Timeout conectando al socket.' : 'Timed out while connecting to the socket.';
  String get socketAckTimeout => isEs
      ? 'Timeout esperando respuesta del socket.'
      : 'Timed out while waiting for the socket response.';
  String get socketGenericError =>
      isEs ? 'Ocurrió un error en socket.' : 'A socket error occurred.';
  String get socketInvalidAck =>
      isEs ? 'El backend devolvió un ack inválido.' : 'The backend returned an invalid ack.';
  String get queueTimeLabel => isEs ? 'Tiempo en cola' : 'Queue time';
  String get localPlayerLabel => isEs ? 'Jugador local' : 'Local player';
  String get trainerFallback => isEs ? 'Entrenador' : 'Trainer';
  String get versusLabel => 'VS';
  String get yourPokemonLabel => isEs ? 'Tu Pokémon' : 'Your Pokemon';
  String get localSearchReadySubtitle => isEs
      ? 'Tu sesión está lista para buscar rival.'
      : 'Your session is ready to search for a rival.';
  String get localReadySubtitle =>
      isEs ? 'Listo para el siguiente paso.' : 'Ready for the next step.';
  String get localNoTeamSubtitle =>
      isEs ? 'Aún sin equipo asignado.' : 'No team assigned yet.';
  String localAssignedTeamSubtitle(int count) => isEs
      ? '$count Pokémon asignados.'
      : '$count Pokemon assigned.';
  String get readyChip => isEs ? 'READY' : 'READY';
  String get rivalLabel => isEs ? 'Rival' : 'Rival';
  String get waitingPlaceholder => isEs ? 'Esperando...' : 'Waiting...';
  String get queueOpenSubtitle =>
      isEs ? 'La cola sigue abierta.' : 'The queue is still open.';
  String get rivalReadySubtitle =>
      isEs ? 'Ya está listo.' : 'Already ready.';
  String get rivalDetectedSubtitle =>
      isEs ? 'Detectado en la sala.' : 'Detected in the lobby.';
  String get waitingActivePokemonHydration => isEs
      ? 'Esperando a que se hidraten los Pokémon activos.'
      : 'Waiting for the active Pokemon snapshots to hydrate.';
  String battleOpening(String localName, String rivalName) => isEs
      ? '$localName abre contra $rivalName.'
      : '$localName opens against $rivalName.';
  String damageSummary({
    required bool defeated,
    required int damage,
    required int remainingHp,
  }) {
    if (isEs) {
      return defeated
          ? 'El Pokémon defensor quedó fuera de combate tras recibir $damage de daño.'
          : 'El defensor recibió $damage de daño y quedó con $remainingHp PS.';
    }

    return defeated
        ? 'The defending Pokemon fainted after taking $damage damage.'
        : 'The defender took $damage damage and remained at $remainingHp HP.';
  }
  String autoSwitchSummary(String pokemonName) => isEs
      ? 'Cambio automático: $pokemonName entró al campo.'
      : 'Auto switch: $pokemonName entered the field.';
  String get selfDisconnectedTitle => isEs
      ? 'Tu conexión salió de la arena'
      : 'Your connection left the arena';
  String get selfDisconnectedBody => isEs
      ? 'La batalla seguirá en pausa hasta que la reconexión se resuelva o expire el contador.'
      : 'The battle will remain paused until the reconnect resolves or the countdown expires.';
  String get opponentDisconnectedBody => isEs
      ? 'La arena está congelada mientras el otro jugador intenta volver.'
      : 'The arena is frozen while the other player tries to come back.';
  String get waitingSnapshot => isEs
      ? 'Esperando snapshot de backend.'
      : 'Waiting for backend snapshot.';
  String hpCounter(int current, int total) =>
      isEs ? 'PS $current / $total' : 'HP $current / $total';
  String koLabel(int damage, bool ko) => ko ? 'K.O.' : '-$damage ${isEs ? 'PS' : 'HP'}';
  String battleResultTitle(bool won) =>
      won ? (isEs ? 'Ganaste la batalla' : 'You won the battle') : (isEs ? 'Perdiste la batalla' : 'You lost the battle');

  String activeBattleIntro(String? rivalNickname) {
    if (isEs) {
      return rivalNickname == null
          ? 'El combate ya está activo. Ataca sólo cuando el turno te pertenezca.'
          : 'El combate contra $rivalNickname ya está activo. Ataca sólo cuando el turno te pertenezca.';
    }

    return rivalNickname == null
        ? 'The battle is already live. Attack only when the turn belongs to you.'
        : 'The battle against $rivalNickname is already live. Attack only when the turn belongs to you.';
  }

  String matchedBattleIntro(String? rivalNickname) {
    if (isEs) {
      return 'Ya hay rival en la sala${rivalNickname == null ? '' : ': $rivalNickname'}. Asigna equipo y marca listo.';
    }

    return 'A rival is already in the lobby${rivalNickname == null ? '' : ': $rivalNickname'}. Assign your team and mark ready.';
  }

  String resultCopy({required bool won, required bool byDisconnect}) {
    if (isEs) {
      if (byDisconnect) {
        return won
            ? 'El rival no volvió a conectarse antes del límite.'
            : 'Tu sesión perdió la batalla por timeout de reconexión.';
      }

      return won
          ? 'Tu equipo cerró el combate con ventaja y aseguró la victoria.'
          : 'Tu equipo quedó sin respuesta en esta arena.';
    }

    if (byDisconnect) {
      return won
          ? 'The opponent did not return before the deadline.'
          : 'Your session lost the battle because reconnect timed out.';
    }

    return won
        ? 'Your team closed the match with the upper hand and secured the win.'
        : 'Your team ran out of answers in this arena.';
  }
}

final appStringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(appLocaleControllerProvider);
  return AppStrings.fromLocale(locale);
});
