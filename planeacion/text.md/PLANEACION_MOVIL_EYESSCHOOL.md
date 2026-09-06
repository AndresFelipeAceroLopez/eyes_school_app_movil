# Eyes School — Planeación de la app móvil (Flutter / Dart)

> Documento de planeación técnica para portar el sistema **Eyes School** a una app móvil en Flutter que consume **la misma API** que el panel web.
> Base de la auditoría: panel web en producción (Next.js 15 / App Router sobre Vercel) + contrato OpenAPI 3.1 de la API (FastAPI sobre Azure App Service).
> Stack acordado: **Riverpod 2 + go_router + Dio**.

---

## 1. Resumen de la auditoría

### 1.1 Qué es hoy el sistema

| Pieza | Realidad encontrada |
|---|---|
| Frontend | Next.js (App Router, Turbopack) desplegado en Vercel. **Todo el consumo de API ocurre server-side** (Server Components + Server Actions): el navegador nunca llama directo a la API. |
| Sesión web | Tokens en **cookies httpOnly** manejadas por el servidor de Next. |
| API | FastAPI. Base: `https://apieyeschool-b7fudxavddh9hhah.canadacentral-01.azurewebsites.net` · Prefijo: `/api/v1` · Docs vivas: `/docs` · Contrato: `/openapi.json` |
| Auth API | `HTTPBearer` (JWT). `access_token` + `refresh_token`. |
| Endpoints | **104 operaciones** en 17 módulos (tags). |
| Schemas | 62 modelos. |

### 1.2 Rutas del panel web actual

```
/                  Landing pública + modal de Login + modal de Registro
/admin             Dashboard institucional (KPIs + 3 gráficas)
/usuarios          CRUD de usuarios + validación de pendientes
/asistencia        Historial de asistencia con filtros
/notas             Consulta de notas por estudiante + boletín PDF
/horarios          Bloques horarios + hub de Cursos/Materias/Asignaciones/Especializaciones
/novedades         Registro de novedades disciplinarias/académicas
/qr                Listado de estudiantes con su código QR + descarga
/qr/escanear       Escáner de QR + registro masivo + registro manual
/reportes          Generación, subida, descarga y estado de reportes
/perfil            Mi perfil + cambio de contraseña + datos administrativos
```

**Cómo funcionan los roles en la web:** las rutas son **compartidas**, no hay namespace por rol (`/docente`, `/estudiante`, `/padre` devuelven 404). Lo que cambia según el rol del usuario logueado es **el contenido**: en `/admin` se pinta el dashboard correspondiente a ese rol, y el sidebar se ajusta. La API respalda esto con `/dashboard/docente`, `/dashboard/estudiante` y `/dashboard/padre`.

**En móvil se conserva el comportamiento (dashboard según rol) pero con rutas namespaceadas** (`/admin/...`, `/docente/...`, etc.). Razón: en móvil el router es también la frontera de permisos y el destino de los deep links. Con rutas compartidas, un deep link o un `restore` de proceso puede aterrizar a un estudiante en una pantalla de docente y solo el widget lo descubriría; con namespace, el `redirect` lo corta antes de construir la pantalla. Además cada rol necesita su propio `BottomNavigationBar` y su propio stack por pestaña, y eso pide un shell por rol de todas formas.

### 1.3 Roles y sus IDs (confirmados en el selector de registro)

| `id_rol` | Rol |
|---|---|
| 1 | Profesor |
| 2 | Estudiante |
| 3 | Administrador |
| 4 | Padre / Acudiente |

---

## 2. Alcance móvil por rol

La app móvil **no es un clon del panel web**. Se define así:

| Rol | Qué hace en móvil | Qué se queda en la web |
|---|---|---|
| **Administrador** | Escanear QR de estudiantes (entrada/salida), registro masivo por curso, y **consultas rápidas** de estudiantes y profesores (ficha, curso, contacto, QR). | CRUD de usuarios, cursos, materias, horarios, asignaciones, reportes, dashboard institucional. |
| **Docente** | Registrar **lo que tiene asignado**: asistencia de sus cursos, notas de sus materias, novedades de sus estudiantes. Ver su horario y su dashboard. | — |
| **Estudiante** | Consulta: notas por periodo, asistencia, horario del curso, novedades, boletín PDF, su propio carné QR. | — |
| **Padre / Acudiente** | Consulta sobre su(s) hijo(s): notas, asistencia, horario, novedades, boletín. | — |

> El admin móvil es deliberadamente **una herramienta de portería/pasillo**, no un panel de gestión. Es la decisión correcta: la gestión pesada (tablas, formularios largos, gráficas) vive mejor en la web.

---

## 3. Inventario de endpoints (los 104) y su uso en móvil

Leyenda de la columna **Móvil**: ✅ se consume · ⚠️ se consume con matices · ❌ no se usa en móvil (queda en web).

### 3.1 Auth — `/api/v1/auth`

| Método | Ruta | Body / Query | Móvil | Uso |
|---|---|---|---|---|
| POST | `/auth/register` | `RegisterRequest` | ✅ | Registro público autoservicio. Un solo payload crea usuario + perfil de rol. |
| POST | `/auth/login` | `LoginRequest {correo, password}` | ✅ | Devuelve `TokenResponse {access_token, refresh_token, token_type}`. |
| POST | `/auth/refresh` | `RefreshRequest {refresh_token}` | ✅ | Devuelve `AccessTokenResponse`. Lo llama el interceptor de Dio. |
| POST | `/auth/logout` | `RefreshRequest` | ✅ | Invalida el refresh en servidor. Limpiar storage siempre, aunque falle. |
| POST | `/auth/forgot-password` | `{correo}` | ✅ | Respuesta neutra por diseño (no revela si el correo existe). |
| POST | `/auth/reset-password` | `{token, new_password}` | ✅ | Entrada por deep link `eyesschool://reset?token=...`. |
| GET | `/auth/me` | — | ✅ | `MeResponse {id_usuario, primer_nombre, primer_apellido, correo, nombre_rol, id_rol, estado}`. **Es la fuente de verdad del rol** → alimenta el redirect del router. |
| POST | `/auth/me/avatar` | multipart | ✅ | Subida de foto desde cámara/galería. |

### 3.2 Usuarios y Roles

| Método | Ruta | Query / Body | Móvil | Uso |
|---|---|---|---|---|
| GET | `/usuarios` | `skip, limit, id_rol, estado, search` | ⚠️ | Solo admin, para el **directorio de consulta rápida**. `search` server-side. |
| POST | `/usuarios` | `UsuarioCreate` | ❌ | Alta de usuarios → web. |
| GET | `/usuarios/{id_usuario}` | — | ✅ | Ficha de contacto en el directorio. |
| PUT | `/usuarios/{id_usuario}` | `UsuarioUpdate` | ⚠️ | Solo para **mi propio perfil** (`/perfil`). |
| DELETE | `/usuarios/{id_usuario}` | — | ❌ | Web. |
| PATCH | `/usuarios/{id_usuario}/estado` | `?estado=` | ❌ | Web. |
| GET | `/roles` | — | ✅ | Poblar el selector de rol en el registro. |

### 3.3 Administradores

