import 'package:dio/dio.dart';
import 'package:eyes_school/core/domain/repositories.dart';
import 'package:eyes_school/features/attendance/data/attendance_api.dart';
import 'package:eyes_school/features/attendance/data/attendance_queue.dart';
import 'package:eyes_school/features/attendance/data/attendance_repository_impl.dart';
import 'package:eyes_school/features/attendance/domain/attendance.dart';
import 'package:eyes_school/features/directory/data/people_api.dart';
import 'package:eyes_school/features/directory/data/student_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_store.dart';
import 'support/scripted_api.dart';

/// A QR holds nothing but `codigo_estudiante`, and the API cannot look a
/// student up by it, so every scan is resolved against the local catalog.
/// These tests pin the rules that make a scan at the classroom door work:
/// tolerant parsing of the code, a refresh for a student enrolled today, and
/// a catalog on disk that keeps scanning alive without signal.
void main() {
  late MemoryStore store;
  late List<Map<String, dynamic>> enrolled;
  late List<RequestOptions> writes;

  setUp(() {
    store = MemoryStore();
    enrolled = [
      _student(7, 'EST007', 'Ana', 'Mora'),
      _student(8, 'EST008', 'Beto', 'Gil', status: 'Retirado'),
      _student(9, 'EST-009', 'Carla', 'Ruiz'),
    ];
    writes = [];
  });

  Map<String, Object? Function(RequestOptions)> api() => {
    '/estudiantes': (_) => enrolled,
    '/asistencia/55': (options) {
      writes.add(options);
      return _record(55);
    },
    '/asistencia': (options) {
      if (options.method == 'GET') return [_record(1), _record(2)];
      writes.add(options);
      return _record(100 + writes.length);
    },
  };

  AttendanceRepositoryImpl repositoryOver(
    Map<String, Object? Function(RequestOptions)> routes, {
    bool online = true,
  }) {
    final client = scriptedClient(
      online
          ? ScriptedAdapter(routes, onUnmatched: notFound)
          : ScriptedAdapter(const {}),
    );
    final attendance = AttendanceApi(client);
    return AttendanceRepositoryImpl(
      api: attendance,
      catalog: StudentCatalog(api: PeopleApi(client), store: store),
      queue: AttendanceQueue(api: attendance, store: store),
    );
  }

  group('resolver un escaneo', () {
    test('el código tal como lo genera el panel web', () async {
      final result = await repositoryOver(
        api(),
      ).resolve(' est007 ', now: _at(7, 0));

      expect(result, isA<ScanResolved>());
      final resolved = result as ScanResolved;
      expect(resolved.student.displayName, 'Ana Mora');
      expect(resolved.suggested, AttendanceState.present);
    });

    test(
      'acepta el código sin guiones, en JSON, en una URL o como id',
      () async {
        final repository = repositoryOver(api());

        for (final raw in [
          'EST009',
          '{"codigo_estudiante": "EST-009"}',
          'https://eyes.edu.co/qr/EST-009',
          '9',
        ]) {
          final result = await repository.resolve(raw);
          expect(result, isA<ScanResolved>(), reason: raw);
          expect((result as ScanResolved).student.studentId, 9, reason: raw);
        }
      },
    );

    test('un estudiante retirado no se registra', () async {
      final result = await repositoryOver(api()).resolve('EST008');

      expect(result, isA<ScanInactiveStudent>());
    });

    test(
      'un estudiante matriculado hoy se encuentra tras refrescar el catálogo',
      () async {
        final repository = repositoryOver(api());
        await repository.warmUp();
        expect(repository.cachedStudentCount, 3);

        enrolled.add(_student(10, 'EST010', 'Dani', 'Rey'));
        final result = await repository.resolve('EST010');

        expect(result, isA<ScanResolved>());
        expect(repository.cachedStudentCount, 4);
        expect(repository.catalogRefreshedAt, isNotNull);
      },
    );

    test('un código desconocido termina en ScanUnknownCode', () async {
      final result = await repositoryOver(api()).resolve('NO-EXISTE');

      expect(result, isA<ScanUnknownCode>());
      expect((result as ScanUnknownCode).code, 'NO-EXISTE');
    });

    test(
      'sin red se escanea con el catálogo guardado en el dispositivo',
      () async {
        await repositoryOver(api()).warmUp();

        final offline = repositoryOver(api(), online: false);
        final result = await offline.resolve('EST007');

        expect(result, isA<ScanResolved>());
        expect(offline.searchStudents('carla').single.code, 'EST-009');
        expect(offline.studentById(7)?.fullName, 'Ana Mora');
      },
    );

    test('sin red y sin catálogo el error llega a la pantalla', () async {
      await expectLater(
        repositoryOver(api(), online: false).resolve('EST007'),
        throwsA(anything),
      );
    });
  });

  group('estado sugerido', () {
    test(
      'después de la hora de corte la entrada es tarde; la salida nunca',
      () {
        final repository = repositoryOver(api());

        expect(
          repository.suggestedState(now: _at(7, 10)),
          AttendanceState.present,
        );
        expect(
          repository.suggestedState(now: _at(7, 40)),
          AttendanceState.late,
        );
        expect(
          repository.suggestedState(kind: AttendanceKind.exit, now: _at(9, 0)),
          AttendanceState.present,
        );
      },
    );
  });

  group('registrar', () {
    test('el mismo estudiante, día y tipo solo se registra una vez', () async {
      final repository = repositoryOver(api());

      Future<bool> scan() => repository.record(
        studentId: 7,
        studentName: 'Ana Mora',
        state: AttendanceState.present,
        kind: AttendanceKind.entry,
        registeredBy: 4,
        date: DateTime(2026, 10, 26),
      );

      expect(await scan(), isTrue);
      expect(await scan(), isFalse);
    });

    test(
      'la asistencia masiva encola todo, reporta progreso y la envía',
      () async {
        final repository = repositoryOver(api());
        final progress = <int>[];

        final result = await repository.recordBulk(
          marks: {7: AttendanceMark.present, 9: AttendanceMark.late},
          names: {7: 'Ana Mora'},
          kind: AttendanceKind.classroom,
          registeredBy: 4,
          date: DateTime(2026, 10, 26),
          observations: {9: 'Llegó del médico'},
          onProgress: (done, total) => progress.add(done),
        );

        expect(result.queued, 2);
        expect(result.duplicates, 0);
        expect(progress, [1, 2]);
        expect(writes.where((w) => w.method == 'POST'), hasLength(2));
        expect(repository.queue.pendingCount, 0);
      },
    );

    test(
      'consultar, corregir y deshacer usan el registro del servidor',
      () async {
        final repository = repositoryOver(api());

        final today = await repository.registeredOn(DateTime(2026, 10, 26));
        await repository.correct(
          55,
          state: AttendanceState.excused,
          observation: 'Excusa médica',
        );
        await repository.undo(55);

        expect(today, hasLength(2));
        expect(writes.map((w) => '${w.method} ${w.path}'), [
          'PUT /asistencia/55',
          'DELETE /asistencia/55',
        ]);
        expect(writes.first.data, {
          'estado': 'Excusa',
          'observacion': 'Excusa médica',
        });
      },
    );
  });
}

DateTime _at(int hour, int minute) => DateTime(2026, 10, 26, hour, minute);

Map<String, dynamic> _student(
  int id,
  String code,
  String first,
  String last, {
  String status = 'Activo',
}) => {
  'id_estudiante': id,
  'id_usuario': 100 + id,
  'codigo_estudiante': code,
  'estado': status,
  'id_curso_actual': 1,
  'primer_nombre': first,
  'primer_apellido': last,
};

Map<String, dynamic> _record(int id) => {
  'id_asistencia': id,
  'id_estudiante': 7,
  'fecha': '2026-10-26',
  'estado': 'Presente',
  'registrado_por': 4,
  'tipo': 'entrada',
};
