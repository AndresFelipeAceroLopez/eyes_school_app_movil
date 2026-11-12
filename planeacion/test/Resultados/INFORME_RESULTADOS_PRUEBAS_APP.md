# Informe de resultados de pruebas — App móvil (Flutter) · Eyes School

> **Ejecutó:** QA (sesión asistida) · **Inicio:** 10/11/2026 · **Corte:** 11/11/2026 · **Estado:** S1 completa en emulador; pendiente POCO X7, cámara, Docker y Azure Boards
> **Rama y commit bajo prueba:** `develop` · `f253eb0` (tal como está, sin fusionar nada)
> **Ramas publicadas en GitHub (11/11/2026):** `test/pr04-unitarias-app` (`a5fb7fd`), `test/pr05-integracion-app` (`40d39b3`), `fix/api-config-url`. Revisadas con gitleaks antes del push: sin secretos
> **API de QA:** `https://apieyeschool-q-g4hfgrgvepbecacc.chilecentral-01.azurewebsites.net/api/v1`
> **Regla del informe:** solo se anota lo que se ejecutó y se vio. Lo que no se ejecutó dice «No ejecutado» y por qué.


## Resumen ejecutivo (corte 11/11/2026)

| Plan | Resultado |
|---|---|
| PR-03 estático | `flutter analyze` 0 ✔ · formato: 117 de 135 archivos sin formato ✘ · duplicación 4,64 % ✘ (≤ 3 %) · cobertura de la lógica 33,5 % ✘ (≥ 60 %) · 0 vulnerabilidades ✔ · 1 secreto esperado (clave de Google Cloud) |
| PR-04 unitarias | 59 de 59 existentes ✔. 8 nuevas (UT-APP-01 a 08) fallan como se esperaba hasta sus correcciones |
| PR-05 integración | 21 endpoints reales grabados. 40 aprobadas · 7 fallidas (3 esperadas, 4 defectos nuevos) |
| PR-06 sistema | Emulador API 33 + API de QA: CP-SIS-066, 072, 081, 085, 090, 091, 095, 097 aprobados. Fallan 067, 069, 087, 092, 094 y NF-004, 010, 011. Automatización APP-INF-2: 5 de 5 flujos verdes (el 4 falla como se esperaba) |
| PR-08 UAT (sin PO) | 28 aceptados · 9 con observación · 17 rechazados · 29 no ejecutados → QA no recomienda aceptar |
| PR-07 defectos | 7 conocidos confirmados + 24 nuevos (N-01 a N-24; solo backend o datos: N-04, N-13, N-23; compartidos app y API: N-07, N-15, N-20). **Altos de la app:** N-01 (corregido en rama), N-08, N-12, N-14, N-17, N-18, N-22, N-24 |

**Lo que sigue sin ejecutar y por qué:** casos con cámara (POCO X7); MobSF (falta Docker); CP-NF-007 en el teléfono; notificaciones (APP-08 no existe); registro masivo (necesita autorización porque deja datos visibles, N-15); SUS y tareas medidas (necesitan participantes); registro de bugs en Azure Boards (sin acceso).

---

## 0. Entorno real (difiere de las planeaciones)

| Dato | Planeación | Realidad verificada |
|---|---|---|
| Pruebas en `develop` | 110 en 12 archivos | 59 en 7 archivos (`app_boot` 2, `architecture` 5, `attendance_queue` 11, `dto_mapping` 20, `student_home_resilience` 2, `usecases` 11, `validators` 8) |
| `test/support/memory_store.dart` | Existe | No existe en `develop` |
| `ci.yml` y `tool/coverage_report.dart` | Existen | No existen en `develop` (solo `release_apk.yml`) |
| `*_repository_test.dart`, `accessibility_test.dart` | Existen | No existen en `develop` |
| Herramientas en la máquina | — | Al iniciar: sin Flutter, Dart, Android SDK ni adb. Se instalaron Flutter estable (`C:\src\flutter`) y Android SDK (`%LOCALAPPDATA%\Android\Sdk`) el 10/11/2026 |

## 1. Datos de prueba verificados en la API de QA (10/11/2026, solo lectura)

| Conjunto | Usuario | id_usuario | Rol (`id_rol`) | Verificado |
|---|---|---|---|---|
| DS-01 admin | admin@eyesschool.edu.co | 1 | 3 | Login 200 |
| DS-01 docente | carlos.jimenez@eyes.edu.co | 2 | 1 | Login 200 |
| DS-01 estudiante | sofia.rodriguez@student.eyes.co | 3 | 2 (id_estudiante 1, EST001, curso 1) | Login 200 |
| DS-01 padre (1 hijo) | roberto.diaz@gmail.com | 8 | 4 → hijo id 2 Juan Pérez (EST002, curso 1) | Login 200 |
| DS-03 padre (2 hijos) | rosa.perez@gmail.com | 4 | 4 → hijos id 1 Sofía (Madre) e id 3 Santiago López (Abuela, curso 2) | Login 200; `/padres/me/hijos` devuelve 2 |

- DS-05 (QR decodificados con OpenCV): válidos `EST001`, `EST002`, `EST003` (existen en QA); inválidos `EST999` (no existe), `HOLA EYES SCHOOL`, `https://www.example.com`.
- Notas / asistencia / novedades: estudiante 1 → 4 / >500 / 4 · estudiante 2 → 3 / 4 / 3 · estudiante 3 → 3 / 3 / 3.
- Padres en QA: solo 2 cuentas (Rosa y Roberto). Ningún padre sin hijo. Estudiantes sin notas: ids 4 a 15 (sintéticos `est.synN@eyeschool.test`), ninguno con padre.

## 2. PR-03 · Análisis estático

| # | Métrica | Herramienta | Resultado | Umbral | Estado |
|---|---|---|---|---|---|
| A1 | Hallazgos del analizador | flutter analyze (Flutter estable, Dart 3.13.7) | 0 hallazgos (98,5 s) | 0 | **Cumple** |
| A2 | Formato | dart format --set-exit-if-changed lib test tool | **117 de 135 archivos** sin formato (código de salida 1) | 0 | **No cumple** (el CI lo tenía con `continue-on-error`) |
| A3 | SonarQube Cloud | — | Pendiente | Sonar way | — |
| A4 | Funciones con CCN > 15 | lizard 1.25.0 | 5: `StudentCatalog._candidateKeys` 23 · `FailureMapper.from` 19 · `_GradeEntryScreenState._save` 18 · `AppUser.copyWith` 18 · `_ProfileScreenState.build` 18 | Informativo | Al plan de remediación |
| A5 | Duplicación | jscpd 4.3.0 | **4,64 %** (868 de 18 700 líneas, 69 clones) | ≤ 3 % | **No cumple** |
| A6 | Líneas de código | pygount | 12 708 código · 926 comentarios · 126 archivos | — | — |
| A7 | Secretos (historial completo) | gitleaks 8.24.2 | 1: `gcp-api-key` en `android/app/google-services.json:18` (commit `dcc9939`) | 0 sin justificar | Esperado (APP-INF-1); pendiente restringir la clave |
| A8 | Dependencias | Dependabot: **desactivado** en el repositorio (API 403). Sustituto: consulta OSV (`api.osv.dev`, ecosistema Pub) de las 125 versiones de `pubspec.lock` + `flutter pub outdated` | 0 vulnerabilidades conocidas. 15 de 15 dependencias directas tienen versión nueva (varias mayores: `go_router` 14→18, `flutter_riverpod` 2→3, `share_plus` 10→13) | 0 críticas/altas | **Cumple** (activar Dependabot sigue pendiente, APP-SA-4) |
| A9 | Arquitectura | architecture_test.dart | Pendiente | 0 | — |
| A10 | Cobertura lógica | flutter test --coverage + `coverage_report.dart` (copia de solo lectura de `chore/modelo-calidad`, porque no existe en `develop`) | **33,5 %** (domain 55,3 % · data 26,8 %) | ≥ 60 % | **No cumple** |

Revisión dirigida: APP-01, APP-02, APP-03, APP-04, APP-06, APP-07 y APP-08 confirmados en el código de `develop` (detalle en la sección 7).

## 3. PR-04 · Pruebas unitarias