| Método | Ruta | Móvil | Uso |
|---|---|---|---|
| GET | `/administradores` · `skip, limit` | ❌ | Web. |
| POST | `/administradores` (`AdministradorCreate`) | ❌ | Web. |
| GET | `/administradores/{id}` | ⚠️ | Solo para pintar `cargo` / `nivel_acceso` en mi perfil de admin. |
| PUT / DELETE | `/administradores/{id}` | ❌ | Web. |

### 3.4 Profesores

| Método | Ruta | Móvil | Uso |
|---|---|---|---|
| GET | `/profesores/me` ⭐ *(por implementar)* | ✅ | **Bootstrap del rol Docente**: devuelve el `ProfesorOut` del usuario logueado. Ver §13 para el código listo para pegar. |
| GET | `/profesores` · `skip, limit, estado` | ⚠️ | Directorio del admin. |
| POST | `/profesores` | ❌ | Web. |
| GET | `/profesores/{id_profesor}` | ✅ | Ficha del docente en el directorio. |
| PUT / DELETE | `/profesores/{id}` | ❌ | Web. |
| GET | `/profesores/{id}/especializaciones` | ✅ | Chips de especialización en la ficha. |
| POST / DELETE | `/profesores/{id}/especializaciones[/{id_esp}]` | ❌ | Web. |

### 3.5 Estudiantes

| Método | Ruta | Query | Móvil | Uso |
|---|---|---|---|---|
| GET | `/estudiantes/me` | — | ✅ | **Bootstrap del rol Estudiante**: da `id_estudiante`, `codigo_estudiante`, `id_curso_actual`. |
| GET | `/estudiantes` | `skip, limit, id_curso, estado` | ✅ | Directorio admin, listas por curso del docente, y **caché local para resolver el QR** (ver §7). |
| POST | `/estudiantes` | `EstudianteCreate` | ❌ | Web. |
| GET | `/estudiantes/{id}` | — | ✅ | Ficha del estudiante. |
| PUT / DELETE | `/estudiantes/{id}` | — | ❌ | Web. |
| GET | `/estudiantes/{id}/notas` | `id_periodo, id_materia` | ✅ | Notas del estudiante/hijo. Filtro por periodo server-side. |
| GET | `/estudiantes/{id}/asistencia` | `skip, limit` | ✅ | Historial de asistencia paginado. |
| GET | `/estudiantes/{id}/novedades` | — | ✅ | Novedades del estudiante/hijo. |
| GET | `/estudiantes/{id}/ips` | — | ⚠️ | Dato de salud/afiliación: mostrar solo en la ficha del admin. |
| POST / DELETE | `/estudiantes/{id}/ips[...]` | — | ❌ | Web. |

### 3.6 Padres

| Método | Ruta | Móvil | Uso |
|---|---|---|---|
| GET | `/padres/me` | ✅ | **Bootstrap del rol Padre**: devuelve el hijo registrado (`id_estudiante`, `nombre_estudiante`, `documento_estudiante`, `parentesco`). Uno por cuenta. |
| GET | `/padres` · `skip, limit` | ⚠️ | Directorio admin (vínculo acudiente↔estudiante). |
| POST / PUT / DELETE | `/padres[/{id}]` | ❌ | Web. |
| GET | `/padres/{id_padre}` | ⚠️ | Ficha de acudiente en directorio admin. |

### 3.7 Cursos, Materias, Especializaciones

| Método | Ruta | Query | Móvil | Uso |
|---|---|---|---|---|
| GET | `/cursos` | `skip, limit, activo` | ✅ | Selector de curso (registro masivo, filtros). Cachear: cambia poco. |
| GET | `/cursos/{id}` | — | ✅ | Encabezado de pantallas de curso. |
| GET | `/cursos/{id}/estudiantes` | — | ✅ | **Lista de la clase** → registro masivo y toma de asistencia del docente. |
| GET | `/cursos/{id}/horarios` | — | ✅ | Horario semanal del curso (estudiante y docente). |
| POST/PUT/DELETE | `/cursos[...]` | — | ❌ | Web. |
| GET | `/materias` | — | ✅ | Catálogo. Cachear. |
| GET | `/materias/{id}` | — | ✅ | Nombre de materia en notas/horarios. |
| POST/PUT/DELETE | `/materias[...]` | — | ❌ | Web. |
| GET | `/especializaciones` · `/especializaciones/{id}` | — | ⚠️ | Solo lectura en fichas de docente. |
| POST/PUT/DELETE | `/especializaciones[...]` | — | ❌ | Web. |

### 3.8 Asignaciones (profesor ↔ curso ↔ materia)

| Método | Ruta | Query | Móvil | Uso |
|---|---|---|---|---|
| GET | `/asignaciones` | `id_profesor, id_curso, id_materia, activo, skip, limit` | ✅ | **Corazón del rol Docente.** `?id_profesor=X&activo=true` = "mis clases". |
| GET | `/asignaciones/{id}` | — | ✅ | Detalle de una asignación. |
| POST/PUT/DELETE | `/asignaciones[...]` | — | ❌ | Web. |

### 3.9 Horarios

| Método | Ruta | Query | Móvil | Uso |
|---|---|---|---|---|
| GET | `/horarios` | `id_curso, skip, limit` | ✅ | Rejilla semanal. `HorarioOut {dia, hora_inicio, hora_fin, salon, id_curso, id_materia}`. |
| GET | `/horarios/{id}` | — | ✅ | Detalle de bloque. |
| POST/PUT/DELETE | `/horarios[...]` | — | ❌ | Web. |
| POST | `/horarios/{id}/profesores` | — | ❌ | Web. |

> ⚠️ `HorarioOut` **no trae** `nombre_materia` ni `nombre_curso`: hay que hacer join local contra los catálogos cacheados de materias y cursos.

### 3.10 Asistencia

| Método | Ruta | Query / Body | Móvil | Uso |
|---|---|---|---|---|
| GET | `/asistencia` | `id_estudiante, fecha, tipo, skip, limit` | ✅ | "Registro del día" del escáner (`?fecha=hoy`). |
| POST | `/asistencia` | `AsistenciaCreate` | ✅ | **El endpoint más usado de la app.** Uno por escaneo y uno por estudiante en el masivo. |
| GET | `/asistencia/{id}` | — | ✅ | Detalle / confirmación. |
| PUT | `/asistencia/{id}` | `AsistenciaUpdate {estado, observacion}` | ✅ | Corregir un registro (p. ej. Ausente → Excusa). |
| DELETE | `/asistencia/{id}` | — | ⚠️ | Deshacer un escaneo equivocado, con confirmación. |

```
AsistenciaCreate:
  id_estudiante*  int
  fecha*          date (YYYY-MM-DD)
  estado*         Presente | Ausente | Tarde | Excusa | Suspensión
  observacion     string?
  registrado_por* int   ← id_usuario del que registra (lo pone el CLIENTE)
  tipo            entrada | salida | clase
```

### 3.11 Notas

| Método | Ruta | Query / Body | Móvil | Uso |
|---|---|---|---|---|
| GET | `/notas` | `id_estudiante, id_materia, id_periodo, skip, limit` | ✅ | Planilla del docente por materia + periodo. |
| POST | `/notas` | `NotaCreate` | ✅ | Registrar nota (docente). |
| GET | `/notas/{id}` | — | ✅ | Detalle. |
| PUT | `/notas/{id}` | `NotaUpdate` | ✅ | Editar nota. |
| DELETE | `/notas/{id}` | — | ⚠️ | Con confirmación, solo docente/admin. |
| GET | `/notas/estudiantes/{id}/boletin/pdf` | — | ✅ | **Descarga autenticada** (Bearer). No sirve `url_launcher`; ver §8.4. |

