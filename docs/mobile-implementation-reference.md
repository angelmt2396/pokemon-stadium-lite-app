# Mobile Implementation Reference

Referencia tecnica para tocar mobile sin romper sesion, socket ni battle.

## Capas principales

### Session

Responsabilidad:

- login
- restore
- persistencia local
- sincronizacion silenciosa
- recuperacion de sesion expirada

Archivos principales:

- `lib/features/session/presentation/session_controller.dart`
- `lib/features/session/data/session_repository.dart`
- `lib/features/session/data/session_api_client.dart`
- `lib/features/session/data/session_local_data_source.dart`

### Network

Responsabilidad:

- cliente HTTP
- normalizacion de errores

Archivos principales:

- `lib/core/network/api_client.dart`
- `lib/core/network/network_error.dart`

### Socket

Responsabilidad:

- handshake autenticado
- conexion por `sessionToken`
- acks de matchmaking y battle

Archivos principales:

- `lib/core/socket/socket_client.dart`
- `lib/core/socket/socket_events.dart`
- `lib/features/battle/data/battle_socket_client.dart`

### Battle

Responsabilidad:

- bootstrap de lobby/batalla
- rehidratacion por `reconnectToken`
- manejo de estados `idle`, `searching`, `matched`, `battling`, `reconnecting`, `result`

Archivos principales:

- `lib/features/battle/presentation/battle_controller.dart`
- `lib/features/battle/presentation/battle_screen.dart`
- `lib/features/battle/presentation/battle_ui_state.dart`

## Reglas operativas

## 1. El socket depende del `sessionToken`

- el socket se crea con `auth.sessionToken`
- si cambia el `sessionToken`, el cliente de socket debe reconstruirse
- no se debe reutilizar un socket autenticado con un token viejo

## 2. `reconnectToken` es parte del estado de sesion

- llega desde `search_match`
- debe persistirse con la sesion
- se usa para `reconnect_player`
- si se pierde, no se puede rehidratar lobby o batalla de forma correcta

## 3. La sesion local no es suficiente por si sola

- puede quedar obsoleta si el backend invalida la sesion
- puede quedar obsoleta si la batalla termina remotamente
- puede quedar obsoleta si el socket cae estando `idle`

Por eso la app hace:

- `restore()` al arrancar
- sincronizacion silenciosa cuando hay lobby o batalla activa
- sincronizacion al volver a foreground

## 4. La pantalla de battle no debe arrancar optimista

Si la sesion local aun tiene `currentLobbyId` o `currentBattleId`:

- la pantalla debe entrar en `reconnecting`
- no debe habilitar `search_match`
- debe intentar rehidratar antes de permitir acciones manuales

## 5. Los errores de backend nunca deben renderizarse crudos

Usar siempre:

- `normalizeNetworkError(...)`

No usar:

- `error.toString()` directo
- mensajes de `DioException` sin sanear

## Sesion y lifecycle

Comportamiento actual:

- `SessionController` sincroniza sesion al volver a foreground
- si localmente existe lobby o batalla activa, tambien mantiene polling silencioso
- si `GET /player-sessions/me` responde sesion expirada, `SessionRepository` intenta reclamar una sesion nueva con el mismo nickname

Impacto UX:

- la home corrige CTAs sin requerir navegacion manual
- battle puede arrancar en `reconnecting`
- la app evita quedarse con tokens rotos

## Battle bootstrap

El `BattleController` hace bootstrap bajo estas condiciones:

- cuando cambia el `sessionToken`
- cuando entra a pantalla con una sesion que ya tiene lobby o batalla activa
- cuando la app vuelve a foreground y la batalla necesita rehidratacion

Orden de prioridad:

1. sincronizar sesion
2. detectar si sigue habiendo lobby o batalla
3. reconstruir socket si el token cambio
4. ejecutar `reconnect_player` con `reconnectToken`

## Checklist para cualquier cambio de implementacion

Antes de cambiar sesion, socket o battle verifica:

- se mantiene `auth.sessionToken` en el handshake
- `search_match` sigue usando payload `{}`
- `reconnect_player` sigue usando `reconnectToken`
- un cambio de `sessionToken` invalida el socket anterior
- al volver de foreground no se rompe el estado de home o battle
- no reaparecen mensajes crudos tipo `Invalid or expired session token`

## Cambios que requieren especial cuidado

- refactors de `SessionController`
- refactors de `BattleController`
- cualquier cambio de persistencia local
- cualquier cambio de lifecycle
- cualquier ajuste visual que vuelva a habilitar acciones durante `reconnecting`

## Fuente de verdad

Fuente de verdad funcional:

- backend `socket-contracts.md`

Fuente de verdad de implementacion mobile:

- los archivos listados arriba
- esta guia
