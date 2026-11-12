# Especificación de casos de prueba — App móvil (Flutter) · Eyes School

> **Tipo de documento:** especificación de casos de prueba (ISO/IEC/IEEE 29119-3, *Test Case Specification*), complemento del **PR-02 v0.2** para las correcciones de la app móvil.
> **Fuentes:** `planeacion/test/Planeacion_test/planeacion-app-movil (1).md` (planeación de correcciones de la app, 28–30/10/2026) y `PR-02_Especificacion_de_Casos_de_Prueba_EyesSchool_v0.2.docx` (30/10/2026). No se usó ninguna otra fuente.
> **Elaboró:** Mariana Cortés (QA) · **Revisa:** Samuel Sierra (líder de pruebas) · **Aprueba:** Sergio Gómez (PO)
> **Fecha:** 02/11/2026 · **Versión:** 0.1

---

## 1. Propósito y alcance

Este documento especifica, en el formato completo del PR-02 (sección 4), los casos de prueba de sistema y no funcionales que verifican las correcciones de la app móvil de la planeación, las dependencias del backend que la app tiene que comprobar en el POCO X7 y los dos casos nuevos que faltaban en el PR-02 v0.2.

**Dentro del alcance:**

| Grupo | Casos |
|---|---|
| Correcciones de la app | CP-NF-011 y CP-SIS-093 (APP-01) · CP-NF-010 (APP-02) · CP-SIS-092 (APP-03) · CP-SIS-094 (APP-04) · CP-SIS-095 (APP-06) · CP-NF-004 (APP-07) · CP-SIS-062 y CP-SIS-063 (APP-08) |
| Dependencias del backend | CP-SIS-066 (BE-03) · CP-SIS-081 (BE-06) · CP-SIS-076, CP-SIS-074 y CP-SIS-096 (BE-08) · CP-NF-019 (BE-13) · CP-SIS-067 (BE-16) · CP-SIS-087 (BE-19) |
| Casos nuevos | CP-SIS-097 (registro de padre vinculado en la app) · CP-SIS-098 (evidencia del QR predecible) |
| Automatización de sistema | Los seis flujos de `integration_test` (APP-INF-2), sección 6 |

**Fuera del alcance:**

| Elemento | Motivo |
|---|---|
| APP-INF-1 (SonarQube Cloud y `gitleaks`) | Son herramientas y se reportan en el PR-03, no llevan casos de prueba |
| BE-10 | No cambia nada que se vea en la app |
| Pruebas unitarias y de widget | Su especificación es el código y se reportan en el PR-04 (UT-APP-01 a UT-APP-08). Aquí solo se citan |
| Pruebas de contrato app ↔ API | Se especifican en el PR-05 (IT-APP-01 a IT-APP-07). `dto_mapping_test.dart` va en CP-INT-075 |
| QR inválidos | Ya los cubren CP-SIS-075 (PR-02, sección 4) y el conjunto DS-05 |
| CP-SIS-077 (escaneo sin conexión) | Ya está en formato completo en el PR-02, sección 4. Aquí solo se cita como caso que automatiza el flujo 2 |

## 2. Supuestos y convenciones

| # | Supuesto o convención | Origen |
|---|---|---|
| S-01 | `applicationId` = `co.edu.eyesschool.app` (recomendación de QA para D-A1). Si el PO decide otro valor, solo cambian los datos de CP-NF-011 | Decisión del equipo del 02/11/2026 de usar la recomendación de la sección 9 de la planeación |
| S-02 | `minSdk` = 30 (recomendación de QA para D-A2) | Igual que S-01 |
| C-01 | **[Texto entre corchetes]** = dato pendiente que el PO o el equipo debe confirmar antes de la versión 1.0, igual que en la convención del PR-02 | PR-02, «Convenciones de esta plantilla» |
| C-02 | «Falla esperada» / «Sin ejecutar» / «Diferido» tienen el mismo significado que en el PR-02, sección 1 | PR-02 |
| C-03 | Las contraseñas de DS-01 y DS-03 salen de `QA_PASSWORD` (BE-INF-2) por un canal privado y nunca se escriben en este documento | PR-02, Tabla 12 |
| C-04 | En «Pruebas automatizadas de soporte» solo va el ID y el archivo. El detalle está en el PR-04 (UT-APP) o en el PR-05 (IT-APP). Los números UT-APP/IT-APP que no se pudieron verificar quedan como `[UT-APP-xx]` | Acuerdo del PR-02 |

## 3. Entorno común de ejecución

| Elemento | Valor |
|---|---|
| Dispositivos (DS-10) | POCO X7 (Android 15, API 35), emulador API 30, emulador API 33 y un segundo equipo para el padre no vinculado |
| APK | APK de QA compilado con `--dart-define=EYESCHOOL_API_BASE=<URL de QA sin /api/v1>` |
| Web | URL de QA en Vercel (Chrome) para los casos «Web + Móvil» |
| Versión base bajo prueba | App 1.0.1, rama `chore/modelo-calidad`, commit `cd650a7` del 25/10/2026 (PR-02, sección 1). La verificación de cada corrección se hace sobre `develop` después de su merge |
| Evidencia | Capturas o video en la carpeta de evidencias de QA y registro en el PR-06. Cada falla se registra como bug en Azure Boards (PR-07) con `AB#<id>` y la referencia de la corrección |

---

## 4. Casos de las correcciones de la app

### 4.1 APP-01 · Firma de release e identificador

