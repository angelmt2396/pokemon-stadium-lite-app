# UI UX Improvement Proposal

Propuesta de mejora visual y de experiencia para la app mobile, alineada con el lenguaje actual:

- base clara
- gradientes navy
- acentos cyan y amber
- tarjetas flotantes con look tipo panel de juego

## Objetivo

Hacer que la app se sienta:

- mas clara en estados de sesion y conectividad
- mas confiable durante reconexion
- mas emocionante durante battle
- mas consistente entre home, lobby y combate

## Hallazgos sobre la experiencia actual

Fortalezas:

- el look ya tiene identidad propia
- el hero card de home se siente consistente con el tono del juego
- battle ya tiene overlays y estados diferenciados

Oportunidades:

- el estado de sesion vive demasiado en el backend y no siempre se traduce visualmente de inmediato
- `home` depende de un CTA que cambia semantica sin suficiente contexto
- `reconnecting` y `paused` todavia pueden sentirse tecnicos en vez de narrativos
- falta una nocion mas visible de presencia, socket y continuidad de partida

## Principios de diseno propuestos

1. No esconder estados criticos.
   Si la partida esta viva, pausada o recuperandose, debe verse en la primera pantalla util.

2. La accion principal debe ser unica y obvia.
   Home no deberia mostrar dos acciones equivalentes sin contexto adicional.

3. Reconexion no debe sentirse como error.
   Debe verse como un proceso controlado con progreso y expectativa clara.

4. El usuario debe entender por que no puede actuar.
   Si `Buscar rival` no aplica, la UI debe explicar por que, no solo deshabilitar.

## Mejoras prioritarias

## P1. Hero de home como panel de estado vivo

Problema actual:

- la home muestra `Reanudar combate` o `Ir a batalla`, pero no explica bien el origen de ese estado

Mejora:

- convertir el hero principal en un `Arena Status Card`
- estados del hero:
  - `ready`
  - `searching`
  - `matched`
  - `battle live`
  - `paused`
  - `reconnecting`
  - `result ready`

Contenido minimo:

- nombre del jugador
- estado remoto/local reconciliado
- CTA principal unica
- subtitulo explicativo
- countdown si existe deadline de reconexion

Impacto:

- reduce confusion de CTA
- hace visible el estado de sesion sin obligar a entrar a battle

## P1. Reconnecting como experiencia dedicada

Problema actual:

- `reconnecting` existe, pero todavia comparte demasiada estructura con un estado comun

Mejora:

- agregar panel central o overlay de reconexion con:
  - titulo fuerte
  - subtitulo en lenguaje humano
  - spinner o pulso animado
  - countdown de tolerancia si aplica
  - lista corta de estados: `sincronizando sesion`, `reconstruyendo socket`, `recuperando batalla`

Impacto:

- mejora claridad
- evita que el usuario interprete el estado como congelamiento

## P1. CTA con contexto y razon

Problema actual:

- botones pueden quedar deshabilitados sin suficiente explicacion contextual

Mejora:

- debajo del CTA principal, agregar una `reason line`
- ejemplos:
  - `Esperando respuesta del backend`
  - `La partida sigue activa en otro estado`
  - `La arena esta recuperando tu sesion`

Impacto:

- menos frustracion
- menos acciones repetidas

## P2. Continuidad visual entre lobby y batalla

Problema actual:

- el salto entre matchmaking, lobby y batalla puede sentirse mas funcional que cinematografico

Mejora:

- usar una banda superior persistente con:
  - avatar local
  - VS
  - avatar rival
  - estado del enfrentamiento

- mantener esa banda desde `matched` hasta `result`

Impacto:

- mas sensacion de continuidad
- menos reorientacion cognitiva al cambiar de etapa

## P2. Resultado final con mejor cierre

Problema actual:

- el resultado existe, pero puede sentirse demasiado operativo

Mejora:

- `Victory` y `Defeat` con layout dedicado
- microresumen:
  - causa del cierre
  - quien gano
  - si hubo `disconnect_timeout`
- CTA principal:
  - `Nueva busqueda`
- CTA secundaria:
  - `Volver a home`

Impacto:

- mejor cierre emocional
- mas claridad del por que termino la partida

## P2. Health y catalogo como soporte tactico

Mejora para home:

- health card con estados mas expresivos y menor peso visual que el CTA principal
- catalogo como modo de preparacion, con copy mas tactico

Mejora para catalogo:

- comparativa rapida de stats
- chips de riesgo o rol
- persistencia del ultimo Pokemon revisado

## P3. Pulido visual

Recomendaciones concretas:

- usar un sistema de gradientes por estado, no uno solo para todo
- reforzar la semantica de color:
  - cyan para sistema y sync
  - amber para accion y espera
  - green para exito
  - rose para derrota o riesgo
- introducir una animacion corta de entrada por pantalla, no microanimacion generica en cada control
- agregar haptics suaves en:
  - match found
  - battle start
  - reconnect success
  - result

## Mejoras de copy

Evitar:

- mensajes tecnicos
- estados ambiguos
- textos demasiado similares entre `idle`, `paused` y `reconnecting`

Preferir:

- `Tu batalla sigue viva. Recuperando conexion...`
- `Tu rival sigue esperando. Vuelve antes de que termine el contador.`
- `La batalla termino por desconexion. Ya puedes iniciar una nueva busqueda.`

## Recomendacion de rollout

Fase 1:

- hero de home con estado vivo
- reconnecting dedicado
- CTA con razon contextual

Fase 2:

- continuidad visual lobby-battle-result
- resultado final mas expresivo

Fase 3:

- polish de motion, haptics y comparativas de catalogo

## KPI cualitativos sugeridos

- menos taps redundantes en `Buscar rival`
- menos confusion al volver de background
- menos reportes de "la app dice una cosa y el backend otra"
- mejor comprension del estado actual sin abrir battle
