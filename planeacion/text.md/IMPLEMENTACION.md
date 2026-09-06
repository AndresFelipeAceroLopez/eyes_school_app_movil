# Eyes School móvil — Estado de la implementación

> Bitácora de lo que se construyó al ejecutar `PLANEACION_MOVIL_EYESSCHOOL.md`,
> las decisiones que se tomaron sobre la marcha y lo que queda abierto.
> El estilo visual de la app (tema, tipografía, tarjetas, gradientes, shells y
> navegación) se conservó **sin cambios**: lo que cambió es de dónde salen los
> datos.

---

## 1. Lo que quedó funcionando

La app dejó de usar datos simulados. Todas las pantallas consumen la API real
(`/api/v1`, FastAPI en Azure) con JWT, refresh silencioso y cola offline.

| Fase del plan | Estado |
|---|---|
| **0 · Cimientos** | ✅ Dio + 4 interceptores, `flutter_secure_storage`, DTOs de los 62 schemas usados, router con guard por rol, bootstrap por rol. |
| **1 · Admin QR** | ✅ Caché de estudiantes, escáner continuo, hoja de confirmación, cola offline completa con reintentos y deduplicación, pantalla de pendientes, registro masivo, registro del día. |
| **2 · Docente** | ✅ Dashboard, mis clases, toma de asistencia por clase, planilla de notas 0.0–5.0, novedades (crear/listar/resolver), horario semanal. |
| **3 · Estudiante y padre** | ✅ Bootstrap `/estudiantes/me` y `/padres/me`, notas por periodo, boletín PDF, asistencia con scroll infinito, horario, novedades, carné QR, perfil compartido. |
| **4 · Pulido** | ✅ Estados vacíos, de error accionables y de carga en toda pantalla de datos; 422 mapeado campo por campo; banner offline. Push notifications: no implementadas (opcionales en el plan). |
| **5 · Verificación** | ✅ 59 pruebas: cola offline (incluye el escenario de campo de 30 escaneos), mapeadores y trampas de serialización, casos de uso, reglas de arquitectura, resiliencia de la UI ante API caída, arranque de la app. |

---

## 2. Decisiones tomadas al ejecutar

### 2.1 Persistencia local sin `build_runner`

El plan proponía **Drift** para el caché de estudiantes y la cola de asistencia.
Se implementó con un almacén JSON propio (`LocalStore`, escritura atómica
mediante archivo temporal + `rename`) sobre `path_provider`.

**Por qué:** Drift exige `build_runner` y código generado, y el volumen real es
pequeño (un colegio son cientos de estudiantes y una jornada son decenas de
escaneos). Las garantías que pedía el plan se conservan íntegras y se prueban:
persistencia entre reinicios, índice por `codigo_estudiante`, deduplicación por
`(id_estudiante, fecha, tipo)`, backoff exponencial y tope de reintentos.

**Cuándo reconsiderarlo:** si la cola pasa a manejar miles de filas o hace falta
consultarla con filtros, migrar a Drift es un cambio localizado en `LocalStore`,
`AttendanceQueue` y `StudentCatalog`.

### 2.2 Arquitectura: Clean Architecture aplicada

La app quedó en tres capas con la dependencia apuntando **hacia adentro**:

```
lib/
├─ domain/                  Dart puro. Cero Flutter, cero Dio, cero JSON.
│  ├─ entities/             AppUser, Grade, ClassSession, Novedad, Course…
│  ├─ value_objects/        AttendanceState, ClassTime, GradeScale, AcademicPeriods
│  ├─ failures/             AppFailure y su familia
│  ├─ repositories/         Los contratos (interfaces)
│  └─ usecases/             Las reglas de negocio de la aplicación
├─ data/                    Implementa los contratos
│  ├─ dto/                  Mapeadores JSON ⇄ entidad
│  ├─ api/                  Módulos HTTP
│  ├─ local/                Caché de estudiantes y cola offline
│  ├─ network/              Traductor de errores → AppFailure
│  └─ repositories/         *_repository_impl.dart
├─ core/                    Infraestructura y UI compartida (tema, router, widgets)
├─ providers/               Raíz de composición: contrato → implementación
└─ features/                Pantallas
```

**Lo que esto cambia en la práctica:**

- **El dominio es Dart puro.** Antes `Grade` importaba `app_colors.dart` y
  `ClassSession` usaba `TimeOfDay`: el dominio dependía del framework de UI.
  Ahora las reglas (escala 0.0–5.0, `Suspensión` con tilde, promedio agrupado
  por materia, estado de un bloque contra el reloj) se prueban sin arrancar
  Flutter.
- **Inversión de dependencias.** Las pantallas dependen de
  `domain/repositories`, no de las clases concretas. La única línea del
  proyecto que sabe qué implementación se usa está en `repository_providers.dart`.
- **La presentación no ve DTOs.** Antes `coursesProvider` devolvía `CursoDto` y
  las pantallas leían `.nombreCurso`. Ahora devuelve `Course` y leen `.name`.