```
NotaCreate: id_estudiante*, id_materia*, id_periodo*, nota* (number), observacion?, registrado_por*
```

> No existe endpoint de **periodos**: en la web están fijos 1–4. Se replica como constante local (y se pide al backend, gap #4).

### 3.12 Novedades

| Método | Ruta | Query / Body | Móvil | Uso |
|---|---|---|---|---|
| GET | `/tipos-novedad` | — | ✅ | Catálogo con `nivel_gravedad` (Bajo/Medio/Alto/Crítico). Cachear. |
| POST/PUT/DELETE | `/tipos-novedad[...]` | — | ❌ | Web. |
| GET | `/novedades` | `id_estudiante, id_tipo, estado, skip, limit` | ✅ | Bandeja del docente / consulta de padre y estudiante. |
| POST | `/novedades` | `NovedadCreate` | ✅ | Docente crea novedad. |
| GET | `/novedades/{id}` | — | ✅ | Detalle. |
| PUT | `/novedades/{id}` | `NovedadUpdate` | ✅ | Cambiar estado / acción tomada. |
| DELETE | `/novedades/{id}` | — | ⚠️ | Solo admin. |

```
NovedadCreate: id_estudiante*, id_tipo_novedad*, fecha*, descripcion*, accion_tomada?, registrado_por*
NovedadOut  : + estado, fecha_resolucion?
```

### 3.13 Reportes

| Método | Ruta | Móvil | Uso |
|---|---|---|---|
| GET | `/reportes` · `id_administrador, skip, limit` | ⚠️ | Solo lectura (lista + estado). |
| POST | `/reportes` (`ReporteCreate`) | ❌ | Generación → web. |
| POST | `/reportes/archivo` (multipart) | ❌ | Web. |
| GET | `/reportes/{id}` | ⚠️ | Detalle. |
| GET | `/reportes/{id}/archivo` | ⚠️ | Descarga autenticada (igual que el boletín). |
| PATCH | `/reportes/{id}/estado` | ❌ | Web. |
| DELETE | `/reportes/{id}` | ❌ | Web. |

> Módulo **fase 3 / opcional** en móvil: es un flujo de escritorio.

### 3.14 Dashboard

| Método | Ruta | Devuelve | Móvil |
|---|---|---|---|
| GET | `/dashboard/docente` | `total_cursos_asignados, total_estudiantes, notas_registradas_hoy, asistencias_registradas_hoy` | ✅ |
| GET | `/dashboard/estudiante` | `promedio_general?, porcentaje_asistencia?, novedades_pendientes, periodo_actual` | ✅ |
| GET | `/dashboard/padre` | `id_estudiante, nombre_estudiante, promedio_general?, porcentaje_asistencia?, novedades_pendientes` | ✅ |

> **No existe `/dashboard/admin`.** Los KPIs del panel web (matrícula 103, promedio 3.9, tasa de aprobación, etc.) se calculan agregando varias listas del lado del cliente. En móvil **no se replica** (el admin móvil no tiene dashboard) — y si algún día se quiere, hay que pedir el endpoint (gap #3).

---

## 4. Modelo de dominio (enums y entidades para Dart)

```dart
enum TipoDocumento { cc, ce, ti, pas }
enum Genero { m, f, o }
enum EstadoAsistencia { presente, ausente, tarde, excusa, suspension }
enum TipoAsistencia { entrada, salida, clase }
enum EstadoEstudiante { activo, inactivo, retirado, graduado, suspendido }
enum EstadoProfesor { activo, inactivo, vacaciones, licencia }
enum NivelGravedad { bajo, medio, alto, critico }
enum NivelAcceso { bajo, medio, alto }
enum Parentesco { padre, madre, tutor, abuelo, otro }
enum DiaSemana { lunes, martes, miercoles, jueves, viernes }   // sin tilde en API
enum Jornada { manana, tarde, unica }                          // API acepta "mañana"|"tarde"|"unica"|1..4
enum TipoReporte { academico, disciplinario, medico, asistencia, estadistico }
enum EstadoReporte { pendiente, generando, procesando, completado, error }
```

⚠️ **Trampas de serialización detectadas** — resolverlas con `@JsonValue` explícito:

| Campo | Valor en API | Nota |
|---|---|---|
| `EstadoAsistencia` | `"Suspensión"` | Lleva **tilde y mayúscula inicial**. |
| `HorarioCreate.dia` | `"Miercoles"` | **Sin tilde**, mayúscula inicial. |
| `CursoCreate.jornada` | `"mañana"` | **Con ñ y minúscula**. |
| `hora_inicio` / `hora_fin` | `"07:00:00"` | `format: time`, no ISO datetime → parsear a `TimeOfDay` a mano. |
| `fecha` | `"2026-09-06"` | `format: date` → `DateTime` sin hora. |
| `nota` | `number` | Puede venir `int` o `double` → `(json['nota'] as num).toDouble()`. |

Entidades núcleo (campos tal cual devuelve la API):

```
UsuarioOut      id_usuario, tipo_documento, numero_documento, primer/segundo_nombre,
                primer/segundo_apellido, genero?, direccion?, correo?, telefono?, estado,
                fecha_registro, ultimo_acceso?, id_rol, foto_perfil?, rol{id_rol,nombre_rol}
EstudianteOut   id_estudiante, id_usuario, codigo_estudiante, fecha_ingreso, fecha_egreso?,
                estado, id_curso_actual?, fecha_registro, primer_nombre?, ...apellidos?
ProfesorOut     id_profesor, id_usuario, codigo_profesor, titulo, nivel_estudios,
                fecha_vinculacion, estado, + nombres?
PadreOut        id_padre, id_usuario, id_estudiante, parentesco, ocupacion?,
                nombre_estudiante?, documento_estudiante?
CursoOut        id_curso, nombre_curso, grado, jornada, ano, area?, intensidad_horaria?,
                descripcion?, activo, fecha_creacion
MateriaOut      id_materia, nombre_materia, codigo_materia, activa
AsignacionOut   id_asignacion, id_profesor, id_curso, id_materia, fecha_asignacion,
                fecha_finalizacion?, activo
HorarioOut      id_horario, id_curso, id_materia, dia, hora_inicio, hora_fin, salon, activo
AsistenciaOut   id_asistencia, id_estudiante, fecha, estado, observacion?, registrado_por,
                fecha_registro, tipo?, codigo_qr?, activo?
NotaOut         id_nota, id_estudiante, id_materia, id_periodo, nota, observacion?,
                fecha_registro, registrado_por
NovedadOut      id_novedad, id_estudiante, id_tipo_novedad, fecha, descripcion,
                accion_tomada?, registrado_por, fecha_resolucion?, estado
```

> **`PadreOut` es un vínculo 1:1 padre-usuario ↔ estudiante.** `GET /padres/me` devuelve **el hijo registrado del acudiente** (con `nombre_estudiante` y `documento_estudiante`), es decir **un solo estudiante por cuenta de acudiente**. El shell del rol Padre trabaja siempre sobre ese `id_estudiante`: **no hay selector de hijo**. Si más adelante el colegio necesita acudientes con varios hijos, el cambio es aditivo (ver §11.1).

---

## 5. Arquitectura de ruteo (go_router)

### 5.1 Principios

1. **Un solo `GoRouter`** con `refreshListenable` sobre el estado de sesión.
2. `redirect` global de tres niveles: *¿sesión? → ¿rol conocido? → ¿la ruta pertenece a ese rol?*
3. **Un `StatefulShellRoute.indexedStack` por rol**, cada uno con su propio `BottomNavigationBar` y su propio stack de navegación por pestaña (así el back preserva la pestaña).
4. Rutas **namespaceadas por rol** (`/admin/...`, `/docente/...`, `/estudiante/...`, `/padre/...`): imposible entrar por URL/deep link a una pantalla de otro rol.
5. Todo id viaja como **path param tipado**, nunca por objeto en `extra` (los deep links y el restore de proceso deben funcionar).

### 5.2 Árbol completo de rutas

```
/splash                         bootstrap: lee storage → GET /auth/me → decide destino
/login
/registro                       POST /auth/register (selector de rol con GET /roles)
/recuperar                      POST /auth/forgot-password
/reset-password                 POST /auth/reset-password  (deep link: eyesschool://reset?token=)

────────────────────────────── ADMIN (id_rol = 3) ──────────────────────────────
ShellRoute /admin   ·  tabs: Escanear · Masivo · Directorio · Perfil
  /admin/escanear                       [tab 0] cámara + escaneo continuo
    /admin/escanear/confirmar/:codigo   sheet de confirmación (tipo entrada/salida)
    /admin/escanear/pendientes          cola offline: reintentar / descartar
    /admin/escanear/dia                 "Registro del día" (GET /asistencia?fecha=hoy)
  /admin/masivo                         [tab 1] jornada → curso → fecha → Entrada/Salida
    /admin/masivo/:idCurso/revisar      lista con checks antes de enviar
  /admin/directorio                     [tab 2] buscador (Estudiantes | Profesores | Acudientes)
    /admin/directorio/estudiante/:id
    /admin/directorio/estudiante/:id/qr     carné QR a pantalla completa
    /admin/directorio/profesor/:id
    /admin/directorio/acudiente/:id
  /admin/perfil                         [tab 3]
    /admin/perfil/editar
    /admin/perfil/password

───────────────────────────── DOCENTE (id_rol = 1) ─────────────────────────────
ShellRoute /docente  ·  tabs: Inicio · Mis clases · Novedades · Horario · Perfil
  /docente                              [tab 0] GET /dashboard/docente
  /docente/clases                       [tab 1] GET /asignaciones?id_profesor=X&activo=true
    /docente/clases/:idAsignacion                     detalle (curso + materia)
    /docente/clases/:idAsignacion/asistencia          toma de asistencia del día
    /docente/clases/:idAsignacion/notas               planilla por periodo
    /docente/clases/:idAsignacion/notas/nueva
    /docente/clases/:idAsignacion/notas/:idNota/editar
    /docente/clases/:idAsignacion/estudiantes
    /docente/clases/:idAsignacion/estudiantes/:idEst  ficha 360 del estudiante
  /docente/novedades                    [tab 2] GET /novedades (filtro por estado)
    /docente/novedades/nueva
    /docente/novedades/:id
  /docente/horario                      [tab 3] rejilla semanal de sus cursos
  /docente/perfil                       [tab 4]

──────────────────────────── ESTUDIANTE (id_rol = 2) ───────────────────────────
ShellRoute /estudiante  ·  tabs: Inicio · Notas · Asistencia · Horario · Perfil
  /estudiante                           [tab 0] GET /dashboard/estudiante
    /estudiante/novedades                       GET /estudiantes/{id}/novedades
    /estudiante/carne                           mi QR a pantalla completa
  /estudiante/notas                     [tab 1] por periodo + boletín PDF
    /estudiante/notas/:idMateria                detalle por materia
  /estudiante/asistencia                [tab 2] historial paginado + % del periodo
  /estudiante/horario                   [tab 3] GET /cursos/{id_curso_actual}/horarios
  /estudiante/perfil                    [tab 4]

────────────────────────── PADRE / ACUDIENTE (id_rol = 4) ──────────────────────
ShellRoute /padre  ·  tabs: Inicio · Notas · Asistencia · Novedades · Perfil
  /padre                                [tab 0] GET /dashboard/padre
  /padre/notas                          [tab 1] + boletín PDF
  /padre/asistencia                     [tab 2]
  /padre/novedades                      [tab 3]
  /padre/horario                        (desde Inicio)
  /padre/perfil                         [tab 4]

/error/sin-permiso                      rol sin acceso a la ruta pedida
/error/mantenimiento                    API caída / 5xx persistente
```

### 5.3 Redirect y guards

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ValueNotifier<AuthState>(ref.read(authControllerProvider));
  ref.listen(authControllerProvider, (_, next) => auth.value = next);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, state) {
      final s   = auth.value;
      final loc = state.matchedLocation;
      const publicas = {'/login','/registro','/recuperar','/reset-password'};

      if (s.isBooting)                      return loc == '/splash' ? null : '/splash';
      if (!s.isAuthenticated)               return publicas.contains(loc) ? null : '/login';
      if (publicas.contains(loc) || loc == '/splash') return s.homeRoute; // por rol

      // guard por namespace de rol
      final raiz = '/${loc.split('/')[1]}';
      if (raiz != s.roleRoot) return '/error/sin-permiso';

      return null;
    },
    routes: [...],
  );
});
```

`homeRoute` / `roleRoot` derivados de `MeResponse.id_rol`:

| `id_rol` | `roleRoot` | `homeRoute` |
|---|---|---|
| 3 Admin | `/admin` | `/admin/escanear` |
| 1 Profesor | `/docente` | `/docente` |
| 2 Estudiante | `/estudiante` | `/estudiante` |
| 4 Padre | `/padre` | `/padre` |

Además: si `MeResponse.estado == false` → `/error/sin-permiso` con el mensaje "tu cuenta está pendiente de validación" (el panel web tiene esa bandeja de **Validación Pendiente**).

### 5.4 Bootstrap por rol (lo que pasa justo después del login)

| Rol | Secuencia | Se guarda en sesión |
|---|---|---|
| Admin | `GET /auth/me` → precarga catálogos (`/cursos`, `/materias`) y **caché de estudiantes** para el QR | `id_usuario` |
| Docente | `GET /auth/me` → `GET /profesores/me` → `GET /asignaciones?id_profesor=X&activo=true` | `id_usuario`, `id_profesor`, lista de asignaciones |
| Estudiante | `GET /auth/me` → `GET /estudiantes/me` | `id_estudiante`, `codigo_estudiante`, `id_curso_actual` |
| Padre | `GET /auth/me` → `GET /padres/me` | `id_padre`, `id_estudiante` del hijo, `parentesco`, `documento_estudiante` |

El `id_estudiante` del hijo queda en el estado de sesión y se usa en todas las consultas del rol Padre. No se persiste en `SharedPreferences`: se vuelve a resolver con `/padres/me` en cada arranque, para que un cambio de vínculo hecho desde la web se refleje al siguiente ingreso.

---

## 6. Pantalla por pantalla: qué hace y qué consume

### 6.1 Públicas

| Pantalla | Funcionalidad | Endpoints | Adaptación móvil |
|---|---|---|---|
| **Splash** | Lee tokens del storage seguro, valida sesión, decide destino. | `GET /auth/me` | Si el `access_token` está vencido, el interceptor refresca en silencio antes de decidir. |
| **Login** | Correo + contraseña. | `POST /auth/login` → `GET /auth/me` | Añadir **biometría** (`local_auth`) para reingresos: el refresh token queda en Keychain/Keystore. |
| **Registro** | Formulario largo con campos condicionales según rol (Estudiante→`id_curso_actual`; Padre→`id_estudiante_vinculado` + `parentesco`; Profesor→`titulo`, `nivel_estudios`, `id_especializacion`; Admin→`cargo`). | `GET /roles`, `POST /auth/register` | En web es un modal de una pantalla; en móvil conviene **stepper de 3 pasos**: 1) identidad, 2) contacto, 3) rol + campos del rol. |
| **Recuperar** | Envía correo. | `POST /auth/forgot-password` | Mensaje neutro, igual que la API. |
| **Reset** | Nueva contraseña con token. | `POST /auth/reset-password` | **Deep link** `eyesschool://reset?token=` + fallback de pegado manual del token. |

