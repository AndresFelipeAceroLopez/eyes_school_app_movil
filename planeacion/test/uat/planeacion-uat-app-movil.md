# Planeación de pruebas de aceptación (UAT) — App móvil (Flutter) · Eyes School

> **Tipo de documento:** planeación de QA para el PR-08 (Informe de pruebas de aceptación y acta). Describe cómo se prepara y se conduce la UAT de la app móvil: escenarios, roles, tareas medidas, encuesta de satisfacción, criterios y acta. No contiene resultados: se llenan en la sesión.
> **Pensado para:** cualquier integrante del equipo o una IA que no conoce el proyecto. Los escenarios y sus ID son los del PR-02 v0.2 (sección 8, Gherkin).
> **Elaboró:** Mariana Cortés (QA) · **Revisa:** Samuel Sierra (líder de pruebas) · **Aprueba:** Sergio Gómez (PO)
> **Plazo:** preparación en S9 y sesión de UAT en S10 (22 – 28 nov 2026) con fecha fija, según el PR-01.

---

## 1. Objetivo

Que el Product Owner, Sergio Gómez, con la revisión del instructor Javier Yara, valide de la app móvil contra los criterios de aceptación de las HU y los PBI, y firme el acta de aceptación del PR-08. Además se mide la calidad en uso (ISO/IEC 25019): éxito de tareas, eficiencia, errores y satisfacción (SUS).

## 2. Condiciones para iniciar la UAT (criterios de entrada)

- [ ] Regresión de S10 terminada: 0 defectos críticos o altos abiertos en lo que se va a aceptar.
- [ ] Versión de QA congelada durante la sesión (sin despliegues) y anotada en el PR-08.
- [ ] Datos de QA recargados la mañana de la sesión (BE-INF-2) y usuarios por rol entregados a los participantes por canal privado.
- [ ] Casos de sistema del PR-06 ejecutados; los escenarios cuya corrección no se fusionó se marcan antes de empezar (columna «Depende de»).

## 3. Participantes y roles

| Participante | Rol en la sesión |
|---|---|
| Sergio Duván Gómez Rodríguez | Product Owner: ejecuta los escenarios con el usuario de cada rol y decide la aceptación |
| Javier Yara | Instructor: observa, revisa la evidencia y firma el acta |
| Samuel Stiven Sierra Rodríguez | Facilitador (líder de pruebas): guía la sesión y toma tiempos |
| Mariana Valentina Cortés Castillo | Facilitadora (QA): registra resultados, observaciones y errores de usuario |
| Representantes del colegio | Por confirmar con el PO: si participan, ejecutan las tareas de su rol y responden el SUS |

## 4. Entorno

| Elemento | Valor |
|---|---|
| Teléfono | POCO X7 (Android 15) con el APK de QA instalado; un segundo teléfono o emulador para el padre no vinculado |
| API | QA (pendiente de definir en el PR-01), con Firebase configurado para las notificaciones |
| Proyección | `scrcpy` (o la función de duplicar pantalla) para que el instructor vea el teléfono |
| Usuarios | Uno por rol (DS-01) y el padre de dos hijos (DS-03) |
| QR | DS-05 impresos o en otra pantalla |

## 5. Escenarios a validar (83)

«Depende de» indica la corrección que debe estar fusionada para que el escenario pueda aceptarse; si no lo está, el escenario se presenta como **Rechazado** o **Aceptado con observación** según decida el PO, nunca se omite.

