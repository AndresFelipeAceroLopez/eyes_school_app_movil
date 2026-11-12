# Informe — Especificación de casos de prueba de la app móvil

> **Fecha:** 02/11/2026 · **Elaboró:** QA (sesión de especificación) · **Para:** Samuel Sierra (líder de pruebas) y Sergio Gómez (PO)

## 1. Archivos

| Archivo | Tipo | Qué es |
|---|---|---|
| `planeacion/test/Especificaciones/Especificacion_casos_prueba_app_movil.md` | Creado | Especificación de los 19 casos en el formato completo del PR-02 (ISO/IEC/IEEE 29119-3) y de los 6 flujos de `integration_test` |
| `planeacion/test/Especificaciones/Informe_especificacion_casos_prueba.md` | Creado | Este informe |
| `planeacion/test/Planeacion_test/planeacion-app-movil (1).md` | Fuente, solo lectura | Planeación de correcciones de la app |
| `planeacion/test/QR/DS-05_*.png` (6 imágenes) | Fuente, solo lectura | Conjunto DS-05: válidos EST001, EST002 y EST003; inválidos con código inexistente, texto libre y URL |
| `C:\Users\marig\Downloads\PR-02_Especificacion_de_Casos_de_Prueba_EyesSchool_v0.2.docx` | Fuente, solo lectura | Formato, IDs, datos de prueba (DS-01 a DS-10) y estado de cada caso |

No se modificó ningún archivo existente. Por instrucción, no se leyeron el PR-01, el PR-04, el PR-05 ni las demás planeaciones de `Downloads`.

## 2. Qué se hizo

1. Se leyó la planeación y se revisaron los QR del DS-05.
2. Se acordaron con el equipo el formato (29119-3), el alcance, la entrega en un solo MD y el tratamiento de D-A1 y D-A2.
3. Se leyó el PR-02 v0.2 para alinear los IDs, los datos, los textos de los mensajes y el estado («Falla esperada» o «Sin ejecutar»).
4. Se especificaron 19 casos y los 6 flujos de automatización:

| Grupo | Casos | Estado hoy |
|---|---|---|
| APP-01 | CP-NF-011, CP-SIS-093 | Falla esperada |
| APP-02 | CP-NF-010 | Falla esperada |
| APP-03 | CP-SIS-092 | Falla esperada |
| APP-04 | CP-SIS-094 | Falla esperada |
| APP-06 | CP-SIS-095 | Falla esperada |
| APP-07 | CP-NF-004 | Falla esperada |
| APP-08 | CP-SIS-062 (falla esperada) · CP-SIS-063 (sin ejecutar) | — |
| BE-03 | CP-SIS-066 | Falla esperada |
| BE-06 | CP-SIS-081 | Sin ejecutar |
| BE-08 | CP-SIS-076 (sin ejecutar) · CP-SIS-074 y CP-SIS-096 (falla esperada) | — |
| BE-13 | CP-NF-019 | Falla esperada |
| BE-16 | CP-SIS-067 | Falla esperada |
| BE-19 | CP-SIS-087 | Falla esperada |
| Nuevos | CP-SIS-097 (registro de padre en la app) · CP-SIS-098 (QR predecible, riesgo aceptado) | Sin ejecutar |
| APP-INF-2 | Flujos 1 a 6 → CP-SIS-066, 077, 076, 092, 097 y 062 | — |

## 3. Decisiones aplicadas

| Decisión | Dónde se aplicó |
|---|---|
| D-A1 = `co.edu.eyesschool.app` y D-A2 = API 30 (recomendación de QA) | Supuestos S-01 y S-02; datos de CP-NF-011 y CP-NF-010 |
| SonarQube y `gitleaks` no llevan casos (van al PR-03); BE-10 tampoco (no cambia nada visible) | Fuera del alcance, sección 1 |
| Las pruebas unitarias y de contrato solo se citan con su ID y archivo; el detalle queda en el PR-04 o el PR-05 | Campo «Automatizado» de cada caso |
| `dto_mapping_test.dart` es de contrato (CP-INT-075), no unitaria | CP-SIS-092 |
| UT-APP-07 verifica que no se registra el token con el permiso negado; CP-SIS-063 no | CP-SIS-063 |
| CP-SIS-076 no depende de BE-08 y hoy debería pasar | CP-SIS-076 |
| El modo avión con 409 no tiene caso propio: va en `attendance_queue_test.dart` (PR-04) y en CP-SIS-077 | No se creó caso |
| CP-SIS-097 y CP-SIS-098 son números nuevos libres; CP-SIS-098 va en la Tabla 2 (NF de seguridad), no en la matriz de CA | Sección 6 y sección 8 (cambios al PR-02) |

