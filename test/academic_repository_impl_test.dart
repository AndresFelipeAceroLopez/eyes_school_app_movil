import 'package:dio/dio.dart';
import 'package:eyes_school/features/academic/data/academic_api.dart';
import 'package:eyes_school/features/academic/data/academic_repository_impl.dart';
import 'package:eyes_school/features/academic/domain/class_session.dart';
import 'package:eyes_school/features/dashboard/data/dashboard_api.dart';
import 'package:eyes_school/features/directory/data/catalog_repository_impl.dart';
import 'package:eyes_school/features/directory/data/people_api.dart';
import 'package:eyes_school/features/novedades/data/novedades_api.dart';
import 'package:eyes_school/features/novedades/domain/severity.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/scripted_api.dart';

/// The academic repository is where the API's bare foreign keys become names
/// a person can read. These tests run the real APIs, mappers and catalog
/// cache over a scripted transport, so a renamed JSON key or a broken join
/// fails here instead of on a teacher's phone.
void main() {
  late List<RequestOptions> writes;

  setUp(() => writes = []);

  Map<String, dynamic> write(RequestOptions options) {
    writes.add(options);
    return <String, dynamic>{};
  }

  /// Two courses, three subjects, one teacher (id 4) teaching two of them.
  Map<String, Object? Function(RequestOptions)> school() => {
    '/cursos/1/horarios': (_) => [
      _block(1, course: 1, subject: 11, day: 'Miercoles', start: '09:00:00'),
      _block(2, course: 1, subject: 12, day: 'Lunes', start: '07:00:00'),
      _block(3, course: 1, subject: 13, day: 'Lunes', start: '08:00:00'),
      _block(
        4,
        course: 1,
        subject: 11,
        day: 'Lunes',
        start: '10:00:00',
        active: false,
      ),
    ],
    '/cursos/2/horarios': (_) => [
      _block(5, course: 2, subject: 11, day: 'Martes', start: '07:00:00'),
      _block(6, course: 2, subject: 13, day: 'Martes', start: '08:00:00'),
    ],
    '/cursos/1/estudiantes': (_) => [
      _student(30, code: 'EST030', first: 'Zoe', last: 'Ruiz'),
      _student(31, code: 'EST031', first: 'Ana', last: 'Mora'),
      _student(32, code: 'EST032', status: 'Retirado'),
      _student(33, code: 'EST033'),
    ],
    '/cursos': (_) => [
      {
        'id_curso': 1,
        'nombre_curso': '10A',
        'grado': '10',
        'jornada': 'manana',
        'ano': 2026,
      },
      {
        'id_curso': 2,
        'nombre_curso': '9B',
        'grado': '9',
        'jornada': 'tarde',
        'ano': 2026,
      },
      {
        'id_curso': 3,
        'nombre_curso': '8C',
        'grado': '8',
        'ano': 2026,
        'activo': false,
      },
    ],
    '/materias': (_) => [
      {
        'id_materia': 11,
        'nombre_materia': 'Matemáticas',
        'codigo_materia': 'MAT',
      },
      {'id_materia': 12, 'nombre_materia': 'Español', 'codigo_materia': 'ESP'},
      {'id_materia': 13, 'nombre_materia': 'Ciencias', 'codigo_materia': 'CIE'},
      {
        'id_materia': 14,
        'nombre_materia': 'Latín',
        'codigo_materia': 'LAT',
        'activa': false,
      },
    ],
    '/tipos-novedad': (_) => [
      {
        'id_tipo_novedad': 5,
        'nombre_tipo': 'Convivencia',
        'nivel_gravedad': 'Alto',
      },
      {
        'id_tipo_novedad': 6,
        'nombre_tipo': 'Salud',
        'nivel_gravedad': 'Bajo',
        'activo': false,
      },
    ],
    '/asignaciones/40': (_) => _assignment(40, course: 1, subject: 11),
    '/asignaciones': (options) => options.queryParameters['id_profesor'] == 4
        ? [
            _assignment(41, course: 2, subject: 11),
            _assignment(40, course: 1, subject: 11),
            _assignment(42, course: 1, subject: 13),
          ]
        : [
            _assignment(40, course: 1, subject: 11),
            _assignment(41, course: 2, subject: 11),
            _assignment(42, course: 1, subject: 13),
          ],
    '/estudiantes/7/notas': (_) => [
      _grade(1, subject: 13, score: 4.2),
      _grade(2, subject: 11, score: 3),
      _grade(3, subject: 99, score: 2.5),
    ],
    '/estudiantes/7/asistencia': (_) => [
      _attendance(1, 'Presente'),
      _attendance(2, 'Presente'),
      _attendance(3, 'Ausente'),
      _attendance(4, 'Tarde'),
    ],
    '/estudiantes/7/novedades': (_) => [_novedad(70, type: 5)],
    '/notas/500': write,
    '/notas': (options) => options.method == 'GET'
        ? [_grade(9, subject: 11, score: 4.8)]
        : write(options),
    '/novedades/80': write,
    '/novedades': (options) => options.method == 'GET'
        ? [_novedad(80, type: 5), _novedad(81, type: 99, status: 'Completado')]
        : write(options),
    '/dashboard/docente': (_) => {
      'total_cursos_asignados': 2,
      'total_estudiantes': 64,
      'notas_registradas_hoy': 3,
      'asistencias_registradas_hoy': 30,
    },
  };

  AcademicRepositoryImpl repositoryOver(
    Map<String, Object? Function(RequestOptions)> routes,
  ) {
    final client = scriptedClient(
      ScriptedAdapter(routes, onUnmatched: notFound),
    );
    final academic = AcademicApi(client);
    final novedades = NovedadesApi(client);
    return AcademicRepositoryImpl(
      academic: academic,
      novedades: novedades,
      people: PeopleApi(client),
      dashboard: DashboardApi(client),
      catalogs: CatalogRepositoryImpl(academic: academic, novedades: novedades),
    );
  }

  group('horarios', () {
    test(
      'el horario del curso trae nombres, omite bloques inactivos y ordena por día y hora',
      () async {
        final sessions = await repositoryOver(school()).courseSchedule(1);

        expect(sessions.map((s) => '${s.day} ${s.subject}'), [
          'Lunes Español',
          'Lunes Ciencias',
          'Miércoles Matemáticas',
        ]);
        expect(sessions.first.room, 'Salón 101');
      },
    );

    test(
      'el horario del docente solo incluye sus materias en cada curso',
      () async {
        final sessions = await repositoryOver(school()).teacherSchedule(4);

        // Curso 1: Matemáticas y Ciencias (no Español). Curso 2: solo Matemáticas.
        expect(sessions.map((s) => s.subject), [
          'Ciencias',
          'Matemáticas',
          'Matemáticas',
        ]);
        expect(sessions.map((s) => s.group), contains('9B · Salón 101'));
      },
    );

    test('un docente sin asignaciones tiene el horario vacío', () async {
      final routes = school()..['/asignaciones'] = (_) => [];

      expect(await repositoryOver(routes).teacherSchedule(4), isEmpty);
    });

    test('todayFrom filtra el día actual', () {
      final weekly = [
        const ClassSession(
          subject: 'A',
          group: '',
          room: '',
          status: ClassStatus.upcoming,
          day: 'Lunes',
        ),
        const ClassSession(
          subject: 'B',
          group: '',
          room: '',
          status: ClassStatus.upcoming,
          day: 'Martes',
        ),
      ];

      final today = AcademicRepositoryImpl.todayFrom(
        weekly,
        now: DateTime(2026, 10, 26, 6),
      );

      expect(today.map((s) => s.subject), ['A']);
    });
  });

  group('clases del docente', () {
    test(
      'se listan ordenadas por curso y materia, con la jornada del curso',
      () async {
        final classes = await repositoryOver(school()).teacherClasses(4);

        expect(classes.map((c) => '${c.courseName} ${c.subjectName}'), [
          '10A Ciencias',
          '10A Matemáticas',
          '9B Matemáticas',
        ]);
        expect(classes.first.shift, 'Mañana');
      },
    );

    test(
      'una asignación existente se resuelve y una inexistente es null',
      () async {
        final repository = repositoryOver(school());

        expect((await repository.teacherClass(40))?.subjectName, 'Matemáticas');
        expect(await repository.teacherClass(999), isNull);
      },
    );

    test(
      'la lista de clase deja fuera a los retirados y usa el código si falta el nombre',
      () async {
        final roster = await repositoryOver(school()).roster(1);

        expect(roster.map((s) => s.name), ['Ana Mora', 'EST033', 'Zoe Ruiz']);
      },
    );
  });

  group('notas', () {
    test(
      'las notas del estudiante llevan el nombre de la materia y se ordenan',
      () async {
        final grades = await repositoryOver(
          school(),
        ).gradesForStudent(7, period: 2);

        expect(grades.map((g) => g.subject), [
          'Ciencias',
          'Matemáticas',
          'Materia 99',
        ]);
        expect(grades.first.score, 4.2);
        expect(grades.first.period, 'Periodo 2');
      },
    );

    test('la planilla de una materia se mapea completa', () async {
      final sheet = await repositoryOver(
        school(),
      ).gradeSheet(subjectId: 11, period: 2);

      expect(sheet.single.score, 4.8);
      expect(sheet.single.subject, 'Matemáticas');
    });

    test('guardar sin id crea la nota con el payload del contrato', () async {
      await repositoryOver(school()).saveGrade(
        studentId: 7,
        subjectId: 11,
        period: 2,
        score: 4.5,
        registeredBy: 4,
        observation: 'Buen trabajo',
      );

      expect(writes.single.method, 'POST');
      expect(writes.single.data, {
        'id_estudiante': 7,
        'id_materia': 11,
        'id_periodo': 2,
        'nota': 4.5,
        'registrado_por': 4,
        'observacion': 'Buen trabajo',
      });
    });

    test('guardar con id actualiza y borrar elimina la misma nota', () async {
      final repository = repositoryOver(school());

      await repository.saveGrade(
        studentId: 7,
        subjectId: 11,
        period: 2,
        score: 3.9,
        registeredBy: 4,
        gradeId: 500,
      );
      await repository.deleteGrade(500);

      expect(writes.map((w) => '${w.method} ${w.path}'), [
        'PUT /notas/500',
        'DELETE /notas/500',
      ]);
      expect(writes.first.data, {'nota': 3.9});
    });
  });

  group('asistencia y novedades', () {
    test('el resumen de asistencia cuenta cada estado', () async {
      final repository = repositoryOver(school());

      final summary = await repository.attendanceSummary(7);
      final history = await repository.attendanceHistory(7);

      expect(history, hasLength(4));
      expect(summary.present, 2);
      expect(summary.absent, 1);
      expect(summary.late, 1);
    });

    test(
      'las novedades toman nombre y gravedad del catálogo de tipos',
      () async {
        final repository = repositoryOver(school());

        final all = await repository.novedades();
        final ofStudent = await repository.novedadesForStudent(7);

        final convivencia = all.firstWhere((n) => n.novedadId == 80);
        final sinTipo = all.firstWhere((n) => n.novedadId == 81);
        expect(convivencia.title, 'Convivencia');
        expect(convivencia.severity, NovedadSeverity.high);
        expect(sinTipo.title, 'Novedad');
        expect(sinTipo.status, NovedadStatus.done);
        // N-21: más reciente primero; con la misma fecha, el id mayor.
        expect(all.map((n) => n.novedadId), [81, 80]);
        expect(ofStudent.single.novedadId, 70);
      },
    );

    test(
      'crear, resolver y reabrir envían el estado que la API acepta',
      () async {
        final repository = repositoryOver(school());

        await repository.createNovedad(
          studentId: 7,
          typeId: 5,
          date: DateTime(2026, 10, 20),
          description: 'Llegó sin uniforme',
          registeredBy: 4,
        );
        await repository.resolveNovedad(80, action: 'Llamada al acudiente');
        await repository.reopenNovedad(80);

        expect(writes.map((w) => '${w.method} ${w.path}'), [
          'POST /novedades',
          'PUT /novedades/80',
          'PUT /novedades/80',
        ]);
        expect(writes[0].data, containsPair('fecha', '2026-10-20'));
        expect(writes[0].data, isNot(contains('accion_tomada')));
        expect(writes[1].data, containsPair('estado', 'Completado'));
        expect(
          writes[1].data,
          containsPair('accion_tomada', 'Llamada al acudiente'),
        );
        expect(writes[2].data, {'estado': 'Pendiente'});
      },
    );
  });

  group('catálogos', () {
    test('las materias activas listan los cursos donde se dictan', () async {
      final subjects = await repositoryOver(school()).subjects();

      expect(subjects.map((s) => s.name), [
        'Ciencias',
        'Español',
        'Matemáticas',
      ]);
      final math = subjects.last;
      expect(math.groups, '10A, 9B');
      expect(math.studentCount, 2);
      expect(subjects[1].groups, 'Sin cursos asignados');
    });

    test('cursos y tipos de novedad respetan el filtro de activos', () async {
      final repository = repositoryOver(school());

      expect((await repository.courses()).map((c) => c.name), ['10A', '9B']);
      expect(await repository.courses(onlyActive: false), hasLength(3));
      expect((await repository.novedadTypes()).map((t) => t.name), [
        'Convivencia',
      ]);
    });

    test(
      'si falla un catálogo los otros siguen y el nombre cae a un genérico',
      () async {
        final routes = school()..remove('/materias');

        final grades = await repositoryOver(routes).gradesForStudent(7);

        expect(
          grades.map((g) => g.subject),
          everyElement(startsWith('Materia ')),
        );
      },
    );

    test('el tablero del docente se lee del endpoint del rol', () async {
      final dashboard = await repositoryOver(school()).teacherDashboard();

      expect(dashboard.totalStudents, 64);
      expect(dashboard.attendanceToday, 30);
    });
  });
}

