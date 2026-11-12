# Planeación de correcciones — App móvil (Flutter) · Eyes School

> **Tipo de documento:** planeación de QA. No contiene el código de las correcciones: define qué cambiar, dónde, con qué diseño para que quede testeable y qué pruebas lo demuestran.
> **Pensado para:** cualquier desarrollador o una IA que no conoce el proyecto. Todas las rutas y números de línea se verificaron contra el código el 28/10/2026.
> **Elaboró:** Mariana Cortés (QA) · **Revisa:** Samuel Sierra (líder de pruebas) · **Aprueba:** Sergio Gómez (PO)
> **Plazo:** sprints S7 (29 oct – 6 nov 2026) y S8 (7 – 14 nov 2026). Liberación `v1.1.0` el 14 nov 2026.
> **Nota:** las 110 pruebas de la app no se pudieron ejecutar en esta revisión porque el entorno no tiene Flutter. La última corrida registrada es la del MC-01 (25/10/2026: 110 de 110). Antes de empezar, confirmarla con `flutter test`.

---

## 1. Contexto técnico

| Dato | Valor |
|---|---|
| Repositorio | `github.com/AndresFelipeAceroLopez/eyes_school_app_movil` |
| Rama base | `chore/modelo-calidad` (25 oct 2026). `main` es del 8 sep 2026 y no tiene los módulos de docente, estudiante ni padre |
| Stack | Flutter, Dart 3.12, Riverpod 2.6 (estado), go_router 14 (rutas), Dio 5.7 (HTTP), flutter_secure_storage (tokens), shared_preferences vía `LocalStore` (cola sin conexión), mobile_scanner y qr_flutter (QR), firebase_messaging (push), open_filex y share_plus (PDF) |
| Plataforma | Android. Según el PR-01: emulador mínimo API 30, emulador intermedio Android 13 (API 33) y POCO X7 con Android 15 (API 35) |
| API | `lib/core/network/api_config.dart`: `String.fromEnvironment('EYESCHOOL_API_BASE')`, por defecto la API de producción en Azure; se le agrega `/api/v1` |
| CI | `.github/workflows/ci.yml`: `dart format`, `flutter analyze`, `flutter test --coverage`, `dart run tool/coverage_report.dart --min-logic=75` |
| Producción | API en Azure App Service, base PostgreSQL en Render; Redis se elimina del sistema (BE-17), sin cambios para la app |
| Distribución | `.github/workflows/release_apk.yml` publica el APK en GitHub Releases al crear una etiqueta `v*`; `lib/core/services/update_service.dart` lo ofrece como actualización OTA |

### 1.1 Arquitectura limpia (obligatoria)

Cada `lib/features/<módulo>/` tiene tres capas:

| Capa | Qué va ahí | Regla |
|---|---|---|
| `domain/` | Entidades y reglas | Dart puro: no importa Flutter, Dio ni Firebase |
| `data/` | `*_api.dart`, DTOs con `fromJson`/`toJson`, `*_repository_impl.dart` | Único lugar que llama a la API |
| `presentation/` | Pantallas y widgets | Leen datos por providers de Riverpod; sin lógica de negocio |

- Lo transversal está en `lib/core/`: `network/` (cliente Dio e interceptores de autenticación, error y reintento), `router/app_router.dart` (rutas por rol), `utils/validators.dart`, `domain/`, `sync/`, `storage/` y `services/`.
- Los providers que conectan todo están en `lib/providers/` (`repository_providers.dart`, `session_provider.dart`, `data_providers.dart`).
- `test/architecture_test.dart` verifica la regla de capas en cada PR.

### 1.2 Cómo se prueba hoy

- 110 pruebas en `test/`: repositorios, validadores, mapeo de DTO, cola de asistencia, resiliencia del inicio del estudiante, accesibilidad y arquitectura.
- Dobles listos en `test/support/`:
  - `scripted_api.dart` → `ScriptedAdapter`, un adaptador de Dio que responde desde un guion por ruta, sin red.
  - `memory_store.dart` → almacenamiento en memoria.
