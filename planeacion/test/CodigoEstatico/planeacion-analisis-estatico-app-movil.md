# Planeación del análisis estático — App móvil (Flutter) · Eyes School

> **Tipo de documento:** planeación de QA para el PR-03 (Informe de análisis estático de código). Describe qué se va a analizar, con qué herramientas y comandos, contra qué umbrales y dónde queda cada resultado. No contiene resultados: se llenan al ejecutar.
> **Pensado para:** cualquier integrante del equipo o una IA que no conoce el proyecto. Las rutas, versiones y pasos del CI se verificaron contra el repositorio el 02/11/2026.
> **Elaboró:** Mariana Cortés (QA) · **Revisa:** Samuel Sierra (líder de pruebas) · **Aprueba:** Sergio Gómez (PO)
> **Plazo:** preparación en S7 (hasta el 6 nov 2026) y ejecución en S8 (7 – 14 nov 2026), según el cronograma del PR-01.

---

## 1. Objetivo y alcance

El análisis estático revisa el código **sin ejecutarlo**: reglas del analizador de Dart, complejidad, duplicación, secretos, dependencias vulnerables y calidad general en SonarQube Cloud. Sus resultados alimentan el PR-03 y se comparan con los umbrales del MC-01.

| Entra | No entra |
|---|---|
| `lib/` (código de producción, 126 archivos Dart) | `build/`, `android/`, `web/`, `windows/` (excluidos en `analysis_options.yaml`) |
| `test/` y `tool/` solo para formato y análisis del CI | Análisis del APK con MobSF: es análisis del binario y va en el PR-06 (CP-NF-004) |
| Historial completo de git (secretos) | Pruebas unitarias y de widgets: son del PR-04, aunque el CI las corre en el mismo job |
| `pubspec.yaml` y `pubspec.lock` (dependencias) | |

## 2. Contexto técnico

| Dato | Valor |
|---|---|
| Repositorio | `github.com/AndresFelipeAceroLopez/eyes_school_app_movil` (público) |
| Rama y commit a analizar | `chore/modelo-calidad` · `cd650a7` (25/10/2026). Si para el 7 nov ya existe `develop` con las correcciones de S7, se analiza `develop` y se anota el commit exacto en el PR-03 |
| Lenguaje | Dart `^3.12.2` (canal estable de Flutter) |
| Reglas del analizador | `analysis_options.yaml`: `include: package:flutter_lints/flutter.yaml` (`flutter_lints ^6.0.0`) |
| CI actual | `.github/workflows/ci.yml`, job «Analisis estatico y pruebas»: `flutter pub get` → `dart format --set-exit-if-changed` (**con `continue-on-error: true`, no bloquea**) → `flutter analyze` → `flutter test --coverage` → `dart run tool/coverage_report.dart --min-logic=75` |
| Línea base (MC-01, 25/10/2026, mismo commit) | `flutter analyze`: 0 hallazgos · cobertura de la lógica 81,5 % · 0 violaciones de arquitectura · 18,7 KLOC |

## 3. Qué se mide

| # | Métrica | Herramienta | Umbral | Dónde va en el PR-03 |
|---|---|---|---|---|
| A1 | Hallazgos del analizador | `flutter analyze` | 0 (MC-01) | Tabla 1 (Quality Gate) y Tabla 2 |
| A2 | Formato | `dart format --set-exit-if-changed` | 0 archivos por formatear | Tabla 2 |
| A3 | Calificaciones de fiabilidad, seguridad y mantenibilidad; bugs, vulnerabilidades, hotspots, code smells, complejidad cognitiva, deuda técnica | SonarQube Cloud | Métrica adicional del MC-01 (Quality Gate «Sonar way» como referencia) | Tablas 1, 2 y 3; captura en la sección 3 |
| A4 | Complejidad ciclomática por función | `lizard 1.25.0` (soporta Dart) | Informativa: se reportan las funciones con CCN > 15 | Tabla 2 |
| A5 | Duplicación | `jscpd 4.3.0` | ≤ 3 % (MC-01) | Tablas 1 y 2 |
| A6 | Líneas de código | `pygount` (sin comentarios ni blancos) y las líneas físicas de jscpd | — | Tablas 2 y 3 |
| A7 | Secretos en el código y en el historial | `gitleaks 8.24.2` | 0 secretos sin justificar | Tablas 1 y 4 |
| A8 | Dependencias vulnerables | Dependabot (ecosistema `pub`) y `flutter pub outdated` | 0 críticas o altas (MC-01) | Tabla 1 |
| A9 | Violaciones de arquitectura | `test/architecture_test.dart` | 0 (MC-01) | Tabla 1 |
| A10 | Cobertura de la lógica (dato de entrada para SonarQube) | `flutter test --coverage` + `tool/coverage_report.dart` | ≥ 60 % (piso del CI 75 %) | Tablas 1 y 2 |