| Campo | Contenido |
|---|---|
| **ID del caso** | **CP-NF-011 · Falla esperada hoy** |
| Título | Firma e identificador del APK de release verificados en el CI |
| HU / requisito | RNF Seguridad · secretos y APK (PR-02, Tabla 2) · APP-01 · CA-PBI93.3 (indirecto: sin la firma estable la OTA no instala) |
| Nivel / tipo | Sistema no funcional · Seguridad |
| Técnica de diseño | Prueba basada en requisitos (verificación de configuración) |
| Prioridad | Alta (severidad de APP-01) |
| Precondiciones | 1. Clave de release creada y cargada en GitHub Secrets: `RELEASE_KEYSTORE_BASE64`, `RELEASE_KEYSTORE_PASSWORD`, `RELEASE_KEY_ALIAS`, `RELEASE_KEY_PASSWORD` y `RELEASE_CERT_SHA256`. 2. `release_apk.yml` tiene el paso nuevo con `apksigner verify --print-certs` y `aapt dump badging`. 3. `build.gradle.kts` define `signingConfigs.create("release")` leyendo `android/key.properties`. |
| Datos de entrada | Etiqueta `v*` de prueba · `RELEASE_CERT_SHA256` · `applicationId` esperado = `co.edu.eyesschool.app` (S-01) |
| Pasos | 1. Crear una etiqueta `v*` para disparar `release_apk.yml`. 2. Revisar en el log del job la salida de `apksigner verify --print-certs` sobre el APK generado. 3. Revisar en el mismo paso la salida de `aapt dump badging`. 4. Control negativo: compilar el release en local **sin** `android/key.properties` (cae a la clave de depuración con advertencia, según el diseño) y pasar ese APK por los mismos dos comandos contra `RELEASE_CERT_SHA256`. |
| Resultado esperado | Paso 2: la huella SHA-256 del certificado coincide con `RELEASE_CERT_SHA256` y el job termina en verde. Paso 3: `package: name='co.edu.eyesschool.app'`. Paso 4: la huella **no** coincide; el paso de verificación falla y el build local muestra la advertencia de que usa la clave de depuración. |
| Postcondiciones | Borrar la etiqueta y el release de prueba si no corresponden a una versión real. |
| Automatizado | Sí — paso de verificación en `release_apk.yml` (APP-01). Hoy falla: el release se firma con `signingConfigs.getByName("debug")` (`build.gradle.kts`, línea 34) y el `applicationId` es `com.example.eyes_school` (línea 21). |

| Campo | Contenido |
|---|---|
| **ID del caso** | **CP-SIS-093 · Falla esperada hoy** |
| Título | Actualización OTA real en el POCO X7 |
| HU / requisito | PBI 93 · CA-PBI93.1 a CA-PBI93.4 · APP-01 · APP-07 (nombre del repositorio) |
| Nivel / tipo | Sistema · Funcional (instalación y actualización) |
| Técnica de diseño | Prueba de escenario (con versión nueva / sin conexión) |
| Prioridad | Alta (severidad de APP-01; el MC-01 mide la OTA con meta de 100 %) |
| Precondiciones | 1. APP-01 y APP-07 en `develop`. 2. DS-09: v1.1.0 firmada con la clave de release instalada en el POCO X7 y v1.1.1 de prueba publicada en el repositorio de pruebas configurado con `EYESCHOOL_UPDATE_REPO`. 3. Sesión abierta con el docente de DS-01. 4. Registros en la cola de pendientes. **[Por confirmar: cómo se mantienen registros en la cola mientras la app descarga la actualización, ya que al volver la red la cola se sincroniza sola (CP-SIS-077). Ver P-03 en el informe]** |
| Datos de entrada | DS-09 (v1.1.0 y v1.1.1) · usuario docente de DS-01 · QR válidos de DS-05 para generar registros en cola |
| Pasos | 1. Con v1.1.0 abierta, confirmar la sesión del docente y el número de registros en la pantalla de pendientes. 2. Publicar v1.1.1 de prueba en el repositorio de pruebas. 3. Cerrar y abrir la app con red. 4. Aceptar el aviso de actualización y completar la descarga e instalación. 5. Abrir la app actualizada y revisar la versión, la sesión y la pantalla de pendientes. 6. Activar el modo avión y abrir la app. |
| Resultado esperado | Paso 3: aparece el aviso con la opción de actualizar (CA-PBI93.1 y .2). Paso 4: Android instala la v1.1.1 **sin desinstalar** la anterior; no aparece «App no instalada». Paso 5: la app muestra v1.1.1, la sesión sigue abierta sin pedir login y los registros pendientes siguen ahí (CA-PBI93.3). Paso 6: la app abre y se usa sin bloqueo por la verificación de versión (CA-PBI93.4). |
| Postcondiciones | Borrar el release v1.1.1 de prueba; el admin borra los registros de asistencia de prueba que se hayan sincronizado. |
| Automatizado | Manual (POCO X7) con evidencia en el PR-06. Pruebas de soporte: `[UT-APP-xx]` `UpdateService` con `ScriptedAdapter` (PR-04): consulta `/repos/AndresFelipeAceroLopez/eyes_school_app_movil/releases/latest`, `hasUpdate` con versión mayor, igual y sin red. Hoy falla: cada versión queda firmada con una clave de depuración distinta. |

> **Nota de ejecución (planeación, APP-01):** cambiar la firma o el identificador obliga a desinstalar e instalar una vez las copias actuales. Esa reinstalación se hace **antes** del paso 1 y no forma parte del resultado esperado.

### 4.2 APP-02 · Versión mínima de Android

| Campo | Contenido |
|---|---|
| **ID del caso** | **CP-NF-010 · Falla esperada hoy** |
| Título | Versión mínima de Android fijada en 30 |
| HU / requisito | RNF Compatibilidad · Android API 30, 33 y 35 (PR-02, Tabla 2) · APP-02 |
| Nivel / tipo | Sistema no funcional · Compatibilidad |
| Técnica de diseño | Valores límite sobre la versión de API (29 rechazada / 30 aceptada) |
| Prioridad | Media (severidad de APP-02) |
| Precondiciones | 1. `minSdk = 30` explícito en `android/app/build.gradle.kts` (S-02). 2. APK de release generado. 3. Emulador API 30 (DS-10) y un emulador **API 29**. **[El emulador API 29 no está en DS-10: hay que agregarlo a la matriz de dispositivos del PR-01]** |
| Datos de entrada | `app-release.apk` · valor esperado `sdkVersion:'30'` |
| Pasos | 1. Ejecutar `aapt dump badging app-release.apk \| grep sdkVersion` (paso del CI). 2. Instalar el APK en el emulador API 29. 3. Instalar el APK en el emulador API 30 y abrir la app. |
| Resultado esperado | Paso 1: `sdkVersion:'30'`. Paso 2: Android rechaza la instalación. Paso 3: se instala y abre la pantalla de inicio de sesión. |
| Postcondiciones | Desinstalar la app del emulador API 30. |
| Automatizado | Parcial — paso 1 en el CI (`aapt dump badging`, APP-02); pasos 2 y 3 manuales con evidencia en el PR-06. Hoy falla: `minSdk = flutter.minSdkVersion` (`build.gradle.kts`, línea 24) no fija el valor. |