- No existe la carpeta `integration_test/`, aunque el PR-01 la usa para las pruebas de sistema.

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test --coverage
dart run tool/coverage_report.dart --min-logic=75
```

### 1.3 Patrón para que cada corrección quede testeable

1. La regla va en `domain/` o `core/domain/` como función pura.
2. Los datos llegan por un repositorio de `data/`. En las pruebas, Dio usa `ScriptedAdapter`.
3. La pantalla se prueba con `ProviderScope(overrides: [...])`, reemplazando repositorios o estado.
4. Lo que hoy se crea adentro de una clase (por ejemplo `FirebaseMessaging.instance`) pasa a llegar por el constructor.

---

## 2. Resumen de hallazgos

| ID | Severidad | Hallazgo | Sprint | Responsable | Antes |
|---|---|---|---|---|---|
| APP-01 | Alta | El APK de release se firma con la clave de depuración del CI y el `applicationId` es `com.example.eyes_school`: la actualización OTA no se puede instalar sobre la versión anterior | S7 | Andrés Acero | nuevo |
| APP-02 | Media | El `minSdk` no está fijado (usa el valor por defecto de Flutter) y no coincide con lo que dice el PR-01 | S7 | Andrés Acero | nuevo |
| APP-03 | Alta | La app solo maneja un hijo por padre | S8 | Mariana Cortés | COR-10 |
| APP-04 | Alta | La contraseña nueva solo exige 8 caracteres | S7 | Mariana Cortés | COR-09 |
| APP-06 | Media | El correo no se pasa a minúsculas al iniciar sesión, registrarse ni recuperar contraseña | S7 | Mariana Cortés | nuevo |
| APP-07 | Baja | El token de notificaciones se imprime en el log, también en release; el actualizador apunta al nombre viejo del repositorio | S8 | Andrés Acero | nuevo |
| APP-INF-1 | Alta | SonarQube Cloud y `gitleaks` en el CI | S7 | Samuel Sierra | COR-14 |
| APP-INF-2 | Media | Pruebas de sistema en dispositivo con `integration_test` | S8 | Samuel Sierra | — |
| APP-08 | Alta | La app nunca envía su token de notificaciones a la API (depende de BE-18) | S8 | Andrés Acero | COR-15 |

**Comportamiento por diseño (no es defecto):** el registro permite que cualquier persona se registre como padre o acudiente y quede vinculada al estudiante que indique (`register_screen.dart`, líneas 513–514; `auth_dto.dart`, líneas 81–82). Es el objetivo del registro (decisión del PO del 30/10/2026). Antes figuraba como APP-05 y se retiró. Se prueba como funcionalidad: el padre registrado inicia sesión y ve los datos de su hijo vinculado.

**Dependencias del backend que la app debe verificar en el POCO X7:**

| Backend | Qué cambia para la app | Qué verificar |
|---|---|---|
| BE-03 | Hoy `GET /dashboard/estudiante` responde 500 siempre. La app lo usa en el inicio del estudiante (`dashboard_api.dart`, línea 16), que por eso muestra el estado de error con reintentar | Tras la corrección, el inicio del estudiante carga datos |
| BE-06 | La API rechazará notas mayores a 5.0 | `grade_entry_screen.dart` ya valida 0.0–5.0; confirmar que un 422 se muestra bien |
| BE-08 | La API responderá 409 a entradas o salidas duplicadas | `attendance_queue.dart` ya trata el 409 como entregado y lo marca «Duplicado»; probar en modo avión |
| BE-10 | La API ignorará `registrado_por` | Se puede dejar de enviar; no rompe nada |
| BE-13 | Una cuenta desactivada ya no podrá renovar el token | El interceptor de autenticación debe cerrar sesión y llevar al login con un mensaje claro |
| BE-16 | El sexto intento fallido de inicio de sesión responderá 429 | La pantalla de login debe mostrar «Demasiados intentos, espera 15 minutos» |
| BE-08 (salida sin entrada) | Una salida sin entrada previa ese día responderá 400 «No hay entrada registrada hoy para este estudiante» (decisión del PO del 30/10/2026) | La cola debe mostrar ese mensaje y no reintentar el registro para siempre; probar en el POCO X7 |
| BE-19 | El boletín de un estudiante sin notas responderá 404 con «No hay datos disponibles para generar el boletín.» | `report_card_download.dart` ya muestra el mensaje de `AppFailure` (línea 72); confirmar que aparece el texto exacto |

---

## 3. Correcciones

### APP-01 · Firma de release e identificador de la app — Alta

**Evidencia.**
- `android/app/build.gradle.kts`, línea 34: el build de release usa `signingConfig = signingConfigs.getByName("debug")`.
- `release_apk.yml` (líneas 43–46) compila en un runner nuevo de GitHub cada vez. Cada runner genera **su propia** clave de depuración, así que cada versión publicada queda firmada con una clave distinta.
- Android no instala una actualización con otra firma («App no instalada»). La actualización OTA de `update_service.dart`, que el MC-01 mide con meta de 100 %, falla.
- Línea 21: `applicationId = "com.example.eyes_school"`, un identificador de plantilla que Google Play no acepta.

**Diseño:**
- Crear una clave de release una sola vez (`keytool -genkey ... -keystore eyes-school-release.jks`), guardarla fuera del repositorio y cargarla en GitHub Secrets: `RELEASE_KEYSTORE_BASE64`, `RELEASE_KEYSTORE_PASSWORD`, `RELEASE_KEY_ALIAS`, `RELEASE_KEY_PASSWORD`.
- `release_apk.yml` decodifica la clave a un archivo temporal y genera `android/key.properties`. `build.gradle.kts` define `signingConfigs.create("release")` leyendo `key.properties` y la usa en `buildTypes.release`. Si `key.properties` no existe (build local), cae a la de depuración con una advertencia.
- **Decisión del PO (D-A1):** `applicationId` definitivo, por ejemplo `co.edu.eyesschool.app`.
- Cambiar la firma o el identificador obliga a **desinstalar e instalar una vez** las copias actuales. Hacerlo ahora, antes de entregar al colegio, y avisarlo en el manual de usuario (MN-02).

**Por qué queda verificable en CI:** la firma se compara de forma automática.

| Verificación | Dónde | Resultado esperado |
|---|---|---|
| Huella de la firma | Paso nuevo en `release_apk.yml`: `apksigner verify --print-certs` contra el secreto `RELEASE_CERT_SHA256` | Coincide; si no, el job falla |
| Identificador | Mismo paso, con `aapt dump badging` | `package: name='<applicationId acordado>'` |
| Actualización real | Caso manual del PR-06 en el POCO X7 | Con v1.1.0 instalada, publicar v1.1.1 de prueba y actualizar desde el aviso de la app sin desinstalar |

---

### APP-02 · `minSdk` sin fijar — Media

**Evidencia.**
- `android/app/build.gradle.kts`, línea 24: `minSdk = flutter.minSdkVersion`, el valor por defecto de la versión de Flutter instalada.
- El PR-01 prueba desde la API 30. Si Flutter permite una versión menor, la app se instala en teléfonos que nadie probó.

**Diseño:**
- **Decisión del PO (D-A2):** la versión mínima soportada. 30 es lo que dice el PR-01; si el colegio tiene teléfonos más viejos, bajarla y agregar ese emulador a la matriz de pruebas.
- Fijar el valor explícito en `build.gradle.kts` (`minSdk = 30` o el acordado) y documentarlo en el README y en el PR-01.

| Verificación | Resultado esperado |
|---|---|
| `aapt dump badging app-release.apk \| grep sdkVersion` en el CI | Muestra el valor acordado |
| Instalación en un emulador una versión por debajo | Android rechaza la instalación |

---

### APP-03 · Un solo hijo por padre — Alta (depende de BE-07)

**Evidencia.**
- `AuthRepositoryImpl` (`lib/features/auth/data/auth_repository_impl.dart`, líneas 150–189) llama `PeopleApi.guardianMe()` → `GET /padres/me` (`people_api.dart`, línea 150) y arma `AppSession` con un solo `childId`, `childName`, `childDocument` y `courseId`.
- `AppSession` (`lib/features/auth/domain/session.dart`, línea 39) tiene un único `childId`.
- `ChildrenScreen` (`children_screen.dart`, líneas 16–20) y `parent_home_screen.dart` (línea 18) asumen un hijo por cuenta.
- `parent_grades_screen.dart` (línea 31) y `parent_attendance_screen.dart` (línea 20) leen `session.childId`.

**Diseño:**
- **Domain:** entidad `LinkedChild` (`id`, `name`, `document`, `relationship`, `courseId`) en `lib/features/directory/domain/`. `AppSession` guarda `children: List<LinkedChild>` y mantiene el getter `childId` para no romper el resto del código.
- **Data:** `PeopleApi.guardianChildren()` → `GET /padres/me/hijos`; `HijoDto` y su mapper en `people_dto.dart`. `AuthRepositoryImpl` usa este método en lugar de `guardianMe()`.
- **Estado:** `activeChildProvider` en `lib/providers/session_provider.dart` guarda el id elegido (por defecto el primero). Las pantallas de padre leen de ahí.
- **Presentación:** `ChildrenScreen` lista los hijos cuando hay dos o más; al tocar uno actualiza `activeChildProvider`. Con uno solo se ve igual que hoy.
- `DashboardApi.guardian()` envía `?id_estudiante=<hijo activo>` a `/dashboard/padre`.

| Prueba | Archivo | Resultado esperado |
|---|---|---|
| Mapeo | `test/dto_mapping_test.dart` | JSON de `/padres/me/hijos` con 2 elementos → 2 `LinkedChild` |
| Sesión | `test/auth_repository_test.dart` (`ScriptedAdapter`) | La sesión tiene 2 hijos y `childId` es el primero |
| Sin hijos | idem | La sesión se crea; las pantallas muestran «Sin estudiante vinculado» (texto que ya existe) |
| Cambio de hijo | prueba de widget de `ChildrenScreen` | Al tocar el segundo hijo, `ParentGradesScreen` pide `/estudiantes/<segundo>/notas` |
| Un solo hijo | idem | No aparece la lista |
| Arquitectura | `test/architecture_test.dart` | Sigue en verde (`LinkedChild` es Dart puro) |
| Dispositivo | Caso del PR-06 en el POCO X7 | El padre de prueba con 2 hijos cambia entre ellos |

---

### APP-04 · Política de contraseña — Alta

**Evidencia.** `Validators.newPassword` (`lib/core/utils/validators.dart`, líneas 24–27) solo exige 8 caracteres. Lo usan:
- `register_screen.dart`, línea 410
- `reset_password_screen.dart`, línea 155
- `profile_screen.dart`, línea 628

La regla oficial tiene cinco condiciones, igual a la web (`src/lib/utils/password.ts`) y a la API tras BE-09.

**Diseño:**
- `lib/core/domain/password_policy.dart` con `PasswordPolicy.check(pwd)`, que devuelve las cinco condiciones (`length`, `upper`, `lower`, `number`, `special`), y `PasswordPolicy.isValid(pwd)`.
- `Validators.newPassword` devuelve el mensaje de la primera condición que falla. Los tres formularios no cambian.
- Widget opcional `PasswordChecklist` en `lib/core/widgets/` con las reglas en vivo.
- `profile_screen.dart`: si BE-09 exige la contraseña actual para cambiarla, agregar ese campo.

| Prueba | Archivo | Resultado esperado |
|---|---|---|
| Cumple | `test/password_policy_test.dart` | `Colegio#2026` válida |
| Cada regla | idem | `Ab1#`, `colegio#2026`, `COLEGIO#2026`, `Colegio#ocho` y `Colegio2026` fallan cada una por su regla |
| Mensaje | `test/validators_test.dart` | `newPassword('Colegio2026')` → mensaje de carácter especial; `Colegio#2026` → `null` |
| Formulario | prueba de widget de `ResetPasswordScreen` | Con `Colegio2026` no se llama al repositorio (doble con contador en `ProviderScope`) |