### 6.2 Admin

| Pantalla | Funcionalidad | Endpoints |
|---|---|---|
| **Escanear** | Cámara con escaneo continuo, feedback háptico + sonoro, resolución del código a estudiante, selector Entrada/Salida, envío. Contador "Registro del día". | `GET /asistencia?fecha=`, `POST /asistencia` |
| **Confirmar escaneo** | Bottom sheet: foto, nombre, curso, código, tipo, estado (Presente/Tarde automático por hora), observación. | `POST /asistencia` |
| **Pendientes (offline)** | Cola local de escaneos no enviados: reintentar todos, editar, descartar. | `POST /asistencia` |
| **Registro masivo** | Jornada → Curso → Fecha → Entrada/Salida → lista con checks → enviar. | `GET /cursos`, `GET /cursos/{id}/estudiantes`, `POST /asistencia` (N llamadas) |
| **Directorio** | Buscador con tres solapas. Búsqueda server-side para usuarios; local para estudiantes por código/curso. | `GET /usuarios?search=`, `GET /estudiantes`, `GET /profesores`, `GET /padres` |
| **Ficha estudiante** | Datos, curso, acudiente, últimas asistencias, novedades abiertas, botón "Ver QR". | `GET /estudiantes/{id}`, `/usuarios/{id}`, `/estudiantes/{id}/asistencia`, `/estudiantes/{id}/novedades` |
| **Ficha profesor** | Datos, especializaciones, cursos asignados. | `GET /profesores/{id}`, `/profesores/{id}/especializaciones`, `GET /asignaciones?id_profesor=` |
| **Perfil** | Editar datos, avatar, contraseña. Documento **bloqueado** (regla ya presente en la web). | `PUT /usuarios/{id}`, `POST /auth/me/avatar` |

