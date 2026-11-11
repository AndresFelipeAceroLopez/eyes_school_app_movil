// IT-APP-07 · Contrato grabado contra la API real (PR-05).
//
// Cada archivo de test/fixtures/api/ es una respuesta REAL de la API de QA,
// grabada con `dart run tool/grabar_contrato.dart`. Aquí se pasa por el mismo
// mapeador que usa la app y se comprueba que no lanza excepción y que los
// campos obligatorios de la entidad tienen valor.
//
// Si la API cambia un campo, `git diff test/fixtures/api/` muestra el cambio y
// esta prueba se pone en rojo, en lugar de dejar una pantalla vacía.
import 'dart:convert';
import 'dart:io';

import 'package:eyes_school/features/academic/data/academic_dto.dart';
import 'package:eyes_school/features/attendance/data/attendance_dto.dart';
import 'package:eyes_school/features/attendance/domain/attendance.dart';
import 'package:eyes_school/features/auth/data/auth_dto.dart';
import 'package:eyes_school/features/dashboard/data/dashboard_dto.dart';
import 'package:eyes_school/features/directory/data/people_dto.dart';
import 'package:eyes_school/features/novedades/data/novedad_dto.dart';
import 'package:eyes_school/features/novedades/domain/severity.dart';
import 'package:eyes_school/features/reports/data/reporte_dto.dart';
import 'package:flutter_test/flutter_test.dart';

Object? _fixture(String name) {
  final file = File('test/fixtures/api/$name.json');
  expect(
    file.existsSync(),
    isTrue,
    reason: 'Falta $name.json: correr tool/grabar_contrato.dart',
  );
  return jsonDecode(file.readAsStringSync());
}

List<Map<String, dynamic>> _list(String name) {
  final body = _fixture(name);
  expect(body, isA<List>(), reason: '$name debe ser una lista');
  return (body as List).cast<Map<String, dynamic>>();
}

Map<String, dynamic> _object(String name) {
  final body = _fixture(name);
  expect(body, isA<Map>(), reason: '$name debe ser un objeto');
  return body as Map<String, dynamic>;
}