### 4.3 APP-03 · Padre con dos hijos

| Campo | Contenido |
|---|---|
| **ID del caso** | **CP-SIS-092 · Falla esperada hoy** |
| Título | Padre con dos hijos en la app: lista, cambio de hijo, sin vínculo y sin red |
| HU / requisito | PBI 91 · CA-PBI91.1 a CA-PBI91.4 · APP-03 · BE-07 · riesgo R-01 |
| Nivel / tipo | Sistema · Funcional y seguridad |
| Técnica de diseño | Partición de equivalencia (0, 1 y 2 hijos), igual que CP-INT-062 |
| Prioridad | Alta (severidad de APP-03; riesgo R-01) |
| Precondiciones | 1. BE-07 desplegado en QA y APP-03 en `develop`. 2. DS-03: rosa.perez@gmail.com vinculada a los estudiantes 1 y 3. 3. DS-01: roberto.diaz@gmail.com, padre de un solo hijo (estudiante 2). 4. Un padre **sin** estudiante vinculado. **[Por definir: ningún conjunto DS tiene un padre sin vínculo. Ver P-04]** 5. Los estudiantes 1 y 3 tienen al menos una nota, un registro de asistencia y una novedad, para que el cambio de hijo se pueda ver. **[Por confirmar en DS-03]** |
| Datos de entrada | Padre de DS-03 · padre de DS-01 · padre sin vínculo |
| Pasos | 1. Iniciar sesión con el padre de DS-03. 2. Abrir la pantalla de hijos. 3. Abrir notas, asistencia y novedades sin cambiar de hijo. 4. Volver a la pantalla de hijos y tocar el segundo hijo. 5. Abrir de nuevo notas, asistencia y novedades. 6. Activar el modo avión y abrir la pantalla de hijos y la de notas. 7. Cerrar sesión e iniciar con el padre de DS-01. 8. Cerrar sesión e iniciar con el padre sin vínculo. |
| Resultado esperado | Paso 2: se listan solo los estudiantes 1 y 3 (CA-PBI91.1). Paso 3: los datos corresponden al primer hijo de la lista (hijo activo por defecto). Paso 5: los datos corresponden al segundo hijo y no aparece nada del primero (CA-PBI91.2). Paso 6: mensaje de error de conexión con opción de reintentar (CA-PBI91.4). Paso 7: **no** aparece la lista de hijos y la app se ve igual que hoy, con los datos del estudiante 2. Paso 8: las pantallas de padre muestran «Sin estudiante vinculado» (CA-PBI91.3). |
| Postcondiciones | Sin cambios en la base (solo lectura). |
| Automatizado | Sí — `integration_test` flujo 4 (APP-INF-2). Pruebas de soporte: `[UT-APP-xx]` `auth_repository_test.dart` (sesión con 2 hijos, `childId` = el primero; sesión sin hijos) y `[UT-APP-xx]` prueba de widget de `ChildrenScreen` (cambio de hijo y un solo hijo) en el PR-04; `dto_mapping_test.dart` en CP-INT-075 (PR-05). Hoy falla: `AppSession` tiene un único `childId` y `/padres/me/hijos` no existe. |

### 4.4 APP-04 · Política de contraseña

| Campo | Contenido |
|---|---|
| **ID del caso** | **CP-SIS-094 · Falla esperada hoy** |
| Título | Contraseña nueva débil rechazada en registro, restablecer y perfil |
| HU / requisito | RNF Seguridad · política de contraseña (5 reglas) (PR-02, Tabla 2) · APP-04 · BE-09 |
| Nivel / tipo | Sistema · Seguridad |
| Técnica de diseño | Partición de equivalencia y valores límite (PR-02, Tabla 5, fila «Contraseña nueva») |
| Prioridad | Alta (severidad de APP-04) |
| Precondiciones | 1. APP-04 en `develop`. 2. Para restablecer: un enlace de recuperación válido de DS-07 por cada intento. 3. Para perfil: sesión abierta con un usuario de DS-01. **[Por confirmar: si BE-09 exige la contraseña actual para cambiarla en el perfil, ese campo se llena con la contraseña vigente. Ver P-05]** |
| Datos de entrada | Caso principal: «Colegio2026» (sin carácter especial). Valores de la Tabla 5 para el formulario de restablecer: «Coleg#1» (7 caracteres), «Colegi#1» (8 caracteres, válida), «colegio#2026» (sin mayúscula), «COLEGIO#2026» (sin minúscula), «Colegio#ocho» (sin número). Control válido: «Colegio#2026». |
| Pasos | 1. Registro: completar el formulario por pasos con datos válidos y la contraseña «Colegio2026»; intentar finalizar. 2. Restablecer: abrir el enlace de DS-07 y escribir «Colegio2026»; intentar enviar. 3. Perfil: cambiar la contraseña a «Colegio2026»; intentar guardar. 4. Restablecer: repetir el paso 2 con cada valor de la Tabla 5. 5. Restablecer: escribir «Colegio#2026» y enviar. 6. Iniciar sesión con la contraseña del paso 5. |
| Resultado esperado | Pasos 1 a 3: el formulario no se envía y muestra el mensaje de la regla de **carácter especial** en los tres. **[Texto exacto del mensaje por confirmar en `Validators.newPassword`]** Paso 4: cada valor inválido se rechaza con el mensaje de **su** regla (longitud, mayúscula, minúscula o número); «Colegi#1» se acepta. Paso 5: la contraseña se actualiza. Paso 6: inicia sesión con «Colegio#2026». |
| Postcondiciones | Volver a fijar la contraseña de QA del usuario con el script de BE-INF-2. Borrar la cuenta del paso 1 si llegó a crearse. |
| Automatizado | Parcial — el caso en dispositivo es manual (PR-06). Pruebas de soporte (PR-04): `[UT-APP-xx]` `password_policy_test.dart` · `[UT-APP-xx]` `validators_test.dart` · `[UT-APP-xx]` prueba de widget de `ResetPasswordScreen` (con «Colegio2026» no se llama al repositorio). Hoy falla: `Validators.newPassword` (`validators.dart`, líneas 24–27) solo exige 8 caracteres. |

