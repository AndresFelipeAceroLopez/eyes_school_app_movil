# Planeación de pruebas de integración — App móvil (Flutter) · Eyes School

> **Tipo de documento:** planeación de QA para el PR-05 (Informe de pruebas de integración). Describe cómo se prueba la interfaz **app ↔ API**: qué casos, con qué herramientas, datos y comandos, y dónde queda cada resultado. No contiene resultados: se llenan al ejecutar.
> **Pensado para:** cualquier integrante del equipo o una IA que no conoce el proyecto. Los casos parten del PR-02 v0.2 (CP-INT-075, riesgo R-07) y el inventario se contó en el código del commit `cd650a7` el 02/11/2026.
> **Elaboró:** Mariana Cortés (QA) · **Revisa:** Samuel Sierra (líder de pruebas) · **Aprueba:** Sergio Gómez (PO)
> **Plazo:** montaje en S7 (hasta el 6 nov 2026) y ejecución en S8 (7 – 14 nov 2026), según el PR-01.

---

## 1. Objetivo y alcance

Verificar que la capa `data` de la app (clientes `*_api.dart`, DTO y repositorios) entiende las respuestas de la API y envía lo que la API espera. El PR-01 clasifica estas pruebas como **pruebas de contrato app ↔ API** (riesgo R-07: pantallas sin datos si el contrato se rompe).

| Entra | No entra |
|---|---|
| `dto_mapping_test.dart` y los `*_repository_test.dart`, más las pruebas de contrato nuevas de APP-03, APP-06 y APP-08 | Casos de uso, validadores y cola sin conexión con dobles: PR-04 |
| **Respuestas reales** de la API de QA guardadas como archivos de prueba (contrato grabado) | Flujos completos en el teléfono con `integration_test`: PR-06 |

## 2. Contexto técnico

| Dato | Valor |
|---|---|
| Repositorio y commit | `eyes_school_app_movil` · `chore/modelo-calidad` · `cd650a7`, o `develop` si ya tiene las correcciones (se anota el commit) |
| Clientes de la API | `lib/features/*/data/*_api.dart`: `academic_api`, `attendance_api`, `auth_api`, `dashboard_api`, `people_api`, `novedades_api`, `reportes_api` (Dio, base `EYESCHOOL_API_BASE` + `/api/v1`) |
| Doble de HTTP | `test/support/scripted_api.dart`: `ScriptedAdapter` responde por ruta (coincidencia por el final de la ruta) y registra las peticiones hechas |
| Framework | `flutter_test`, el mismo del PR-04 |

## 3. Casos

### 3.1 Pruebas de contrato existentes (CP-INT-075)

| Archivo | Casos | Qué verifica |
|---|---|---|
| `dto_mapping_test.dart` | 20 | Estados de asistencia con y sin tilde, fecha `yyyy-MM-dd`, horas `07:00:00`, nota entera o decimal, jornada, estudiante, gravedad de novedades, `id_rol` → pantalla |
| `academic_repository_test.dart` | 18 | Notas, horario y clases contra respuestas programadas |
| `attendance_repository_test.dart` | 11 | Envío y lectura de asistencia |
| `auth_repository_test.dart` | 11 | Login, sesión, perfil y recuperación |
| `directory_repository_test.dart` | 9 | Directorio y estudiantes |
| **Total** | **69** | Línea base (MC-01, 25/10/2026): aprobadas dentro de las 110 de la suite |

### 3.2 Pruebas de contrato nuevas (de la planeación de correcciones)

| ID | Corrección | Archivo | Caso | Hoy |
|---|---|---|---|---|
| IT-APP-01 | APP-03 | `test/dto_mapping_test.dart` | El JSON de `/padres/me/hijos` con 2 elementos produce 2 `LinkedChild` | Falla esperada (APP-03 y BE-07) |
| IT-APP-02 | APP-03 | `test/auth_repository_test.dart` | Con 2 hijos la sesión tiene 2 y `childId` es el primero; sin hijos la sesión se crea | Falla esperada |
| IT-APP-03 | APP-06 | `test/auth_repository_test.dart` | Login con « Ana@X.com »: el cuerpo enviado lleva `ana@x.com` | Falla esperada |
| IT-APP-04 | APP-08 | `test/device_token_repository_test.dart` | `POST /dispositivos` con `{"token_fcm": ...}` y `DELETE /dispositivos/{token}` | Falla esperada (APP-08 y BE-18) |
| IT-APP-05 | BE-08 · salida sin entrada | `test/attendance_repository_test.dart` | Un 400 «No hay entrada registrada hoy» queda como fallido con ese mensaje y no se reintenta sin fin | Sin ejecutar (verifica la decisión del PO del 30/10/2026) |
| IT-APP-06 | BE-19 | `test/academic_repository_test.dart` | Un 404 del boletín produce `AppFailure` con «No hay datos disponibles para generar el boletín.» | Sin ejecutar |