### 3.1 Corrida U1 · `develop` `f253eb0` · 10/11/2026

`flutter test --coverage --reporter expanded` → **59 de 59 aprobadas, 0 fallidas, 0 omitidas · 22 s**. Evidencia: `evidencias/PR-04/app/U1_suite_expanded.txt`, `U1_lcov.info`.

| Archivo | Casos | Aprobados | Nivel (PR-01) |
|---|---|---|---|
| usecases_test.dart | 11 | 11 | Unitaria |
| attendance_queue_test.dart | 11 | 11 | Unitaria |
| validators_test.dart | 8 | 8 | Unitaria |
| architecture_test.dart | 5 | 5 | Unitaria (estática) → 0 violaciones de arquitectura |
| app_boot_test.dart | 2 | 2 | Widget |
| student_home_resilience_test.dart | 2 | 2 | Widget |
| dto_mapping_test.dart | 20 | 20 | Contrato (PR-05) |
| **Total** | **59** | **59** | |

Cobertura por capa (`U1_cobertura_por_capa.txt`):

| Capa | Líneas | Cobertura |
|---|---|---|
| domain | 198 / 358 | 55,3 % |
| data | 317 / 1 181 | 26,8 % |
| core | 354 / 796 | 44,5 % |
| presentación | 393 / 4 662 | 8,4 % |
| **Lógica (domain + data)** | **515 / 1 539** | **33,5 %** → no cumple ≥ 60 % (MC-01) ni ≥ 75 % (CI) |
| Total | 1 262 / 6 997 | 18,0 % |

Nota: `lcov` de Flutter solo cuenta los archivos que alguna prueba importa; la cobertura real de la lógica puede ser menor. La cobertura de ramas no la reporta `lcov` de Flutter: «No disponible en Flutter».

### 3.2 Pruebas nuevas UT-APP-01 a 08 · rama `test/pr04-unitarias-app` · commit `021377c` (local, sin push)

Corrida U1c (10/11/2026) contra el código de `develop`: los archivos que compilan, juntos (`U1c_compilan.json`); los que no compilan, uno por uno (`U1c_<archivo>.txt`).

| ID | Corrección | Archivo | Casos | Resultado hoy | ¿Esperado? |
|---|---|---|---|---|---|
| UT-APP-01 | APP-04 | `test/password_policy_test.dart` | 6 | **No compila**: no existe `lib/core/domain/password_policy.dart` | Sí (falla esperada) |
| UT-APP-02 | APP-04 | `test/validators_test.dart` (3 casos nuevos) | 3 | 2 fallan: `newPassword('Colegio2026')` → `null`; mensajes `['Usa al menos 8 caracteres.', null, null, null, null]`. 1 pasa (`Colegio#2026` válida) | Sí |
| UT-APP-03 | APP-04 | `test/reset_password_screen_test.dart` | 1 + 1 de control | Falla: con «Colegio2026» el repositorio se llamó 1 vez (esperado 0). El control con «Colegio#2026» pasa | Sí |
| UT-APP-04 | APP-06 | `test/email_normalization_test.dart` | 3 | **No compila**: `normalizeEmail` no existe | Sí |
| UT-APP-05 | APP-03 | `test/children_screen_test.dart` | 2 | 2 hijos: **falla**. 1 hijo: pasa | Sí. Además revela el defecto N-05 (ver 7.2): la pantalla pinta el nombre del hijo vacío («») y el avatar «?» |
| UT-APP-06 | APP-03 | `test/architecture_test.dart` (existente) | 5 | 5 de 5 pasan | Sí (regresión) |
| UT-APP-07 | APP-08 | `test/push_notification_service_test.dart` | 4 | **No compila**: no existe `device_token_repository.dart` y el servicio no recibe dependencias | Sí |
| UT-APP-08 | APP-07 | `test/update_service_test.dart` | 4 | 2 fallan (no se consulta el repositorio; `hasUpdate` falso con v1.1.0); 2 pasan (versión igual, sin red) | Sí |

Totales de la corrida U1c: 64 aprobadas · 6 fallidas · 3 archivos sin compilar (13 casos) · 0 omitidas. Todas las fallas corresponden a pruebas nuevas cuya corrección no está fusionada (Tabla 4 del PR-04: «Falla esperada»). Las 59 existentes siguen en verde.

Decisiones y observaciones de QA sobre estas pruebas:

| # | Observación |
|---|---|
| O-U1 | **Un archivo de prueba que no compila tumba a otros archivos.** En la suite completa (`U1b_flutter_test.json`) el compilador se cayó («The Dart compiler exited unexpectedly») y arrastró a `app_boot_test.dart`, que pasa 2 de 2 cuando se corre solo. Mientras UT-APP-01, 04 y 07 no tengan su corrección, la corrida oficial debe ejecutarlos por separado, o el CI dará falsos rojos |
| O-U2 | UT-APP-04 va en un archivo propio y no en `validators_test.dart` (como dice la planeación): si no compila, arrastraría a las 8 pruebas existentes de validadores. QA supone que `normalizeEmail` vive en `lib/core/utils/validators.dart`; la planeación solo dice `lib/core/utils/` |
| O-U3 | UT-APP-07 usa nombres que la planeación no define y que propuso QA: `PushNotificationService(messaging:, deviceTokens:)`, `onSignedIn()`, `onSignedOut()` y el archivo `device_token_repository.dart`. El desarrollador puede cambiarlos ajustando solo esas líneas |
| O-U4 | UT-APP-08 no puede pasar en el CI con el diseño actual: `checkForUpdates` sale antes de consultar si `Platform.isAndroid` es falso. La corrección de APP-07 debe permitir probar la consulta fuera de Android |
| O-U5 | UT-APP-02 no fija el texto exacto de los mensajes (pendiente P-10); exige que el de la regla especial contenga «especial» y que los cinco sean distintos |

## 4. PR-05 · Integración app ↔ API

Verificación estática del contrato (rutas de `lib/**` contra `/openapi.json` de QA):
- 43 de las 44 rutas distintas que usa la app existen. Falta `/profesores/me` (`people_api.dart:108`); el código lo documenta y tiene respaldo (pagina `/profesores`). Observación.
- QA expone 3 rutas que producción no tiene: `GET /padres/me/hijos`, `POST /dispositivos`, `DELETE /dispositivos/{token_fcm}`.

### 4.1 Corrida I1 · rama `test/pr05-integracion-app` · commit `8df8c8d` (local, sin push) · 10–11/11/2026

Contrato grabado: `dart run tool/grabar_contrato.dart` con DS-01 (admin, docente, estudiante) y DS-03 (rosa.perez) → **21 endpoints, todos 200**, sin tokens ni contraseñas (verificado con búsqueda de `access_token|refresh_token|bearer|password`). Archivos: `test/fixtures/api/*.json` y `evidencias/PR-05/app/fixtures/`.

| ID | Archivo | Casos | Resultado | ¿Esperado? |
|---|---|---|---|---|
| CP-INT-075 (existente) | dto_mapping_test.dart | 20 | 20 pasan | Sí |
| IT-APP-07 | contrato_grabado_test.dart | 22 | 19 pasan · **3 fallan** (ver abajo) | No: son hallazgos de la API de QA |
| IT-APP-01 | dto_hijos_test.dart (usa la respuesta real de `/padres/me/hijos`) | 1 | **No compila** (no existen `LinkedChild` ni `HijoDto`) | Sí |
| IT-APP-02 | auth_repository_test.dart | 2 | 2 hijos: falla (la app nunca pide `/padres/me/hijos`; pidió `/auth/login, /auth/me, /cursos, /materias, /tipos-novedad ×2, /padres/me, /dashboard/padre, /estudiantes/1`). Sin hijos: pasa | Sí |
| IT-APP-03 | auth_repository_test.dart | 1 | Falla: el cuerpo enviado lleva `'Ana@X.com'` | Sí |
| IT-APP-04 | device_token_repository_test.dart | 2 | **No compila** (no existe la implementación) | Sí |
| IT-APP-05 | attendance_repository_test.dart (respuesta real de QA) | 1 | **Falla**: con el 400 «No hay entrada registrada hoy para este estudiante» el registro queda `pending` y se reintenta (hasta 5 veces con espera creciente) | **No**: defecto nuevo N-08 |
| IT-APP-06 | academic_repository_test.dart (respuesta real de QA) | 1 | **Falla**: la app produce `NotFoundFailure` «No encontramos el recurso solicitado.» en lugar de «No hay datos disponibles para generar el boletín.» | **No**: defecto nuevo N-09 |

