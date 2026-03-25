# Mobile Flow Reference

Documento de referencia funcional para validar que la app mobile y el backend esten alineados.

## Objetivo

Definir:

- que debe pasar en pantalla
- que estado local debe guardar la app
- que espera el backend en HTTP y Socket.IO

## Glosario rapido

- `sessionToken`: identidad operativa de la sesion para REST y socket
- `reconnectToken`: token para recuperar lobby o batalla despues de una desconexion
- `idle`: jugador sin lobby ni batalla activa
- `searching`: jugador en matchmaking
- `matched`: lobby con dos jugadores, antes de la batalla activa
- `battling`: batalla activa
- `reconnecting`: estado temporal de UI mientras mobile intenta rehidratar lobby o batalla
- `disconnect_timeout`: cierre de batalla por exceder la tolerancia de reconexion

## Flujo 1. Login o restore de sesion

Precondiciones:

- backend disponible
- nickname libre o reclaimable

Pasos:

1. abrir la app
2. si existe sesion persistida, mobile intenta `restore`
3. si la sesion sigue viva, entra a home autenticado
4. si la sesion expiro, mobile intenta reclamar una nueva con el mismo nickname

Resultado esperado:

- no se muestran errores crudos de backend
- la app termina en `home`
- `sessionToken` y `reconnectToken` quedan persistidos

## Flujo 2. Matchmaking desde home

Precondiciones:

- sesion autenticada
- REST y Socket.IO apuntan al mismo backend

Pasos:

1. entrar a `battle`
2. tocar `Buscar rival`
3. mobile conecta socket con `auth.sessionToken`
4. mobile emite `search_match` con payload `{}`

Resultado esperado:

- la UI cambia a `searching`
- backend responde ack con `playerId`, `lobbyId`, `status`, `lobbyStatus` y `reconnectToken`
- mobile actualiza `currentLobbyId` y el `reconnectToken`

## Flujo 3. Match found y preparacion de batalla

Pasos:

1. dos jugadores hacen matchmaking
2. backend emite `match_found`
3. mobile pasa a `matched`
4. se ejecutan auto-assign y auto-ready cuando aplica
5. backend emite `battle_start`

Resultado esperado:

- el lobby se hidrata con ambos jugadores
- los equipos se asignan y el usuario ve una transicion clara
- la sesion local actualiza `currentBattleId`

## Flujo 4. Salir de battle y volver antes de 15 segundos

Precondiciones:

- batalla ya iniciada

Pasos:

1. usuario deja la pantalla o manda la app a background
2. backend pausa la batalla
3. usuario vuelve antes del deadline

Resultado esperado:

- la pantalla de battle arranca en `reconnecting`, no en `idle`
- mobile sincroniza sesion, reconstruye socket si hace falta y ejecuta `reconnect_player`
- backend responde con `battle_resume` o con estado pausado recuperable
- el usuario vuelve a la batalla sin poder disparar un `search_match` paralelo

## Flujo 5. Volver despues de 15 segundos

Pasos:

1. usuario sale de la batalla
2. backend supera la tolerancia de 15 segundos
3. backend emite `battle_end` con `reason = disconnect_timeout`
4. el usuario vuelve a la app

Resultado esperado:

- mobile no muestra `Invalid or expired session token`
- si el backend invalido la sesion, mobile la reclama de nuevo con el mismo nickname
- la home deja de mostrar `Reanudar combate`
- battle queda lista para una nueva busqueda

## Flujo 6. Desconexion idle y reclaim de nickname

Pasos:

1. usuario esta autenticado pero sin lobby ni batalla
2. el socket se cae o la app va a background
3. backend marca la sesion como desconectada
4. el usuario vuelve

Resultado esperado:

- mobile sincroniza la sesion al volver a foreground
- si el token viejo ya no sirve, se reclama una sesion nueva limpia
- la app no queda en un estado zombie con CTA obsoleto

## Flujo 7. Home CTA y estado visual

La home decide entre:

- `Ir a batalla`
- `Reanudar combate`

Reglas esperadas:

- si `currentLobbyId` o `currentBattleId` existen y siguen vivos, debe mostrarse `Reanudar combate`
- si el backend ya limpio el estado remoto, la CTA debe corregirse sin obligar a abrir `battle`
- al volver de foreground, la home debe resincronizar estado antes de perpetuar un CTA obsoleto

## Eventos backend clave a observar

- `search_match`
- `match_found`
- `lobby_status`
- `battle_start`
- `battle_pause`
- `battle_resume`
- `battle_end`

## Señales de que algo esta roto

- la pantalla de battle entra en `idle` aunque localmente siga habiendo lobby o batalla
- `Buscar rival` se habilita mientras el backend aun te considera en batalla
- la home sigue mostrando `Reanudar combate` despues de que el backend ya cerro la batalla
- el usuario ve `Invalid or expired session token`
- el socket no se reconstruye despues de cambiar el `sessionToken`
