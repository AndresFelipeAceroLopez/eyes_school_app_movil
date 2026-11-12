# Planeación de pruebas de sistema — App móvil (Flutter) · Eyes School

> **Tipo de documento:** planeación de QA para el PR-06 (Informe de pruebas de sistema). Describe qué casos de sistema de la app se ejecutan, en qué dispositivos, con qué herramientas y dónde queda cada resultado. No contiene resultados: se llenan al ejecutar.
> **Pensado para:** cualquier integrante del equipo o una IA que no conoce el proyecto. Los casos y sus ID son los del PR-02 v0.2.
> **Elaboró:** Mariana Cortés (QA) · **Revisa:** Samuel Sierra (líder de pruebas) · **Aprueba:** Sergio Gómez (PO)
> **Plazo:** montaje de `integration_test` en S8 (APP-INF-2) y ejecución en S9 (15 – 21 nov 2026), según el PR-01. Regresión en S10.

---

## 1. Objetivo y alcance

Verificar la app completa, instalada en teléfonos reales y emuladores, contra la API y la base de QA: flujos de punta a punta por rol (funcionales) y características no funcionales (seguridad del APK, arranque, accesibilidad, compatibilidad y resiliencia).

| Entra | No entra |
|---|---|
| 31 casos de sistema de la app (CP-SIS «Móvil») y 3 que cruzan web y app | Casos de la web: planeación web del PR-06 |
| No funcionales de la app: CP-NF-004, 006, 007, 009, 010 y 011, y la parte móvil de CP-NF-017, 018 y 019 | Carga de la API y escaneo DAST: planeación del backend del PR-06 |

## 2. Entorno y dispositivos

| Elemento | Valor |
|---|---|
| APK | Build de QA con `--dart-define=EYESCHOOL_API_BASE=<URL de la API de QA sin /api/v1>` y firma de release (APP-01) |
| API y base | QA (URL pendiente de definir en el PR-01); datos de BE-INF-2 cargados antes de cada día de pruebas |
| Dispositivo físico | POCO X7 · HyperOS · Android 15 (API 35) |
| Emuladores | Android 11 (API 30, mínimo) y Android 13 (API 33, cambio del permiso de notificaciones) |
| Segundo equipo | Emulador o teléfono con la sesión de un padre **no** vinculado, para CP-SIS de notificaciones |
| Usuarios | DS-01 (un usuario por rol; padre de un hijo `roberto.diaz@gmail.com`) y DS-03 (padre de dos hijos `rosa.perez@gmail.com`). Contraseña `QA_PASSWORD`, entregada por canal privado |
| Datos de QR | DS-05 (`DS-05_codigos_QR.zip`): 3 inválidos y 3 válidos |

## 3. Herramientas

| Herramienta | Uso |
|---|---|
| `integration_test` (SDK de Flutter) | Flujos automatizados de la sección 4.2, en el teléfono y en los emuladores |
| `adb` | Instalar el APK, grabar la pantalla (`adb shell screenrecord`) y medir el arranque (`adb shell am start -W`) |
| MobSF (Docker) | Análisis del APK de release (CP-NF-004) |
| `apksigner` y `aapt` (Android SDK build-tools) | Firma, `applicationId` y `minSdk` (CP-NF-010 y 011) |
| Accessibility Scanner (Google Play) y `accessibility_test.dart` | Accesibilidad (CP-NF-006) |
| VS Code con Flutter y Dart | Ejecutar `integration_test` y ver los registros |

## 4. Casos

### 4.1 Casos de sistema de la app