- **Los errores son del dominio.** `ApiException` (que vivía en `core/network`,
  junto a Dio) pasó a `AppFailure` en `domain/failures`. El traductor de
  `DioException` → `AppFailure` es lo único que queda en `data`.
- **Cómo se ve el dominio es de la presentación.** `Grade.color` y
  `NovedadSeverity.background` salieron de las entidades a
  `core/theme/domain_styles.dart`.

**Casos de uso: solo donde hay una decisión.** `SignIn`, `RestoreSession`,
`RegisterScan`, `RegisterCourseAttendance`, `SaveGradeSheet`, `TodaysClasses`,
`NextClass`, `NameNovedades`. Una clase por endpoint (`GetCursos`, `GetNotas`…)
sería ceremonia: `getCursos()` no decide nada y envolverlo agrega un archivo sin
agregar una regla. Lo que sí está aquí son las reglas que de otro modo quedarían
repartidas por los widgets, donde no se pueden probar.

**Las reglas se verifican, no se documentan.** `test/architecture_test.dart`
falla la build si alguien: importa un paquete externo desde `domain/`, importa
un DTO o Dio desde una pantalla, o instancia un repositorio concreto fuera de la
raíz de composición. Un diseño en capas se degrada de a un import cómodo por vez;
esto es lo que lo sostiene cuando aprieta una fecha.

### 2.3 Rutas en inglés, guard idéntico

El plan nombra los namespaces `/admin`, `/docente`, `/estudiante`, `/padre`. Se
mantuvieron los que ya existían (`/admin`, `/teacher`, `/student`, `/parent`)
porque la propiedad que importa —**el router es la frontera de permisos**— ya
estaba y renombrar era churn sin beneficio visible. El `redirect` de tres
niveles (¿sesión? → ¿rol? → ¿la ruta pertenece al rol?) sí se implementó tal
cual, más el caso de cuenta pendiente de validación.

### 2.4 QR generado en el dispositivo

El panel web pide la imagen a `api.qrserver.com`. La app la dibuja localmente
con `qr_flutter` **codificando exactamente el mismo dato** (`codigo_estudiante`
en texto plano), así que ambos QR son intercambiables. La razón es el offline:
un carné que necesita red no sirve en la puerta del colegio.

### 2.5 Escala de notas corregida a 0.0–5.0

La versión con datos simulados calificaba sobre 10 (`score / 10` en las barras
de progreso, "Excelente" a partir de 9.0). La escala institucional real es
0.0–5.0, que es la que valida el panel web. Se corrigió en `Grade.progress`,
`Grade.qualitative` y en la validación de la planilla del docente.

### 2.6 Pestaña "Hijos" del acudiente

`GET /padres/me` devuelve **un** estudiante por cuenta, así que no hay selector.
En vez de dejar una pestaña vacía, "Hijos" pasó a ser la ficha del estudiante
vinculado (tarjeta + novedades + horario). El estado de sesión ya modela un
`childId` "activo", que es lo que hace que soportar varios hijos más adelante
sea aditivo (§11.1 del plan).

### 2.7 Asistencia del estudiante

El shell del estudiante conserva sus 5 pestañas. El historial paginado se abre
desde la tarjeta "Asistencia" del inicio (`/student/asistencia`), en lugar de
gastar una pestaña.

---

## 3. Vacíos del backend: cómo se manejó cada uno

| # | Vacío | Cómo lo resuelve la app hoy |
|---|---|---|
| **1** | `GET /profesores/me` **no está desplegado** (se verificó contra el `openapi.json` en producción) | `PeopleApi.profesorMe()` lo intenta primero; ante 404/422 pagina `/profesores` y empareja por `id_usuario`. **En cuanto el endpoint se despliegue, la ruta rápida se activa sola, sin tocar la app.** Si no hay perfil, el docente entra igual y ve el aviso en su inicio. |
| 3 | Sin `/dashboard/admin` | El inicio del admin calcula sus contadores desde `GET /asistencia?fecha=hoy`. No se replican los KPIs institucionales. |
| 4 | Sin catálogo de periodos | Constante local 1–4 (`AppConstants.periods`) y `periodo_actual` del dashboard cuando existe. |
| 5 | Sin búsqueda por `codigo_estudiante` | Caché local con índice por código. Se queda aunque llegue el endpoint: es lo que habilita el offline. |
| 6 | `POST /asistencia` sin idempotencia | Deduplicación en cliente por `(id_estudiante, fecha, tipo)`; un 409 (o un 422 que diga "duplicado") se marca como entregado, no como error. |
| 7 | Sin registro por lotes | Todo se encola primero y la cola drena; barra de progreso "18/32". |
| 8 | `registrado_por` lo pone el cliente | Siempre `session.user.userId`, nunca un valor que la UI pueda influir. |
| 9 | `/asistencia` no filtra por curso ni jornada | Fecha en el servidor; curso y jornada en el cliente sobre el resultado. |
| 10 | `HorarioOut`/`NotaOut`/`NovedadOut` sin nombres | `CatalogRepository` cachea cursos, materias y tipos de novedad; el join ocurre en la capa de datos. |
| 11 | Sin metadatos de paginación | Scroll infinito con `page.length == limit`. |
| 12 | Matriz de permisos no documentada | **Pendiente de verificar con un token real de cada rol.** Ver §4. |
| 13 | QR sin firma ni expiración | Decisión tomada: se mantiene. Mitigación: solo un admin autenticado registra, y queda `registrado_por` auditado. |
| 14 | `/estudiantes/{id}/ips` expone datos de salud | **No se consume en ninguna pantalla ni se guarda en el caché local.** |

