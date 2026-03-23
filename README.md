# Pokemon Stadium Lite App

Aplicación mobile de `Pokemon Stadium Lite` construida con Flutter.

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

Validación real en esta etapa:

- Android: sí probado
- iOS: no probado

La implementación y el flujo actual deben considerarse validados sólo para Android.

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

### 5. Un `401` en sesión suele significar sesión expirada

La app limpia sesión inválida restaurada y normaliza los errores HTTP de login/logout para no mostrar `DioException` crudo.

### 6. El backend debe soportar HTTP y Socket.IO

Para que battle funcione bien, el backend debe exponer:

- REST de sesión y catálogo
- canal Socket.IO de matchmaking y battle

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
- `lib/features/session/`
- `lib/features/battle/`

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

- sesión vieja persistida
- token inválido
- backend reiniciado y la sesión ya no existe

Prueba:

- cerrar y abrir la app
- volver a iniciar sesión

### Matchmaking o battle no avanzan

Verifica:

- que REST y Socket.IO apunten al mismo backend
- que el backend esté emitiendo `match_found`, `lobby_status` y `battle_start`
- que el otro cliente esté conectado al mismo entorno

## Backend relacionado

Si necesitas correr el backend local, revisa:

- el `README.md` del proyecto `pokemon-stadium-lite-backend`