Los seis casos son los mismos de la API y la web.

---

### APP-06 · Correo sin pasar a minúsculas — Media

**Evidencia.** `auth_repository_impl.dart`, líneas 36 (login) y 249 (recuperar contraseña): solo `trim()`. La web pasa el correo a minúsculas. Quien se registra en la app con `Ana@x.com` no puede entrar desde la web. BE-12 lo corrige en la API, pero el cliente debe ser coherente.

**Diseño:** función pura `normalizeEmail(String)` en `lib/core/utils/` que hace `trim().toLowerCase()`. Se usa en login, registro y recuperación.

| Prueba (`test/validators_test.dart`) | Resultado esperado |
|---|---|
| `normalizeEmail(' Ana@X.com ')` | `ana@x.com` |
| Login con `ScriptedAdapter` | El cuerpo enviado lleva `ana@x.com` |

---

### APP-07 · Token en el log y nombre del repositorio — Baja

**Evidencia.**
- `push_notification_service.dart`, líneas 94–97: `debugPrint('[FCM TOKEN]: $_fcmToken')`. `debugPrint` también escribe en las versiones de release.
- `update_service.dart`, líneas 35–36: consulta `AndresFelipeAceroLopez/eyes_school`, pero el repositorio actual es `eyes_school_app_movil`. Hoy funciona porque GitHub redirige el nombre viejo; si ese nombre se reutiliza o se quita la redirección, la OTA deja de encontrar versiones en silencio.