### 6.3 Docente

| Pantalla | Funcionalidad | Endpoints |
|---|---|---|
| **Inicio** | 4 KPIs + accesos rápidos "Tomar asistencia" / "Registrar nota" + clases de hoy. | `GET /dashboard/docente`, `GET /profesores/me`, `GET /asignaciones?id_profesor=`, `GET /horarios?id_curso=` |
| **Mis clases** | Lista de asignaciones activas agrupadas por curso. | `GET /asignaciones?id_profesor=X&activo=true` + join con `/cursos` y `/materias` |
| **Tomar asistencia** | Lista de la clase; cada fila con chips `Presente / Tarde / Ausente / Excusa`; acción "marcar todos presentes"; observación por estudiante; envío por lotes. | `GET /cursos/{id}/estudiantes`, `POST /asistencia` (`tipo: clase`) |
| **Planilla de notas** | Selector de periodo (1–4); lista de estudiantes con su nota; edición inline; validación 0.0–5.0. | `GET /notas?id_materia=&id_periodo=`, `POST /notas`, `PUT /notas/{id}` |
| **Ficha 360 del estudiante** | Notas de mi materia, asistencia, novedades. | `GET /estudiantes/{id}/notas?id_materia=`, `/asistencia`, `/novedades` |
| **Novedades** | Bandeja filtrable por estado; crear con tipo + gravedad; cambiar estado. | `GET /tipos-novedad`, `GET/POST/PUT /novedades` |
| **Horario** | Rejilla semanal de todos sus cursos, con "clase actual" resaltada. | `GET /horarios?id_curso=` por cada curso asignado |

### 6.4 Estudiante

| Pantalla | Funcionalidad | Endpoints |
|---|---|---|
| **Inicio** | Promedio, % asistencia, novedades pendientes, periodo actual, próxima clase. | `GET /dashboard/estudiante`, `GET /cursos/{id}/horarios` |
| **Notas** | Por periodo, agrupadas por materia, promedio por materia y general. Botón **Boletín PDF**. | `GET /estudiantes/{id}/notas?id_periodo=`, `GET /notas/estudiantes/{id}/boletin/pdf` |
| **Asistencia** | Historial paginado con scroll infinito + resumen del periodo. | `GET /estudiantes/{id}/asistencia?skip=&limit=` |
| **Horario** | Rejilla semanal del curso. | `GET /cursos/{id_curso_actual}/horarios` |
| **Novedades** | Lista con gravedad y estado. | `GET /estudiantes/{id}/novedades`, `GET /tipos-novedad` |
| **Mi carné QR** | El mismo QR que usa el panel web, a pantalla completa, con brillo al máximo. | (ver §7.4) |

### 6.5 Padre / Acudiente

Mismo conjunto que Estudiante pero **sobre el hijo registrado** (`id_estudiante` que devuelve `GET /padres/me`), más:

| Pantalla | Funcionalidad | Endpoints |
|---|---|---|
| **Inicio** | Tarjeta del hijo (nombre + documento) con promedio, % asistencia y novedades pendientes. | `GET /padres/me`, `GET /dashboard/padre` |

---

## 7. Módulo QR / Asistencia (el corazón móvil)

### 7.1 Qué codifica el QR hoy

El panel web genera la imagen contra `api.qrserver.com` con:

```
data = codigo_estudiante      // p. ej. "EST001", "SYN0013"
```

**Decisión tomada: se mantiene el QR actual tal cual.** La app **lee texto plano = `codigo_estudiante`** y lo resuelve contra el catálogo de estudiantes. No se cambia el formato, no se firma, no se generan códigos nuevos desde la app.

> Consecuencia de seguridad a documentar (no a resolver ahora): el código es adivinable y no expira, así que **cualquiera puede fabricar el QR de otro**. Mitigación de bajo costo hoy: el registro solo lo hace un admin autenticado desde su dispositivo, y queda `registrado_por` auditado. Si más adelante se quiere endurecer, la vía es un token firmado y rotativo emitido por el backend.

### 7.2 Resolución `codigo_estudiante` → `id_estudiante`

