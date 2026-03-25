# Mobile QA Checklist

Checklist manual orientado a Android.

## Preparacion

- backend REST y Socket.IO apuntando al mismo entorno
- dos dispositivos o dos emuladores disponibles
- build reciente de mobile
- logs del backend accesibles si se quiere corroborar eventos

## Smoke

- [ ] abrir app
- [ ] login con nickname valido
- [ ] ver home sin errores crudos
- [ ] entrar a catalogo
- [ ] entrar a health
- [ ] entrar a battle

## Sesion

- [ ] restore de sesion al relanzar app
- [ ] logout limpio desde home
- [ ] un `401` no deja la app en estado roto
- [ ] una sesion expirada puede recuperarse sin mostrar `DioException`

## Matchmaking

- [ ] dos usuarios pueden hacer `search_match`
- [ ] el primer usuario queda en `searching`
- [ ] al llegar el segundo usuario ambos ven `match_found`
- [ ] se persiste `reconnectToken` despues del ack exitoso

## Lobby y preparacion

- [ ] auto-assign ocurre cuando corresponde
- [ ] auto-ready ocurre cuando corresponde
- [ ] si no aplica automatizacion, la UI manual funciona
- [ ] `battle_start` actualiza `currentBattleId`

## Reconexion antes de 15 segundos

Pasos:

1. iniciar batalla
2. mandar una app a background o salir de la pantalla
3. volver antes de 15 segundos

Esperado:

- [ ] la pantalla entra en `reconnecting`
- [ ] no se habilita `Buscar rival`
- [ ] battle vuelve a hidratarse
- [ ] el oponente ve pausa y luego reanudacion

## Disconnect timeout despues de 15 segundos

Pasos:

1. iniciar batalla
2. mandar una app a background mas de 15 segundos
3. dejar al rival conectado
4. volver con el jugador desconectado

Esperado:

- [ ] backend cierra la batalla con `disconnect_timeout`
- [ ] mobile no muestra `Invalid or expired session token`
- [ ] la sesion se recupera o reclama limpiamente
- [ ] home deja de mostrar `Reanudar combate`
- [ ] battle queda lista para nueva busqueda

## Home CTA

- [ ] si hay lobby o batalla viva, muestra `Reanudar combate`
- [ ] si el backend ya limpio el estado, cambia a `Ir a batalla`
- [ ] el CTA se corrige al volver de foreground

## Idle disconnect y reclaim

Pasos:

1. dejar usuario autenticado en home
2. mandar la app a background
3. volver despues de un rato

Esperado:

- [ ] la sesion no queda zombie
- [ ] si el backend reclamo el nickname, la app recupera una sesion valida
- [ ] la home no queda con CTA vieja

## Error handling

- [ ] no se muestran mensajes crudos de `DioException`
- [ ] no se muestran mensajes tecnicos de socket sin sanear
- [ ] conflictos de backend se traducen a mensajes utiles

## Visual y UX

- [ ] `reconnecting` se entiende sin leer logs
- [ ] `paused` se distingue de `idle`
- [ ] `result` se distingue de `battle active`
- [ ] no hay acciones habilitadas en estados donde el backend no las aceptaria

## Evidencia sugerida

- capturas de home antes y despues de timeout
- captura de battle en `reconnecting`
- logs backend con `battle_pause`, `battle_resume` o `battle_end`
- video corto del flujo de foreground/background