**Diseño:**
- Envolver el log del token en `if (kDebugMode)`.
- Cambiar `_repoName` a `eyes_school_app_movil` y sacarlo a `api_config.dart` como `String.fromEnvironment('EYESCHOOL_UPDATE_REPO', defaultValue: ...)`, para que QA apunte a otro repositorio de pruebas.

| Prueba | Resultado esperado |
|---|---|
| `UpdateService` con Dio y `ScriptedAdapter` | Consulta `/repos/AndresFelipeAceroLopez/eyes_school_app_movil/releases/latest` |
| Versión publicada mayor | `hasUpdate == true` |
| Versión igual | `hasUpdate == false` |
| Sin red | `hasUpdate == false` sin excepción |

---

## 4. Infraestructura de pruebas

### APP-INF-1 · SonarQube Cloud y secretos (S7)

- `flutter test --coverage` ya genera `coverage/lcov.info`. En `ci.yml`, agregar `SonarSource/sonarqube-scan-action` (secreto `SONAR_TOKEN`) y `gitleaks/gitleaks-action`.
- `sonar-project.properties`:
  - `sonar.sources=lib`
  - `sonar.tests=test`
  - `sonar.dart.lcov.reportPaths=coverage/lcov.info`
  - exclusiones: `lib/main.dart` y el código generado.