| ID | Escenario | Funcionalidad (base) | Rol | Depende de |
|---|---|---|---|---|
| CP-ACE-001 | Inicio de sesión exitoso según el rol | Inicio de sesión · US017 · PBI 2 | Todos los roles | APP-06, BE-03, BE-12 |
| CP-ACE-002 | Credenciales incorrectas | Inicio de sesión · US017 · PBI 2 | Todos los roles | BE-16 |
| CP-ACE-005 | Error de conexión | Inicio de sesión · US017 · PBI 2 | Todos los roles | — |
| CP-ACE-006 | Sesión guardada en la app | Inicio de sesión · US017 · PBI 2 | Todos los roles | — |
| CP-ACE-007 | El docente ve solo sus módulos | Inicio por rol · US021 · PBI 88 | Todos los roles | — |
| CP-ACE-008 | Acceso a un módulo de otro rol | Inicio por rol · US021 · PBI 88 | Todos los roles | — |
| CP-ACE-009 | Error al cargar el inicio | Inicio por rol · US021 · PBI 88 | Todos los roles | — |
| CP-ACE-010 | Registro completo | Auto-registro · US019 · PBI 17 | Nuevo usuario | — |
| CP-ACE-011 | Correo ya registrado | Auto-registro · US019 · PBI 17 | Nuevo usuario | APP-06, BE-12 |
| CP-ACE-012 | Campo obligatorio vacío | Auto-registro · US019 · PBI 17 | Nuevo usuario | — |
| CP-ACE-013 | Registro de padre vinculado (comportamiento por diseño) | Auto-registro · US019 · PBI 17 | Nuevo usuario | — |
| CP-ACE-014 | Correo registrado | Recuperación de contraseña · US018 · PBI 14 | Todos los roles | — |
| CP-ACE-015 | Correo no registrado | Recuperación de contraseña · US018 · PBI 14 | Todos los roles | — |
| CP-ACE-016 | Nueva contraseña válida | Recuperación de contraseña · US018 · PBI 14 | Todos los roles | — |
| CP-ACE-017 | Enlace o contraseña no válidos | Recuperación de contraseña · US018 · PBI 14 | Todos los roles | — |
| CP-ACE-018 | Ver mi perfil | Perfil y cierre de sesión · US020 · PBI 13 | Todos los roles | — |
| CP-ACE-019 | Cerrar sesión | Perfil y cierre de sesión · US020 · PBI 13 | Todos los roles | BE-13, BE-17 |
| CP-ACE-030 | Consulta sin resultados | Gestión de usuarios · US001–US004 · PBI 3 | Administrador | — |
| CP-ACE-031 | Error de conexión en la consulta | Gestión de usuarios · US001–US004 · PBI 3 | Administrador | — |
| CP-ACE-032 | Directorio en la app | Gestión de usuarios · US001–US004 · PBI 3 | Administrador | — |
| CP-ACE-033 | Ver mi QR | Código QR del estudiante · US028 · PBI 4 | Estudiante | — |
| CP-ACE-034 | El QR de la web se lee en la app | Código QR del estudiante · US028 · PBI 4 | Estudiante | — |
| CP-ACE-036 | QR sin conexión en la app | Código QR del estudiante · US028 · PBI 4 | Estudiante | — |
| CP-ACE-037 | Entrada por primera vez en el día | Asistencia por código QR · US005, US006 · PBI 5 | Estudiante | — |
| CP-ACE-038 | Código inválido | Asistencia por código QR · US005, US006 · PBI 5 | Estudiante | — |
| CP-ACE-039 | Doble entrada | Asistencia por código QR · US005, US006 · PBI 5 | Estudiante | BE-08 |
| CP-ACE-040 | Salida después de la entrada | Asistencia por código QR · US005, US006 · PBI 5 | Estudiante | — |
| CP-ACE-041 | Doble salida | Asistencia por código QR · US005, US006 · PBI 5 | Estudiante | BE-08 |
| CP-ACE-042 | Escaneo sin conexión | Asistencia por código QR · US005, US006 · PBI 5 | Estudiante | — |
| CP-ACE-043 | Registrar el curso con excepciones | Registro masivo de asistencia · US025 · PBI 9 | Administrador | — |
| CP-ACE-044 | Falla la conexión a mitad del envío | Registro masivo de asistencia · US025 · PBI 9 | Administrador | — |
| CP-ACE-045 | Reintentar los fallidos | Registro masivo de asistencia · US025 · PBI 9 | Administrador | — |
| CP-ACE-046 | Filtrar el registro del día | Registro de asistencia del día · US026 · PBI 10 | Administrador | — |
| CP-ACE-047 | Registros pendientes | Registro de asistencia del día · US026 · PBI 10 | Administrador | — |
| CP-ACE-048 | Sin datos para los filtros | Registro de asistencia del día · US026 · PBI 10 | Administrador | — |
| CP-ACE-049 | Error de conexión | Registro de asistencia del día · US026 · PBI 10 | Administrador | — |
| CP-ACE-050 | Ver la asistencia del hijo | Historial de asistencia · US012 · PBI 11 | Padre | BE-04 |
| CP-ACE-051 | Credenciales inválidas | Historial de asistencia · US012 · PBI 11 | Padre | — |
| CP-ACE-052 | Error de conexión | Historial de asistencia · US012 · PBI 11 | Padre | — |
| CP-ACE-053 | Sin registros | Historial de asistencia · US012 · PBI 11 | Padre | — |
| CP-ACE-054 | Nota válida | Registro de notas y promedios · US007, US008 · PBI 6 (CA ajustados por el PO el 30/10/2026) | Docente | — |
| CP-ACE-055 | Nota fuera de rango | Registro de notas y promedios · US007, US008 · PBI 6 (CA ajustados por el PO el 30/10/2026) | Docente | BE-06 |
| CP-ACE-056 | Falta información obligatoria | Registro de notas y promedios · US007, US008 · PBI 6 (CA ajustados por el PO el 30/10/2026) | Docente | — |
| CP-ACE-057 | Error de conexión | Registro de notas y promedios · US007, US008 · PBI 6 (CA ajustados por el PO el 30/10/2026) | Docente | — |
| CP-ACE-058 | El promedio se actualiza | Registro de notas y promedios · US007, US008 · PBI 6 (CA ajustados por el PO el 30/10/2026) | Docente | — |
| CP-ACE-059 | Nota ya registrada | Registro de notas y promedios · US007, US008 · PBI 6 (CA ajustados por el PO el 30/10/2026) | Docente | — |
| CP-ACE-060 | Error en el cálculo | Registro de notas y promedios · US007, US008 · PBI 6 (CA ajustados por el PO el 30/10/2026) | Docente | — |
| CP-ACE-061 | El estudiante ve sus notas | Consulta de notas · US010, US011 · PBI 7 | Estudiante y padre | — |
| CP-ACE-062 | Trimestre sin notas | Consulta de notas · US010, US011 · PBI 7 | Estudiante y padre | — |
| CP-ACE-063 | Credenciales incorrectas | Consulta de notas · US010, US011 · PBI 7 | Estudiante y padre | — |
| CP-ACE-064 | El padre ve las notas de su hijo | Consulta de notas · US010, US011 · PBI 7 | Estudiante y padre | — |
| CP-ACE-065 | Periodo sin notas (padre) | Consulta de notas · US010, US011 · PBI 7 | Estudiante y padre | — |
| CP-ACE-066 | Error de conexión | Consulta de notas · US010, US011 · PBI 7 | Estudiante y padre | — |
| CP-ACE-067 | Registro completo y notificación | Registro de novedades · US009 · PBI 8 | Docente | — |
| CP-ACE-068 | Faltan datos obligatorios | Registro de novedades · US009 · PBI 8 | Docente | — |
| CP-ACE-069 | Consultar el historial | Registro de novedades · US009 · PBI 8 | Docente | — |
| CP-ACE-070 | Error de conexión | Registro de novedades · US009 · PBI 8 | Docente | — |
| CP-ACE-071 | Historial de novedades del hijo | Consulta de novedades · US013 · PBI 12 | Padre | — |
| CP-ACE-072 | Sin novedades | Consulta de novedades · US013 · PBI 12 | Padre | — |
| CP-ACE-073 | Credenciales incorrectas | Consulta de novedades · US013 · PBI 12 | Padre | — |
| CP-ACE-074 | El administrador ve toda la institución | Consulta de novedades · US013 · PBI 12 | Padre | — |
| CP-ACE-075 | Consultar mis hijos | Hijos asociados · US024 · PBI 91 | Padre | APP-03, BE-07 |
| CP-ACE-076 | Seleccionar un hijo | Hijos asociados · US024 · PBI 91 | Padre | APP-03, BE-07 |
| CP-ACE-077 | Sin hijos vinculados | Hijos asociados · US024 · PBI 91 | Padre | — |
| CP-ACE-078 | Error de conexión | Hijos asociados · US024 · PBI 91 | Padre | — |
| CP-ACE-079 | Ver mis clases | Clases asignadas · US023 · PBI 90 | Docente | — |
| CP-ACE-080 | Sin clases asignadas | Clases asignadas · US023 · PBI 90 | Docente | — |
| CP-ACE-081 | Error de conexión | Clases asignadas · US023 · PBI 90 | Docente | — |
| CP-ACE-082 | Ver mi horario | Horario de clases · US022 · PBI 89 | Estudiante | — |
| CP-ACE-083 | Sin horario registrado | Horario de clases · US022 · PBI 89 | Estudiante | — |
| CP-ACE-084 | Error de conexión | Horario de clases · US022 · PBI 89 | Estudiante | — |
| CP-ACE-085 | El acudiente vinculado recibe la notificación | Notificaciones de novedades · US027 · PBI 92 | Padre | APP-08, BE-18 |
| CP-ACE-086 | Un acudiente no vinculado no la recibe | Notificaciones de novedades · US027 · PBI 92 | Padre | APP-08, BE-18 |
| CP-ACE-087 | Abrir la notificación | Notificaciones de novedades · US027 · PBI 92 | Padre | APP-08 |
| CP-ACE-088 | Notificaciones bloqueadas | Notificaciones de novedades · US027 · PBI 92 | Padre | — |
| CP-ACE-089 | Hay una versión nueva | Actualización de la app · PBI 93 (no aplica en web) | Todos los roles | APP-01 |
| CP-ACE-090 | Sin conexión | Actualización de la app · PBI 93 (no aplica en web) | Todos los roles | — |
| CP-ACE-091 | Descargar el boletín | Boletín académico · US014 · PBI 15 | Padre | — |
| CP-ACE-092 | Sin datos para el boletín | Boletín académico · US014 · PBI 15 | Padre | BE-19 |
| CP-ACE-094 | Sin datos para los filtros | Reportes · US016 (CA ajustados por el PO el 30/10/2026) · PBI 16 | Administrador | — |
| CP-ACE-095 | Error de conexión o de acceso a datos | Reportes · US016 (CA ajustados por el PO el 30/10/2026) · PBI 16 | Administrador | — |
| CP-ACE-096 | Consultar y descargar en la app | Reportes · US016 (CA ajustados por el PO el 30/10/2026) · PBI 16 | Administrador | — |
| CP-ACE-097 | Sin reportes en la app | Reportes · US016 (CA ajustados por el PO el 30/10/2026) · PBI 16 | Administrador | — |