## 4. Preparación (S7, hasta el 6 nov)

### APP-SA-1 · SonarQube Cloud (es la tarea APP-INF-1 de la planeación de correcciones)

1. Entrar a SonarQube Cloud con la cuenta de GitHub del dueño del repositorio, importar la organización y el repositorio `eyes_school_app_movil` (gratis por ser público). Clave de proyecto sugerida: `AndresFelipeAceroLopez_eyes_school_app_movil`.
2. Desactivar el «Automatic Analysis» del proyecto, porque la cobertura solo llega por el CI.
3. Crear el secreto `SONAR_TOKEN` en GitHub → Settings → Secrets → Actions.
4. Agregar `sonar-project.properties` en la raíz:
   - `sonar.projectKey` y `sonar.organization` (los que muestre SonarQube Cloud)
   - `sonar.sources=lib`
   - `sonar.tests=test`
   - `sonar.dart.lcov.reportPaths=coverage/lcov.info`
   - `sonar.exclusions=lib/main.dart`
5. En `ci.yml`, después de «Coverage by layer», un paso con `SonarSource/sonarqube-scan-action` y `env: SONAR_TOKEN`.
6. Quality Gate del proyecto: «Sonar way». Se documenta en el PR-03 que el gate oficial del proyecto es el del MC-01 y que el de SonarQube es una métrica adicional.

### APP-SA-2 · gitleaks en el CI

- Job nuevo en `ci.yml` con `gitleaks/gitleaks-action` y `fetch-depth: 0` en el checkout, para revisar todo el historial.
- Hallazgo esperado: la clave de cliente de Firebase en `android/app/google-services.json`. No es un secreto de servidor, pero hay que **restringirla** en Google Cloud Console al paquete Android y a la huella de la firma de release (APP-01). Solo después de restringirla se agrega a la lista permitida en `.gitleaks.toml`, con un comentario que explique por qué.

### APP-SA-3 · Formato bloqueante

- Quitar `continue-on-error: true` del paso «Verify formatting». Antes, correr `dart format lib test tool` en un PR propio que solo cambie formato.

### APP-SA-4 · Dependabot para `pub`

- Archivo `.github/dependabot.yml` con `package-ecosystem: "pub"`, `directory: "/"` y `schedule.interval: "weekly"`. Revisar la pestaña Security → Dependabot alerts.

### APP-SA-5 · Herramientas locales de quien ejecuta

- Flutter estable (el mismo del CI) y VS Code con las extensiones Flutter y Dart.
- `pip install lizard==1.25.0 pygount` · Node.js para `npx jscpd@4.3.0` · binario `gitleaks` 8.24.2 desde GitHub Releases.
- Carpeta de evidencias del equipo: `evidencias/PR-03/app/` (en la unidad compartida, no en el repositorio).

## 5. Ejecución (S8)

Se hacen dos corridas sobre el mismo procedimiento:

| Corrida | Fecha | Qué mide |
|---|---|---|
| E1 · línea base del PR-03 | 7 nov 2026 | El estado al empezar S8 (commit anotado) |
| E2 · después de correcciones | 13 nov 2026 | El estado con las correcciones de S7 y S8 fusionadas; alimenta la sección 8 (evolución) del PR-03 |

Pasos de cada corrida, desde la raíz del repositorio y con la rama actualizada (`git pull`):

```bash
# 0. Registrar el entorno y el commit
git rev-parse --short HEAD              > evidencias/PR-03/app/E1_commit.txt
flutter --version                       > evidencias/PR-03/app/E1_flutter_version.txt
flutter pub get

# 1. Analizador y formato (A1, A2)
flutter analyze                         > evidencias/PR-03/app/E1_flutter_analyze.txt
dart format --output=none --set-exit-if-changed lib test tool > evidencias/PR-03/app/E1_format.txt

# 2. Arquitectura y cobertura (A9, A10)
flutter test test/architecture_test.dart
flutter test --coverage
dart run tool/coverage_report.dart --min-logic=75 > evidencias/PR-03/app/E1_coverage.txt

# 3. Complejidad y tamaño (A4, A6)
lizard lib -l dart --csv                > evidencias/PR-03/app/E1_lizard.csv
lizard lib -l dart -C 15 -w             > evidencias/PR-03/app/E1_lizard_ccn15.txt
pygount --format=summary lib            > evidencias/PR-03/app/E1_loc.txt

# 4. Duplicación (A5)
npx jscpd@4.3.0 lib --min-lines 5 --min-tokens 50 --reporters json,console --output evidencias/PR-03/app/E1_jscpd

# 5. Secretos en todo el historial (A7); --redact evita que el reporte muestre el valor
gitleaks git . --redact --report-format json --report-path evidencias/PR-03/app/E1_gitleaks.json

# 6. Dependencias (A8)
flutter pub outdated                    > evidencias/PR-03/app/E1_pub_outdated.txt
```