Totales I1: 40 aprobadas · 7 fallidas · 2 archivos sin compilar (3 casos). De las 7 fallas: 3 esperadas (IT-APP-02 y 03), 4 son defectos nuevos (3 de la API, 2 de la app; N-04 aparece dos veces).

Fallas del contrato grabado (API de QA):
1. `/estudiantes/1/asistencia`: `tipo` trae `Manual` y `QR`. La API solo acepta `entrada|salida|clase` al crear (`AsistenciaCreate`), pero devuelve esos valores heredados. La app los convierte en silencio en «Entrada» (`AttendanceKind.parse`, `orElse: entry`). Defecto N-07.
2. y 3. `/dashboard/estudiante` y `/dashboard/padre`: `porcentaje_asistencia` = **140,6**. Defecto N-04.

Verificaciones directas contra la API de QA (11/11/2026, con limpieza):

| Verificación | Resultado |
|---|---|
| `GET /notas/estudiantes/4/boletin/pdf` (estudiante sin notas) | 404 `{"detail":"No hay datos disponibles para generar el boletín."}` → BE-19 desplegado en QA |
| `GET /notas/estudiantes/1/boletin/pdf` | 200, PDF (`%PDF-1.3`) |
| `POST /asistencia` salida del estudiante 5 sin entrada hoy | 400 `{"detail":"No hay entrada registrada hoy para este estudiante"}` → regla de BE-08 desplegada; no se creó registro |
| `POST /asistencia` con estado «Suspensión» (como lo envía la app) | 201 (id 1916), borrado enseguida (204). El OpenAPI de QA anuncia el valor con la codificación dañada «SuspensiÃ³n», pero la API acepta el correcto. Observación de documentación |
| Esquema `DispositivoCreate` | Exige `token_fcm` **y** `plataforma` (`android`, `ios` o `web`). La planeación de APP-08 / IT-APP-04 solo menciona `token_fcm`: con eso la API respondería 422. IT-APP-04 ya exige los dos |

Observaciones de QA:
- O-I1: IT-APP-01 y 04 van en archivos propios para no arrastrar a las pruebas existentes si no compilan (ver O-U1). Nombres propuestos por QA: `linked_child.dart`, `HijoDto.toEntity()`, `DeviceTokenRepositoryImpl(ApiClient)` en `device_token_repository_impl.dart`.
- O-I2: el grabador se escribió en Dart (`tool/grabar_contrato.dart`) y no en `.sh` con `jq`, porque `jq` no está instalado y así corre igual en Windows y en el CI. Lee usuarios y contraseña solo de variables de entorno.
- O-I3: `ScriptedAdapter` ahora acepta `ScriptedResponse(status, body)` para responder 400 o 404, y guarda cada petición enviada (`sent`). Lo existente sigue igual (las 20 pruebas de `dto_mapping_test.dart` pasan).

## 5. PR-06 · Sistema

Rama `test/pr06-sistema-app` (desde `develop`). Entorno: emulador `EyesQA_API33` (Android 13, x86_64, WHPX) · API de QA. También existen `EyesQA_API29` y `EyesQA_API30`. El POCO X7 no está conectado (pendiente).

### 5.1 Verificaciones de sistema contra la API de QA (11/11/2026, con limpieza)

| Caso | Qué se hizo | Resultado | Estado |
|---|---|---|---|
| CP-SIS-089 / seguridad · autorregistro con rol privilegiado | La app ofrece «Administrador» y «Docente» en el registro y envía `id_rol` tal cual. Se registró por la API una cuenta con `id_rol`=3 y otra con `id_rol`=1 | Ambas 201 pero **inactivas**: login → 401 «Usuario inactivo». Borradas (204) | Aprobado: la API lo mitiga. La app avisa «pendiente de validación por un administrador» |
| CP-SIS-097 (precondición) · autorregistro de padre | Registro con `id_rol`=4 vinculado al estudiante 2 | 201 y la cuenta queda **activa** (login 200). Borrada (204) | Ver N-11 |
| CP-SIS-094 (perfil) · P-05 | Cuenta temporal de padre: `PUT /usuarios/{id}` como lo hace la app (solo `password`) | 400 «Debe indicar la contraseña actual para cambiarla». Con `password_actual` y nueva fuerte → 200. Con nueva sin carácter especial → 422 «La contraseña incumple: carácter especial». Borrada (204) | **Falla**: N-12. BE-09 desplegado en QA |

| CP-SIS-067 (API) · bloqueo al 6.º intento | Cuenta temporal: correo inexistente y 7 intentos con contraseña errada; luego la correcta | Correo inexistente e intentos 1 a 5: 401 «Credenciales inválidas» (mismo mensaje genérico). Intentos 6 y 7: **429 «Demasiados intentos, espera 15 minutos»**. La contraseña correcta también recibe 429. Borrada (204) | Aprobado en la API (BE-16 desplegado). Falta el mensaje en la app (dispositivo) |

| CP-NF-019 (API) · usuario desactivado | Cuenta temporal con sesión abierta; el admin la desactiva (`PATCH /usuarios/{id}/estado?estado=false` → 200) | El token de acceso vigente sigue respondiendo (`/auth/me` 200) hasta vencer (~30 min según `exp`). `POST /auth/refresh` → **401 «Token expirado o revocado»**. Login → 401 «Usuario inactivo». Borrada (204) | Aprobado en la API (BE-13 desplegado). Falta que la app vuelva al login con mensaje (dispositivo) |

| CP-SIS-096 / CP-SIS-074 (API) · duplicados y salida sin entrada | Estudiante 6 (ya tenía una entrada de hoy, ajena a QA): entrada desde el docente y desde el admin; salida; segunda salida. Estudiante 5 sin entrada: salida | Entrada repetida: **409 «Ya existe un registro de entrada para este estudiante en esta fecha»** (las dos). Salida: 201 (id 1917, borrada). Segunda salida: **409**. Salida sin entrada: **400 «No hay entrada registrada hoy para este estudiante»** | Aprobado en la API (BE-08 desplegado). En la app, la salida sin entrada falla (N-08) |

| CP-SIS-083 (API + código) · registrar novedad | Docente de DS-01, estudiante 2: novedad completa, sin descripción y sin tipo | Completa: 201. **Sin descripción: 201** (la API la guarda). Sin tipo: 422. Novedades 12 y 13 borradas (204). La app sí exige la descripción (`novedad_form_screen.dart:269`, «Describe la novedad.») | App: aprobado en código (falta en dispositivo). API: N-13 |

Nota de ejecución: un primer intento de CP-NF-019 envió `estado` en el cuerpo (422, sin efecto) e imprimió en la consola los tokens de la cuenta temporal. La cuenta se borró enseguida, así que esos tokens ya no sirven. Se repitió bien.

Respuesta a P-05: sí, BE-09 exige la contraseña actual.

### 5.2 APK de QA y no funcionales (S1, 11/11/2026)

APK: `flutter build apk --release --split-per-abi --dart-define=EYESCHOOL_API_BASE=<QA>` desde `test/pr06-sistema-app` (código de `develop`). Para compilar en Windows sin el Modo de desarrollador se desactivó el escritorio Windows de Flutter (`flutter config --no-enable-windows-desktop`) y se instaló el NDK 28.2.13676358 que pide Gradle.

