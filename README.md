# EyeSchool

App móvil de EyeSchool construida en Flutter, con cuatro roles: **Docente**, **Estudiante**, **Padre/Acudiente** y **Administrador**. Registra la asistencia escaneando el QR del estudiante (también sin conexión), y permite consultar notas, horarios, novedades y el boletín en PDF.

## Requisitos

- Flutter estable con Dart `^3.12.2` (`flutter --version`).
- Android SDK y JDK 17 para compilar el APK.
- Un dispositivo o emulador con cámara para el escáner QR (`mobile_scanner` funciona en Android, iOS y Web, no en Windows desktop).

## Cómo correr el proyecto

```bash
flutter pub get
flutter run                 # dispositivo/emulador conectado
```

La app consume la **API de EyeSchool** (FastAPI en Azure App Service) en `/api/v1`. La URL por defecto está en [`lib/core/network/api_config.dart`](lib/core/network/api_config.dart) y se puede cambiar al compilar, por ejemplo para una API local:

```bash
flutter run --dart-define=EYESCHOOL_API_BASE=http://10.0.2.2:8000
```

Las cuentas son las que existen en la base de datos de la API; no hay usuarios simulados en la app. Desde **Registrarse**, en el login, se crea una cuenta nueva junto con el perfil de su rol.

Las notificaciones push usan Firebase Cloud Messaging (`android/app/google-services.json`). Si Firebase no inicializa, la app arranca igual y solo pierde las notificaciones.

## Calidad: análisis y pruebas

```bash
flutter analyze                         # análisis estático (flutter_lints)
flutter test --coverage                 # pruebas unitarias y de widgets
dart run tool/coverage_report.dart      # cobertura por capa (domain, data, core, presentación)
```

| Prueba | Qué verifica |
|---|---|
| `architecture_test.dart` | Las reglas de capas: el dominio no depende de Flutter, Dio ni otras capas. |
| `usecases_test.dart`, `dto_mapping_test.dart` | Casos de uso y conversión entre la API y el dominio. |
| `*_repository_test.dart` | Los repositorios de auth, académico, directorio y asistencia sobre una API simulada (`test/support/scripted_api.dart`): sesión por rol, uniones con catálogos, payloads de escritura y resolución de códigos QR sin conexión. |
| `attendance_queue_test.dart` | La cola de asistencia sin conexión: reintentos, deduplicación y fecha del escaneo. |
| `student_home_resilience_test.dart` | Que una API caída degrade la pantalla de inicio del estudiante sin cerrar la app. |
| `accessibility_test.dart` | Pautas de accesibilidad: tamaño táctil, etiquetas y contraste WCAG AA. |
| `validators_test.dart`, `app_boot_test.dart` | Validaciones de formularios y arranque de la app. |

El workflow [`ci.yml`](.github/workflows/ci.yml) ejecuta el análisis, las pruebas y la cobertura en cada pull request y en cada push a `main`. Es el punto de control QG3 del modelo de calidad (MC-01).

## Publicar una versión

1. Actualice `version:` en `pubspec.yaml` (por ejemplo `1.0.2+3`).
2. Cree y suba el tag: `git tag v1.0.2 && git push origin v1.0.2`.

El workflow [`release_apk.yml`](.github/workflows/release_apk.yml) analiza, prueba, compila el APK con la versión del tag y lo publica en GitHub Releases. Al abrir la app, `UpdateService` compara la versión instalada con la última release y ofrece descargar la nueva.

## Arquitectura

- **Por funcionalidad y por capas**: cada módulo en `lib/features/<módulo>` (`auth`, `academic`, `attendance`, `directory`, `dashboard`, `novedades`, `reports`, `notifications`) tiene `domain` (entidades puras), `data` (API, DTO e implementación del repositorio) y `presentation` (pantallas). Las interfaces de repositorio y los casos de uso están en `lib/core/domain`.
- **Estado**: Riverpod (`lib/providers`).
- **Navegación**: go_router con un shell de navegación inferior por rol y redirecciones según sesión y rol ([`app_router.dart`](lib/core/router/app_router.dart)).
- **Red**: Dio con interceptores de autenticación (renovación del token), reintentos y traducción de errores a `AppFailure` (`lib/core/network`).
- **Seguridad**: los tokens se guardan en `flutter_secure_storage` (Keystore en Android). El registro de peticiones solo existe en modo debug y oculta los datos sensibles.
- **Sin conexión**: los escaneos de asistencia se guardan primero en el dispositivo y `SyncWorker` los envía al recuperar la red, al volver a la app o cada 60 segundos.
- **Diseño**: tokens centralizados en `lib/core/theme` (colores, tipografía, tema).
