# Pokemon Stadium Lite App

Aplicacion mobile de `Pokemon Stadium Lite` construida con Flutter.

## Estado actual

La app ya incluye:

- login por nickname
- restore y logout de sesión
- navegación con `go_router`
- home
- catálogo
- health
- battle con matchmaking, lobby, auto-assign, auto-ready y combate activo
- reconexión, pausa y resultado final
- animaciones y overlays mobile alineados con la referencia web

Validacion real en esta etapa:

- Android: sí probado
- iOS: no probado

La implementacion y el flujo actual deben considerarse validados solo para Android.

## Documentacion del proyecto

La documentacion del repo ya no vive solo en este archivo.

Mapa rapido:

- [docs/README.md](./docs/README.md)
- [docs/mobile-flows.md](./docs/mobile-flows.md)
- [docs/mobile-implementation-reference.md](./docs/mobile-implementation-reference.md)
- [docs/mobile-qa-checklist.md](./docs/mobile-qa-checklist.md)
- [docs/ui-ux-improvement-proposal.md](./docs/ui-ux-improvement-proposal.md)

Estas guias sirven para:

- validar flujos funcionales
- entender el contrato actual app-backend
- revisar decisiones de implementacion
- tener referencia de UX para nuevos cambios

## Stack

- Flutter
- `flutter_riverpod`
- `go_router`
- `dio`
- `socket_io_client`
- `flutter_secure_storage`
- `shared_preferences`

## Requisitos

### Flutter

Usa Flutter con SDK compatible con lo declarado en `pubspec.yaml`.

Valida el entorno:

```bash
flutter doctor -v
```

### Android

Para correr en Android localmente:

- Android Studio
- Android SDK
- emulador configurado

Aceptar licencias:

```bash
flutter doctor --android-licenses
```

Si el SDK está en una ruta personalizada:

```bash
flutter config --android-sdk /ruta/al/android-sdk
```

### iOS / macOS

Para iOS o macOS:

- Xcode completo
- `xcode-select`
- `xcodebuild -runFirstLaunch`
- CocoaPods

Pasos típicos:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
sudo gem install cocoapods
```

Importante:

- no se realizó validación real en iOS durante esta etapa
- el soporte efectivamente probado del proyecto actual es Android
- si se quiere publicar o cerrar iOS, hace falta una pasada específica de QA y ajuste por plataforma

## Instalación

Desde la raíz de `pokemon-stadium-lite-app`:

```bash
flutter pub get
```

## Configuración de backend

La app soporta dos variables de entorno en runtime:

- `API_BASE_URL`
- `SOCKET_BASE_URL`

Se pasan con `--dart-define`.

### Comportamiento por defecto

Si no mandas `--dart-define`, la app usa defaults por plataforma:

- Android Emulator: `http://10.0.2.2:3000`
- Web / iOS Simulator / macOS: `http://localhost:3000`

Esto existe para que el emulador Android pueda hablar con el backend local de tu máquina sin depender de una IP LAN cambiante.

## Contrato operativo actual

El comportamiento actual de mobile contra backend se apoya en estas reglas:

- `sessionToken` es la identidad operativa de REST y Socket.IO
- el socket debe conectarse con `auth.sessionToken`
- `search_match` se emite con payload `{}` y el backend resuelve la identidad del jugador desde la sesion autenticada
- el `reconnectToken` del ack de matchmaking debe persistirse y reutilizarse en `reconnect_player`
- si el backend expira o rota el `sessionToken`, la app debe reconstruir la sesion y el socket con el nuevo token
- si la sesion local sigue marcando lobby o batalla activa, mobile entra en modo `reconnecting` al abrir la pantalla de battle
- al volver de background/foreground, la app sincroniza sesion para corregir CTAs, sesiones reclamadas, lobby activo y batalla pausada
- mientras exista un lobby o batalla activa local, la app hace sincronizacion silenciosa de sesion para evitar estado visual obsoleto

Referencia complementaria:

- backend: `pokemon-stadium-lite-backend/docs/socket-contracts.md`
- mobile: [docs/mobile-implementation-reference.md](./docs/mobile-implementation-reference.md)

## Cómo correr contra backend local

### Android Emulator

```bash
flutter run
```

También puedes dejarlo explícito:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:3000 \
  --dart-define=SOCKET_BASE_URL=http://10.0.2.2:3000
```

### iOS Simulator / macOS

```bash
flutter run \
  --dart-define=API_BASE_URL=http://localhost:3000 \
  --dart-define=SOCKET_BASE_URL=http://localhost:3000
```

Nota:

- esta ruta queda documentada por completitud técnica
- no fue validada en esta etapa

### Dispositivo físico

En dispositivo físico `localhost` no apunta a tu máquina.  
Debes usar la IP de tu red local:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://192.168.x.x:3000 \
  --dart-define=SOCKET_BASE_URL=http://192.168.x.x:3000
```

## Cómo correr contra backend productivo

Backend productivo actual:

- [https://pokemon-albo-backend-199595569982.us-central1.run.app/](https://pokemon-albo-backend-199595569982.us-central1.run.app/)

Ejemplo:

```bash
flutter run \
  --dart-define=API_BASE_URL=https://pokemon-albo-backend-199595569982.us-central1.run.app \
  --dart-define=SOCKET_BASE_URL=https://pokemon-albo-backend-199595569982.us-central1.run.app
```

## APK listo para probar

El repositorio incluye un APK release ya generado y listo para usarse:

- `app-release.apk`

Consideraciones:

- corresponde al flujo Android validado
- está pensado para probar la app sin compilar localmente
- si se genera un nuevo release, ese archivo debe actualizarse para que el repo siga reflejando la versión más reciente

## Consideraciones importantes

### 1. Socket.IO usa la misma base URL

La app separa `API_BASE_URL` y `SOCKET_BASE_URL`, pero normalmente ambos deben apuntar al mismo backend.

### 2. Android Emulator no usa `localhost`

Dentro del emulador Android:

- `localhost` es el emulador
- `10.0.2.2` es tu máquina host

### 3. Dispositivo físico no usa `10.0.2.2`

`10.0.2.2` sólo funciona en Android Emulator.  
En dispositivo físico necesitas:

- IP LAN de tu máquina
- o backend público

### 4. Soporte validado actual

El soporte validado actualmente es:

- Android Emulator
- Android físico cuando apunte al backend correcto

iOS no se considera cerrado ni validado todavía.

### 5. Un `401` en sesion suele significar sesion expirada

La app limpia sesion invalida restaurada, puede reclamar una sesion nueva con el mismo nickname si el backend invalido el token anterior y normaliza errores HTTP/socket para no mostrar `DioException` crudo.

### 6. El backend debe soportar HTTP y Socket.IO

Para que battle funcione bien, el backend debe exponer:

- REST de sesión y catálogo
- canal Socket.IO de matchmaking y battle

### 7. La presencia de socket ya importa para UX

Con el backend actual, el socket ya no es un detalle secundario:

- si el socket se cae estando `idle`, la sesion puede quedar reclamable
- si el socket se cae en batalla, el backend pausa la batalla y aplica una ventana de tolerancia
- la UI debe reflejar `reconnecting`, `paused`, `battle_end` y cambios de sesion sin depender de un refresh manual

## Comandos útiles

### Análisis y tests

```bash
flutter analyze
flutter test
```

### Correr la app

```bash
flutter run
```

### Elegir dispositivo

```bash
flutter devices
flutter run -d <device-id>
```

## Flujos recomendados de prueba

### Smoke test básico

1. abrir app
2. login por nickname
3. entrar a catálogo
4. volver a home
5. entrar a battle
6. buscar rival

### Flujo completo de battle

1. login
2. battle
3. matchmaking
4. match encontrado
5. auto-assign
6. auto-ready
7. battle start
8. ataque
9. resultado final

### Reconexión

1. entrar a una batalla activa
2. provocar pérdida temporal de conexión
3. validar pausa
4. reconectar antes del deadline
5. validar `battle_resume`

Todas estas pruebas corresponden al flujo Android validado.

Checklists y flujos mas detallados:

- [docs/mobile-flows.md](./docs/mobile-flows.md)
- [docs/mobile-qa-checklist.md](./docs/mobile-qa-checklist.md)

## Estructura

```txt
lib/
  app/
    app.dart
    router/
    theme/
  core/
    config/
    i18n/
    network/
    socket/
    theme/
    widgets/
  features/
    session/
    home/
    catalog/
    health/
    battle/
test/
```

## Archivos clave

- `lib/core/config/app_config.dart`
- `lib/core/network/api_client.dart`
- `lib/core/network/network_error.dart`
- `lib/core/socket/socket_client.dart`
- `lib/features/session/`
- `lib/features/battle/`

Referencia ampliada:

- [docs/mobile-implementation-reference.md](./docs/mobile-implementation-reference.md)

## Troubleshooting

### No conecta al backend local en Android Emulator

Verifica que estés usando:

- `http://10.0.2.2:3000`

No:

- `http://localhost:3000`

### No conecta desde dispositivo físico

Verifica:

- que el backend escuche fuera de `localhost` si aplica
- que tu firewall permita conexiones
- que app y backend estén en la misma red
- que uses la IP LAN correcta

### Sale `401` en login/logout

Posibles causas:

- sesion vieja persistida
- token inválido
- backend reiniciado y la sesion ya no existe
- token invalidado por `disconnect_timeout`
- sesion reclamada desde otra instancia despues de una desconexion `idle`

Prueba:

- cerrar y abrir la app
- volver a iniciar sesion
- revisar si el socket y REST apuntan al mismo entorno

### Matchmaking o battle no avanzan

Verifica:

- que REST y Socket.IO apunten al mismo backend
- que el backend esté emitiendo `match_found`, `lobby_status` y `battle_start`
- que el otro cliente esté conectado al mismo entorno
- que el cliente haya persistido el `reconnectToken`
- que el socket se haya reconstruido si cambio el `sessionToken`

## Backend relacionado

Si necesitas correr el backend local, revisa:

- el `README.md` del proyecto `pokemon-stadium-lite-backend`
- `pokemon-stadium-lite-backend/docs/socket-contracts.md`