## 4. Preguntas abiertas (marcadas entre corchetes en la especificación)

| # | Caso | Pregunta | Para quién |
|---|---|---|---|
| P-01 | Varios | No pude verificar los números UT-APP-xx ni IT-APP-xx (salvo UT-APP-07) porque no leí el PR-04 ni el PR-05. Quedaron como `[UT-APP-xx]`. ¿Cuál corresponde a cada archivo? ¿`device_token_repository_test.dart` está en el PR-04 o en el PR-05? | Mariana Cortés |
| P-02 | CP-SIS-063, 067, 097, 098, CP-NF-019 | La prioridad no se puede sacar de la planeación ni del PR-02. ¿Qué prioridad llevan? | Samuel Sierra |
| P-03 | CP-SIS-093 | El caso pide actualizar «sin perder la cola», pero para descargar la actualización hace falta red y al volver la red la cola se sincroniza sola (CP-SIS-077). ¿Cómo se mantienen registros pendientes durante la actualización? | Andrés Acero |
| P-04 | CP-SIS-092 | Ningún conjunto DS tiene un padre sin estudiante vinculado. ¿Se agrega a DS-01 o DS-03? | Samuel Sierra |
| P-05 | CP-SIS-094 | ¿BE-09 exige la contraseña actual para cambiarla desde el perfil? Si la exige, `profile_screen.dart` tiene un campo nuevo | Andrés Acero |
| P-06 | CP-SIS-095 | «ana@x.com» no existe en ningún DS. ¿Se usa el docente de DS-01 con mayúsculas y espacios, o se crea Ana? | Samuel Sierra |
| P-07 | CP-SIS-062 | Si el padre tiene dos hijos, ¿la notificación abre las novedades del estudiante de la novedad o las del hijo activo? | Sergio Gómez (PO) |
| P-08 | CP-SIS-081 | La planeación pide confirmar que un 422 de BE-06 se muestra bien, pero `grade_entry_screen.dart` ya valida 0.0–5.0 antes de enviar. ¿Cómo se provoca el 422 desde la app? | Andrés Acero |
| P-09 | CP-SIS-087, CP-NF-019, CP-SIS-097 | Faltan datos: un estudiante sin notas vinculado a un padre; un usuario que se pueda desactivar sin afectar a DS-01; confirmar que el estudiante de DS-02 del CP-SIS-097 tiene notas, asistencia y novedades | Samuel Sierra |
| P-10 | CP-SIS-094, CP-NF-019, CP-SIS-062, CP-SIS-074 | Textos y tiempos sin definir: mensaje exacto de la regla de carácter especial, mensaje al cerrar la sesión de un usuario desactivado, tiempo máximo de llegada de la notificación y tiempo de espera para confirmar que no se reintenta | Mariana Cortés |
| P-11 | CP-NF-004, flujos | Versión y lugar de ejecución de MobSF; nombres de las variables `--dart-define` de los usuarios; cómo simulan los flujos 2 y 3 la cámara y la pérdida de red | Samuel Sierra |

## 5. Observaciones sobre el PR-02

- En la Tabla 3, APP-06 también tiene CP-SIS-089 (auto-registro por pasos). No se especificó porque no estaba en la asignación. ¿Se agrega?
- En la Tabla 3, APP-01 lista CP-NF-004. En la especificación, CP-NF-004 verifica la firma de release además de APP-07.
- CP-NF-010 necesita un emulador API 29 que no está en DS-10.
- Los cambios que hay que llevar al PR-02 (matriz, Tabla 2, Tabla 10, totales y DS-10) están en la sección 8 de la especificación.