### 4.5 APP-06 · Correo en minúsculas

| Campo | Contenido |
|---|---|
| **ID del caso** | **CP-SIS-095 · Falla esperada hoy** |
| Título | Inicio de sesión con el correo en mayúsculas y con espacios |
| HU / requisito | PBI 2 · CA-PBI2.1 · RNF Seguridad · correo único sin distinguir mayúsculas · APP-06 · BE-12 |
| Nivel / tipo | Sistema · Funcional |
| Técnica de diseño | Partición de equivalencia (PR-02, Tabla 5, fila «Correo»: « Ana@X.com » ≡ «ana@x.com») |
| Prioridad | Media (severidad de APP-06) |
| Precondiciones | 1. APP-06 en `develop` (y BE-12 en QA para la verificación cruzada con la web). 2. Usuario activo registrado con el correo en minúsculas. **[Por confirmar: «ana@x.com» es el ejemplo del PR-02 y no está en ningún conjunto DS. Propuesta: usar el docente de DS-01 escrito como « Carlos.Jimenez@Eyes.edu.co ». Ver P-06]** |
| Datos de entrada | Correo del usuario con mayúsculas y un espacio antes y otro después · contraseña de QA |
| Pasos | 1. En la app, iniciar sesión con el correo en mayúsculas y con espacios. 2. Cerrar sesión e iniciar con el correo en minúsculas sin espacios. 3. En la web, iniciar sesión con el mismo correo en minúsculas. |
| Resultado esperado | Paso 1: entra igual que con el correo en minúsculas y llega al inicio de su rol. Paso 2: mismo resultado. Paso 3: entra en la web (la cuenta es la misma en los dos clientes). |
| Postcondiciones | Sin cambios. |
| Automatizado | Parcial — en dispositivo es manual. Pruebas de soporte (PR-04): `[UT-APP-xx]` `validators_test.dart`: `normalizeEmail(' Ana@X.com ')` → `ana@x.com` y login con `ScriptedAdapter` cuyo cuerpo lleva `ana@x.com`. Hoy falla: `auth_repository_impl.dart`, líneas 36 y 249, solo hace `trim()`. |

### 4.6 APP-07 · Token en el log y nombre del repositorio

| Campo | Contenido |
|---|---|
| **ID del caso** | **CP-NF-004 · Falla esperada hoy** |
| Título | Análisis del APK de release con MobSF y revisión del log |
| HU / requisito | RNF Seguridad · secretos y APK (PR-02, Tabla 2) · APP-07 · APP-01 |
| Nivel / tipo | Sistema no funcional · Seguridad |
| Técnica de diseño | Análisis estático y dinámico del binario con herramienta (MobSF) |
| Prioridad | Baja para APP-07 (su severidad); el caso también verifica la firma de APP-01 (Alta) |
| Precondiciones | 1. APP-01 y APP-07 en `develop`. 2. APK de **release** generado por `release_apk.yml`. 3. MobSF disponible. **[Versión de MobSF y dónde corre, por definir en el PR-01]** 4. POCO X7 con depuración USB para `adb logcat`. |
| Datos de entrada | `app-release.apk` · usuario padre de DS-01 (para que la app obtenga el token de FCM) |
| Pasos | 1. Cargar el APK de release en MobSF y ejecutar el análisis estático. 2. Revisar en el informe la sección de firma del certificado. 3. Instalar el mismo APK en el POCO X7, iniciar `adb logcat` y abrir la app. 4. Iniciar sesión con el padre de DS-01 y esperar a que se registre el token. 5. Buscar en el log la cadena `[FCM TOKEN]`. |
| Resultado esperado | Paso 1: 0 hallazgos de severidad alta. Paso 2: el APK está firmado con el certificado de release (la misma huella de CP-NF-011), no con uno de depuración. Paso 5: no aparece `[FCM TOKEN]` ni el valor del token en el log. |
| Postcondiciones | Guardar el informe de MobSF como evidencia en el PR-06; desinstalar la app. |
| Automatizado | Manual con herramienta. Pruebas de soporte: `[UT-APP-xx]` `UpdateService` con `ScriptedAdapter` (PR-04), que verifica el nombre nuevo del repositorio (`eyes_school_app_movil`). Hoy falla: `debugPrint('[FCM TOKEN]: $_fcmToken')` (`push_notification_service.dart`, líneas 94–97) escribe en release y el APK está firmado con la clave de depuración. |

### 4.7 APP-08 · Notificaciones push