## 6. Tareas medidas (calidad en uso)

Cada participante hace las tareas de su rol **sin ayuda**. El facilitador mide el tiempo y cuenta los errores (acciones que el usuario tuvo que deshacer o en las que pidió ayuda).

| Rol | Tarea | Escenario relacionado |
|---|---|---|
| Docente | Escanear la entrada de tres estudiantes, una de ellas sin conexión | Asistencia por código QR |
| Docente | Registrar una nota | Registro de notas y promedios |
| Administrador | Buscar un estudiante en el directorio | Gestión de usuarios (directorio) |
| Estudiante | Abrir su QR sin conexión y consultar su horario | Código QR · Horario |
| Padre | Cambiar de hijo (DS-03) y consultar sus novedades | Hijos asociados · Consulta de novedades |
| Padre | Abrir una notificación de novedad | Notificaciones de novedades |

- **Tiempo esperado:** el que tarda un integrante del equipo en hacer la misma tarea, medido en S9. La meta de eficiencia es ≤ 1,5 veces ese tiempo.
- **Eficacia:** tareas completadas sin ayuda ÷ tareas asignadas, por rol. Meta ≥ 85 % (MC-01).
- **Errores de usuario:** meta ≤ 1 por tarea.

## 7. Encuesta de satisfacción (SUS)

