// Comportamiento del dominio que tocaron las correcciones de QA (S2).
import 'package:eyes_school/features/academic/domain/teacher_class.dart';
import 'package:eyes_school/features/attendance/domain/attendance.dart';
import 'package:eyes_school/features/auth/domain/app_user.dart';
import 'package:eyes_school/features/auth/domain/session.dart';
import 'package:eyes_school/features/dashboard/domain/dashboard.dart';
import 'package:eyes_school/features/directory/domain/linked_child.dart';
import 'package:eyes_school/features/directory/domain/role.dart';
import 'package:eyes_school/features/novedades/domain/novedad.dart';
import 'package:eyes_school/features/novedades/domain/severity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cada rol tiene su etiqueta, su ruta de inicio y su id de la API', () {
    expect(Role.values.map((r) => r.label), [
      'Docente',
      'Estudiante',
      'Padre / Acudiente',
      'Administrador',
    ]);
    expect(Role.values.map((r) => r.homePath), [
      '/teacher',
      '/student',
      '/parent',
      '/admin',
    ]);
    expect(Role.values.map((r) => r.apiId), [1, 2, 4, 3]);
  });

  test('N-22 · un reporte «Generado» o «Completado» está listo', () {
    Report report(String status) =>
        Report(id: 1, type: 'Notas', status: status, hasFile: true);
    expect(report('Generado').isReady, isTrue);
    expect(report('Completado').isReady, isTrue);
    expect(report(' generado ').isReady, isTrue);
    expect(report('Pendiente').isReady, isFalse);
    expect(report('Error').isFailed, isTrue);
  });

  test('la marca de asistencia corresponde a su estado', () {
    expect(AttendanceMark.values.map((m) => m.state), [
      AttendanceState.present,
      AttendanceState.late,
      AttendanceState.absent,
      AttendanceState.excused,
    ]);
    expect(AttendanceMark.late.label, AttendanceState.late.label);
  });

  test(
    'withStudentName y withStudentCount conservan el resto de los datos',
    () {
      final novedad = Novedad(
        studentName: 'Estudiante 7',
        title: 'Convivencia',
        severity: NovedadSeverity.high,
        novedadId: 80,
        studentId: 7,
        typeId: 5,
        description: 'Llegó tarde',
        date: DateTime(2026, 11, 10),
        status: NovedadStatus.done,
      );
      final named = novedad.withStudentName('Ana Mora');
      expect(named.studentName, 'Ana Mora');
      expect(
        [named.novedadId, named.typeId, named.description],
        [80, 5, 'Llegó tarde'],
      );
      expect(named.resolved, isTrue);

      const clase = TeacherClass(
        assignmentId: 1,
        courseId: 2,
        subjectId: 3,
        courseName: 'Sexto A',
        subjectName: 'Matemáticas',
        active: true,
        shift: 'Mañana',
      );
      final counted = clase.withStudentCount(12);
      expect(counted.studentCount, 12);
      expect(
        [counted.courseName, counted.subjectName, counted.shift],
        ['Sexto A', 'Matemáticas', 'Mañana'],
      );
    },
  );

  group('APP-03 · hijo activo de la sesión', () {
    const user = AppUser(
      userId: 4,
      name: 'Rosa Pérez',
      email: 'r@x.co',
      role: Role.parent,
    );
    const sofia = LinkedChild(
      id: 1,
      name: 'Sofía',
      document: '1',
      relationship: 'Madre',
      courseId: 1,
    );
    const santiago = LinkedChild(
      id: 3,
      name: 'Santiago',
      relationship: 'Abuela',
      courseId: 2,
    );
    final session = const AppSession(
      user: user,
      children: [sofia, santiago],
      currentPeriod: 1,
    ).withActiveChild(1);

    test('el primer hijo queda activo con sus datos', () {
      expect(session.hasSeveralChildren, isTrue);
      expect(session.childId, 1);
      expect(session.activeChild?.name, 'Sofía');
      expect(session.subjectStudentId, 1);
      expect(session.courseId, 1);
    });

    test('cambiar de hijo cambia todos los datos del hijo activo', () {
      final other = session.withActiveChild(3);
      expect(other.childId, 3);
      expect(other.childName, 'Santiago');
      expect(other.relationship, 'Abuela');
      expect(other.courseId, 2);
      expect(other.currentPeriod, 1);
      expect(other.copyWith(currentPeriod: 2).children, hasLength(2));
    });

    test('un id que no es de sus hijos deja la sesión igual', () {
      expect(identical(session.withActiveChild(99), session), isTrue);
    });
  });
}