| ID | Prueba | Resultado | Meta | Estado |
|---|---|---|---|---|
| CP-NF-011 | `apksigner verify --print-certs` + `aapt2 dump badging` | Firmado con **`CN=Android Debug`** (SHA-256 `af8ec467…b0ffaf`) · `package: name='com.example.eyes_school'` | Huella de release · `co.edu.eyesschool.app` | **Falla** (esperada, APP-01) · `S1_firma.txt`, `S1_badging.txt` |
| CP-NF-010 | `aapt2 dump badging` | `minSdkVersion:'24'` (`targetSdk` 36) | 30 | **Falla** (esperada, APP-02) |
| Tamaño APK | split por ABI | arm64-v8a **27,8 MB** · armeabi-v7a 23,9 MB · x86_64 30,3 MB | ≤ 40 MB | **Cumple** · `S1_tamano_apk.txt` |
| CP-NF-007 | 5 × `am start -W` en frío, emulador API 33 x86_64 con GPU del equipo | 9,1 / 6,9 / 7,9 / 6,5 / 5,6 s → promedio **7,2 s** | ≤ 3 s | **No concluyente**: un emulador en este equipo no representa el POCO X7. Se repite en el teléfono · `S1_arranque_API33.txt` |
| CP-NF-009 (parcial) | Primer login en API 33 | Android pide «Allow eyes_school to send you notifications?» | Pedir el permiso en API ≥ 33 | **Cumple** en API 33 · `CP-NF-009_permiso_notif_API33.png`. Faltan API 30 y el POCO X7 |
| CP-NF-004 (parcial) | `adb logcat` del APK **de release** tras iniciar sesión | `I flutter : [FCM TOKEN]: fRSERy…` (token completo en el log; la evidencia lo tapa) | Sin token en el log | **Falla** (esperada, APP-07) · `CP-NF-004_logcat_release_token_FCM.txt`. MobSF no ejecutado (falta Docker) |
| Permisos | `aapt2 dump badging` | Además de los esperados pide `READ_MEDIA_VIDEO`, `READ_MEDIA_AUDIO` y `REQUEST_INSTALL_PACKAGES` | — | Observación: video y audio no se usan; Google Play pide justificarlos |

Hallazgo N-14 (versión): en la etiqueta `v1.0.1`, `pubspec.yaml` decía `version: 0.1.0+1` y `release_apk.yml` compila sin `--build-name`, así que el APK publicado como v1.0.1 se reporta como 0.1.0 (`versionName='0.1.0'`). `UpdateService` compara la etiqueta (1.0.1) con esa versión y siempre ve una versión nueva.

### 5.3 Casos ejecutados en el emulador API 33 con el APK de release de QA (S1, 11/11/2026)

Evidencias: `evidencias/PR-06/app/CP-*_API33.png`.

| ID | Qué se hizo | Resultado | Estado |
|---|---|---|---|
| CP-SIS-066 · admin | Login admin@eyesschool.edu.co | Inicio del admin con datos (registros del día, acciones). Sin «Reintentar» | **Aprobado** (con N-15 y N-16 a la vista) |
| CP-SIS-066 · docente | Login carlos.jimenez | Inicio del docente con datos | **Aprobado** |
| CP-SIS-066 · estudiante | Login sofia.rodriguez | Inicio carga (BE-03 corregido en QA), pero muestra **«Asistencia 141%»** | **Aprobado** el caso; N-04 visible al usuario |
| CP-SIS-066 · padre (2 hijos) | Login rosa.perez | Inicio con Sofía | Aprobado (ver CP-SIS-092) |
| CP-SIS-070 (parcial) | Pestañas por rol | Admin: Inicio, Gestión, Novedades, Perfil · Docente: Inicio, Clases, Notas, Perfil · Estudiante: Inicio, Notas, Horario, Novedades, Perfil · Padre: Inicio, Hijos, Asistencia, Notas, Más | Aprobado (falta probar una ruta de otro rol) |
| CP-SIS-085 | Perfil del admin; Cerrar sesión → «¿Quieres salir de tu cuenta?» → Salir | Datos del usuario autenticado; vuelve al login | **Aprobado** |
| CP-SIS-091 | Docente → Clases | 4 asignaciones (Noveno A, Octavo A, Sexto A, Sexto B · Matemáticas) = API | **Aprobado** (vacío y sin red: pendientes) |
| CP-SIS-081 | Planilla Matemáticas · Sexto A · P1, estudiante 4 | 5.1 → «La nota debe estar entre 0.0 y 5.0.» y no se guarda · 5.0 → guardada (nota 12) · reabrir → carga 5.0 · 0.0 → actualiza la misma nota 12 (sin duplicar) · modo avión → «Sin conexión. Revisa tu red e intenta de nuevo.» + Reintentar → al volver la red, Reintentar recarga | **Aprobado** (CA-PBI6.1, 6.2, 6.3, 6.5). 6.4 (promedio) y paso 7 (422) pendientes. La nota de prueba la borró el docente (204); el admin recibió 403 al intentar borrarla |
| CP-SIS-072 | Estudiante en modo avión → Mi QR | Carné con nombre, EST001 y curso; el QR de la captura decodifica `EST001` | **Aprobado** |
| CP-SIS-090 | Estudiante → Horario | Lunes 07:00 Matemáticas, Aula 101… = `/cursos/1/horarios` | **Aprobado** (vacío y sin red: pendientes) |
| CP-SIS-082 (parcial) | Estudiante → Notas | Promedio P1 4.3 (API 4.28), notas por asignatura | Aprobado lo visto |
| CP-SIS-092 | Rosa (DS-03) → Hijos | Solo Sofía; Santiago no aparece. Avatar «?» y nombre vacío | **Falla** (esperada, APP-03) + **N-05 confirmado** |
| CP-SIS-092 paso 8 / CP-ACE-077 | Padre sin vínculo (P-04) | Inicio y Notas: «Sin estudiante vinculado» con subtítulo «Perfil padre no encontrado» (texto técnico de la API) | **Aprobado** (observación menor por el subtítulo) |
| CP-SIS-087 pasos 1–2 | Roberto → Notas → Descargar boletín PDF | El PDF se descarga y se abre en el visor del sistema. **Al volver, la app queda en pantalla negra** | **Falla** → N-17 |
| CP-SIS-087 paso 4 | Padre del estudiante 4 sin notas (P-09a) → Compartir boletín | **Pantalla negra** en < 1 s, sin mensaje; «Atrás» cierra la app. Reproducido 2 veces | **Falla** → N-17 (y N-09) |

| CP-SIS-094 (perfil) / N-12 | Padre temporal (P-09a) → Más → Cambiar contraseña | La hoja solo tiene «Nueva» y «Confirmar». Con `Colegio#2027` en los dos: **«Debe indicar la contraseña actual para cambiarla»** y no hay dónde escribirla | **Falla** → N-12 confirmado · `N-12_*_API33.png` |
| CP-SIS-094 (registro) | Registro por pasos con «Colegio2026» (sin carácter especial), rol padre, estudiante 2 | La app acepta la contraseña en el paso 2 y avanza (APP-04). Al crear, la API responde 422 (BE-09) y la app solo dice **«Revisa los datos marcados.»** en el paso 3, donde no hay nada marcado (el error es de la contraseña, en el paso 2). No se creó la cuenta (verificado en la API) | **Falla** (esperada, APP-04) + N-19 · `CP-SIS-094_registro_*_API33.png` |
| CP-SIS-067 | Padre temporal sin vínculo: 6 logins con contraseña errada | **Ningún mensaje** en ningún intento: el formulario vuelve vacío. La API sí los recibió: después, la contraseña correcta da **429** | **Falla** → N-18 · `CP-SIS-067_intento_*_API33.png` |
| CP-SIS-069 | Modo avión → login del docente | Vuelve al login vacío **sin mensaje de red ni Reintentar** | **Falla** → N-18 · `CP-SIS-069_login_sin_red_API33.png` |
| CP-SIS-095 | Login con «␣␣Carlos.Jimenez@Eyes.edu.co␣␣» (P-06) | Entra al inicio del docente | **Aprobado** de punta a punta gracias a BE-12 (la API ignora mayúsculas). APP-06 sigue pendiente en el cliente (UT-APP-04, IT-APP-03) |

Nota de ejecución: los primeros intentos de login en el emulador fallaron porque su DNS todavía no estaba listo («unknown host»). En esa situación sin red, **la app volvió al login sin mostrar ningún mensaje** (ver CP-SIS-069, que se ejecutará a propósito). `profile_screen.dart` necesita el campo nuevo y `changePassword` tiene que enviar `password_actual`.

## 6. PR-08 · UAT (sin el PO)

