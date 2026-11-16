// CP-ACE-039 (observación): la hoja de confirmación avisa, antes de
// «Registrar», que el estudiante ya tiene ese registro hoy.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eyes_school/core/domain/repositories.dart';
import 'package:eyes_school/features/attendance/data/attendance_api.dart';
import 'package:eyes_school/features/attendance/data/attendance_queue.dart';
import 'package:eyes_school/features/attendance/data/attendance_repository_impl.dart';
import 'package:eyes_school/features/attendance/domain/attendance.dart';
import 'package:eyes_school/features/directory/data/people_api.dart';
import 'package:eyes_school/features/directory/data/student_catalog.dart';

import 'support/memory_store.dart';
import 'support/scripted_api.dart';

final _day = DateTime(2026, 11, 16, 7, 0);

Map<String, dynamic> _ana() => {
  'id_estudiante': 7,
  'id_usuario': 107,
  'codigo_estudiante': 'EST007',
  'estado': 'Activo',
  'id_curso_actual': 1,
  'primer_nombre': 'Ana',
  'primer_apellido': 'Mora',
};

Map<String, dynamic> _entry() => {
  'id_asistencia': 1,
  'id_estudiante': 7,
  'fecha': '2026-11-16',
  'estado': 'Presente',
  'registrado_por': 4,
  'tipo': 'entrada',
  'activo': true,
};

void main() {
  late MemoryStore store;

  setUp(() => store = MemoryStore());

  (AttendanceRepositoryImpl, AttendanceQueue) build(
    Map<String, Object? Function(RequestOptions)> routes,
  ) {
    final client = scriptedClient(ScriptedAdapter(routes));
    final api = AttendanceApi(client);
    final queue = AttendanceQueue(api: api, store: store);
    return (
      AttendanceRepositoryImpl(
        api: api,
        catalog: StudentCatalog(api: PeopleApi(client), store: store),
        queue: queue,
      ),
      queue,
    );
  }

  Future<ScanResolved> scan(AttendanceRepositoryImpl repo) async =>
      await repo.resolve('EST007', kind: AttendanceKind.entry, now: _day)
          as ScanResolved;

  test('sin registro hoy → sin aviso', () async {
    final (repo, _) = build({
      '/estudiantes': (_) => [_ana()],
      '/asistencia': (_) => <Object>[],
    });

    expect((await scan(repo)).alreadyRecorded, isFalse);
  });

  test('la API ya tiene la entrada (web u otro teléfono) → aviso', () async {
    final (repo, _) = build({
      '/estudiantes': (_) => [_ana()],
      '/asistencia': (_) => [_entry()],
    });

    expect((await scan(repo)).alreadyRecorded, isTrue);
  });

  test('sin red, la cola de este teléfono basta para avisar', () async {
    // El catálogo queda en disco con red; luego se pierde la conexión.
    final (online, _) = build({
      '/estudiantes': (_) => [_ana()],
      '/asistencia': (_) => <Object>[],
    });
    await online.warmUp();
    final (offline, queue) = build(const {});
    await queue.enqueue(
      studentId: 7,
      studentName: 'Ana Mora',
      date: _day,
      state: AttendanceState.present,
      kind: AttendanceKind.entry,
      registeredBy: 4,
    );

    expect((await scan(offline)).alreadyRecorded, isTrue);
  });

  test('una salida no se confunde con la entrada del día', () async {
    final (repo, _) = build({
      '/estudiantes': (_) => [_ana()],
      '/asistencia': (_) => [_entry()],
    });

    final exit =
        await repo.resolve('EST007', kind: AttendanceKind.exit, now: _day)
            as ScanResolved;
    expect(exit.alreadyRecorded, isFalse);
  });
}