| ID | Escenario | Pasos clave | Resultado esperado | Automatización | Hoy |
|---|---|---|---|---|---|
| CP-SIS-063 | Permiso de notificaciones negado | Emulador API 33: negar el permiso; registrar una novedad | La app funciona y la novedad aparece en la pantalla de novedades | Manual | Sin ejecutar |
| CP-SIS-066 | Inicio de sesión por rol | Iniciar sesión con DS-01 en cada rol | Llega al inicio del rol y los datos cargan | integration_test (APP-INF-2) | Falla esperada (BE-03) |
| CP-SIS-067 | Credenciales incorrectas y bloqueo | Contraseña errada; luego 6 intentos fallidos | Mensaje genérico; al 6.º «Demasiados intentos, espera 15 minutos» | integration_test (APP-INF-2) + manual | Falla esperada (BE-16) |
| CP-SIS-068 | Sesión guardada | Iniciar sesión, cerrar la app y abrirla | Entra sin pedir login | auth_repository_test.dart + manual | Sin ejecutar |
| CP-SIS-069 | Sin conexión al iniciar sesión | Modo avión; iniciar sesión | Mensaje de error de red y opción de reintentar | Manual | Sin ejecutar |
| CP-SIS-070 | Inicio por rol | Entrar con cada rol; intentar abrir una ruta de otro rol; API caída | Solo módulos del rol; navegación bloqueada; mensaje y reintento | integration_test (APP-INF-2) + manual | Sin ejecutar |
| CP-SIS-071 | Directorio de usuarios | Admin abre el directorio, cambia de pestaña y busca; búsqueda sin resultados; API caída | Pestañas estudiantes, docentes y acudientes; resultados en vivo; mensaje; reintento | Manual | Sin ejecutar |
| CP-SIS-072 | Mi QR sin conexión | Estudiante en modo avión abre Mi QR | QR generado en el teléfono con nombre y datos básicos | Manual | Sin ejecutar |
| CP-SIS-073 | Escaneo QR: entrada y salida | Docente escanea un QR válido; luego el mismo QR otra vez | Primero entrada y luego salida, con fecha, hora y tipo | integration_test | Sin ejecutar |
| CP-SIS-074 | Salida sin entrada previa | Escanear como salida el QR de un estudiante sin entrada hoy | Mensaje «No hay entrada registrada hoy para este estudiante»; no queda en la cola | Manual | Falla esperada (BE-08) |
| CP-SIS-075 | Escaneo QR inválido | Escanear un QR que no es de un estudiante | Mensaje claro de error | Manual | Sin ejecutar |
| CP-SIS-076 | Doble registro en el mismo teléfono | Escanear el mismo QR para el mismo tipo dos veces | Bloqueo con advertencia («Duplicado») | attendance_queue_test.dart | Sin ejecutar |
| CP-SIS-077 | Escaneo sin conexión | Modo avión, escanear 3 QR, volver a la red | Quedan en la cola y se sincronizan sin pérdidas ni duplicados | integration_test (flujo 2) | Sin ejecutar |
| CP-SIS-078 | Registro masivo | Admin elige curso; marca excepciones; corta la red a mitad | Todos inician «Presente»; cada registro se encola; no se pierde lo marcado | Manual | Sin ejecutar |
| CP-SIS-079 | Registro del día y pendientes | Filtrar por curso y jornada; ver la cola; reintentar y descartar; filtro sin datos | Registros del día; cola con acciones; mensaje informativo | Manual | Sin ejecutar |
| CP-SIS-080 | Historial de asistencia | Estudiante y padre consultan; sin registros; modo avión | Por fecha y tipo; padre solo del hijo; mensaje; reintento | Manual + pytest (API) | Falla esperada (BE-04) |
| CP-SIS-081 | Registrar nota y promedio | Docente registra 0.0, 5.0, 5.1; abre una nota existente; corta la red | Acepta límites; rechaza 5.1; carga la nota existente; recalcula promedio; reintento | validators_test.dart + manual | Sin ejecutar |
| CP-SIS-082 | Consultar notas | Estudiante y padre consultan; periodo sin notas; modo avión | Por asignatura y periodo; padre solo del hijo; mensaje; reintento | Manual | Sin ejecutar |
| CP-SIS-083 | Registrar novedad | Docente elige estudiante del curso, tipo y descripción; luego sin descripción; modo avión | Guarda con gravedad del tipo; no guarda sin datos; reintento | Manual | Sin ejecutar |
| CP-SIS-084 | Consultar novedades | Padre, estudiante y admin consultan; sin novedades | Ordenadas por fecha y tipo; padre solo del hijo; admin toda la institución; mensaje | Manual | Sin ejecutar |
| CP-SIS-085 | Perfil y cierre de sesión | Abrir perfil; cerrar sesión | Datos del usuario autenticado; vuelve al login y borra el token | Manual | Sin ejecutar |
| CP-SIS-086 | Recuperar contraseña | Correo registrado y no registrado | Mensaje neutral y confirmación visual | Manual | Sin ejecutar |
| CP-SIS-087 | Boletín PDF | Padre descarga, abre y comparte; estudiante sin notas | Abre en el visor y se comparte; sin notas «No hay datos disponibles para generar el boletín.» | Manual | Falla esperada (BE-19) |
| CP-SIS-088 | Reportes del administrador | Admin lista, descarga y abre; sin reportes; modo avión | Lista con estado; abre el archivo; mensaje de que se generan en la web; reintento | Manual | Sin ejecutar |
| CP-SIS-089 | Auto-registro por pasos | Completar identidad, contacto y rol; correo existente; campo faltante | Confirmación de cuenta creada; error sin crear; no avanza | Manual | Falla esperada (BE-12, APP-06) |
| CP-SIS-090 | Horario del estudiante | Consultar; curso sin horario; modo avión | Por día y franja de su curso; mensaje; reintento | Manual | Sin ejecutar |
| CP-SIS-091 | Clases del docente | Consultar; docente sin asignaciones; modo avión | Solo sus cursos y materias; mensaje; reintento | Manual | Sin ejecutar |
| CP-SIS-092 | Padre con dos hijos | DS-03: ver hijos y cambiar; padre sin vínculo; modo avión | Solo sus hijos; la información cambia con el hijo; «Sin estudiante vinculado»; reintento | integration_test (flujo 4) | Falla esperada (BE-07, APP-03) |
| CP-SIS-093 | Actualización OTA | Con v1.1.0 instalada y sesión abierta con registros en cola, publicar v1.1.1 de prueba; abrir la app; luego sin red | Aviso con opción de actualizar; instala sin perder sesión ni cola; sin red no bloquea | Manual (POCO X7) | Falla esperada (APP-01, APP-07) |
| CP-SIS-094 | Contraseña nueva débil | «Colegio2026» en registro, restablecer y perfil | Rechazada con el mensaje de la regla de carácter especial | password_policy_test.dart | Falla esperada (APP-04) |
| CP-SIS-095 | Correo con mayúsculas | Iniciar sesión con « Ana@X.com » | Entra igual que con ana@x.com | validators_test.dart | Falla esperada (APP-06, BE-12) |
### 4.2 Casos que cruzan la web y la app