7. **SonarQube Cloud (A3):** abrir el proyecto después de que el CI corra sobre la rama analizada. Guardar:
   - captura del Overview (va en la sección 3 del PR-03);
   - captura de Issues filtrada por severidad Blocker y Critical (Tabla 4);
   - el valor de Technical Debt y Debt Ratio de la pestaña Measures → Maintainability (Tabla 3).
8. **Dependabot (A8):** captura de Security → Dependabot alerts con los filtros por severidad.

En E2 se repiten los mismos pasos cambiando el prefijo `E1_` por `E2_`.

## 6. Criterio de aprobación (Quality Gate de la app)

| Condición | Umbral | Origen |
|---|---|---|
| Hallazgos de `flutter analyze` | 0 | MC-01 / QG3 |
| Vulnerabilidades críticas o altas en código y dependencias (incluye secretos sin justificar) | 0 | MC-01 |
| Duplicación | ≤ 3 % | MC-01 |
| Violaciones de arquitectura | 0 | MC-01 |
| Cobertura de la lógica | ≥ 60 % (el CI exige 75 %) | MC-01 |
| Quality Gate de SonarQube Cloud | Aprobado (métrica adicional, no bloquea por sí sola) | MC-01, sección de instrumentos |

La app aprueba si cumple todas las condiciones con umbral del MC-01. Las funciones con CCN > 15 y los code smells de SonarQube se reportan y entran al plan de remediación, pero no bloquean.

## 7. Revisión dirigida (hallazgos ya conocidos que el análisis debe confirmar)

Estos puntos salieron de la revisión de código del 28 – 30/10/2026. El análisis debe confirmarlos o descartarlos y registrarlos en la Tabla 4 del PR-03:

| Ref. | Qué revisar | Dónde | Herramienta que debería detectarlo |
|---|---|---|---|
| APP-01 | Release firmado con la clave de depuración; `applicationId` de plantilla | `android/app/build.gradle.kts`, líneas 21 y 34 | Revisión manual (los analizadores de Dart no leen Gradle) |
| APP-02 | `minSdk` sin fijar | `android/app/build.gradle.kts`, línea 24 | Revisión manual |
| APP-07 | Token de notificaciones impreso con `debugPrint` | `push_notification_service.dart`, líneas 94–97 | SonarQube Cloud (registro de datos sensibles) o revisión manual |
| APP-INF-1 | Clave de cliente de Firebase sin restringir | `android/app/google-services.json` | gitleaks (`gcp-api-key`) |

## 8. Registro de hallazgos

- Todo hallazgo Bloqueante o Crítico de SonarQube, todo secreto y toda vulnerabilidad alta o crítica se registra como **Bug en Azure Boards** con la etiqueta `analisis-estatico` y se lista en la Tabla 4 del PR-03 (y luego en el PR-07).
- Los code smells mayores, la duplicación y las funciones con CCN > 15 entran al plan de remediación del PR-03 (sección 7), con esfuerzo, sprint y responsable.
- Un falso positivo se marca así en SonarQube (o en `.gitleaks.toml`) con la justificación escrita; no se borra.

## 9. Responsables y calendario

| Actividad | Fecha | Responsable |
|---|---|---|
| APP-SA-1 a APP-SA-4 (preparación) | 3 – 6 nov | Samuel Sierra (SonarQube, gitleaks, Dependabot) · Andrés Acero (formato) |
| E1 | 7 nov | Mariana Cortés |
| Registro de bugs y plan de remediación | 7 – 8 nov | Mariana Cortés |
| E2 | 13 nov | Mariana Cortés |
| Llenar la parte móvil del PR-03 | 13 – 14 nov | Mariana Cortés · revisa Samuel Sierra |

## 10. Definición de terminado

- [ ] SonarQube Cloud muestra el proyecto con cobertura cargada desde el CI.
- [ ] gitleaks y Dependabot activos; formato bloqueante en el CI.
- [ ] E1 y E2 ejecutadas, con todas las evidencias en `evidencias/PR-03/app/`.
- [ ] Bugs registrados en Azure Boards con la etiqueta `analisis-estatico`.
- [ ] Columna «Móvil» del PR-03 diligenciada y revisada por el líder de pruebas.
