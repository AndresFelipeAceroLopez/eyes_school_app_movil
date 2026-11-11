// IT-APP-02 (APP-03) e IT-APP-03 (APP-06) · AuthRepositoryImpl contra
// respuestas programadas con ScriptedAdapter (PR-05).
//
// Las respuestas son las reales de la API de QA del 10/11/2026 (rosa.perez,
// DS-03). Las pruebas son de caja negra: miran lo que la app pide y envía,
// no nombres internos de la corrección.
//
// Antes de las correcciones:
//   IT-APP-02 «2 hijos»  → FALLA (la app no consulta /padres/me/hijos).
//   IT-APP-02 «sin hijos» → pasa (la sesión ya se crea sin vínculo).
//   IT-APP-03            → FALLA (el correo solo se recorta, no pasa a minúsculas).
import 'dart:convert';

import 'package:eyes_school/core/network/dio_client.dart';
import 'package:eyes_school/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/scripted_api.dart';

const _rosaMe = {
  'id_usuario': 4,
  'primer_nombre': 'Rosa',
  'primer_apellido': 'Pérez',
  'correo': 'rosa.perez@gmail.com',
  'nombre_rol': 'padre',
  'id_rol': 4,
  'estado': true,
};

const _rosaPadreMe = {
  'id_padre': 1,
  'id_usuario': 4,
  'id_estudiante': 1,
  'parentesco': 'Madre',
  'ocupacion': 'Enfermera',
  'nombre_estudiante': 'Sofía Rodríguez',
  'documento_estudiante': '20000001',
};

const _rosaHijos = [
  {
    'id_estudiante': 1,
    'nombre_estudiante': 'Sofía Rodríguez',
    'documento_estudiante': '20000001',
    'parentesco': 'Madre',
    'id_curso_actual': 1,
  },
  {
    'id_estudiante': 3,
    'nombre_estudiante': 'Santiago López',
    'documento_estudiante': '20000003',
    'parentesco': 'Abuela',
    'id_curso_actual': 2,
  },
];

Map<String, Object? Function(dynamic)> _baseRoutes() => {
  '/auth/login': (_) => {
    'access_token': 'acceso-de-prueba',
    'refresh_token': 'refresco-de-prueba',
    'token_type': 'bearer',
  },
  '/dashboard/padre': (_) => {
    'id_estudiante': 1,
    'nombre_estudiante': 'Sofía Rodríguez',
    'promedio_general': 4.28,
    'porcentaje_asistencia': 90.0,
    'novedades_pendientes': 0,
  },
  '/estudiantes/1': (_) => {
    'id_estudiante': 1,
    'id_usuario': 3,
    'codigo_estudiante': 'EST001',
    'fecha_ingreso': '2026-01-20',
    'estado': 'Activo',
    'id_curso_actual': 1,
    'fecha_registro': '2026-11-03T03:03:37.192536',
  },
  '/cursos': (_) => <Object>[],
  '/materias': (_) => <Object>[],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  ProviderContainer containerWith(ScriptedAdapter adapter) {
    final c = ProviderContainer(
      overrides: [
        dioProvider.overrideWith((ref) {
          final dio = buildDio(
            tokens: ref.watch(tokenStorageProvider),
            onSessionExpired: ref.watch(sessionExpiryProvider).fire,
          );
          dio.httpClientAdapter = adapter;
          return dio;
        }),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('IT-APP-02 · sesión del padre', () {
    test(
      'con 2 hijos: la app consulta /padres/me/hijos y el hijo activo es el primero',
      () async {
        final adapter = ScriptedAdapter({
          ..._baseRoutes(),
          '/auth/me': (_) => _rosaMe,
          '/padres/me': (_) => _rosaPadreMe,
          '/padres/me/hijos': (_) => _rosaHijos,
        });
        final session = await containerWith(adapter)
            .read(authRepositoryProvider)
            .signIn(email: 'rosa.perez@gmail.com', password: 'x');

        expect(
          adapter.requested.any((p) => p.endsWith('/padres/me/hijos')),
          isTrue,
          reason: 'pedidas: ${adapter.requested}',
        );
        expect(session.childId, 1);
      },
    );

    test('sin hijos: la sesión se crea sin hijo vinculado', () async {
      // Ningún padre de QA está sin vínculo (pregunta P-04): la respuesta 404
      // de /padres/me es la que da FastAPI a un recurso inexistente.
      final adapter = ScriptedAdapter({
        ..._baseRoutes(),
        '/auth/me': (_) => _rosaMe,
        '/padres/me': (_) =>
            const ScriptedResponse(404, {'detail': 'No encontrado'}),
        '/padres/me/hijos': (_) => <Object>[],
      });
      final session = await containerWith(adapter)
          .read(authRepositoryProvider)
          .signIn(email: 'rosa.perez@gmail.com', password: 'x');

      expect(session.childId, isNull);
      expect(session.user.userId, 4);
    });
  });

  test('IT-APP-03 · login con « Ana@X.com » envía «ana@x.com»', () async {
    final adapter = ScriptedAdapter({
      ..._baseRoutes(),
      '/auth/me': (_) => _rosaMe,
      '/padres/me': (_) => _rosaPadreMe,
      '/padres/me/hijos': (_) => _rosaHijos,
    });
    await containerWith(
      adapter,
    ).read(authRepositoryProvider).signIn(email: ' Ana@X.com ', password: 'x');

    final login = adapter.sent.firstWhere(
      (o) => o.path.endsWith('/auth/login'),
    );
    final body = login.data is String
        ? jsonDecode(login.data as String)
        : login.data;
    expect((body as Map)['correo'], 'ana@x.com');
  });
}