**Cómo se hizo (por instrucción del 10/11/2026):** QA ejecutó los escenarios en el lugar del PO, en el emulador API 33 con el APK de release de QA y la API de QA. Veredictos: **Aceptado**, **Aceptado con observación**, **Rechazado**, o **No ejecutado** con el motivo. No es la aceptación formal del PR-08: el acta la firman el PO, el líder de pruebas y el instructor.

**No aplicable sin participantes:** encuesta SUS (sección 7 de la planeación) y tareas medidas de calidad en uso (sección 6), porque necesitan usuarios reales y tiempos de referencia. Quedan para la sesión con el PO.

Evidencias: `evidencias/PR-08/app/` y `evidencias/PR-06/app/`.

### 6.2 Veredictos por escenario (11/11/2026)

| ID | Escenario | Veredicto | Evidencia / motivo |
|---|---|---|---|
| CP-ACE-001 | Inicio de sesión exitoso según el rol | Aceptado con observación | 4 roles entran (manual + `integration_test`, 5/5). Obs.: el estudiante y el padre ven «Asistencia 141%» (N-04) |
| CP-ACE-002 | Credenciales incorrectas | **Rechazado** | No se muestra ningún mensaje (N-18) |
| CP-ACE-005 | Error de conexión | **Rechazado** | Login sin red vuelve vacío y sin mensaje (N-18) |
| CP-ACE-006 | Sesión guardada | Aceptado | Cerrar y reabrir la app entra sin pedir login |
| CP-ACE-007 | Cada rol ve solo sus módulos | Aceptado | Barra de pestañas propia por rol |
| CP-ACE-008 | Acceso a un módulo de otro rol | No ejecutado | Falta un deep link a una ruta de otro rol; el de recuperación ya no funciona (N-24) |
| CP-ACE-009 | Error al cargar el inicio | No ejecutado en dispositivo | No se puede detener la API de QA. `student_home_resilience_test.dart` pasa (2/2) |
| CP-ACE-010 | Registro completo | Aceptado con observación | Flujo 5 pasa. Obs.: al padre se le dice «pendiente de validación» aunque ya puede entrar (N-11) |
| CP-ACE-011 | Correo ya registrado | No ejecutado | Por tiempo. Riesgo: probablemente igual que N-19 (el error es de un campo del paso 2) |
| CP-ACE-012 | Campo obligatorio vacío | Aceptado | Sin primer apellido, «Continuar» no avanza |
| CP-ACE-013 | Registro de padre vinculado (por diseño) | Aceptado con observación | Flujo 5 pasa. Obs.: el hijo aparece sin nombre (N-05) y la vinculación usa ids consecutivos (R-N1) |
| CP-ACE-014 | Recuperar con correo registrado | Aceptado | «Enlace enviado» + mensaje neutral (correo `example.com` temporal) |
| CP-ACE-015 | Recuperar con correo no registrado | Aceptado | Mismo mensaje neutral |
| CP-ACE-016 | Nueva contraseña válida | **Rechazado** | No se llega a la pantalla: el enlace `eyesschool://reset?token=` abre el login (N-24) |
| CP-ACE-017 | Enlace o contraseña no válidos | **Rechazado** | Mismo motivo (N-24) |
| CP-ACE-018 | Ver mi perfil | Aceptado | Perfil del admin y del padre con sus datos |
| CP-ACE-019 | Cerrar sesión | Aceptado | Confirmación «¿Quieres salir de tu cuenta?» → login |
| CP-ACE-030 | Consulta sin resultados | Aceptado | «Sin resultados · No encontramos a nadie con "zzqx"» |
| CP-ACE-031 | Error de conexión en la consulta | No ejecutado | El directorio trabaja desde la caché local (103 estudiantes) |
| CP-ACE-032 | Directorio en la app | Aceptado | Pestañas Estudiantes/Profesores/Acudientes y búsqueda en vivo |
| CP-ACE-033 | Ver mi QR | Aceptado | Carné con QR, nombre, código y curso |
| CP-ACE-034 | El QR de la web se lee en la app | No ejecutado | Requiere cámara (POCO X7) |
| CP-ACE-036 | QR sin conexión | Aceptado | Modo avión; el QR decodifica `EST001` |
| CP-ACE-037 a 042 | Escaneo de asistencia (entrada, inválido, doble, salida, sin red) | No ejecutado en la app | Requieren cámara (POCO X7). En la API: 409 por duplicado y 400 por salida sin entrada (BE-08). En la app, la salida sin entrada se reintenta (N-08) |
| CP-ACE-043 a 045 | Registro masivo | No ejecutado | Escribiría la asistencia de un curso completo en QA y el borrado es lógico y queda visible (N-15). Requiere autorización |
| CP-ACE-046 | Filtrar el registro del día | Aceptado con observación | Filtros por tipo y curso. Obs.: muestra y cuenta un registro borrado (N-15) |
| CP-ACE-047 | Registros pendientes | Aceptado | «Pendientes por sincronizar · Todo sincronizado» |
| CP-ACE-048 | Sin datos para los filtros | Aceptado | «Sin registros hoy» + «Quitar filtros» |
| CP-ACE-049 | Error de conexión | Aceptado | «Sin conexión…» + Reintentar |
| CP-ACE-050 | Ver la asistencia del hijo | Aceptado con observación | Historial por fecha y tipo. Obs.: los registros `QR`/`Manual` se ven como «Entrada» (N-07), y el porcentaje no coincide con el del inicio (100 % vs 75 %, N-20) |
| CP-ACE-051 | Credenciales inválidas | **Rechazado** | N-18 |
| CP-ACE-052 | Error de conexión | Aceptado con observación | Sin red deja los datos anteriores en pantalla sin avisar |
| CP-ACE-053 | Sin registros | No ejecutado | Ningún hijo vinculado en QA está sin registros |
| CP-ACE-054 | Nota válida | Aceptado | 5.0 y 0.0 guardadas |
| CP-ACE-055 | Nota fuera de rango | Aceptado | 5.1 → «La nota debe estar entre 0.0 y 5.0.» |
| CP-ACE-056 | Falta información obligatoria | No ejecutado | — |
| CP-ACE-057 | Error de conexión | Aceptado | «Sin conexión…» + Reintentar |
| CP-ACE-058 | El promedio se actualiza | No ejecutado | No se verificó el recálculo en pantalla |
| CP-ACE-059 | Nota ya registrada | Aceptado | Se carga la existente y se actualiza la misma (id 12), sin duplicar |
| CP-ACE-060 | Error en el cálculo | No ejecutado | — |
| CP-ACE-061 | El estudiante ve sus notas | Aceptado | Promedio P1 4.3 = API |
| CP-ACE-062 | Trimestre sin notas | Aceptado | «Sin notas en el periodo 2» |
| CP-ACE-063 | Credenciales incorrectas | **Rechazado** | N-18 |
| CP-ACE-064 | El padre ve las notas de su hijo | Aceptado | Roberto → notas de Juan |
| CP-ACE-065 | Periodo sin notas (padre) | Aceptado | Padre del estudiante 4: «Sin notas en el periodo 1» |
| CP-ACE-066 | Error de conexión | Aceptado | «Sin conexión…» + Reintentar |
| CP-ACE-067 | Registro completo y notificación | **Rechazado** | Registro OK en la API (201), pero no hay notificación: APP-08 no implementado |
| CP-ACE-068 | Faltan datos obligatorios | Aceptado con observación | La app exige la descripción; la API no (N-13) |
| CP-ACE-069 | Consultar el historial | No ejecutado | — |
| CP-ACE-070 | Error de conexión | No ejecutado | — |
| CP-ACE-071 | Historial de novedades del hijo | Aceptado | Rosa: «Novedades recientes» de Sofía |
| CP-ACE-072 | Sin novedades | Aceptado | Hijo sin novedades: «Todo en orden · No hay novedades registradas.» |
| CP-ACE-073 | Credenciales incorrectas | **Rechazado** | N-18 |
| CP-ACE-074 | El admin ve toda la institución | Aceptado con observación | Ve las 10 novedades. Obs.: no están ordenadas por fecha (N-21) |
| CP-ACE-075 | Consultar mis hijos | **Rechazado** | Solo un hijo (APP-03) y sin nombre (N-05) |
| CP-ACE-076 | Seleccionar un hijo | **Rechazado** | APP-03 |
| CP-ACE-077 | Sin hijos vinculados | Aceptado con observación | «Sin estudiante vinculado» con el texto técnico «Perfil padre no encontrado» |
| CP-ACE-078 | Error de conexión | Aceptado | «Sin conexión…» + Reintentar |
| CP-ACE-079 | Ver mis clases | Aceptado | 4 asignaciones = API |
| CP-ACE-080 | Sin clases asignadas | No ejecutado | No hay docente sin asignaciones en QA |
| CP-ACE-081 | Error de conexión | No ejecutado | — |
| CP-ACE-082 | Ver mi horario | Aceptado | = `/cursos/1/horarios` |
| CP-ACE-083 | Sin horario registrado | No ejecutado | No hay curso sin horario con estudiante en QA |
| CP-ACE-084 | Error de conexión | No ejecutado | — |
| CP-ACE-085 a 087 | Notificaciones (recibir, no recibir, abrir) | **Rechazado** | APP-08 no implementado: la app nunca registra su token |
| CP-ACE-088 | Notificaciones bloqueadas | No ejecutado | — |
| CP-ACE-089 | Hay una versión nueva | **Rechazado** | APP-01 (firma de depuración) y N-14 (versión 0.1.0) |
| CP-ACE-090 | Sin conexión (actualización) | No ejecutado | — |
| CP-ACE-091 | Descargar el boletín | **Rechazado** | El PDF se abre, pero al volver la app queda en negro (N-17) |
| CP-ACE-092 | Sin datos para el boletín | **Rechazado** | Pantalla negra sin mensaje (N-17, N-09) |
| CP-ACE-094 | Sin datos para los filtros (reportes) | No ejecutado | La app no tiene filtros de reportes |
| CP-ACE-095 | Error de conexión o de acceso | No ejecutado | — |
| CP-ACE-096 | Consultar y descargar en la app | **Rechazado** | Se listan, pero ninguno se puede descargar: la app espera `completado` y la API usa `Generado` (N-22); además la API da 404 al archivo (N-23) |
| CP-ACE-097 | Sin reportes en la app | No ejecutado | QA tiene reportes |

