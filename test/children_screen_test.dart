// UT-APP-05 · APP-03 · Padre con varios hijos (PR-04).
//
// Prueba de caja negra: la sesión se restaura por la API (ScriptedAdapter) con
// las respuestas reales de la API de QA del 10/11/2026 para rosa.perez
// (DS-03, hijos 1 Sofía y 3 Santiago) y roberto.diaz (DS-01, hijo 2 Juan).
// No depende de nombres internos de la corrección (LinkedChild,
// activeChildProvider…): solo de lo que ve el padre y de lo que pide la app.
//
// Antes de la corrección: FALLA (la app solo lee /padres/me, un único hijo).
// Después de APP-03 + BE-07: pasa.
import 'package:eyes_school/core/network/dio_client.dart';
import 'package:eyes_school/features/academic/presentation/parent_grades_screen.dart';
import 'package:eyes_school/features/directory/presentation/children_screen.dart';
import 'package:eyes_school/providers/repository_providers.dart';
import 'package:eyes_school/providers/session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/scripted_api.dart';

Map<String, Object? Function(dynamic)> _guardian({
  required Map<String, Object?> me,
  required Map<String, Object?> padreMe,
  required List<Map<String, Object?>> hijos,
}) {
  final routes = <String, Object? Function(dynamic)>{
    '/auth/me': (_) => me,
    '/padres/me': (_) => padreMe,
    '/padres/me/hijos': (_) => hijos,
    '/dashboard/padre': (_) => {
      'id_estudiante': hijos.first['id_estudiante'],
      'nombre_estudiante': hijos.first['nombre_estudiante'],
      'promedio_general': 4.28,
      'porcentaje_asistencia': 90.0,
      'novedades_pendientes': 0,
    },
    '/cursos': (_) => <Object>[],
    '/materias': (_) => <Object>[],
  };
  for (final h in hijos) {
    final id = h['id_estudiante'];
    routes['/estudiantes/$id'] = (_) => {
      'id_estudiante': id,
      'id_usuario': 100 + (id as int),
      'codigo_estudiante': 'EST00$id',
      'fecha_ingreso': '2026-01-20',
      'fecha_egreso': null,
      'estado': 'Activo',
      'id_curso_actual': h['id_curso_actual'],
      'fecha_registro': '2026-11-03T03:03:37.192536',
      'primer_nombre': null,
      'segundo_nombre': null,
      'primer_apellido': null,
      'segundo_apellido': null,
    };
    routes['/estudiantes/$id/notas'] = (_) => <Object>[];
    routes['/estudiantes/$id/novedades'] = (_) => <Object>[];
    routes['/cursos/${h['id_curso_actual']}/horarios'] = (_) => <Object>[];
  }
  return routes;
}

final _rosa = _guardian(
  me: {
    'id_usuario': 4,
    'primer_nombre': 'Rosa',
    'primer_apellido': 'Pérez',
    'correo': 'rosa.perez@gmail.com',
    'nombre_rol': 'padre',
    'id_rol': 4,
    'estado': true,
  },
  padreMe: {
    'id_padre': 1,
    'id_usuario': 4,
    'id_estudiante': 1,
    'parentesco': 'Madre',
    'ocupacion': 'Enfermera',
    'nombre_estudiante': 'Sofía Rodríguez',
    'documento_estudiante': '20000001',
  },
  hijos: [
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
  ],
);

final _roberto = _guardian(
  me: {
    'id_usuario': 8,
    'primer_nombre': 'Roberto',
    'primer_apellido': 'Díaz',
    'correo': 'roberto.diaz@gmail.com',
    'nombre_rol': 'padre',
    'id_rol': 4,
    'estado': true,
  },
  padreMe: {
    'id_padre': 2,
    'id_usuario': 8,
    'id_estudiante': 2,
    'parentesco': 'Padre',
    'ocupacion': 'Ingeniero',
    'nombre_estudiante': 'Juan Pérez',
    'documento_estudiante': '20000002',
  },
  hijos: [
    {
      'id_estudiante': 2,
      'nombre_estudiante': 'Juan Pérez',
      'documento_estudiante': '20000002',
      'parentesco': 'Padre',
      'id_curso_actual': 1,
    },
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'eyeschool.auth.access_token': 'token-de-prueba',
      'eyeschool.auth.refresh_token': 'refresh-de-prueba',
    });
  });

  Future<(ProviderContainer, ScriptedAdapter)> restoreSession(
    Map<String, Object? Function(dynamic)> routes,
  ) async {
    final adapter = ScriptedAdapter(routes);
    final container = ProviderContainer(
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
    addTearDown(container.dispose);
    container.read(sessionProvider);
    // Espera a que la sesión se restaure desde la API programada.
    for (var i = 0; i < 50 && container.read(sessionProvider).isLoading; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(container.read(currentSessionProvider), isNotNull);
    return (container, adapter);
  }

  Future<void> pump(
    WidgetTester tester,
    ProviderContainer c,
    Widget screen,
  ) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  testWidgets(
    'UT-APP-05 · con 2 hijos se listan y al elegir el segundo se piden sus notas',
    (tester) async {
      final (container, adapter) =
          await tester.runAsync(() => restoreSession(_rosa)) ??
          (throw StateError('sin sesión'));

      await pump(tester, container, const ChildrenScreen());
      expect(tester.takeException(), isNull);

      // CA-PBI91.1: se ven los dos hijos vinculados.
      expect(find.textContaining('Sofía Rodríguez'), findsWidgets);
      expect(find.textContaining('Santiago López'), findsWidgets);

      // CA-PBI91.2: al tocar el segundo, las notas son las de él.
      await tester.tap(find.textContaining('Santiago López').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      adapter.requested.clear();
      await pump(tester, container, const ParentGradesScreen());
      expect(
        adapter.requested.any((p) => p.endsWith('/estudiantes/3/notas')),
        isTrue,
        reason: 'pedidas: ${adapter.requested}',
      );
      expect(
        adapter.requested.any((p) => p.endsWith('/estudiantes/1/notas')),
        isFalse,
      );
    },
  );

  testWidgets('UT-APP-05 · con 1 hijo no aparece ningún otro estudiante', (
    tester,
  ) async {
    final (container, _) =
        await tester.runAsync(() => restoreSession(_roberto)) ??
        (throw StateError('sin sesión'));

    await pump(tester, container, const ChildrenScreen());
    expect(tester.takeException(), isNull);
    expect(container.read(currentSessionProvider)!.childId, 2);
    expect(find.textContaining('Sofía'), findsNothing);
    expect(find.textContaining('Santiago'), findsNothing);
  });
}
