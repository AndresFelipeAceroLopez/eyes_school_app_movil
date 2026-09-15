import 'package:eyes_school/core/utils/json_x.dart';
import 'package:eyes_school/features/academic/data/academic_dto.dart';
import 'package:eyes_school/features/attendance/data/attendance_dto.dart';
import 'package:eyes_school/features/novedades/data/novedad_dto.dart';
import 'package:eyes_school/features/directory/data/people_dto.dart';
import 'package:eyes_school/features/directory/domain/catalog.dart';
import 'package:eyes_school/features/academic/domain/grade.dart';
import 'package:eyes_school/features/directory/domain/role.dart';
import 'package:eyes_school/features/attendance/domain/attendance.dart';
import 'package:eyes_school/features/academic/domain/class_time.dart';
import 'package:eyes_school/features/novedades/domain/severity.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the boundary between the wire and the domain: the accented
/// `Suspensión`, `Miercoles` without one, `hora_inicio` as a bare time, and
/// `nota` arriving as either an int or a double.
void main() {
  group('AttendanceState', () {
    test('conserva la tilde y la mayúscula que exige la API', () {
      expect(AttendanceState.suspended.label, 'Suspensión');
      expect(AttendanceState.present.label, 'Presente');
    });

    test('lee "Suspensión" venga con tilde o sin ella', () {
      expect(AttendanceState.parse('Suspensión'), AttendanceState.suspended);
      expect(AttendanceState.parse('Suspension'), AttendanceState.suspended);
      expect(AttendanceState.parse('suspensión'), AttendanceState.suspended);
    });

    test('un estado desconocido no rompe la pantalla', () {
      expect(AttendanceState.parse('Vacaciones'), AttendanceState.present);
      expect(AttendanceState.parse(null), AttendanceState.present);
    });

    test('llegar tarde cuenta como asistencia; la excusa no', () {
      expect(AttendanceState.present.countsAsAttendance, isTrue);
      expect(AttendanceState.late.countsAsAttendance, isTrue);
      expect(AttendanceState.excused.countsAsAttendance, isFalse);
      expect(AttendanceState.absent.countsAsAttendance, isFalse);
    });
  });

  group('AsistenciaCreate', () {
    test('serializa la fecha como yyyy-MM-dd, no como ISO datetime', () {
      final json = AttendanceMapper.createPayload(
        studentId: 12,
        date: DateTime(2026, 9, 6, 14, 30),
        state: AttendanceState.late,
        registeredBy: 3,
        kind: AttendanceKind.entry,
      );

      expect(json['fecha'], '2026-09-06');
      expect(json['estado'], 'Tarde');
      expect(json['tipo'], 'entrada');
      expect(json['registrado_por'], 3);
    });

    test('omite la observación vacía en lugar de mandar cadena vacía', () {
      final json = AttendanceMapper.createPayload(
        studentId: 1,
        date: DateTime(2026, 1, 5),
        state: AttendanceState.present,
        registeredBy: 1,
        observation: '',
      );

      expect(json.containsKey('observacion'), isFalse);
    });
  });

  group('HorarioOut', () {
    test('parsea "07:00:00" a ClassTime: no es un datetime ISO', () {
      final block = ScheduleBlockDto.fromJson(const {
        'id_horario': 1,
        'id_curso': 2,
        'id_materia': 3,
        'dia': 'Miercoles',
        'hora_inicio': '07:00:00',
        'hora_fin': '08:30:00',
        'salon': 'Aula 204',
        'activo': true,
      });

      expect(block.start, const ClassTime(7, 0));
      expect(block.end, const ClassTime(8, 30));
      expect(block.start!.formatted, '07:00');
      // La API escribe el día sin tilde; el dominio lo normaliza al mostrar.
      expect(block.day, 'Miercoles');
    });

    test('una hora ilegible deja el bloque sin hora en vez de reventar', () {
      final block = ScheduleBlockDto.fromJson(const {
        'id_horario': 1,
        'id_curso': 2,
        'id_materia': 3,
        'dia': 'Lunes',
        'hora_inicio': '',
        'salon': 'Aula 1',
        'activo': true,
      });

      expect(block.start, isNull);
    });
  });

  group('NotaOut', () {
    Grade grade(Object nota) => GradeMapper.fromJson({
          'id_nota': 1,
          'id_estudiante': 1,
          'id_materia': 1,
          'id_periodo': 2,
          'nota': nota,
          'registrado_por': 9,
        }, (_) => 'Matemáticas');

    test('acepta la nota como entero o como decimal', () {
      expect(grade(4).score, 4.0);
      expect(grade(4.5).score, 4.5);
    });

    test('etiqueta el periodo con el nombre institucional', () {
      expect(grade(4).period, 'Periodo 2');
    });
  });

  group('CursoOut.jornada', () {
    Course course(String jornada) => CourseMapper.fromJson({
          'id_curso': 1,
          'nombre_curso': '10-A',
          'grado': '10',
          'jornada': jornada,
          'ano': 2026,
          'activo': true,
        });

    test('normaliza las variantes que acepta la API', () {
      expect(course('mañana').shiftLabel, 'Mañana');
      expect(course('manana').shiftLabel, 'Mañana');
      expect(course('1').shiftLabel, 'Mañana');
      expect(course('tarde').shiftLabel, 'Tarde');
      expect(course('unica').shiftLabel, 'Única');
    });
  });

  group('EstudianteOut', () {
    test('el ida y vuelta por el caché conserva lo que resuelve un escaneo', () {
      final original = EstudianteDto.fromJson(const {
        'id_estudiante': 41,
        'id_usuario': 88,
        'codigo_estudiante': 'EST001',
        'fecha_ingreso': '2024-02-01',
        'estado': 'Activo',
        'id_curso_actual': 7,
        'fecha_registro': '2024-02-01T10:00:00',
        'primer_nombre': 'Ana',
        'primer_apellido': 'Gómez',
      }).toIdentity();

      final restored =
          StudentIdentityMapper.fromJson(StudentIdentityMapper.toJson(original));

      expect(restored.studentId, 41);
      expect(restored.code, 'EST001');
      expect(restored.courseId, 7);
      expect(restored.fullName, 'Ana Gómez');
      expect(restored.active, isTrue);
    });

    test('sin nombres, el carné cae al código en vez de quedar vacío', () {
      final student = EstudianteDto.fromJson(const {
        'id_estudiante': 1,
        'id_usuario': 1,
        'codigo_estudiante': 'EST002',
        'fecha_ingreso': '2024-02-01',
        'estado': 'Activo',
        'fecha_registro': '2024-02-01T10:00:00',
      }).toIdentity();

      expect(student.fullName, '');
      expect(student.displayName, 'EST002');
    });
  });

  group('NovedadSeverity', () {
    test('reconoce "Crítico" con y sin tilde', () {
      expect(NovedadSeverity.parse('Crítico'), NovedadSeverity.critical);
      expect(NovedadSeverity.parse('Critico'), NovedadSeverity.critical);
      expect(NovedadSeverity.parse('Alto'), NovedadSeverity.high);
    });

    test('la gravedad la define el tipo, no la novedad', () {
      final type = NovedadTypeMapper.fromJson(const {
        'id_tipo_novedad': 3,
        'nombre_tipo': 'Agresión',
        'nivel_gravedad': 'Crítico',
        'requiere_accion': true,
        'activo': true,
      });

      final novedad = NovedadMapper.fromJson(
        const {
          'id_novedad': 9,
          'id_estudiante': 41,
          'id_tipo_novedad': 3,
          'fecha': '2026-09-06',
          'descripcion': 'Incidente en el patio',
          'registrado_por': 1,
          'estado': 'Pendiente',
        },
        typeName: (_) => type.name,
        severityOf: (_) => type.severity,
      );

      expect(novedad.title, 'Agresión');
      expect(novedad.severity, NovedadSeverity.critical);
      expect(novedad.resolved, isFalse);
    });
  });

  group('Rol', () {
    test('los id_rol de la API mapean al shell correcto', () {
      expect(roleFromApiId(1), Role.teacher);
      expect(roleFromApiId(2), Role.student);
      expect(roleFromApiId(3), Role.admin);
      expect(roleFromApiId(4), Role.parent);
    });

    test('un rol desconocido cae en el shell más restringido', () {
      expect(roleFromApiId(99), Role.student);
    });
  });

  group('Escala de notas', () {
    test('la barra de progreso usa 0.0–5.0, no 0–10', () {
      const perfect = Grade(subject: 'Matemáticas', score: 5, period: 'Periodo 1');
      const passing = Grade(subject: 'Matemáticas', score: 3, period: 'Periodo 1');
      const failing = Grade(subject: 'Matemáticas', score: 2.5, period: 'Periodo 1');

      expect(perfect.progress, 1.0);
      expect(passing.progress, closeTo(0.6, 0.001));
      expect(passing.passing, isTrue);
      expect(failing.passing, isFalse);
      expect(GradeScale.isValid(5.1), isFalse);
    });

    test('el promedio agrupa por materia antes de promediar', () {
      const grades = [
        Grade(subject: 'Matemáticas', score: 3, period: 'Periodo 1'),
        Grade(subject: 'Matemáticas', score: 5, period: 'Periodo 1'),
        Grade(subject: 'Historia', score: 2, period: 'Periodo 1'),
      ];

      // Matemáticas promedia 4.0; con Historia en 2.0 el general es 3.0.
      // Sin agrupar daría 3.33, que sobrevalora la materia con más notas.
      expect(Grade.overallAverage(grades), closeTo(3.0, 0.001));
    });
  });

  group('Lecturas defensivas', () {
    test('un campo nulo o de otro tipo no tumba el parseo', () {
      expect(asInt(null), 0);
      expect(asInt('12'), 12);
      expect(asDouble('4.5'), 4.5);
      expect(asBool('true'), isTrue);
      expect(asStringOrNull('   '), isNull);
      expect(asDate('no es fecha'), isNull);
      expect(toApiDate(DateTime(2026, 1, 5)), '2026-01-05');
    });
  });
}
