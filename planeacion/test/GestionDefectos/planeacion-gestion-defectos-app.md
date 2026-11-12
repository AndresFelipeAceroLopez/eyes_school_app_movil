# Planeación del registro y gestión de defectos — App móvil (Flutter) · Eyes School

> **Tipo de documento:** planeación de QA para el PR-07 (Registro y gestión de defectos). Describe cómo se registran, clasifican, corrigen, verifican y cierran los defectos de este componente en Azure Boards, y lista los defectos que ya se conocen. No contiene resultados de ejecución.
> **Pensado para:** cualquier integrante del equipo o una IA que no conoce el proyecto. Los defectos conocidos salen de la revisión de código (prueba estática) del 28 al 30/10/2026 y del 02/11/2026, documentada en las planeaciones de correcciones, el PR-02 y el PR-03.
> **Elaboró:** Mariana Cortés (QA) · **Revisa:** Samuel Sierra (líder de pruebas) · **Aprueba:** Sergio Gómez (PO)
> **Plazo:** registro de los defectos conocidos en S7 (hasta el 6 nov 2026); gestión continua en S8 a S10; corte del PR-07 el 21 nov (S9) y cierre el 28 nov (S10), según el PR-01.

---

## 1. Dónde viven los defectos

| Elemento | Valor |
|---|---|
| Herramienta | Azure Boards del proyecto (proceso Scrum), tipo de elemento **Bug** |
| Etiquetas | `app-movil` (componente) y el origen: `revision-codigo`, `analisis-estatico`, `pruebas-unitarias`, `pruebas-integracion`, `pruebas-sistema` o `uat` |
| Enlace con el código | Cada PR de corrección en `eyes_school_app_movil` lleva `AB#<id>` en el título o la descripción. Requiere la app Azure Boards instalada en la organización de GitHub (una sola vez) |
| Relación con el caso | Campo «Repro Steps» con el ID del caso (CP-INT, CP-SIS, CP-NF o CP-ACE) y la corrección planeada (BE, WEB o APP) |

## 2. Ciclo de vida (proceso Scrum de Azure Boards)

| Estado | Quién lo mueve | Cuándo |
|---|---|---|
| New | QA | Al registrar el bug con la ficha de la sección 4 del PR-07 |
| Approved | PO (Sergio Gómez) | Al confirmar la prioridad en el refinamiento |
| Committed | Desarrollador asignado | Al tomarlo en el sprint |
| Done | QA (Mariana Cortés o Samuel Sierra) | Solo después de verificar la corrección en QA: el caso que lo detectó pasa y la regresión del módulo no rompe nada |
| Removed | PO | Si es un falso positivo o una decisión de diseño (con la justificación escrita) |

Un bug que falla la verificación vuelve a **Committed** y se cuenta como reabierto (métrica del PR-07).

## 3. Clasificación

- **Severidad (la define QA)** con los cuatro niveles del PR-07: Crítica, Alta, Media y Baja. En Azure Boards: 1 - Critical, 2 - High, 3 - Medium, 4 - Low.
- **Prioridad (la define el PO)** de P1 a P4. QA propone: Crítica → P1, Alta → P2, Media → P3, Baja → P4, y el PO la confirma o la cambia.
- **Tiempo objetivo de corrección:** Crítica ≤ 24 h; Alta ≤ 3 días; Media dentro del mismo sprint; Baja al backlog. Las críticas conocidas tienen acción el primer día de S7.

## 4. Defectos ya conocidos de este componente

Se registran en Azure Boards antes del 6 nov con estado New, etiqueta `revision-codigo` y la fecha en que se identificaron como fecha de apertura. El número `AB#` que asigne Azure Boards se anota en el PR-07.