| Campo | Contenido |
|---|---|
| **ID del caso** | **CP-SIS-062 · Falla esperada hoy** |
| Título | La notificación de una novedad llega solo al padre vinculado y abre las novedades del hijo |
| HU / requisito | US009 · CA-US009.2 · US027 · CA-US027.1 a .3 · PBI 92 · CA-PBI92.1, .3 y .4 · APP-08 · BE-18 |
| Nivel / tipo | Sistema · Funcional (Web + Móvil) |
| Técnica de diseño | Prueba de escenario con partición de equivalencia del destinatario (padre vinculado / no vinculado) |
| Prioridad | Alta (severidad de APP-08) |
| Precondiciones | 1. BE-18 en QA y APP-08 en `develop`. 2. POCO X7 con sesión del padre de DS-03 (estudiantes 1 y 3) y permiso de notificaciones concedido. 3. Segundo equipo (DS-10) con sesión de otro padre que **no** está vinculado al estudiante de la novedad (padre de DS-01, estudiante 2) y permiso concedido. 4. Web de QA con sesión de un docente autorizado a registrar novedades del estudiante 1. **[Por confirmar: que el docente de DS-01 tenga asignación en el curso del estudiante 1, por BE-11]** 5. App del POCO X7 en segundo plano. |
| Datos de entrada | Novedad de tipo académica o disciplinaria del estudiante 1, con fecha y descripción de prueba |
| Pasos | 1. En la web, el docente registra la novedad del estudiante 1. 2. Observar los dos teléfonos durante **[tiempo máximo de llegada por definir]**. 3. En el POCO X7, tocar la notificación. 4. Revisar la pantalla que se abre. |
| Resultado esperado | Paso 2: la notificación llega al POCO X7 (CA-US027.1, CA-PBI92.1) y **no** llega al segundo equipo (CA-US027.2, CA-PBI92.3). Paso 3: se abre la app. Paso 4: se ven las novedades del hijo, con la novedad recién registrada (CA-US027.3, CA-PBI92.4). **[Por confirmar con dos hijos: si se abren las novedades del estudiante de la novedad o las del hijo activo. Ver P-07]** |
| Postcondiciones | El admin borra la novedad de prueba. Al cerrar sesión en los dos equipos, el token se da de baja (`DELETE /api/v1/dispositivos/{token}`). |
| Automatizado | Parcial — `integration_test` flujo 6 (APP-INF-2) + manual en el POCO X7 (PR-06). Pruebas de soporte: `[UT-APP-xx]` `push_notification_service_test.dart` (registro tras login, token renovado, cierre de sesión) en el PR-04; `[IT-APP-xx]` `device_token_repository_test.dart` (`POST /dispositivos` con `{"token_fcm": ...}`) **[confirmar si está en el PR-04 o en el PR-05]**. Hoy falla: el token solo se imprime con `debugPrint` y nunca se envía a la API; en la API no existe el emisor (BE-18). |

| Campo | Contenido |
|---|---|
| **ID del caso** | **CP-SIS-063 · Sin ejecutar** |
| Título | Permiso de notificaciones negado: la app funciona y la novedad se consulta en pantalla |
| HU / requisito | US027 · CA-US027.4 · PBI 92 · CA-PBI92.2 |
| Nivel / tipo | Sistema · Funcional |
| Técnica de diseño | Partición de equivalencia del permiso (concedido en CP-SIS-062 / negado aquí) |
| Prioridad | **[Por confirmar]** |
| Precondiciones | 1. Emulador API 33 (Android 13, que pide el permiso `POST_NOTIFICATIONS`) con la app recién instalada. 2. Padre de DS-01 (estudiante 2). 3. Web de QA con sesión de un docente que puede registrar novedades del estudiante 2. |
| Datos de entrada | Novedad de prueba del estudiante 2 |
| Pasos | 1. Abrir la app e iniciar sesión con el padre. 2. Cuando Android pida el permiso de notificaciones, negarlo. 3. Recorrer el inicio, notas, asistencia y novedades. 4. En la web, registrar la novedad del estudiante 2. 5. En la app, abrir la pantalla de novedades. |
| Resultado esperado | Paso 2: la app sigue abierta sin error. Paso 3: todas las pantallas cargan con normalidad. Paso 4: no llega ninguna notificación al emulador. Paso 5: la novedad aparece en la pantalla de novedades. |
| Postcondiciones | El admin borra la novedad de prueba. |
| Automatizado | Manual. Que no se registre el token con el permiso negado lo verifica la prueba unitaria **UT-APP-07** (`push_notification_service_test.dart`, PR-04), no este caso. Hoy no se espera falla: el comportamiento ya existe. |

---

## 5. Casos de las dependencias del backend

| Campo | Contenido |
|---|---|
| **ID del caso** | **CP-SIS-066 · Falla esperada hoy** |
| Título | Inicio de sesión por rol en la app con el inicio cargado |
| HU / requisito | PBI 2 · CA-PBI2.1 y CA-PBI2.2 · BE-03 |
| Nivel / tipo | Sistema · Funcional |
| Técnica de diseño | Partición de equivalencia por rol (admin, docente, estudiante, padre) |
| Prioridad | Alta (BE-03 es un error crítico en producción, PR-02 sección 4) |
| Precondiciones | 1. BE-03 desplegado en QA para la verificación. 2. Los cuatro usuarios de DS-01 activos. |
| Datos de entrada | admin@eyesschool.edu.co · carlos.jimenez@eyes.edu.co · sofia.rodriguez@student.eyes.co · roberto.diaz@gmail.com |
| Pasos | 1. Iniciar sesión con cada usuario de DS-01, uno a la vez. 2. Esperar a que cargue el inicio. 3. Cerrar sesión antes de pasar al siguiente rol. |
| Resultado esperado | Cada rol llega a la pantalla de inicio de su rol y los datos cargan. El inicio del estudiante **no** muestra el estado de error con reintentar (hoy `GET /dashboard/estudiante` responde 500). |
| Postcondiciones | Sin cambios. |
| Automatizado | Sí — `integration_test` flujo 1 (APP-INF-2). Relacionado: CP-INT-060 (PR-02, sección 4). Prueba de soporte: `student_home_resilience_test.dart` (existe). |