| ID | Escenario | Pasos clave | Resultado esperado | Automatización | Hoy |
|---|---|---|---|---|---|
| CP-SIS-030 | QR web leído en la app | Mostrar el QR de la web y escanearlo desde la app (docente) | La app reconoce al estudiante y registra | Manual | Sin ejecutar |
| CP-SIS-062 | Notificación push de novedad | POCO X7 con sesión del padre de DS-03 y permiso concedido; docente registra una novedad en la web; un segundo teléfono o emulador con otro padre | Llega al padre vinculado, no al otro; al tocarla abre las novedades del hijo | integration_test (APP-INF-2) + manual | Falla esperada (BE-18, APP-08) |
| CP-SIS-096 | Entrada desde dos equipos | Registrar la entrada de un estudiante en la app y luego en la web | El segundo registro se rechaza (409) y se informa | Manual + pytest (API) | Falla esperada (BE-08) |
### 4.3 Automatización con `integration_test` (APP-INF-2)

Se automatizan los seis flujos mínimos de la planeación de la app; el resto se ejecuta a mano con grabación de pantalla:

| Flujo | Casos que cubre | Archivo propuesto |
|---|---|---|
| 1. Inicio de sesión de cada rol con su inicio cargado | CP-SIS del inicio de sesión por rol | `integration_test/login_roles_test.dart` |
| 2. Escaneo sin red y sincronización | Escaneo sin conexión | `integration_test/cola_sin_conexion_test.dart` |
| 3. Registro duplicado marcado «Duplicado» | Doble registro en el mismo teléfono | `integration_test/duplicado_test.dart` |
| 4. Padre con dos hijos | Padre con dos hijos | `integration_test/padre_dos_hijos_test.dart` |
| 5. Registro de padre que ve a su hijo vinculado | Auto-registro (comportamiento por diseño) | `integration_test/registro_padre_test.dart` |
| 6. Notificación de novedad en el teléfono del padre | Notificación push | `integration_test/push_novedad_test.dart` (la recepción se confirma a mano) |

El escaneo con cámara no se puede automatizar con `integration_test`; esos casos se ejecutan a mano con la DS-05 impresa o en otra pantalla.

### 4.4 No funcionales de la app

| ID | Prueba | Cómo | Meta (MC-01 / PR-01) | Hoy |
|---|---|---|---|---|
| CP-NF-004 | Análisis del APK | MobSF sobre el APK de release | 0 hallazgos altos; firma de release; sin token FCM en el log | Falla esperada (APP-01, APP-07) |
| CP-NF-006 | Accesibilidad | `flutter test test/accessibility_test.dart` + Accessibility Scanner en el POCO X7 en las pantallas de login, inicio de cada rol, notas y asistencia | 100 % de pantallas evaluadas sin errores | Sin ejecutar |
| CP-NF-007 | Arranque en frío | 5 mediciones con `adb shell am start -W -n <paquete>/.MainActivity` después de `adb shell am force-stop` | `TotalTime` ≤ 3 s (promedio) | Sin ejecutar |
| CP-NF-009 | Compatibilidad Android | Login, escaneo, cola sin conexión y notificación en API 30, API 33 y POCO X7 | Mismo resultado; en API 33 o más se pide el permiso de notificaciones | Sin ejecutar |
| CP-NF-010 | Versión mínima | `aapt dump badging app-release.apk \| grep sdkVersion`; instalar en un emulador de una versión menor | Valor acordado; la instalación se rechaza | Falla esperada (APP-02) |
| CP-NF-011 | Firma e identificador | `apksigner verify --print-certs` y `aapt dump badging` | Huella de release y `applicationId` acordado | Falla esperada (APP-01) |
| CP-NF-017 | Usabilidad (parte móvil) | Evaluación heurística de Nielsen en la UAT | Sin problemas de severidad 3 o 4 abiertos | Sin ejecutar |
| CP-NF-018 | Fallo de la API (parte móvil) | Detener la API de QA y recorrer los módulos de cada rol | Ninguna pantalla se cierra; todas muestran mensaje y reintento | Sin ejecutar |
| CP-NF-019 | Usuario desactivado (parte móvil) | El admin desactiva la cuenta con sesión abierta en la app | Pierde el acceso al vencer el token (≤ 30 min) y vuelve al login con mensaje | Falla esperada (BE-13) |
| Tamaño del APK | Métrica del MC-01 | `flutter build apk --split-per-abi --analyze-size` | ≤ 40 MB (línea base 27,6 MB, MC-01) | Sin ejecutar |