### 3.3 Contrato grabado contra la API real (IT-APP-07)

Hoy las respuestas de `ScriptedAdapter` están escritas a mano. Si la API cambia un campo, esas pruebas siguen en verde y la pantalla queda vacía. Para cerrar ese hueco:

1. Script `tool/grabar_contrato.sh` que inicia sesión en la API de QA con los usuarios de DS-01 y DS-03 y guarda, **sin el token**, las respuestas de los endpoints que usa la app en `test/fixtures/api/<endpoint>.json`: `/auth/me`, `/estudiantes/me`, `/estudiantes/{id}/notas`, `/estudiantes/{id}/asistencia`, `/estudiantes/{id}/novedades`, `/horarios`, `/asignaciones`, `/asistencia?fecha=`, `/novedades`, `/tipos-novedad`, `/reportes`, `/padres/me` y, cuando exista, `/padres/me/hijos`.
2. `test/contrato_grabado_test.dart` carga cada archivo, lo pasa por el DTO de la app y comprueba que no lanza excepción y que los campos obligatorios de la entidad tienen valor.
3. El script se corre antes de cada corrida (I1 e I2). Si el JSON cambió, `git diff test/fixtures/api/` muestra exactamente qué cambió en la API.
4. Los datos son sintéticos (seed de QA); aun así se revisa que no queden tokens ni contraseñas antes de hacer commit.

`/dashboard/estudiante` se graba aparte: hoy responde 500 (BE-03), así que su caso queda como falla esperada hasta el hotfix.

## 4. Preparación (S7)

- Flutter estable y VS Code con las extensiones Flutter y Dart.
- `curl` y `jq` para el script de grabación; variables `QA_API_URL` y correos de DS-01 y DS-03, y la contraseña `QA_PASSWORD` como secreto.
- URL de la API de QA: pendiente de definir en el PR-01. Mientras no exista, el script graba contra la API local de la planeación de integración del backend.

## 5. Ejecución (S8)

| Corrida | Fecha | Qué mide |
|---|---|---|
| I1 | 7 nov 2026 | Estado al empezar S8 |
| I2 | 13 nov 2026 | Con las correcciones de S7 y S8 en QA; resultado oficial del PR-05 |

```bash
git rev-parse --short HEAD > evidencias/PR-05/app/I1_commit.txt
flutter pub get

# 1. Grabar el contrato real (la contraseña sale de un secreto)
QA_API_URL=... QA_PASSWORD=... bash tool/grabar_contrato.sh
git diff --stat test/fixtures/api/      > evidencias/PR-05/app/I1_cambios_contrato.txt

# 2. Pruebas de contrato
flutter test test/dto_mapping_test.dart test/academic_repository_test.dart \
             test/attendance_repository_test.dart test/auth_repository_test.dart \
             test/directory_repository_test.dart test/device_token_repository_test.dart \
             test/contrato_grabado_test.dart \
             --reporter json                > evidencias/PR-05/app/I1_contrato.json
```

## 6. Criterios

| Indicador | Meta |
|---|---|
| Casos ejecutados | 100 % (69 existentes + IT-APP-01 a 07) |
| Casos aprobados en la I2 | ≥ 95 % (PR-01); 100 % de los que no dependen de una corrección pendiente |
| Endpoints grabados que la app no logra mapear | 0 |

## 7. Registro en el PR-05 y defectos

| Resultado | Dónde va |
|---|---|
| Totales de `I2_contrato.json` | Tabla 1 (sumados con la API y la web) |
| Casos de contrato | Tabla 2, fila «Móvil ↔ API», y Tabla 3 (CP-INT-075) |
| Cambio de contrato detectado por `git diff` | Tabla 6 y bug en Azure Boards (etiqueta `pruebas-integracion`) con el endpoint y el campo |

## 8. Responsables y calendario

| Actividad | Fecha | Responsable |
|---|---|---|
| Script de grabación y `contrato_grabado_test.dart` | 3 – 6 nov | Mariana Cortés |
| IT-APP-03 (APP-06) | S7 | Mariana Cortés |
| IT-APP-01, 02 (APP-03), 04 (APP-08), 05 y 06 | S8 | Andrés Acero · Mariana Cortés |
| I1 | 7 nov | Mariana Cortés |
| I2 y fila Móvil del PR-05 | 13 – 14 nov | Mariana Cortés · revisa Samuel Sierra |

## 9. Definición de terminado

- [ ] `test/fixtures/api/` tiene las respuestas reales de QA sin tokens.
- [ ] Las 6 pruebas nuevas y `contrato_grabado_test.dart` existen; las de correcciones fallaron antes y pasan después.
- [ ] I1 e I2 ejecutadas, con evidencias en `evidencias/PR-05/app/`.
- [ ] Fila Móvil ↔ API del PR-05 diligenciada y revisada por el líder de pruebas.