Se entrega al final de la sesión, en papel o en un formulario, a cada participante.

| # | Afirmación (escala 1 = totalmente en desacuerdo a 5 = totalmente de acuerdo) |
|---|---|
| 1 | Creo que me gustaría usar este sistema con frecuencia |
| 2 | Encontré el sistema innecesariamente complejo |
| 3 | Pensé que el sistema era fácil de usar |
| 4 | Creo que necesitaría el apoyo de una persona técnica para poder usar este sistema |
| 5 | Encontré que las funciones de este sistema estaban bien integradas |
| 6 | Pensé que había demasiada inconsistencia en este sistema |
| 7 | Imagino que la mayoría de las personas aprenderían a usar este sistema muy rápido |
| 8 | Encontré el sistema muy difícil de usar |
| 9 | Me sentí muy seguro usando el sistema |
| 10 | Necesité aprender muchas cosas antes de poder usar este sistema |

Puntaje = (Σ(ítems impares − 1) + Σ(5 − ítems pares)) × 2,5. Escala de 0 a 100; meta ≥ 68.

Escenarios que solo aplican en la web (gestión de usuarios: crear, editar y eliminar; registro de reportes; campos vacíos y cierre por inactividad del panel) no se validan en la app: están en la planeación de UAT de la web. La OTA (CP-ACE de actualización) exige haber instalado antes la versión anterior del APK.