## 5. Ejecución

| Corrida | Fecha | Qué mide |
|---|---|---|
| S1 | 17 – 19 nov 2026 (S9) | Primera ejecución completa en los tres equipos |
| S2 (regresión) | 24 – 26 nov 2026 (S10) | Casos fallidos de S1 después de corregir, más los flujos automatizados completos |

```bash
# Instalar el APK de QA y preparar evidencias
adb install -r app-qa-release.apk
adb shell screenrecord /sdcard/CP-SIS-xxx.mp4      # se detiene con Ctrl+C y se baja con adb pull

# Flujos automatizados (usuarios por --dart-define; la contraseña sale de un secreto)
flutter test integration_test \
  --dart-define=EYESCHOOL_API_BASE=$QA_API_BASE \
  --dart-define=QA_PASSWORD=$QA_PASSWORD -d <id del dispositivo> > evidencias/PR-06/app/S1_integration_<equipo>.txt

# Arranque en frío (repetir 5 veces)
adb shell am force-stop <paquete>
adb shell am start -W -n <paquete>/.MainActivity  >> evidencias/PR-06/app/S1_arranque.txt

# APK: firma, identificador, minSdk y tamaño
apksigner verify --print-certs app-release.apk     > evidencias/PR-06/app/S1_firma.txt
aapt dump badging app-release.apk | grep -E "package|sdkVersion" > evidencias/PR-06/app/S1_badging.txt
```

- El `<paquete>` es el `applicationId` acordado en APP-01; hoy es `com.example.eyes_school`.
- MobSF: `docker run -it --rm -p 8000:8000 opensecurity/mobile-security-framework-mobsf`, subir el APK y exportar el PDF del reporte.

## 6. Criterios

| Indicador | Meta | Origen |
|---|---|---|
| Casos ejecutados | 100 % | PR-01 |
| Casos aprobados | ≥ 95 % al cierre de la regresión | PR-01 / MC-01 |
| Asistencia sin conexión entregada sin pérdida ni duplicado | 100 %, verificada en dispositivo | PR-01, criterio de salida |
| Arranque en frío | ≤ 3 s | MC-01 |
| Accesibilidad de la app | 100 % de pantallas evaluadas | MC-01 |
| Defectos críticos o altos abiertos | 0 | PR-01 |

## 7. Registro en el PR-06 y defectos

- Cada caso deja su evidencia (video o captura) con el nombre `CP-SIS-xxx_<equipo>.mp4` en `evidencias/PR-06/app/`.
- Caso fallido → bug en Azure Boards con la plantilla del PR-07 (sección 4), el ID del caso y el equipo.
- Si el caso tenía falla esperada, el bug se enlaza al de su corrección (APP-xx o BE-xx) y no se duplica.
- Resultados: Tabla 2 (detalle), sección 6 (accesibilidad) y Tabla de compatibilidad (sección 7) del PR-06.

## 8. Responsables y calendario

| Actividad | Fecha | Responsable |
|---|---|---|
| APP-INF-2 (`integration_test` y los seis flujos) | 7 – 14 nov (S8) | Samuel Sierra |
| Emuladores API 30 y API 33 configurados; MobSF en Docker | 14 nov | Samuel Sierra |
| S1 | 17 – 19 nov | Samuel Sierra · Mariana Cortés |
| S2 (regresión) | 24 – 26 nov | Samuel Sierra |
| Parte móvil del PR-06 | 21 nov (S1) y 26 nov (S2) | Samuel Sierra · revisa Mariana Cortés |

## 9. Definición de terminado

- [ ] Los 34 casos de sistema y los no funcionales de la app ejecutados en los equipos indicados, con evidencia.
- [ ] Bugs registrados en Azure Boards y enlazados a su corrección cuando existe.
- [ ] Parte móvil del PR-06 diligenciada y revisada.