---

## 3.bis Fallos encontrados y corregidos al probar en dispositivo

Cinco defectos reales que salieron al ejecutar la app, no al leerla. Cada uno
quedó cubierto por una prueba.

| Síntoma | Causa | Corrección |
|---|---|---|
| **No dejaba iniciar sesión.** «Ingresa un correo válido» con un correo válido. | La expresión regular del validador admitía **un solo punto** tras la `@`, así que rechazaba `@eyesschool.edu.co` — justo la forma de los dominios institucionales colombianos (`.edu.co`, `.com.co`, `.gov.co`). Ni siquiera llegaba a hacer la petición. | Patrón que acepta dominios de varios niveles, en `Validators.email`. Cubre también el registro y la edición de perfil. |
| **Pantalla roja en el rol estudiante.** Toda la app en rojo con «Sin conexión». | En Riverpod 2, `AsyncValue.value` **relanza** la excepción cuando el estado es error; el que devuelve `null` es `valueOrNull`. Se usaba `.value` en 15 sitios, así que una API caída no degradaba la pantalla: tumbaba la app. | Todas las lecturas pasaron a `valueOrNull`. `test/student_home_resilience_test.dart` reproduce el escenario exacto y falla si vuelve a escaparse una excepción al árbol de widgets. |
| **Desbordamientos de layout en teléfono.** Invisibles en el viewport por defecto de las pruebas (800×600). | Cinco pestañas en 390 px hacían que «Novedades» pasara a dos líneas y desbordara la barra; la celda del grid de acciones rápidas era más baja que su contenido; el botón de reintentar no cabía en su ancho fijo. | `Flexible` + una línea en la barra, `Flexible` en la tarjeta de acción, ancho máximo en vez de fijo en el botón. Las pruebas ahora usan un viewport de teléfono real, así que estos fallos se detectan. Se disparaban también con el texto ampliado por accesibilidad. |
| **`flush()` de la cola mentía.** Se rendía si ya había otra pasada en curso, así que `await flush()` podía volver antes de enviar nada. | Descartar la llamada concurrente en vez de encadenarla. | Las pasadas se serializan; esperar el futuro sí significa «la cola tuvo su oportunidad de vaciarse». |
| **Reintentos y replay saltándose la configuración del cliente.** | `AuthInterceptor` y `RetryInterceptor` creaban su propio `Dio` con adaptador propio, así que un proxy, un certificado fijado o un transporte de prueba dejaban de aplicar en esos caminos. | Ambos reciben una fábrica que toma el adaptador del cliente principal **en el momento de la llamada**. |

---

## 4. Qué falta antes de producción

1. **Probar contra la API con un token de cada rol.** El código está escrito
   contra el contrato OpenAPI, no contra respuestas reales de los cuatro roles.
   Es lo primero que hay que hacer, y es lo que cierra el vacío #12.
2. **Desplegar `GET /profesores/me`** (§13 del plan). Sin él, el arranque del
   docente pagina `/profesores`, que funciona pero es caro.
3. **Compilar el APK.** No se pudo verificar aquí: la máquina no tiene Android
   SDK (`flutter build apk` falla con *No Android SDK found*). El análisis
   estático y las 29 pruebas sí pasan.
4. **Prueba de campo obligatoria** del plan: modo avión → 30 escaneos → recuperar
   red → verificar 30 registros exactos en la API. La versión unitaria de esa
   prueba ya existe y pasa (`test/attendance_queue_test.dart`), pero falta
   hacerla contra el servidor real.
5. **`applicationId`** sigue siendo `com.example.eyes_school` y la release firma
   con la clave de debug.

---

## 5. Configuración

- **Base URL:** se puede apuntar a otro entorno sin tocar código:
  `flutter run --dart-define=EYESCHOOL_API_BASE=https://mi-api`
- **Deep link de recuperación:** `eyesschool://reset?token=…` (declarado en el
  manifest y traducido en el router, porque un esquema propio llega con el
  destino en el *host*, no en el path). La pantalla también acepta pegar el
  token a mano, por si el cliente de correo descarta el esquema.
- **Permisos Android:** `INTERNET`, `ACCESS_NETWORK_STATE` y `CAMERA`. Los dos
  primeros son necesarios en release; Flutter solo los inyecta en debug.