Map<String, dynamic> _block(
  int id, {
  required int course,
  required int subject,
  required String day,
  required String start,
  bool active = true,
}) => {
  'id_horario': id,
  'id_curso': course,
  'id_materia': subject,
  'dia': day,
  'salon': 'Salón 101',
  'hora_inicio': start,
  'hora_fin': start.replaceFirst(':00:', ':50:'),
  'activo': active,
};

Map<String, dynamic> _assignment(
  int id, {
  required int course,
  required int subject,
}) => {
  'id_asignacion': id,
  'id_profesor': 4,
  'id_curso': course,
  'id_materia': subject,
  'activo': true,
};

Map<String, dynamic> _student(
  int id, {
  required String code,
  String status = 'Activo',
  String? first,
  String? last,
}) => {
  'id_estudiante': id,
  'id_usuario': 100 + id,
  'codigo_estudiante': code,
  'estado': status,
  'id_curso_actual': 1,
  'primer_nombre': ?first,
  'primer_apellido': ?last,
};

Map<String, dynamic> _grade(
  int id, {
  required int subject,
  required num score,
}) => {
  'id_nota': id,
  'id_estudiante': 7,
  'id_materia': subject,
  'id_periodo': 2,
  'nota': score,
};

Map<String, dynamic> _attendance(int id, String state) => {
  'id_asistencia': id,
  'id_estudiante': 7,
  'fecha': '2026-10-0$id',
  'estado': state,
  'registrado_por': 4,
  'tipo': 'Entrada',
};

Map<String, dynamic> _novedad(
  int id, {
  required int type,
  String status = 'Pendiente',
}) => {
  'id_novedad': id,
  'id_estudiante': 7,
  'id_tipo_novedad': type,
  'descripcion': 'Descripción $id',
  'fecha': '2026-10-15',
  'estado': status,
};