- `android/app/google-services.json` está en el repositorio. Es configuración de cliente de Firebase, no un secreto de servidor, pero hay que **restringir esa API key** en Google Cloud Console al paquete Android y a la huella de firma de APP-01.

### APP-INF-2 · Pruebas de sistema con `integration_test` (S8)

- Agregar `integration_test` (SDK de Flutter) a `dev_dependencies` y la carpeta `integration_test/`.
- La API se elige con `--dart-define=EYESCHOOL_API_BASE=<URL de QA sin /api/v1>`. Los usuarios de prueba entran por `--dart-define`; nunca van escritos en el código.
- Flujos mínimos:
  1. Inicio de sesión de cada rol, con su inicio cargado (verifica BE-03).
  2. Escaneo QR sin red y sincronización al volver la red (cola).
  3. Registro duplicado marcado «Duplicado» (BE-08).
  4. Padre con dos hijos (APP-03).
  5. Registro de padre que ve los datos de su hijo vinculado (comportamiento por diseño).
  6. Notificación de novedad recibida en el teléfono del padre (APP-08 + BE-18).
- Se ejecutan en el POCO X7 (Android 15) y en emuladores API 30 y API 33: `flutter test integration_test --dart-define=EYESCHOOL_API_BASE=...`. No corren en cada PR; el resultado va al PR-06.

---

## 5. Notificaciones push y riesgos aceptados

### APP-08 · La app no envía su token de notificaciones — Alta (depende de BE-18)

**Evidencia (verificada en todas las ramas el 30/10/2026).**
- La app **sí recibe y muestra** notificaciones: `push_notification_service.dart` escucha `FirebaseMessaging.onMessage` (línea 111) y obtiene el token (línea 94).
- Pero el token solo se imprime con `debugPrint` (líneas 95–97) y nunca se envía a la API. Además, la clase crea `FirebaseMessaging.instance` adentro (línea 27), lo que impide probarla.
- Como en la API tampoco existe el emisor (BE-18), al registrar una novedad el acudiente no recibe nada. El PBI 92 y la US027 lo piden, así que los casos del PR-02 fallarán hasta corregirlo.

**Diseño:**
- Interfaz `DeviceTokenRepository` en `lib/features/notifications/domain/` con `register(String token)` y `unregister(String token)`. Implementación en `data/` con `POST /api/v1/dispositivos` y `DELETE /api/v1/dispositivos/{token}`.
- `PushNotificationService` recibe por constructor el `FirebaseMessaging` y el `DeviceTokenRepository`; se provee desde `lib/features/notifications/providers/push_provider.dart`.
- Registra el token después de iniciar sesión y en cada `onTokenRefresh`. Lo da de baja al cerrar sesión.
- En Android 13 o superior pide el permiso `POST_NOTIFICATIONS` (ya declarado en el `AndroidManifest`). Si se niega, la app sigue funcionando y la novedad se ve en la pantalla de novedades.
- Al tocar la notificación se abre la pantalla de novedades del hijo (`/parent/more` o la ruta de novedades del padre en `app_router.dart`).
- Quitar el `debugPrint` del token (también es parte de APP-07).

