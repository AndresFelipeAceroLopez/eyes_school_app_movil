# EyeSchool

App móvil de EyeSchool construida en Flutter, con cuatro roles: **Docente**, **Estudiante**, **Padre/Acudiente** y **Administrador**.

## Cómo correr el proyecto

```bash
flutter pub get
flutter run            # dispositivo/emulador conectado
flutter run -d edge    # navegador (Windows)
```

## Cuentas de prueba

No hay backend todavía: la app usa un repositorio simulado (`lib/data/mock`) con estos usuarios. Cualquiera de ellas inicia sesión con la contraseña indicada, o tócalas desde "Cuentas de prueba" en la pantalla de login para autocompletarlas.

| Rol | Correo | Contraseña |
|---|---|---|
| Docente | docente@eyeschool.edu | docente123 |
| Estudiante | carlos.j@colegio.edu | estudiante123 |
| Padre/Acudiente | padre@eyeschool.edu | padre123 |
| Administrador | admin@eyeschool.edu | admin123 |

La sesión se guarda localmente (`shared_preferences`), así que al reabrir la app entra directo a tu rol sin volver a iniciar sesión, hasta que uses "Cerrar sesión" en Perfil.

## Arquitectura

- **Estado**: Riverpod (`lib/providers`).
- **Navegación**: go_router con un shell de navegación inferior por rol (`lib/core/router/app_router.dart`), con redirecciones automáticas según sesión/rol.
- **Datos**: interfaces de repositorio (`lib/data/repositories`) con una implementación mock (`lib/data/mock/mock_seed.dart`). Para conectar un backend real, solo hay que crear una nueva implementación de `AuthRepository`, `UserRepository` y `AcademicRepository` y registrarla en `lib/providers/repository_providers.dart` — el resto de la app no cambia.
- **Diseño**: tokens centralizados en `lib/core/theme` (colores, tipografía, tema) para mantener consistencia visual.

## Pantallas incluidas

Todas las pantallas de las capturas de referencia están implementadas: Splash, Login, Recuperar contraseña, Home de cada rol, Usuarios (Admin) y Perfil del estudiante (con tabs Resumen/Notas/Asistencia/Novedades). Los destinos de la barra inferior que no tenían mockup (Clases, Horario, Gestión, Reportes, etc.) usan una pantalla de marcador de posición ("Próximamente") con el mismo lenguaje visual, para que la navegación esté completa sin inventar UI no especificada.

El escáner QR (`mobile_scanner`) requiere cámara real — funciona en Android/iOS/Web, no en Windows desktop.