| ID PR-07 | Corrección | Título | Severidad | Prioridad propuesta | Caso que lo verifica | Asignado | Identificado | Sprint |
|---|---|---|---|---|---|---|---|---|
| DEF-029 | APP-01 | El APK de release se firma con la clave de depuración y el applicationId es de plantilla: la OTA no instala | Alta | P2 | CP-NF-011, CP-SIS-093 | Andrés Acero | 28/10/2026 | S7 |
| DEF-030 | APP-02 | El minSdk no está fijado | Media | P3 | CP-NF-010 | Andrés Acero | 28/10/2026 | S7 |
| DEF-031 | APP-03 | La app solo maneja un hijo por padre | Alta | P2 | CP-SIS-092 | Mariana Cortés | 28/10/2026 | S8 |
| DEF-032 | APP-04 | La contraseña nueva solo exige 8 caracteres | Alta | P2 | CP-SIS-094 | Mariana Cortés | 28/10/2026 | S7 |
| DEF-033 | APP-06 | El correo no se pasa a minúsculas al iniciar sesión, registrarse ni recuperar contraseña | Media | P3 | CP-SIS-095 | Mariana Cortés | 28/10/2026 | S7 |
| DEF-034 | APP-07 | El token de notificaciones se imprime en el log (también en release) y el actualizador usa el nombre viejo del repositorio | Baja | P4 | CP-NF-004 | Andrés Acero | 28/10/2026 | S8 |
| DEF-035 | APP-08 | La app nunca envía su token de notificaciones a la API | Alta | P2 | CP-SIS-062 | Andrés Acero | 30/10/2026 | S8 |

## 5. Ficha del bug en Azure Boards

| Campo de Azure Boards | Contenido |
|---|---|
| Title | Verbo + qué falla + dónde (como los títulos de la sección 4) |
| Repro Steps | Pasos numerados, resultado esperado, resultado obtenido, ID del caso y corrección planeada |
| System Info | Android (POCO X7 / emulador API 30 o 33), versión del APK y commit |
| Severity / Priority | Sección 3 |
| Assigned To | Responsable de la corrección en la planeación |
| Tags | `app-movil` + origen |
| Adjuntos | Captura, video o log **sin tokens ni contraseñas** |
| Al cerrar | Causa raíz (Requisitos, Diseño, Codificación, Datos o Entorno) y commit de la corrección |

## 6. Verificación y regresión

1. El desarrollador fusiona la corrección en `develop` con la prueba que demuestra el defecto (fallaba antes y pasa después).
2. Se despliega en QA y QA repite el caso que lo detectó.
3. Se corre la regresión del módulo: las pruebas automatizadas del componente y los casos de sistema del mismo módulo.
4. Si todo pasa, QA mueve el bug a **Done** y anota la fecha de cierre; si no, vuelve a **Committed** y se cuenta como reabierto.

## 7. Registro en el PR-07

| Dato | Dónde va |
|---|---|
| Cada defecto con su `AB#`, estado y fechas | Tabla 2 (registro consolidado) |
| Conteos por severidad, reabiertos y tiempos | Tabla 3 (métricas) y Figura 2 |
| Causa raíz al cerrar | Sección 7 (análisis de causa raíz) |

Corte del registro: 21 nov 2026 (fin de S9) y 28 nov 2026 (fin de S10). En cada corte se exporta la consulta de Azure Boards («Bugs del proyecto Eyes School») a CSV y se anexa al PR-07.

## 8. Responsables y calendario

| Actividad | Fecha | Responsable |
|---|---|---|
| Registrar los 7 defectos conocidos en Azure Boards | 3 – 6 nov | Mariana Cortés |
| Confirmar prioridades | Refinamiento de S7 | Sergio Gómez (PO) |
| Registrar los defectos nuevos de PR-03 a PR-06 | Durante cada corrida | Quien ejecuta la corrida |
| Verificar correcciones y cerrar | S8 a S10 | Mariana Cortés · Samuel Sierra |
| Cortes del PR-07 | 21 y 28 nov | Samuel Sierra (líder de pruebas) |

## 9. Definición de terminado

- [ ] Los 7 defectos conocidos de este componente están en Azure Boards con su `AB#` anotado en el PR-07.
- [ ] Cada bug cerrado tiene la verificación en QA, la causa raíz y el commit.
- [ ] 0 defectos críticos o altos abiertos al cierre de S10 (criterio de salida del PR-01).