| Campo | Contenido |
|---|---|
| **ID del caso** | **CP-SIS-081 · Sin ejecutar** |
| Título | Registrar nota en la app: límites, nota existente, promedio y error de conexión |
| HU / requisito | PBI 6 · CA-PBI6.1 a CA-PBI6.5 · BE-06 · riesgo R-04 |
| Nivel / tipo | Sistema · Funcional |
| Técnica de diseño | Valores límite (PR-02, Tabla 5, fila «Nota») |
| Prioridad | Alta (riesgo R-04) |
| Precondiciones | 1. BE-06 desplegado en QA. 2. Docente de DS-01 con asignación activa en la materia y el curso del estudiante 2. 3. El estudiante 2 sin nota en esa materia para el periodo 1. |
| Datos de entrada | DS-04: 0.0, 5.0, 5.1 · serie 4.0 / 3.0 / 5.0 para el promedio |
| Pasos | 1. Registrar 0.0 y guardar. 2. Cambiar a 5.0 y guardar. 3. Intentar guardar 5.1. 4. Salir y volver a abrir la nota del estudiante 2 en esa materia y periodo. 5. Registrar la serie de promedio de DS-04 y revisar el promedio. 6. Activar el modo avión e intentar guardar una nota válida. 7. Provocar una respuesta 422 de la API y revisar el mensaje en la pantalla. **[Por confirmar cómo provocar el 422 desde la app, porque `grade_entry_screen.dart` ya valida 0.0–5.0 antes de enviar. Ver P-08]** |
| Resultado esperado | Pasos 1 y 2: se aceptan los límites. Paso 3: mensaje de error y no se guarda (CA-PBI6.1 y .2). Paso 4: se carga la nota existente para editarla, sin crear otra (CA-PBI6.3). Paso 5: el promedio se recalcula con cada cambio (media simple, CA-PBI6.4). Paso 6: mensaje de error de conexión y opción de reintentar (CA-PBI6.5). Paso 7: el mensaje del 422 se muestra con claridad y la nota no se guarda. |
| Postcondiciones | Borrar las notas de prueba. |
| Automatizado | Parcial — `validators_test.dart` (existe) + manual. Relacionado: CP-INT-043 (PR-02, sección 4). |

| Campo | Contenido |
|---|---|
| **ID del caso** | **CP-SIS-076 · Sin ejecutar** |
| Título | Doble registro en el mismo teléfono, marcado «Duplicado» |
| HU / requisito | PBI 5 · CA-PBI5.4 · riesgo R-03 |
| Nivel / tipo | Sistema · Funcional |
| Técnica de diseño | Tabla de decisión (PR-02, Tabla 8, regla R2) y transición de estados de la cola |
| Prioridad | Alta (riesgo R-03) |
| Precondiciones | 1. APK de QA con sesión del docente de DS-01. 2. Un estudiante de DS-05 sin registros de asistencia hoy. |
| Datos de entrada | QR válido de DS-05 (`DS-05_valido_EST001.png`) · tipo entrada |
| Pasos | 1. Escanear el QR como entrada. 2. Escanear el mismo QR como entrada por segunda vez. 3. Abrir la pantalla de registros pendientes. 4. En la web (admin), revisar el registro del día. |
| Resultado esperado | Paso 1: entrada registrada. Paso 2: bloqueo con advertencia y el registro queda marcado «Duplicado». Paso 3: no queda ningún registro duplicado pendiente de envío. Paso 4: una sola entrada del estudiante. |
| Postcondiciones | El admin borra el registro de prueba. |
| Automatizado | Sí — `integration_test` flujo 3 (APP-INF-2). Prueba de soporte: `attendance_queue_test.dart` (existe, PR-04). No depende de BE-08: la app ya lo bloquea con su cola, así que hoy debería pasar. |

| Campo | Contenido |
|---|---|
| **ID del caso** | **CP-SIS-074 · Falla esperada hoy** |
| Título | Salida sin entrada previa: mensaje y no queda en la cola |
| HU / requisito | PBI 5 · CA-PBI5.2 · BE-08 (regla de salida sin entrada, decisión del PO del 30/10/2026) |
| Nivel / tipo | Sistema · Funcional |
| Técnica de diseño | Tabla de decisión (PR-02, Tabla 8, regla R5) |
| Prioridad | Alta (riesgo R-03) |
| Precondiciones | 1. BE-08 desplegado en QA. 2. APK de QA en el POCO X7 con sesión del docente de DS-01. 3. Un estudiante de DS-05 sin entrada hoy. |
| Datos de entrada | QR válido de DS-05 (`DS-05_valido_EST002.png`) · tipo salida |
| Pasos | 1. Escanear el QR como salida. 2. Abrir la pantalla de registros pendientes. 3. Esperar **[tiempo por definir]** con red y volver a abrir la pantalla de pendientes. |
| Resultado esperado | Paso 1: mensaje «No hay entrada registrada hoy para este estudiante». Pasos 2 y 3: el registro **no** está en la cola y la app no lo reintenta. |
| Postcondiciones | Sin cambios (no se crea registro). |
| Automatizado | Manual (POCO X7) con evidencia en el PR-06. Hoy falla: la API no tiene la regla de salida sin entrada. |

| Campo | Contenido |
|---|---|
| **ID del caso** | **CP-SIS-096 · Falla esperada hoy** |
| Título | Entrada del mismo estudiante desde dos equipos (app y web) |
| HU / requisito | US005 · CA-US005.3 · US006 · CA-US006.3 · PBI 5 · CA-PBI5.4 · BE-08 · riesgo R-03 |
| Nivel / tipo | Sistema · Funcional (Web + Móvil) |
| Técnica de diseño | Tabla de decisión (PR-02, Tabla 8, regla R2) |
| Prioridad | Alta (riesgo R-03) |
| Precondiciones | 1. BE-08 desplegado en QA. 2. APK de QA con sesión del docente de DS-01; web `/qr/escanear` con sesión de docente. 3. Un estudiante de DS-05 sin registros hoy. |
| Datos de entrada | QR válido de DS-05 (`DS-05_valido_EST003.png`) · tipo entrada |
| Pasos | 1. En la app, escanear el QR como entrada y esperar a que se sincronice. 2. En la web, escanear el mismo QR como entrada. 3. En la web (admin), revisar el registro del día. |
| Resultado esperado | Paso 1: entrada registrada. Paso 2: la API rechaza el segundo registro con 409 («Ya existe un registro de entrada para este estudiante en esta fecha», CP-INT-031) y la web lo informa con una advertencia. Paso 3: una sola entrada del estudiante. |
| Postcondiciones | El admin borra el registro de prueba. |
| Automatizado | Manual + pytest (API): `tests/test_asistencia_duplicados.py` (BE-08). Hoy falla: la API acepta el segundo registro con 201. |