## 8. Conducción de la sesión

1. Presentación del alcance (HU y PBI incluidos, US015 excluida, CA-US016.2 y .3 diferidos) y de la forma de registrar resultados.
2. Por cada rol: las tareas medidas de la sección 6 y luego los escenarios de la sección 5 de ese rol.
3. Cada escenario se marca **Aceptado**, **Aceptado con observación** o **Rechazado**, con la observación del PO en sus palabras.
4. Cada observación se clasifica como Defecto, Mejora o Nueva HU, con la decisión del PO (corregir antes de liberar o backlog) y un plazo.
5. Encuesta SUS.
6. Lectura del resumen y firma del acta: se acepta, se acepta con observaciones (con fecha límite) o no se acepta.

## 9. Registro en el PR-08 y defectos

| Resultado | Dónde va |
|---|---|
| Fecha, versión, entorno, facilitadores y duración | Sección 1 del PR-08 |
| Participantes | Tabla 1 |
| Resultado y observaciones de cada escenario | Tabla 2 |
| Eficacia, eficiencia, SUS y errores | Tabla 3 |
| Observaciones clasificadas | Sección 5 |
| Decisión y firmas | Acta de aceptación |

Cada escenario rechazado y cada observación clasificada como Defecto es un bug en Azure Boards con la etiqueta `uat` (ficha del PR-07).

## 10. Responsables y calendario

| Actividad | Fecha | Responsable |
|---|---|---|
| Confirmar fecha, lugar y participantes | S9 | Sergio Gómez (PO) · Samuel Sierra |
| Medir los tiempos esperados de las tareas | S9 | Mariana Cortés |
| Preparar formatos (resultados, tiempos, SUS) | S9 | Mariana Cortés |
| Sesión de UAT | Fecha por definir en S10 (22 – 28 nov) | Samuel Sierra · Mariana Cortés |
| PR-08 y acta firmada | Hasta el 28 nov | Mariana Cortés · firma Sergio Gómez, Samuel Sierra y Javier Yara |

## 11. Definición de terminado

- [ ] Todos los escenarios de la sección 5 tienen resultado y, si aplica, observación.
- [ ] Tareas medidas y SUS registrados por participante.
- [ ] Bugs de la UAT en Azure Boards con la etiqueta `uat`.
- [ ] Acta firmada por el PO, el líder del equipo y el instructor.