**Resumen UAT (83 escenarios, con 037–042, 043–045 y 085–087 contados uno por uno):** Aceptado 28 · Aceptado con observación 9 · **Rechazado 17** · No ejecutado 29 (contado sobre la tabla). Con 17 escenarios rechazados, QA **no recomienda aceptar** la app en el estado de `develop` del 11/11/2026. El acta la decide el PO.

## 6.1 Preguntas de datos (resueltas en lo posible con la lógica de la app y la API de QA)

**Decisiones del 11/11/2026:** P-04 sí, P-09a sí, P-09c sí (estudiante 2), P-06 sí (`carlos.jimenez@eyes.edu.co` en mayúsculas). Datos temporales creados en QA, que se borran al terminar:

| Uso | Usuario | id_usuario | Verificación |
|---|---|---|---|
| P-04 · padre sin vínculo | `qa.padre.sinvinculo.<ts>@example.com` (creado por el admin con `POST /usuarios`, rol 4, sin registro en `/padres`) | 135 | `/padres/me` → 404 «Perfil padre no encontrado»; `/padres/me/hijos` → `[]` |
| P-09a · padre de un estudiante sin notas | `qa.padre.est4.<ts>@example.com` (autorregistro vinculado al estudiante 4, María Rodríguez) | 136 | Boletín → 404 «No hay datos disponibles para generar el boletín.» |

La respuesta real de `/padres/me` sin vínculo (404) confirma la suposición de IT-APP-02 «sin hijos».


| # | Caso | Qué se averiguó | Qué falta decidir |
|---|---|---|---|
| P-04 | CP-SIS-092 paso 8, CP-ACE-077 | En QA solo hay 2 padres (Rosa y Roberto), ambos vinculados. La app trata «sin vínculo» cuando `/padres/me` falla (`_bootstrapGuardian`: aviso «Tu cuenta de acudiente aún no está vinculada a un estudiante»). El registro de la app no deja crear un padre sin estudiante (campo obligatorio). | ¿QA crea por la API un usuario con `id_rol`=4 **sin** registro en `/padres` (y lo borra al terminar), o el equipo lo agrega al seed de BE-INF-2? |
| P-06 | CP-SIS-095 | «ana@x.com» no existe en QA. | ¿Se usa `carlos.jimenez@eyes.edu.co` escrito « Carlos.Jimenez@Eyes.edu.co »? (UT-APP-04 ya lo usa) |
| P-09a | CP-SIS-087 paso 4, CP-ACE-092 | Los estudiantes 4 a 15 no tienen notas ni padre. La API ya responde 404 con el texto correcto para el estudiante 4. Un padre autorregistrado queda activo de inmediato. | ¿QA registra un padre temporal vinculado al estudiante 4 para probar el boletín sin notas desde la app (y lo borra después)? |
| P-09b | CP-NF-019 | Se probó en la API con una cuenta temporal (padre autorregistrado) y funcionó sin tocar DS-01. | ¿Se aprueba usar siempre una cuenta temporal así para este caso? |
| P-09c | CP-SIS-097 | DS-02 no está en este repositorio. Se propone el estudiante 2 (Juan Pérez: 3 notas, 4 asistencias, 3 novedades). | ¿Cuál es el estudiante de DS-02? |
| P-10 | CP-SIS-062, CP-SIS-074 | Mensajes de la API confirmados: «Demasiados intentos, espera 15 minutos», «No hay entrada registrada hoy para este estudiante», «No hay datos disponibles para generar el boletín.», «Usuario inactivo», «Token expirado o revocado». | Tiempo máximo de llegada de la notificación y tiempo de espera para confirmar que la cola no reintenta |
| P-07 | CP-SIS-062 | — | (PO) Con dos hijos, ¿la notificación abre las novedades del hijo de la novedad o las del hijo activo? |
| P-08 | CP-SIS-081 paso 7 | La app valida 0.0–5.0 antes de enviar, así que el 422 no se provoca desde la app. | ¿Se acepta verificar el 422 solo en la API (prueba de BE-06)? |
| P-03 | CP-SIS-093 | Además, cerrar sesión con registros pendientes los borra (aviso de `profile_screen.dart`). | ¿Cómo se mantiene la cola durante la actualización OTA? |

## 7. Defectos

### 7.1 Conocidos (PR-07), confirmados en `develop`

| ID | Corrección | Evidencia en `develop` | Estado |
|---|---|---|---|
| DEF-029 | APP-01 | `android/app/build.gradle.kts:21` `com.example.eyes_school`; `:34` firma `debug` | Abierto |
| DEF-030 | APP-02 | `build.gradle.kts:24` `minSdk = flutter.minSdkVersion` | Abierto |
| DEF-031 | APP-03 | `session.dart:39` un único `childId`; no se llama `/padres/me/hijos` | Abierto |
| DEF-032 | APP-04 | `validators.dart:24-28` solo 8 caracteres | Abierto |
| DEF-033 | APP-06 | `auth_repository_impl.dart:36,249` solo `trim()` | Abierto |
| DEF-034 | APP-07 | `push_notification_service.dart:96` `debugPrint('[FCM TOKEN]…')`; `update_service.dart:36` `_repoName = 'eyes_school'` | Abierto |
| DEF-035 | APP-08 | Sin referencias a `/dispositivos` en `lib/` | Abierto |

### 7.2 Nuevos