**No hay endpoint de búsqueda por código.** `GET /estudiantes` solo filtra por `skip, limit, id_curso, estado`. Entonces:

```
Al iniciar sesión el admin:
  GET /estudiantes?limit=500  (paginando hasta agotar)
  → guardar en Drift: (codigo_estudiante, id_estudiante, id_curso_actual, nombres, estado)
  → índice único sobre codigo_estudiante
Al escanear:
  lookup local O(1) → si no existe: refrescar caché una vez → si sigue sin existir: error "código no reconocido"
```

Este caché **es también el que hace posible el modo offline**. Refresco: al abrir el escáner si tiene > 12 h, y con pull-to-refresh manual.
👉 Si el backend agrega `GET /estudiantes/by-codigo/{codigo}` (gap #5), esto se simplifica muchísimo — pero el caché se queda igual porque el offline lo necesita.

### 7.3 Escaneo continuo + cola offline

**Paquete:** `mobile_scanner` (formato `BarcodeFormat.qrCode`, `detectionSpeed: noDuplicates`).

Flujo:

```
[cámara continua]
   → detección
   → debounce 1500 ms por mismo código (evita triple registro)
   → lookup local del estudiante
   → cálculo de estado sugerido:
        tipo=entrada y hora > hora_limite_entrada  →  "Tarde"
        en cualquier otro caso                     →  "Presente"
   → bottom sheet de confirmación (auto-confirma a los 3 s si está activado "modo rápido")
   → encolar en tabla local `asistencia_pendiente`
   → intentar envío inmediato
```

**Cola offline (Drift):**

```dart
class AsistenciaPendiente {
  int     localId;          // PK autoincrement
  int     idEstudiante;
  String  codigoQr;         // el texto escaneado, se guarda como evidencia
  DateTime fecha;           // fecha del escaneo (no la del envío)
  String  estado;           // Presente | Tarde | ...
  String? observacion;
  int     registradoPor;    // id_usuario del admin
  String  tipo;             // entrada | salida | clase
  DateTime creadoEn;
  int     intentos;
  String? ultimoError;
  EstadoSync sync;          // pendiente | enviando | enviado | fallido | duplicado
}
```

Reglas de sincronización:

1. Todo escaneo **primero se escribe local**, después se intenta la red. La UI nunca espera al servidor.
2. Worker que dispara: al encolar, al recuperar conectividad (`connectivity_plus`), al abrir la app, y cada 60 s si hay pendientes.
3. Reintento con **backoff exponencial** (2s, 8s, 30s, 2min…) y tope de 5 intentos → pasa a `fallido` y aparece en `/admin/escanear/pendientes`.
4. **Idempotencia:** la API no ofrece clave de idempotencia (gap #6). Mitigación en cliente: índice único local `(id_estudiante, fecha, tipo)` → un duplicado se marca `duplicado` sin reenviar. Y si el POST devuelve 409/400 por duplicado, se marca `enviado`.
5. La `fecha` que se envía es **la del escaneo**, no la del envío. Un escaneo del viernes que se sincroniza el lunes sigue siendo del viernes.
6. Badge con el número de pendientes siempre visible en la pestaña Escanear.

### 7.4 Registro masivo por curso

```
1. Selector jornada  (local: mañana / tarde)
2. Selector curso    GET /cursos?activo=true   (filtrado por jornada en cliente)
3. Fecha             date picker (por defecto hoy)
4. Tipo              Entrada / Salida
5. GET /cursos/{id}/estudiantes  → lista con todos marcados "Presente"
6. Desmarcar/ajustar los que falten
7. Enviar            N × POST /asistencia
```

Como **no existe un endpoint de lote** (gap #7), el envío se hace con concurrencia limitada (`Future.wait` en tandas de 5) y una barra de progreso "18/32 enviados". Los fallidos caen en la misma cola offline y se reintentan; nunca se pierde el trabajo del usuario.

### 7.5 Mostrar / compartir el QR del estudiante

- Se muestra la **misma imagen que usa la web**: `api.qrserver.com/v1/create-qr-code/?data={codigo_estudiante}&size=…&ecc=…&margin=…`, con `cached_network_image` para que sobreviva sin red una vez vista.
- **Compartir**: descargar los bytes → `share_plus` con el archivo PNG.
- **Guardar**: `path_provider` + `gal` para llevarlo a la galería (el carné del estudiante).
- Pantalla de carné con brillo forzado al máximo (`screen_brightness`) mientras está visible.

---

## 8. Arquitectura de la app

### 8.1 Estructura de carpetas (feature-first + capas)

```
lib/
├─ main.dart
├─ app/
│  ├─ app.dart                    MaterialApp.router + tema
│  ├─ router/  router.dart · routes.dart · guards.dart · shells/
│  └─ theme/   colors.dart · typography.dart · theme.dart   (claro/oscuro, como la web)
├─ core/
│  ├─ network/    dio_client.dart · auth_interceptor.dart · error_interceptor.dart
│  │              api_exception.dart · api_result.dart
│  ├─ storage/    secure_storage.dart · prefs.dart
│  ├─ db/         app_database.dart (Drift) · daos/
│  ├─ sync/       sync_worker.dart · connectivity.dart
│  ├─ utils/      date_x.dart · time_of_day_x.dart · validators.dart
│  └─ widgets/    app_scaffold · empty_state · error_view · loading · paged_list
├─ features/
│  ├─ auth/          data/ (dto, api) · domain/ (model, repo) · application/ (providers) · presentation/
│  ├─ usuarios/
│  ├─ estudiantes/
│  ├─ profesores/
│  ├─ padres/
│  ├─ cursos/        (incluye materias + catálogos cacheados)
│  ├─ asignaciones/
│  ├─ horarios/
│  ├─ asistencia/    (incluye qr_scan/ y cola offline)
│  ├─ notas/
│  ├─ novedades/
│  ├─ reportes/      (fase 3)
│  └─ dashboard/
└─ shared/  constants.dart · enums.dart · periodos.dart
```

Cada feature: `data → domain ← application ← presentation`. La capa `presentation` **nunca** ve un DTO ni un `Dio`.

### 8.2 Capa de red (Dio)

```dart
BaseOptions(
  baseUrl: 'https://apieyeschool-b7fudxavddh9hhah.canadacentral-01.azurewebsites.net/api/v1',
  connectTimeout: Duration(seconds: 15),
  receiveTimeout: Duration(seconds: 30),
)
```

Interceptores, en orden:

1. **AuthInterceptor** — inyecta `Authorization: Bearer <access_token>`. En `401`: pausa la cola, hace **un solo** `POST /auth/refresh` (mutex, para que 10 peticiones simultáneas no disparen 10 refresh), reintenta las pendientes; si el refresh falla → `logout()` y el router redirige a `/login`.
2. **ErrorInterceptor** — traduce a excepciones de dominio:
   - `422 HTTPValidationError` → `ValidationException` con `detail[].loc` → **mapa campo→mensaje** para pintar el error en el `TextFormField` correcto. Es el error más frecuente de FastAPI y merece manejo de primera clase.
   - `401` → `UnauthorizedException` · `403` → `ForbiddenException` · `404` → `NotFoundException` · `5xx` → `ServerException` · timeout/socket → `NetworkException`.
3. **RetryInterceptor** — solo para `GET` idempotentes: 2 reintentos con backoff. **Nunca** reintenta POST/PUT/PATCH automáticamente (eso lo hace la cola de asistencia, que sí sabe deduplicar).
4. **LogInterceptor** solo en debug, con el header `Authorization` redactado.

**Almacenamiento de tokens:** `flutter_secure_storage` (Keystore / Keychain). Nunca `SharedPreferences`, nunca en la base local.

### 8.3 Estado con Riverpod

| Tipo de provider | Uso |
|---|---|
| `Provider` | `dio`, `apiClient`, repos, `router` |
| `AsyncNotifierProvider` | `authController` (sesión + rol + hijo activo) |
| `FutureProvider.family` | Lecturas simples: `estudianteProvider(id)`, `cursoProvider(id)` |
| `AsyncNotifierProvider.family` | Pantallas con acciones: `notasPlanillaController((idMateria, idPeriodo))`, `asistenciaClaseController(idAsignacion)` |
| `NotifierProvider` | `colaAsistenciaController` (cola offline, escucha el DAO de Drift) |
| `StreamProvider` | `pendientesCountProvider` (badge), `connectivityProvider` |
| `Provider` (cache) | `catalogosProvider`: cursos, materias, tipos de novedad, roles — cargados una vez y refrescados por pull-to-refresh |

Patrón obligatorio: **toda pantalla de datos maneja los tres estados** `AsyncValue.when(data/loading/error)` con `error` accionable ("Reintentar"), y `RefreshIndicator` en todas las listas.

### 8.4 Paginación y descargas

**Paginación:** la API usa `skip` / `limit` sin metadatos de total. La web muestra "Mostrando 1–10 de 111", así que el total sale de otra parte (una lista completa). En móvil: **scroll infinito** sin totales.

```dart
// hasMore = (pagina.length == limit)   ← única señal disponible
```

**Descargas autenticadas** (boletín PDF, archivo de reporte): requieren header `Bearer`, así que `url_launcher` **no sirve**.

```dart
await dio.download(
  '/notas/estudiantes/$idEstudiante/boletin/pdf',
  '${(await getTemporaryDirectory()).path}/boletin_$idEstudiante.pdf',
  onReceiveProgress: (r, t) => ...,
);
await OpenFilex.open(path);   // o share_plus para enviarlo al acudiente
```

### 8.5 Permisos nativos

| Permiso | Para qué | Cuándo se pide |
|---|---|---|
| Cámara | Escáner QR, foto de perfil | Al entrar a `/admin/escanear` por primera vez, con pantalla previa que explica por qué |
| Galería / Fotos | Avatar, guardar carné QR | Al tocar la acción |
| Notificaciones | (fase 3) avisos de novedades y notas | Después del onboarding, no al arrancar |

Con `permission_handler`, y una pantalla de "permiso denegado permanentemente" que lleve a Ajustes.

### 8.6 Dependencias propuestas

```yaml
dependencies:
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  go_router: ^14.0.0
  dio: ^5.4.0
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0
  flutter_secure_storage: ^9.2.2
  shared_preferences: ^2.2.3
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.20
  path_provider: ^2.1.3
  connectivity_plus: ^6.0.3
  mobile_scanner: ^5.1.1
  permission_handler: ^11.3.1
  cached_network_image: ^3.3.1
  share_plus: ^9.0.0
  open_filex: ^4.4.0
  image_picker: ^1.1.2
  intl: ^0.19.0
  fl_chart: ^0.68.0          # KPIs del docente/estudiante
  gal: ^2.3.0                # guardar QR en galería
  local_auth: ^2.2.0         # biometría (opcional)
  screen_brightness: ^1.0.1  # carné QR

dev_dependencies:
  build_runner · freezed · json_serializable · riverpod_generator
  drift_dev · mocktail · flutter_test
```

---

## 9. Vacíos del backend que hay que resolver o negociar

Ordenados por impacto. Los tres primeros **bloquean** funcionalidad; el resto son mejoras de costo/rendimiento.

| # | Vacío | Impacto | Salida propuesta |
|---|---|---|---|
| ~~**1**~~ | ~~No existe `GET /profesores/me`~~ → **RESUELTO: se implementa en el backend.** Código listo para pegar en §13. | ✅ Cerrado | La app asume `GET /profesores/me` en el bootstrap del docente. |
| ~~**2**~~ | ~~¿`/padres/me` devuelve objeto o lista?~~ → **RESUELTO: devuelve el hijo registrado del acudiente (uno solo).** | ✅ Cerrado | Sin selector de hijo. El shell del rol Padre trabaja sobre un único `id_estudiante`. |
| **3** | **No hay `GET /dashboard/admin`.** Los KPIs del panel web se agregan en el cliente. | 🟡 No bloquea (el admin móvil no lleva dashboard) | Solo pedirlo si algún día se quiere el resumen institucional en móvil. |
| **4** | **No hay endpoint de periodos.** `id_periodo` se usa en notas pero no hay catálogo ni "periodo vigente" (salvo `periodo_actual` dentro de `/dashboard/estudiante`). | 🟡 | Constante local 1–4 + tomar `periodo_actual` del dashboard cuando exista. Ideal: `GET /periodos`. |
| **5** | **No se puede buscar estudiante por `codigo_estudiante`.** | 🟡 Obliga al caché completo | Pedir `GET /estudiantes/by-codigo/{codigo}` o un `?search=` en `/estudiantes`. El caché se queda igual por el offline. |
| **6** | **`POST /asistencia` no tiene idempotencia.** Sin clave de idempotencia, un reintento de red puede duplicar el registro. | 🟡 Riesgo de datos sucios | Deduplicación en cliente por `(id_estudiante, fecha, tipo)`. Ideal: header `Idempotency-Key` o `UNIQUE` en BD que devuelva 409. |
| **7** | **No hay registro de asistencia por lotes.** El masivo de un curso de 35 son 35 POST. | 🟡 Lento y frágil en red mala | Pedir `POST /asistencia/bulk` con arreglo. Mientras tanto: tandas de 5 concurrentes + cola. |
| **8** | **`registrado_por` lo envía el cliente.** Cualquiera con token podría atribuir un registro a otro usuario. | 🟠 Seguridad | Debería derivarse del JWT en el servidor. En cliente: enviar siempre `me.id_usuario`, nunca un valor manipulable por UI. |
| **9** | **`GET /asistencia` no filtra por curso ni jornada** (solo `id_estudiante, fecha, tipo`), pero la web ofrece esos filtros → los hace en cliente. | 🟡 | En móvil: filtrar por `fecha` en servidor y por curso/jornada en cliente sobre el resultado. Ideal: `?id_curso=`. |
| **10** | **`HorarioOut` / `AsistenciaOut` / `NotaOut` no traen nombres**, solo IDs. | 🟡 N+1 de joins | Resolver con catálogos cacheados (cursos, materias). Ideal: campos `nombre_*` como ya hacen `EstudianteOut` y `PadreOut`. |
| **11** | **Sin metadatos de paginación** (`total`, `has_more`). | 🟢 Menor | Scroll infinito basado en `length == limit`. |
| **12** | **Permisos por rol no documentados en el OpenAPI.** No se sabe qué rol puede llamar qué. | 🟠 | Pedir la matriz de permisos, o probar endpoint por endpoint con un token de cada rol antes de codificar las pantallas. |
| **13** | **QR sin firma ni expiración** (§7.1). | 🟠 Suplantación posible | Documentado, no se cambia por ahora (decisión tomada). |
| **14** | **`GET /estudiantes/{id}/ips`** expone datos de afiliación en salud. | 🟠 Privacidad | No mostrarlo en pantallas de docente/padre; solo en la ficha del admin, y no cachearlo en la BD local. |

---

## 10. Plan de implementación por fases

### Fase 0 — Cimientos (semana 1)
- Proyecto Flutter, flavors (dev/prod), tema claro/oscuro alineado a la web.
- Dio + los 4 interceptores + `flutter_secure_storage`.
- Generación de **todos** los modelos con freezed/json_serializable a partir del `openapi.json`.
- `GoRouter` con redirect, shells vacíos por rol y pantallas placeholder.
- **Entregable verificable:** login real contra la API → `GET /auth/me` → aterriza en el shell correcto según `id_rol`.

### Fase 1 — Admin QR (semanas 2–3) · *la razón de ser de la app*
- Caché de estudiantes en Drift + resolución por `codigo_estudiante`.
- Escáner continuo + hoja de confirmación + `POST /asistencia`.
- **Cola offline completa** con reintentos, deduplicación y pantalla de pendientes.
- Registro masivo por curso.
- Registro manual (buscador → estudiante → tipo → estado).
- **Entregable:** un admin puede tomar asistencia de una jornada entera sin señal y sincronizar al llegar a la oficina.

### Fase 2 — Docente (semanas 4–5)
- Requiere `GET /profesores/me` desplegado (§13).
- Dashboard, Mis clases, Toma de asistencia por clase.
- Planilla de notas (crear/editar) con validación 0.0–5.0.
- Novedades (crear, listar, cambiar estado).
- Horario semanal.

### Fase 3 — Estudiante y Padre (semanas 6–7)
- Bootstrap `/estudiantes/me` y `/padres/me` + selector de hijo.
- Notas por periodo + descarga de boletín PDF.
- Asistencia con scroll infinito.
- Horario, novedades, carné QR.
- Perfil compartido (los 4 roles usan la misma pantalla).

### Fase 4 — Pulido (semana 8)
- Estados vacíos, skeletons, animaciones, accesibilidad (tamaños de toque, contraste, `Semantics`).
- Manejo fino de 422 → error por campo.
- Push notifications (opcional): nueva nota, nueva novedad, ausencia registrada.
- Reportes en solo lectura (opcional).

### Fase 5 — Verificación
- Tests unitarios de mappers y de la **lógica de deduplicación de la cola** (lo más crítico).
- Tests de widget de los formularios (notas, novedades, registro).
- Test de integración del flujo QR con API mockeada.
- **Prueba de campo obligatoria:** modo avión → 30 escaneos → recuperar red → verificar que hay exactamente 30 registros en la API, ni uno más ni uno menos.
- Matriz de permisos verificada con un token real de cada rol.

---

## 11. Diferencias de diseño web → móvil (decisiones ya tomadas)

| En la web | En móvil | Por qué |
|---|---|---|
| Sidebar de 10 ítems | `BottomNavigationBar` de 4–5 ítems por rol | Un menú de 10 no cabe ni se usa con el pulgar. |
| Tablas con muchas columnas | Tarjetas / `ListTile` con las 3 datos que importan + detalle al tocar | Nada de scroll horizontal. |
| Paginación numerada (1, 2, … 12) | Scroll infinito + pull-to-refresh | La API no da totales y el gesto es el estándar móvil. |
| Filtros en fila horizontal | Bottom sheet de filtros + chips de filtros activos | Los `<select>` en fila no caben en 390 px. |
| Modales grandes de formulario | Pantalla completa o stepper | El teclado se come el modal. |
| `/horarios` como hub de 4 CRUDs | No existe en móvil | Gestión de catálogos = trabajo de escritorio. |
| Escáner con webcam | Cámara nativa, continua, con háptica y sonido | Es la ventaja real del móvil sobre la web. |
| Sin offline | Cola offline en asistencia | Es la otra ventaja real del móvil. |
| Descarga por link | `dio.download` + abrir/compartir | Las descargas requieren header `Bearer`. |

### 11.1 Si algún día un acudiente tiene varios hijos

Hoy `GET /padres/me` devuelve **un** hijo, así que la app no lleva selector. El día que el colegio necesite acudientes con varios estudiantes, el cambio es **aditivo y localizado**:

1. El endpoint pasa a devolver arreglo (o se agrega `GET /padres/me/estudiantes`).
2. En sesión, `hijoActivoId` deja de derivarse y pasa a guardarse en `SharedPreferences`.
3. Se agrega la ruta `/padre/seleccionar-hijo` fuera del shell + un selector en el `AppBar`.
4. El resto de pantallas no cambia: **todas ya consultan por `hijoActivoId`, no por "el hijo"**.

Por eso el estado del rol Padre se modela desde ahora como `hijoActivoId` y no como un campo suelto: cuesta lo mismo hoy y ahorra un refactor mañana.

Version para Android
---

---

## 13. Anexo: `GET /profesores/me` para implementar en el backend

Es el único endpoint nuevo que necesita la app. Sigue exactamente el mismo patrón que `/estudiantes/me` y `/padres/me`, así que entra en el router de profesores sin tocar nada más.

```python
# app/api/v1/endpoints/profesores.py

@router.get("/me", response_model=ProfesorOut)
def get_profesor_me(
    db: Session = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),
):
    """Devuelve el perfil de profesor del usuario autenticado."""
    profesor = (
        db.query(Profesor)
        .filter(Profesor.id_usuario == current_user.id_usuario)
        .first()
    )
    if not profesor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El usuario autenticado no tiene perfil de profesor",
        )
    return profesor
```

**Dos detalles que importan:**

1. **Orden de rutas.** `@router.get("/me")` tiene que declararse **antes** de `@router.get("/{id_profesor}")`. Si queda después, FastAPI intenta convertir `"me"` a `int` y responde `422`. (Es la misma razón por la que `/estudiantes/me` y `/padres/me` ya están arriba en sus routers.)

2. **Enriquecer la respuesta.** `ProfesorOut` ya trae `primer_nombre` / `primer_apellido` opcionales; conviene poblarlos aquí (join con `Usuario`) para que la app no tenga que pedir `/usuarios/{id}` justo después del login.

**Verificación rápida una vez desplegado:**

```bash
# 1. login como docente
curl -s -X POST "$API/api/v1/auth/login" \
     -H "Content-Type: application/json" \
     -d '{"correo":"carlos.jimenez@eyes.edu.co","password":"***"}'

# 2. con el access_token
curl -s "$API/api/v1/profesores/me" -H "Authorization: Bearer $TOKEN"
# esperado: 200 con id_profesor, codigo_profesor, titulo, nivel_estudios, estado
```

Y un caso negativo que conviene dejar cubierto: un **estudiante** llamando `/profesores/me` debe recibir `404` (o `403`), nunca el perfil de otra persona.


*Documento generado a partir de la auditoría del panel web en producción y del contrato OpenAPI 3.1 de la API de Eyes School (104 operaciones, 62 schemas).*