void main() {
  group('Contrato grabado · autenticación y personas', () {
    for (final rol in ['estudiante', 'docente', 'admin', 'padre']) {
      test('/auth/me ($rol) → MeDto', () {
        final me = MeDto.fromJson(_object('auth_me_$rol'));
        expect(me.idUsuario, greaterThan(0));
        expect(me.primerNombre, isNotEmpty);
        expect(me.idRol, inInclusiveRange(1, 4));
        expect(me.correo, isNotNull);
      });
    }

    test('/estudiantes/me → EstudianteDto', () {
      final e = EstudianteDto.fromJson(_object('estudiantes_me'));
      expect(e.idEstudiante, greaterThan(0));
      expect(e.codigoEstudiante, isNotEmpty);
      expect(e.idCursoActual, isNotNull);
    });

    test('/padres/me → PadreDto', () {
      final p = PadreDto.fromJson(_object('padres_me'));
      expect(p.idEstudiante, greaterThan(0));
      expect(p.parentesco, isNotEmpty);
      expect(p.nombreEstudiante, isNotNull);
    });
  });

  group('Contrato grabado · académico', () {
    test('/cursos → Course', () {
      final rows = _list('cursos');
      expect(rows, isNotEmpty);
      for (final c in rows.map(CourseMapper.fromJson)) {
        expect(c.id, greaterThan(0));
        expect(c.name, isNotEmpty);
      }
    });

    test('/materias → CourseSubject', () {
      for (final s in _list('materias').map(SubjectMapper.fromJson)) {
        expect(s.id, greaterThan(0));
        expect(s.name, isNotEmpty);
      }
    });

    test('/estudiantes/{id}/notas → Grade (0.0–5.0)', () {
      final rows = _list('estudiantes_id_notas');
      expect(rows, isNotEmpty);
      for (final g in rows.map(
        (j) => GradeMapper.fromJson(j, (id) => 'Materia $id'),
      )) {
        expect(g.score, inInclusiveRange(0.0, 5.0));
        expect(g.subjectId, isNotNull);
        expect(g.periodId, isNotNull);
      }
    });

    test('/cursos/{id}/horarios → ScheduleBlockDto con horas', () {
      final rows = _list('cursos_id_horarios');
      expect(rows, isNotEmpty);
      for (final b in rows.map(ScheduleBlockDto.fromJson)) {
        expect(b.day, isNotEmpty);
        expect(b.start, isNotNull);
        expect(b.end, isNotNull);
      }
    });

    test('/asignaciones?id_profesor= → AssignmentDto', () {
      final rows = _list('asignaciones_docente');
      expect(rows, isNotEmpty);
      for (final a in rows.map(AssignmentDto.fromJson)) {
        expect(a.courseId, greaterThan(0));
        expect(a.subjectId, greaterThan(0));
      }
    });
  });

  group('Contrato grabado · asistencia', () {
    for (final name in ['estudiantes_id_asistencia', 'asistencia_fecha']) {
      test('$name → AttendanceRecord', () {
        for (final r in _list(name).map(AttendanceMapper.fromJson)) {
          expect(r.id, greaterThan(0));
          expect(r.studentId, greaterThan(0));
        }
      });

      // Los registros heredados de QA traen `tipo` «QR» o «Manual» (cómo se
      // tomó, no entrada/salida). La API ya no los acepta al crear, pero los
      // sigue devolviendo: es un pendiente de datos del backend (N-07). Lo
      // que la app debe garantizar es no inventar una «Entrada» con ellos.
      test('$name · un «tipo» desconocido no se muestra como entrada', () {
        final known = AttendanceKind.values.map((k) => k.wire).toSet();
        for (final json in _list(name)) {
          final tipo = (json['tipo'] as String?)?.toLowerCase().trim();
          final record = AttendanceMapper.fromJson(json);
          if (tipo == null || !known.contains(tipo)) {
            expect(record.kind, isNull, reason: 'tipo «${json['tipo']}»');
          } else {
            expect(record.kind?.wire, tipo);
          }
        }
      });
    }
  });

  group('Contrato grabado · novedades y reportes', () {
    test('/tipos-novedad → NovedadType', () {
      final rows = _list('tipos_novedad');
      expect(rows, isNotEmpty);
      for (final t in rows.map(NovedadTypeMapper.fromJson)) {
        expect(t.id, greaterThan(0));
        expect(t.name, isNotEmpty);
      }
    });

    for (final name in ['novedades', 'estudiantes_id_novedades']) {
      test('$name → Novedad', () {
        for (final n in _list(name).map(
          (j) => NovedadMapper.fromJson(
            j,
            typeName: (id) => 'Tipo $id',
            severityOf: (_) => NovedadSeverity.values.first,
          ),
        )) {
          expect(n.novedadId, isNotNull);
          expect(n.studentId, isNotNull);
          expect(n.date, isNotNull);
        }
      });
    }

    test('/reportes → Report', () {
      for (final r in _list('reportes').map(ReportMapper.fromJson)) {
        expect(r.id, greaterThan(0));
        expect(r.type, isNotEmpty);
        expect(r.status, isNotEmpty);
      }
    });
  });

  group('Contrato grabado · tableros', () {
    test('/dashboard/docente → TeacherDashboard', () {
      final d = DashboardMapper.teacher(_object('dashboard_docente'));
      expect(d.assignedCourses, greaterThanOrEqualTo(0));
    });

    test('/dashboard/estudiante → StudentDashboard (porcentaje 0–100)', () {
      final d = DashboardMapper.student(_object('dashboard_estudiante'));
      expect(d.attendancePercent, isNotNull);
      expect(d.attendancePercent, inInclusiveRange(0, 100));
    });

    test('/dashboard/padre → GuardianDashboard (porcentaje 0–100)', () {
      final d = DashboardMapper.guardian(_object('dashboard_padre'));
      expect(d.studentId, isNotNull);
      expect(d.attendancePercent, inInclusiveRange(0, 100));
    });
  });
}
