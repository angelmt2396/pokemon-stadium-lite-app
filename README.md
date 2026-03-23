# Pokemon Stadium Lite App

Aplicación mobile de `Pokemon Stadium Lite` construida con Flutter.

## Estado actual

El repo ya está inicializado como proyecto Flutter y hoy incluye:

- arquitectura base por features
- sesión con login, restore y logout
- navegación inicial con `go_router`
- tema visual alineado con la app web
- pantallas base de `home`, `catalog` y `battle`
- primera integración real con backend para el catálogo

## Stack

- Flutter
- `flutter_riverpod`
- `go_router`
- `dio`
- `socket_io_client`
- `flutter_secure_storage`
- `shared_preferences`

## Requisitos locales

### Flutter

Instala Flutter y valida el entorno:

```bash
flutter doctor -v
```

### Android

Para compilar y correr Android localmente hace falta:

- Android Studio
- Android SDK
- aceptar licencias con:

```bash
flutter doctor --android-licenses
```

Si el SDK queda en una ruta personalizada:

```bash
flutter config --android-sdk /ruta/al/android-sdk
```

### iOS / macOS

Para correr en iOS o macOS hace falta:

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

## Instalación

```bash
flutter pub get
```

## Configuración

La app consume el backend usando `--dart-define`.

Variables soportadas:

- `API_BASE_URL`
- `SOCKET_BASE_URL`

Valores por defecto:

- `http://localhost:3000`

Ejemplo contra backend local:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://localhost:3000 \
  --dart-define=SOCKET_BASE_URL=http://localhost:3000
```

Ejemplo contra backend remoto:

```bash
flutter run \
  --dart-define=API_BASE_URL=https://tu-backend.run.app \
  --dart-define=SOCKET_BASE_URL=https://tu-backend.run.app
```

## Scripts útiles

```bash
flutter analyze
flutter test
flutter run
```

## Estructura

```txt
lib/
  app/
  core/
  features/
    session/
    home/
    catalog/
    battle/
```

## Siguiente trabajo recomendado

1. completar `battle` con waiting room, sockets y reconexión
2. agregar `health`
3. expandir testing a catálogo y batalla
4. preparar builds Android/iOS
