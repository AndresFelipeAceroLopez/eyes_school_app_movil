# Planeación de pruebas unitarias y cobertura — App móvil (Flutter) · Eyes School

> **Tipo de documento:** planeación de QA para el PR-04 (Informe de pruebas unitarias y cobertura). Describe qué pruebas unitarias existen, cuáles se escriben, cómo se ejecutan, cómo se mide la cobertura y dónde queda cada resultado. No contiene resultados: se llenan al ejecutar.
> **Pensado para:** cualquier integrante del equipo o una IA que no conoce el proyecto. El inventario se contó leyendo el código del commit `cd650a7` el 02/11/2026.
> **Elaboró:** Mariana Cortés (QA) · **Revisa:** Samuel Sierra (líder de pruebas) · **Aprueba:** Sergio Gómez (PO)
> **Plazo:** las pruebas nuevas se escriben con cada corrección (S7 y S8); la ejecución que se reporta en el PR-04 es en S8 (7 – 14 nov 2026), según el PR-01.

---

## 1. Objetivo y alcance

Verificar unidades aisladas de la app (casos de uso, reglas de dominio, validadores, cola sin conexión, widgets) con dobles de prueba, y medir la cobertura de la lógica (capas `domain` y `data`) contra el umbral del MC-01.

| Es prueba unitaria (PR-04) | No es prueba unitaria |
|---|---|
| `usecases_test.dart`, `validators_test.dart`, `attendance_queue_test.dart`, `architecture_test.dart`, `accessibility_test.dart`, `app_boot_test.dart`, `student_home_resilience_test.dart` y las pruebas nuevas de las correcciones APP-xx | `dto_mapping_test.dart` y `*_repository_test.dart`: el PR-01 las clasifica como **pruebas de contrato app ↔ API** y se reportan en el PR-05 |
| Pruebas de widget con `ProviderScope` y dobles | `integration_test/` en dispositivo: PR-06 |

## 2. Contexto técnico

| Dato | Valor |
|---|---|
| Repositorio y commit | `eyes_school_app_movil` · `chore/modelo-calidad` · `cd650a7` (25/10/2026). Si para el 7 nov ya existe `develop` con las correcciones, se ejecuta sobre `develop` y se anota el commit |
| Framework | `flutter_test` (SDK). Sin librerías de mocks: los dobles son clases propias en `test/support/` (`memory_store.dart`, `scripted_api.dart` con `ScriptedAdapter` para Dio) |
| Cobertura | `flutter test --coverage` genera `coverage/lcov.info`; `tool/coverage_report.dart` la resume por capa (`domain`, `data`, `presentation`, `core`) y falla si la lógica (`domain` + `data`) baja del umbral |
| CI | `ci.yml`: `flutter test --coverage` → `dart run tool/coverage_report.dart --min-logic=75` → sube `coverage-lcov` como artefacto |
| Línea base (MC-01, 25/10/2026) | 110 de 110 pruebas aprobadas · lógica 81,5 % (domain 69,8 %, data 85,1 %) |

## 3. Inventario actual (contado en el código)

| Archivo | Casos | Qué prueba | Nivel |
|---|---|---|---|
| `usecases_test.dart` | 11 | `SaveGradeSheet`, `RegisterScan`, `TodaysClasses` y `NextClass`, `RestoreSession` | Unitaria |
| `attendance_queue_test.dart` | 11 | Cola sin conexión: encolar, duplicados, sincronizar, 409 como entregado | Unitaria |
| `validators_test.dart` | 8 | Validadores de formularios (correo, contraseña, nota) | Unitaria |
| `architecture_test.dart` | 5 | Ningún import cruza una frontera de capa prohibida | Unitaria (estática) |
| `accessibility_test.dart` | 2 | Área táctil, etiquetas y contraste en 2 pantallas | Widget |
| `app_boot_test.dart` | 2 | Arranque de la app | Widget |
| `student_home_resilience_test.dart` | 2 | El inicio del estudiante no se cae cuando la API falla | Widget |
| **Subtotal unitarias** | **41** | | |
| `dto_mapping_test.dart` | 20 | Mapeo JSON → entidades | Contrato (PR-05) |
| `academic_repository_test.dart` · `attendance_repository_test.dart` · `auth_repository_test.dart` · `directory_repository_test.dart` | 18 · 11 · 11 · 9 | Repositorios contra respuestas programadas con `ScriptedAdapter` | Contrato (PR-05) |
| **Total del proyecto** | **110** | | |

## 4. Pruebas unitarias nuevas (salen de la planeación de correcciones)

Cada una se escribe **antes** del cambio y debe fallar contra el código actual (definición de terminado de las correcciones).

| ID | Corrección | Archivo | Casos | Resultado esperado hoy |
|---|---|---|---|---|
| UT-APP-01 | APP-04 · política de contraseña | `test/password_policy_test.dart` | 6: `Colegio#2026` válida; `Ab1#`, `colegio#2026`, `COLEGIO#2026`, `Colegio#ocho` y `Colegio2026` fallan cada una por su regla | Falla: `PasswordPolicy` no existe |
| UT-APP-02 | APP-04 · mensaje del validador | `test/validators_test.dart` (casos nuevos) | `newPassword('Colegio2026')` → mensaje de carácter especial; `Colegio#2026` → `null` | Falla: hoy solo exige 8 caracteres |
| UT-APP-03 | APP-04 · formulario | Prueba de widget de `ResetPasswordScreen` | Con `Colegio2026` no se llama al repositorio (doble con contador en `ProviderScope`) | Falla |
| UT-APP-04 | APP-06 · correo | `test/validators_test.dart` (casos nuevos) | `normalizeEmail(' Ana@X.com ')` → `ana@x.com` | Falla: la función no existe |
| UT-APP-05 | APP-03 · varios hijos | Prueba de widget de `ChildrenScreen` | Con 2 hijos aparece la lista y al tocar el segundo se pide `/estudiantes/<segundo>/notas`; con 1 hijo no aparece | Falla |
| UT-APP-06 | APP-03 · arquitectura | `test/architecture_test.dart` | `LinkedChild` es Dart puro; sigue en verde | Pasa (regresión) |
| UT-APP-07 | APP-08 · token de notificaciones | `test/push_notification_service_test.dart` | Registro tras login; token renovado; permiso negado sin excepción; baja al cerrar sesión | Falla: el servicio no recibe sus dependencias |
| UT-APP-08 | APP-07 · actualizador | Prueba de `UpdateService` con `ScriptedAdapter` | Consulta el repositorio `eyes_school_app_movil`; versión mayor → `hasUpdate`; igual → no; sin red → no y sin excepción | Falla: apunta al nombre viejo |