| Campo | Contenido |
|---|---|
| **ID del caso** | **CP-NF-019 · Falla esperada hoy** |
| Título | Usuario desactivado con sesión abierta en la web y en la app |
| HU / requisito | RNF Seguridad · sesión, bloqueo y cierre (PR-02, Tabla 2) · BE-13 |
| Nivel / tipo | Sistema no funcional · Seguridad |
| Técnica de diseño | Tabla de decisión de la renovación de la sesión (PR-02, Tabla 7, regla R5) |
| Prioridad | **[Por confirmar]** |
| Precondiciones | 1. BE-13 desplegado en QA. 2. Usuario de prueba activo con sesión abierta en la web y en la app. **[Por definir qué usuario se desactiva: desactivar uno de DS-01 afecta a los demás casos]** 3. Admin de DS-01 con sesión en la web. |
| Datos de entrada | Usuario de prueba · hora de desactivación |
| Pasos | 1. El admin desactiva la cuenta de prueba y anota la hora. 2. En la app, seguir usando las pantallas hasta que venza el token de acceso (≤ 30 min). 3. Repetir el paso 2 en la web. |
| Resultado esperado | La cuenta pierde el acceso al vencer el token de acceso (≤ 30 min desde la desactivación). En la app, el interceptor de autenticación cierra la sesión y lleva al login con un mensaje claro. **[Texto del mensaje por definir]** |
| Postcondiciones | El admin reactiva la cuenta. |
| Automatizado | Manual. Prueba de soporte en la API: `tests/test_sesion.py` (BE-13). Hoy falla: el usuario desactivado sigue renovando su acceso. |

| Campo | Contenido |
|---|---|
| **ID del caso** | **CP-SIS-067 · Falla esperada hoy** |
| Título | Credenciales incorrectas y bloqueo al sexto intento |
| HU / requisito | PBI 2 · CA-PBI2.3 · BE-16 |
| Nivel / tipo | Sistema · Funcional y seguridad |
| Técnica de diseño | Valores límite (PR-02, Tabla 5, fila «Intentos fallidos»: 4.º, 5.º y 6.º intento) |
| Prioridad | **[Por confirmar]** |
| Precondiciones | 1. BE-16 desplegado en QA. 2. Usuario de DS-01 sin intentos fallidos en los últimos 15 minutos. |
| Datos de entrada | Correo del usuario de DS-01 con contraseña errada · correo inexistente |
| Pasos | 1. Iniciar sesión con contraseña errada. 2. Iniciar sesión con un correo inexistente. 3. Hacer intentos fallidos con el mismo correo hasta completar seis seguidos. 4. En el 6.º intento, revisar el mensaje. |
| Resultado esperado | Pasos 1 y 2: el mismo mensaje genérico, sin decir cuál campo falló. Intentos 4.º y 5.º: mensaje genérico. 6.º intento: «Demasiados intentos, espera 15 minutos» (la API responde 429). |
| Postcondiciones | Esperar 15 minutos o reiniciar el contador en QA antes del siguiente caso con ese usuario. |
| Automatizado | Parcial — `integration_test` (APP-INF-2) + manual. En la API: prueba con repositorio doble y reloj fijo (BE-16), que cubre los minutos 14 y 16. |

| Campo | Contenido |
|---|---|
| **ID del caso** | **CP-SIS-087 · Falla esperada hoy** |
| Título | Boletín PDF: descargar, abrir y compartir; estudiante sin notas |
| HU / requisito | PBI 15 · CA-PBI15.1 a CA-PBI15.3 · BE-19 · BE-15 |
| Nivel / tipo | Sistema · Funcional |
| Técnica de diseño | Partición de equivalencia (estudiante con notas / sin notas) |
| Prioridad | Media (H-03 tiene severidad media en el PR-02) |
| Precondiciones | 1. BE-19 desplegado en QA. 2. Padre de DS-01 cuyo hijo (estudiante 2) tiene notas. 3. Un padre cuyo hijo no tiene notas. **[Por definir: ningún conjunto DS tiene un estudiante sin notas vinculado a un padre]** |
| Datos de entrada | Padre de DS-01 · padre del estudiante sin notas |
| Pasos | 1. Con el padre de DS-01, descargar el boletín. 2. Abrirlo con el visor del sistema. 3. Compartir el archivo. 4. Con el padre del estudiante sin notas, pedir el boletín. |
| Resultado esperado | Paso 1: el PDF se descarga con la sesión activa. Paso 2: se abre en el visor (CA-PBI15.1). Paso 3: aparece la hoja de compartir del sistema (CA-PBI15.2). Paso 4: se muestra el texto exacto «No hay datos disponibles para generar el boletín.» (CA-PBI15.3), que llega de la API (404) y que `report_card_download.dart` muestra desde `AppFailure` (línea 72). |
| Postcondiciones | Borrar el PDF descargado del dispositivo. |
| Automatizado | Manual. En la API: prueba de boletín sin notas (404) de BE-19. Hoy falla: sin notas, la API genera igual un PDF con «Promedio general: N/A» (H-03). |

---

## 6. Casos nuevos