| ID | Título | Evidencia | Severidad propuesta | Componente |
|---|---|---|---|---|
| N-01 | La URL por defecto de la API está caída y el APK de release no la cambia (**corregido en la rama `fix/api-config-url`, commit en GitHub; falta el PR a `develop`**) | `api_config.dart`: `apieyeschool-b7fudxavddh9hhah.canadacentral-01…` → `/openapi.json` 503; producción `api-eyesschool-hrf2gsg7hyf9dacq.westus3-01…` → 200. `release_apk.yml:34` `flutter build apk --release` sin `--dart-define` | Crítica | App |
| N-02 | Las pruebas, `ci.yml` y `coverage_report.dart` de `chore/modelo-calidad` no están en `develop` | `git merge-base --is-ancestor` negativo; `develop` tiene 59 pruebas | Alta (proceso) | App |
| N-03 | `develop` no tiene las correcciones de accesibilidad de `chore/modelo-calidad` | 11 archivos: `tooltip` en `IconButton`; `textSecondary` 0xFF7C7F93 (no cumple AA) | Media | App |
| N-05 | El padre ve vacío el nombre de su hijo en «Mi estudiante» | Con la sesión del padre, la API de QA responde 403 a `/usuarios/{id}` y `/estudiantes/{id}` trae los nombres en `null`. `DirectoryRepositoryImpl.studentProfile` arma el nombre con esas dos fuentes y no usa `nombre_estudiante` de `/padres/me`. Reproducido en prueba de widget con las respuestas reales: texto «» y avatar «?» (`children_screen_test.dart`) | Media (por confirmar en el emulador) | App |
| N-06 | El token de FCM también se imprime al renovarse | `push_notification_service.dart:104` `debugPrint('[FCM] Token re-generado: $newToken')`; la planeación de APP-07 solo cita las líneas 94–97 | Baja (se suma a DEF-034) | App |
| N-07 | Registros de asistencia con `tipo` desconocido se muestran como «Entrada» | QA devuelve `tipo` `Manual` y `QR` (datos heredados, la API ya no los acepta al crear). `AttendanceKind.parse` cae en `entry` sin avisar. `contrato_grabado_test.dart` | Media | API (datos) + App |
| N-08 | La cola reintenta una salida sin entrada en vez de dejarla fallida | Con el 400 real de QA el registro queda `pending` y se reintenta hasta 5 veces. Contradice la decisión del PO del 30/10/2026 y CP-SIS-074. `attendance_queue.dart`: el 400 cae en la rama genérica de `AppFailure`. `attendance_repository_test.dart` | Alta (riesgo R-03) | App |
| N-09 | El boletín sin notas muestra un mensaje genérico | Con el 404 real de QA la app produce «No encontramos el recurso solicitado.»: `dio.download` no decodifica el cuerpo del error y se pierde el `detail`. CP-SIS-087 y CA-PBI15.3 piden el texto exacto. `academic_repository_test.dart` | Media | App |
| N-10 | Cambio local sin commit en `api_config.dart` rompe la URL por defecto | El valor nuevo `'api-eyesschool-hrf2gsg7hyf9dacq.westus3-01.azurewebsites.net/api/v1'` no tiene `https://` y `baseUrl` le vuelve a agregar `/api/v1` → `…/api/v1/api/v1`. Debe ser `'https://api-eyesschool-hrf2gsg7hyf9dacq.westus3-01.azurewebsites.net'`. QA no lo modificó | Alta si se hace commit así | App · **Resuelto** el 11/11: se reemplazó por `https://api-eyesschool-hrf2gsg7hyf9dacq.westus3-01.azurewebsites.net` (verificado: `/api/v1/auth/me` → 401, API viva; con `/api/v1` duplicado → 404) |
| N-11 | Al padre se le dice «pendiente de validación» aunque su cuenta ya está activa | `register_screen.dart` `_showSuccess` muestra siempre ese texto; en QA el padre autorregistrado entra de inmediato (login 200), mientras que docente y administrador quedan inactivos | Baja | App |
| N-12 | Cambiar la contraseña desde el perfil siempre falla | La API de QA (BE-09) responde 400 «Debe indicar la contraseña actual para cambiarla». La app no tiene ese campo y `AuthRepositoryImpl.changePassword` (línea 231) solo envía `password` | Alta | App |
| N-13 | La API guarda novedades con descripción vacía | `POST /novedades` con `"descripcion": ""` → 201. La app lo valida, pero la web u otro cliente no tienen por qué hacerlo | Baja | API (backend) |
| N-14 | El APK publicado como v1.0.1 se reporta como 0.1.0: la OTA ofrece actualizar siempre | `git show v1.0.1:pubspec.yaml` → `version: 0.1.0+1`; `release_apk.yml:34` sin `--build-name`; el APK de QA dice `versionName='0.1.0'`. `UpdateService` compara la etiqueta con `PackageInfo.version` | Alta (MC-01 mide la OTA) | App / CI |
| N-15 | Se muestran y se cuentan registros de asistencia borrados | El DELETE de `/asistencia` es lógico (`activo=false`) y `GET /asistencia` los sigue devolviendo. El inicio del admin mostró «13 registros hoy» (12 activos) y la salida borrada del estudiante 6 | Media | App (no filtra `activo`) + API |
| N-16 | El admin ve «Estudiante 6» en vez del nombre | Inicio del admin, «Registro del día»; la API le entrega «Laura López» en `/usuarios/13`. La planilla del docente sí muestra los nombres | Media | App |
| N-17 | **Pantalla negra después de pedir el boletín** | Con notas: el PDF se abre y al volver la app queda negra. Sin notas: negra al instante y sin mensaje; «Atrás» cierra la app. Causa probable: `report_card_download.dart` abre el diálogo de progreso con `showDialog` (navegador raíz) y lo cierra con `Navigator.of(context).pop()`, que dentro del `ShellRoute` cierra la pantalla. Evidencia: `CP-SIS-087_pantalla_negra_sin_notas_API33.png`, `CP-SIS-087_regreso_tras_pdf_API33.png` | **Alta** | App |
| N-18 | **El login nunca muestra errores** (credenciales, bloqueo, sin red) | El formulario vuelve vacío y sin mensaje; la API recibió los 6 intentos (después responde 429). Causa probable: `SessionNotifier.login` pone el estado en «cargando», `app_router.dart:85` redirige a `/splash` y destruye `LoginScreen`; el error se escribe en una pantalla que ya no existe. Rompe CA-PBI2.3 (CP-SIS-067), CP-SIS-069 y CP-ACE-002/005 | **Alta** | App |
| N-19 | Un error de la API en un campo de otro paso del registro no se ve | Contraseña rechazada (422 en `password`, paso 2) → en el paso 3 solo «Revisa los datos marcados.» sin nada marcado; «Atrás» sale al login | Media | App |
| N-20 | Dos porcentajes de asistencia distintos para el mismo hijo | Padre de Juan: el inicio dice 75 % (dato de la API) y «Asistencia» dice 100 % «sobre los últimos 4 registros» (calculado por la app) | Media | App + API |
| N-21 | Las novedades del admin no están ordenadas por fecha | Orden mostrado: hace 5, 5, 4, 5 y 4 meses. CP-SIS-084 pide ordenarlas por fecha | Baja | App |
| N-22 | Ningún reporte se puede descargar desde la app | `Report.isReady` exige `estado == 'completado'` (`dashboard.dart:85`); la API usa «Generado». La app no ofrece descargar y pinta «Generado» igual que «Pendiente» | **Alta** | App (contrato) |
| N-23 | Los archivos de los reportes del seed no existen | `GET /reportes/1/archivo` → 404 «Archivo no encontrado en el servidor» | Media | API (datos) |
| N-24 | El enlace de recuperación de contraseña abre el login | `eyesschool://reset?token=…` (frío y caliente) termina en `/login`. La traducción existe (`app_router.dart:51-53`), pero la redirección inicial a `/splash` parece descartarla. No hay otro camino a `ResetPasswordScreen` | **Alta** | App |
| R-N1 | (Riesgo, no defecto) Vinculación del padre por id consecutivo | El registro pide «Código o id del estudiante» con teclado numérico. Los ids son enteros consecutivos (1 a 103 en QA): quien se registre como padre puede vincularse a cualquier estudiante y ver sus notas, asistencia y novedades. Es comportamiento por diseño (PO, 30/10/2026); QA recomienda que el PO lo revise por tratarse de datos de menores | — | PO |
| N-04 | `/dashboard/estudiante` devuelve `porcentaje_asistencia` mayor que 100 | QA, sofia.rodriguez: `{"porcentaje_asistencia": 140.6}`; el estudiante 1 tiene >500 registros, con varios «clase» en la misma fecha | Media | API (backend) |

---

## 8. Correcciones y regresión S2 (11–12/11/2026)

