// N-04 / N-20 (app): los tableros muestran el porcentaje calculado con los
// registros activos, igual que la pantalla de asistencia, y nunca > 100 %.
// También: reportes del más reciente al más antiguo y providers nuevos.
import 'package:eyes_school/core/network/dio_client.dart';
import 'package:eyes_school/features/notifications/data/device_token_repository_impl.dart';
import 'package:eyes_school/providers/data_providers.dart';
import 'package:eyes_school/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/scripted_api.dart';

Map<String, Object?> _asistencia(int id, String estado, {bool activo = true}) =>
    {
      'id_asistencia': id,
      'id_estudiante': 1,
      'fecha': '2026-11-0$id',
      'estado': estado,
      'registrado_por': 2,
      'tipo': 'entrada',
      'activo': activo,
    };

Map<String, Object? Function(dynamic)> _routes() => {
  // La API de QA devolvía 140,6 antes del PR #45 del backend.
  '/dashboard/estudiante': (_) => {
    'promedio_general': 4.2,
    'porcentaje_asistencia': 140.6,
    'novedades_pendientes': 1,
    'periodo_actual': 1,
  },
  '/dashboard/padre': (_) => {
    'id_estudiante': 3,
    'nombre_estudiante': 'Santiago López',
    'promedio_general': 3.5,
    'porcentaje_asistencia': 140.6,
    'novedades_pendientes': 0,
  },
  '/estudiantes/me': (_) => {
    'id_estudiante': 1,
    'id_usuario': 3,
    'codigo_estudiante': 'EST001',
    'estado': 'Activo',
    'id_curso_actual': 1,
    'fecha_registro': '2026-11-03T03:03:37',
  },
  '/estudiantes/1/asistencia': (_) => [
    _asistencia(1, 'Presente'),
    _asistencia(2, 'Tarde'),
    _asistencia(3, 'Ausente'),
    _asistencia(4, 'Presente', activo: false), // borrado: no cuenta (N-15)
  ],
  '/estudiantes/3/asistencia': (_) => <Object>[],
  '/estudiantes': (_) => <Object>[],
  '/reportes': (_) => [
    {
      'id_reporte': 1,
      'tipo_reporte': 'Notas',
      'estado': 'Generado',
      'fecha_generacion': '2026-06-01',
    },
    {
      'id_reporte': 2,
      'tipo_reporte': 'Asistencia',
      'estado': 'Generado',
      'fecha_generacion': '2026-06-30',
    },
    {'id_reporte': 3, 'tipo_reporte': 'Novedades', 'estado': 'Pendiente'},
  ],
  '/cursos': (_) => <Object>[],
  '/materias': (_) => <Object>[],
  '/tipos-novedad': (_) => <Object>[],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  (ProviderContainer, ScriptedAdapter) containerWith() {
    final adapter = ScriptedAdapter(_routes());
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
    return (c, adapter);
  }

  test(
    'estudiante: porcentaje de los registros activos, no el de la API',
    () async {
      final (c, _) = containerWith();
      final d = await c.read(academicRepositoryProvider).studentDashboard();

      // Presente + Tarde sobre 3 activos; el borrado no cuenta.
      expect(d.attendancePercent, closeTo(66.67, 0.01));
      expect(d.average, 4.2);
      expect(d.currentPeriod, 1);
    },
  );

  test(
    'padre: se pide el hijo activo y, sin registros, la cifra de la API se limita a 100',
    () async {
      final (c, adapter) = containerWith();
      final d = await c
          .read(academicRepositoryProvider)
          .guardianDashboard(studentId: 3);

      final request = adapter.sent.firstWhere(
        (o) => o.path.endsWith('/dashboard/padre'),
      );
      expect(request.queryParameters['id_estudiante'], 3);
      expect(d.studentId, 3);
      expect(d.attendancePercent, 100);
    },
  );

  test('los reportes se listan del más reciente al más antiguo', () async {
    final (c, _) = containerWith();
    final reports = await c.read(reportRepositoryProvider).reports();

    expect(reports.map((r) => r.id), [2, 1, 3]);
    expect(reports.first.isReady, isTrue);
  });

  test('los providers nuevos se resuelven', () async {
    final (c, _) = containerWith();

    expect(
      c.read(deviceTokenRepositoryProvider),
      isA<DeviceTokenRepositoryImpl>(),
    );
    await expectLater(c.read(studentCatalogReadyProvider.future), completes);
  });
}