| Campo | Contenido |
|---|---|
| **ID del caso** | **CP-SIS-097 · Sin ejecutar** |
| Título | Registro de padre vinculado en la app |
| HU / requisito | PBI 17 · CA-PBI17.1 · comportamiento por diseño (decisión del PO del 30/10/2026; antes APP-05) |
| Plataforma | Móvil |
| Nivel / tipo | Sistema · Funcional |
| Técnica de diseño | Prueba de escenario (equivalente móvil de CP-SIS-014) |
| Prioridad | **[Por confirmar]** |
| Precondiciones | 1. APK de QA. 2. Un estudiante de DS-02 con al menos una nota, un registro de asistencia y una novedad. **[Por confirmar en DS-02]** 3. Correo nuevo, no registrado. |
| Datos de entrada | Documento del estudiante de DS-02 · correo nuevo · contraseña «Colegio#2026» (cumple la política de APP-04) · rol padre o acudiente |
| Pasos | 1. Abrir el registro de la app. 2. Completar el paso de identidad. 3. Completar el paso de contacto con el correo nuevo y la contraseña. 4. En el paso de datos del rol, elegir padre o acudiente e indicar el documento del estudiante de DS-02. 5. Finalizar el registro. 6. Iniciar sesión con la cuenta nueva. 7. Abrir notas, asistencia y novedades. |
| Resultado esperado | Pasos 2 a 4: el formulario avanza por pasos (CA-PBI17.1). Paso 5: confirmación visual de cuenta creada. Paso 6: llega al inicio del padre. Paso 7: ve las notas, la asistencia y las novedades **de ese estudiante** y de ningún otro. |
| Postcondiciones | El admin elimina la cuenta de prueba desde la web. |
| Automatizado | Sí — `integration_test` flujo 5 (APP-INF-2). Hoy queda «Sin ejecutar» porque es comportamiento por diseño. |

| Campo | Contenido |
|---|---|
| **ID del caso** | **CP-SIS-098 · Sin ejecutar** |
| Título | Evidencia del QR predecible: el QR con el código de otro estudiante se registra |
| HU / requisito | RNF Seguridad · riesgo aceptado «QR predecible» (decisión del PO del 30/10/2026; evidencia para el PR-09). **No es un criterio de aceptación ni una falla esperada**: va en la Tabla 2 (requisitos no funcionales, seguridad) y no en la matriz de CA |
| Plataforma | Móvil y web |
| Nivel / tipo | Sistema · Seguridad (riesgo aceptado) |
| Técnica de diseño | Suposición de errores (*error guessing*) sobre el riesgo aceptado |
| Prioridad | **[Por confirmar]** |
| Precondiciones | 1. APK de QA con sesión del docente de DS-01; web `/qr/escanear` con sesión de docente. 2. Dos estudiantes de DS-05 sin registros hoy. 3. Los QR de DS-05 se generaron fuera del sistema solo a partir del código del estudiante, sin que el estudiante abriera «Mi QR». |
| Datos de entrada | `DS-05_valido_EST001.png` (app) y `DS-05_valido_EST002.png` (web) |
| Pasos | 1. En la app, escanear el QR de EST001 desde la imagen impresa o en pantalla, no desde el teléfono del estudiante. 2. Revisar la pantalla de confirmación. 3. En la web, escanear el QR de EST002 de la misma forma. 4. Revisar la confirmación. 5. En la web (admin), revisar el registro del día. |
| Resultado esperado | Pasos 1 y 3: el registro se crea (el QR con el código de otro estudiante se acepta; es el riesgo aceptado). Pasos 2 y 4: quien escanea ve el nombre y los datos del estudiante en la confirmación (mitigación operativa). Paso 5: las dos entradas aparecen. Las capturas de los pasos 2 y 4 son la evidencia para el PR-09. |
| Postcondiciones | El admin borra los registros de prueba. |
| Automatizado | Manual (requiere cámara) con evidencia en el PR-06 y el PR-09. |

---

## 7. Automatización de sistema con `integration_test` (APP-INF-2)

Los seis flujos **automatizan** casos de sistema que ya están especificados. No se crean casos nuevos: el resultado esperado es el del caso de sistema. Se ejecutan en el POCO X7 (Android 15) y en los emuladores API 30 y API 33. No corren en cada PR; el resultado va al PR-06.

**Condiciones comunes:**
- `integration_test` en `dev_dependencies` y carpeta `integration_test/` creada.
- Ejecución: `flutter test integration_test --dart-define=EYESCHOOL_API_BASE=<URL de QA sin /api/v1>`.
- Los usuarios de prueba entran por `--dart-define`. **[Nombres de las variables por definir]** Nunca se escriben en el código.

| Flujo | Qué automatiza | Caso de sistema | Datos | Qué no se automatiza (queda manual) |
|---|---|---|---|---|
| 1 | Inicio de sesión de cada rol con su inicio cargado (verifica BE-03) | CP-SIS-066 | DS-01 | — |
| 2 | Escaneo QR sin red y sincronización al volver la red | CP-SIS-077 (PR-02, sección 4) | DS-02 | La lectura con la cámara y el modo avión en el dispositivo: evidencia manual (PR-06). **[Por confirmar cómo el flujo simula el escaneo y la pérdida de red]** |
| 3 | Registro duplicado marcado «Duplicado» | CP-SIS-076 | DS-05 válido | Igual que el flujo 2 para la cámara |
| 4 | Padre con dos hijos | CP-SIS-092 | DS-03 | Padre sin vínculo (dato por definir) |
| 5 | Registro de padre que ve los datos de su hijo vinculado | CP-SIS-097 | DS-02 + correo nuevo | Borrado de la cuenta (postcondición) |
| 6 | Notificación de novedad recibida en el teléfono del padre (APP-08 + BE-18) | CP-SIS-062 | DS-03, DS-10 | Llegada real de la notificación y el toque en el segundo equipo: manual (PR-06) |

---

## 8. Cambios que hay que llevar al PR-02

| Sección del PR-02 | Cambio |
|---|---|
| Tabla 1 (matriz), fila PBI 17 · CA-PBI17.1 | Agregar CP-SIS-097 en la columna CP-SIS (junto a CP-SIS-089) |
| Tabla 2 (no funcionales) | Nueva fila «Seguridad · QR predecible (riesgo aceptado, PR-09)» con CP-SIS-098 · corrección «—» · estado «Sin ejecutar» |
| Tabla 10 (sistema funcional) | Agregar CP-SIS-097 (Móvil) y CP-SIS-098 (Web + Móvil) |
| Resumen de la Tabla 1 | «Casos especificados»: 98 de sistema (antes 96); total 297 (antes 295) |
| Tabla 12 (datos) | DS-10: agregar el emulador API 29 para CP-NF-010. Definir los datos de P-04 y P-06 |