**Entregas:** app → PR [#16](https://github.com/AndresFelipeAceroLopez/eyes_school_app_movil/pull/16) (`fix/correcciones-qa` → `develop`; incluye las fusiones de las ramas de prueba, porque la regla del repositorio rechaza el push directo a `develop`). Backend → PR [#45](https://github.com/AndresFelipeAceroLopez/backend-Eyes-School/pull/45) (`fix/qa-defectos-app-movil` → `developer`). No se desplegó nada.

### 8.1 Métricas después de las correcciones

| Métrica | S1 (develop `f253eb0`) | S2 (`5374162`) | Umbral |
|---|---|---|---|
| `flutter analyze` | 0 | 0 | 0 |
| Formato | 117 archivos sin formato | 0 | 0 |
| Duplicación (jscpd) | 4,64 % | **2,89 %** | ≤ 3 % |
| Cobertura de la lógica | 33,5 % | **83,1 %** | ≥ 60 % (CI 75 %) |
| Pruebas | 59 | **166 aprobadas + 2 skip** (N-04, backend) | 100 % de las que no dependen de otro componente |
| Tamaño APK arm64 | 27,8 MB | 29,2 MB | ≤ 40 MB |
| minSdk | 24 | **30** | 30 |
| MobSF 4.4.0 (sin Docker, venv) | — | Altos: firma debug (APP-01, faltan secretos) y AES/CBC en una clase de `flutter_secure_storage` que la app no usa (`encryptedSharedPreferences: true`). Se corrigió `allowBackup` y se quitaron 2 permisos. | 0 altos |

### 8.2 Regresión en el emulador (APK de release de QA)

| Defecto / caso | Resultado S2 | Evidencia (`evidencias/PR-06/app/S2/`) |
|---|---|---|
| N-18 / CP-SIS-067 | «Correo o contraseña incorrectos.» y el formulario conserva los datos | `N-18_credenciales_incorrectas.png` |
| CP-SIS-069 | «Sin conexión. Revisa tu red e intenta de nuevo.» | `CP-SIS-069_login_sin_red.png` |
| N-24 | El enlace abre «Restablecer contraseña» con el código (en frío y con la app abierta). Nota: el correo del backend envía un enlace **web** (`FRONTEND_URL/reset-password`), no `eyesschool://` | `N-24_deeplink_frio.png` |
| N-25 (nuevo en S2) | Un código inválido mostraba «Tu sesión expiró»; ahora muestra el motivo de la API. Corregido y con prueba | `CP-ACE-017_codigo_invalido.png` (antes) |
| APP-03 / N-05 / CP-SIS-092 | «Mis hijos» lista a Sofía y Santiago con nombre; al elegir a Santiago, sus notas (promedio 3,5 = API) | `APP-03_*.png` |
| N-17 / N-09 / CP-SIS-087 | Con notas: el PDF se abre y al volver la app sigue en Notas. Sin notas: «No hay datos disponibles para generar el boletín.» | `N-17_*.png`, `N-09_boletin_sin_notas.png` |
| N-12 | Hoja con «Contraseña actual»; el cambio se aplica (la API acepta la nueva y rechaza la anterior) | `N-12_*.png` |
| N-20 / N-04 (app) | El inicio de Sofía muestra 75 % (antes 141 %) | — |
| N-15 | El historial del estudiante 6 cuenta 1 registro; la salida borrada ya no aparece | `N-15_historial_est6.png` |
| CP-NF-004 (log) | 0 líneas «FCM TOKEN» en el logcat del APK de release | — |
| CP-NF-010 | `minSdkVersion:'30'` | badging |

Datos temporales de QA creados y borrados en S2: padre del estudiante 4 (id 149). Quedan 0 usuarios `qa.*`.

### 8.3 Estado de los defectos

| Estado | Defectos |
|---|---|
| Corregidos en la app (PR #16) | APP-02, APP-03, APP-04, APP-06, APP-07, APP-08, N-01, N-02, N-03, N-05, N-07 (app), N-08, N-09, N-10, N-11, N-12, N-14, N-15, N-16, N-17, N-18, N-19, N-20, N-21, N-22, N-24, N-25 |
| Corregidos en el backend (PR #45, sin desplegar) | N-04, N-13, N-07 (seed + `scripts/qa/corregir_datos_asistencia.sql`) |
| Preparados, falta acción del equipo | APP-01: crear la clave de release y los secretos `RELEASE_KEYSTORE_BASE64`, `RELEASE_KEYSTORE_PASSWORD`, `RELEASE_KEY_ALIAS`, `RELEASE_KEY_PASSWORD`, `RELEASE_CERT_SHA256`; el `applicationId` definitivo exige registrar el paquete en Firebase y reemplazar `google-services.json` · APP-INF-1: restringir la API key de Firebase |
| Necesita decisión | N-23: los reportes del seed apuntan a archivos inexistentes y los subidos se guardan en el disco del App Service, que se reemplaza en cada despliegue |
| No ejecutado aún | Casos con cámara y CP-NF-007 en el POCO X7; registro masivo (requiere autorización); SUS y tareas medidas (participantes); bugs en Azure Boards |

---

## 9. Despliegue (12/11/2026)

| Componente | Qué se hizo | Resultado |
|---|---|---|
| Backend → QA | PR [#45](https://github.com/AndresFelipeAceroLopez/backend-Eyes-School/pull/45) fusionado en `developer` (CI, integración PostgreSQL 18, gitleaks y Sonar en verde) → workflow `apieyeschool-q` | Desplegado. Verificado en vivo: `/dashboard/estudiante` 99,94 % (antes 140,6 %), `/dashboard/padre` 100 %, novedad con descripción vacía → 422 |
| Datos de QA (N-07, estados) | Por la API (`PUT /asistencia/{id}`): `Tardanza` → `Tarde` | 1 registro (id 5) corregido |
| Datos de QA (N-07, `tipo`) | `scripts/qa/corregir_datos_asistencia.sql` | **Pendiente**: requiere la conexión de la base de QA (la API no permite cambiar `tipo`). El `.env` local apunta a una base de Render que no se pudo confirmar como la de QA, así que no se tocó |
| Backend → producción | — | **No desplegado**: requiere decisión (fusionar `developer` en `main` lleva también otros cambios) |
| App → `develop` | PR [#16](https://github.com/AndresFelipeAceroLopez/eyes_school_app_movil/pull/16) fusionado (commit `2d04035`) con CI, gitleaks y Quality Gate de SonarQube en verde (seguridad A, cobertura del código nuevo 81,5 %, duplicación 0,6 %) | Fusionado |
| Contrato app ↔ API | Regrabado tras el despliegue; los 2 `skip` de N-04 se quitaron | 168 de 168 pruebas |
| Backend · Newman | PR [#46](https://github.com/AndresFelipeAceroLopez/backend-Eyes-School/pull/46): CP-INT-052 busca solo un estudiante sin notas (cambio que estaba sin commit) | Fusionado |
| App → release APK (OTA) | Clave de release creada fuera del repositorio (`C:\Users\marig\.eyesschool-release\`, huella SHA-256 `7A:E1:AE:3F:…:99:22`) | **Pendiente**: cargar los 5 secretos `RELEASE_*` en GitHub (la sesión no tiene permiso para escribir secretos) y crear la etiqueta `v1.1.0` |

Ajustes hechos durante el despliegue:
- El CI usaba Flutter 3.50.0 (nuevo), que depreca `package:flutter/material.dart` (78 avisos de analyze). `ci.yml` y `release_apk.yml` fijan **Flutter 3.47.9**, la versión con la que se verificó todo; migrar a `material_ui` queda como tarea aparte.
- Una prueba traída de `chore/modelo-calidad` tenía una carrera entre pruebas (falló en Linux); se aisló la lista de escrituras de cada prueba.
- SonarQube marcaba como credencial el mapa de errores `'password': 'Requerido'` del login (S2068, falso positivo que `NOSONAR` no silencia); los campos del login ahora se nombran con el enum `LoginField`.
- `sonar.coverage.exclusions` aplica las exclusiones de la planeación de pruebas unitarias (sección 8).
- Antes de subir `planeacion/test` se encontró la contraseña de QA en dos logs de `integration_test` (Flutter repite los `--dart-define`); se tachó. Se verificó con `git log -S` que nunca entró al historial de ningún repositorio.