| Prueba | Archivo | Resultado esperado |
|---|---|---|
| Registro tras login | `test/push_notification_service_test.dart` (dobles del mensajero y del repositorio) | Se llama `register(token)` |
| Token renovado | idem | Se vuelve a llamar `register` con el token nuevo |
| Permiso negado | idem | No se llama `register` y no hay excepción |
| Cierre de sesión | idem | Se llama `unregister(token)` |
| API | `test/device_token_repository_test.dart` con `ScriptedAdapter` | `POST /dispositivos` con `{"token_fcm": ...}` |
| Dispositivo (PR-06) | POCO X7 con sesión de padre | Al registrar una novedad desde la web llega la notificación y al tocarla abre las novedades del hijo |

### Riesgo aceptado: QR predecible

El QR del estudiante se genera con su código (`my_qr_screen.dart`, líneas 67–68). Al registrarse, ese código es su número de documento, así que quien lo conozca puede fabricar el QR de otro estudiante. El PO decidió el 30/10/2026 no firmar el QR en esta versión. Queda como riesgo aceptado en el PR-09. Mitigación operativa: quien escanea ve el nombre del estudiante en la confirmación.

## 6. Reglas de código testeable para la app

1. **`domain/` es Dart puro.** `test/architecture_test.dart` lo vigila en cada PR.
2. **Toda llamada a la API está en `data/`.** Ninguna pantalla usa Dio.
3. **Dependencias por constructor**, nunca instancias globales adentro (`FirebaseMessaging.instance`, `Dio()`).
4. **Estado compartido en providers** (sesión, hijo activo, cola), reemplazables con `ProviderScope(overrides: [...])`.
5. **Pruebas sin red:** `ScriptedAdapter` para la API y `memory_store.dart` para el almacenamiento.
6. **Cada pantalla nueva o tocada tiene tres estados probados:** con datos, vacía y con error con reintento (regla de resiliencia del MC-01).
7. **Accesibilidad:** botones de ícono con etiqueta y contraste WCAG AA; agregar la pantalla a `test/accessibility_test.dart`.
8. **Nada sensible en logs de release:** todo `debugPrint` con datos de sesión va dentro de `if (kDebugMode)`.
9. **Configuración por `--dart-define`**, nunca URLs ni usuarios escritos en el código.

## 7. Definición de terminado

- [ ] La prueba que demuestra el defecto se escribió primero y fallaba antes del cambio.
- [ ] `dart format` sin cambios pendientes y `flutter analyze` sin hallazgos.
- [ ] `flutter test --coverage` en verde y `tool/coverage_report.dart --min-logic=75` aprobado.
- [ ] `architecture_test.dart` y `accessibility_test.dart` en verde.
- [ ] Quality Gate de SonarQube aprobado y `gitleaks` limpio.
- [ ] Probado en el POCO X7 con el APK de QA (`EYESCHOOL_API_BASE` de QA).
- [ ] PR revisado por otro integrante, con `AB#<id>` del bug en Azure Boards.

## 8. Ramas y calendario

- Primer día de S7: merge de `chore/modelo-calidad` a `develop`.
- Ramas desde `develop`: `fix/APP-xx-descripcion-corta`, `chore/APP-INF-x-...`.
- Commits: `test(auth): la contraseña nueva exige carácter especial (APP-04)` y luego `fix(auth): aplica la política completa (APP-04)`.
- Liberación: etiqueta `v1.1.0` → `release_apk.yml` publica el APK **ya firmado con la clave de release (APP-01)**, junto con la API y la web el 14 nov 2026.

| Sprint | Fechas | Trabajo |
|---|---|---|
| S7 | 29 oct – 1 nov | APP-01 (clave de release y decisión de `applicationId`), APP-02, APP-INF-1 |
| S7 | 2 – 6 nov | APP-04, APP-06 |
| S8 | 7 – 11 nov | APP-03 (cuando BE-07 esté en `develop`), APP-08 (con BE-18), APP-07 |
| S8 | 11 – 14 nov | APP-INF-2 en el POCO X7 y emuladores, verificación de BE-03, BE-08, BE-13 y BE-16, liberación |

## 9. Decisiones pendientes del PO

| # | Pregunta | Recomendación QA |
|---|---|---|
| D-A1 | `applicationId` definitivo | Un dominio del colegio o del proyecto, por ejemplo `co.edu.eyesschool.app`; decidirlo antes de entregar |
| D-A2 | Versión mínima de Android | La más baja que tengan los docentes del colegio, con su emulador en la matriz de pruebas; si no se sabe, 30 como dice el PR-01 |