Las pruebas de APP-03 que mapean JSON y la sesión con dos hijos (`dto_mapping_test.dart`, `auth_repository_test.dart`) son de contrato y van en la planeación del PR-05.

## 5. Herramientas en VS Code

- Extensiones **Flutter** y **Dart**: la pestaña Testing lista y ejecuta cada `test()` y muestra la cobertura.
- Flutter estable, el mismo canal del CI.
- Opcional, para ver la cobertura en HTML: `genhtml` (paquete `lcov` en Linux o WSL).

## 6. Ejecución (S8)

| Corrida | Fecha | Qué mide |
|---|---|---|
| U1 | 7 nov 2026 | Estado al empezar S8, con las pruebas nuevas que ya existan |
| U2 | 13 nov 2026 | Con las correcciones de S7 y S8 fusionadas; es el resultado oficial del PR-04 |

```bash
git rev-parse --short HEAD                     > evidencias/PR-04/app/U1_commit.txt
flutter pub get

# 1. Solo las pruebas unitarias y de widget (las de contrato van en el PR-05)
flutter test test/usecases_test.dart test/attendance_queue_test.dart test/validators_test.dart \
             test/architecture_test.dart test/accessibility_test.dart test/app_boot_test.dart \
             test/student_home_resilience_test.dart test/password_policy_test.dart \
             test/push_notification_service_test.dart \
             --reporter expanded                > evidencias/PR-04/app/U1_unitarias.txt

# 2. Suite completa con cobertura (es la cifra que exige el CI y el MC-01)
flutter test --coverage --reporter json        > evidencias/PR-04/app/U1_flutter_test.json
dart run tool/coverage_report.dart --min-logic=75 > evidencias/PR-04/app/U1_cobertura_por_capa.txt
cp coverage/lcov.info evidencias/PR-04/app/U1_lcov.info

# 3. Reporte HTML para la captura del PR-04 (opcional)
genhtml coverage/lcov.info -o evidencias/PR-04/app/U1_html
```

- El tiempo total de ejecución se toma de la línea final de `flutter test` (o del resumen del job en GitHub Actions).
- La cobertura de ramas no la reporta `lcov` de Flutter; en el PR-04 se escribe «No disponible en Flutter».

## 7. Criterios

| Indicador | Meta | Origen |
|---|---|---|
| Pruebas ejecutadas | 100 % de las planificadas | PR-01 |
| Pruebas aprobadas | ≥ 95 %; en la U2, 100 % de las de correcciones ya fusionadas | PR-01 / MC-01 |
| Cobertura de la lógica (`domain` + `data`) | ≥ 60 % para liberar; el CI no deja bajar de 75 % | MC-01 |
| Violaciones de arquitectura | 0 | MC-01 |

## 8. Exclusiones de la medición

| Excluido | Motivo |
|---|---|
| `lib/**/presentation/**` | Las pantallas se validan con pruebas de sistema (PR-06) y aceptación (PR-08); el MC-01 mide solo la lógica |
| `lib/main.dart` | Arranque de la app |
| `lib/core/**` | Se reporta aparte en `coverage_report.dart`; no entra en la meta |

## 9. Registro en el PR-04 y defectos

| Resultado | Dónde va |
|---|---|
| Totales de `U2_flutter_test.json` (planificadas, ejecutadas, aprobadas, fallidas, omitidas) | Tabla 1 |
| Archivos y número de casos | Tabla 2 (inventario) |
| `U2_cobertura_por_capa.txt` | Tabla 3 |
| Prueba fallida que no corresponde a una corrección planeada | Bug en Azure Boards (etiqueta `pruebas-unitarias`) y Tabla 4 |
| Prueba nueva que falla porque su corrección no se ha fusionado | Tabla 4 con estado «Falla esperada» y la referencia APP-xx |

## 10. Responsables y calendario

| Actividad | Fecha | Responsable |
|---|---|---|
| Escribir UT-APP-01 a 04 (APP-04, APP-06) | S7 | Mariana Cortés |
| Escribir UT-APP-05, 06 (APP-03), 07 (APP-08) y 08 (APP-07) | S8 | Mariana Cortés · Andrés Acero |
| U1 | 7 nov | Mariana Cortés |
| U2 y columna Móvil del PR-04 | 13 – 14 nov | Mariana Cortés · revisa Samuel Sierra |

## 11. Definición de terminado

- [ ] Las 8 pruebas nuevas existen, fallaron antes de su corrección y pasan después.
- [ ] U1 y U2 ejecutadas, con evidencias en `evidencias/PR-04/app/`.
- [ ] Lógica ≥ 75 % en el CI y 0 violaciones de arquitectura.
- [ ] Columna Móvil del PR-04 diligenciada y revisada por el líder de pruebas.
