// CP-ACE-058 (observación): el padre veía la nota vieja hasta recargar a mano.
// Al cambiar de pestaña con conexión, las pantallas de datos vuelven a
// consultar la API sin perder lo que ya mostraban.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eyes_school/core/domain/repositories.dart';
import 'package:eyes_school/features/academic/domain/grade.dart';
import 'package:eyes_school/features/attendance/domain/attendance.dart';
import 'package:eyes_school/features/auth/domain/app_user.dart';
import 'package:eyes_school/features/auth/domain/session.dart';
import 'package:eyes_school/features/directory/domain/role.dart';
import 'package:eyes_school/providers/data_providers.dart';
import 'package:eyes_school/providers/repository_providers.dart';
import 'package:eyes_school/providers/session_provider.dart';

/// Counts every call by member name. Anything but the grades never answers:
/// the test is about *whether* each screen asks again, not the data.
class _Counting {
  final calls = <String, int>{};

  Future<T> hit<T>(String name) {
    calls[name] = (calls[name] ?? 0) + 1;
    // Never completes: only the call matters here, not its data.
    return Completer<T>().future;
  }
}

class _Academic implements AcademicRepository {
  _Academic(this.c);
  final _Counting c;

  @override
  Future<List<Grade>> gradesForStudent(
    int studentId, {
    int? period,
    int? subjectId,
  }) async {
    c.calls['grades'] = (c.calls['grades'] ?? 0) + 1;
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString().split('"')[1];
    return c.hit<dynamic>(name);
  }
}

class _Attendance implements AttendanceRepository {
  _Attendance(this.c);
  final _Counting c;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString().split('"')[1];
    return c.hit<dynamic>(name);
  }
}

void main() {
  test('el pulso de recarga vuelve a pedir las notas', () async {
    final c = _Counting();
    final container = ProviderContainer(
      overrides: [academicRepositoryProvider.overrideWithValue(_Academic(c))],
    );
    addTearDown(container.dispose);
    const args = (studentId: 2, period: 1);
    final sub = container.listen(gradesForStudentProvider(args), (_, _) {});
    addTearDown(sub.close);

    await container.read(gradesForStudentProvider(args).future);
    expect(c.calls['grades'], 1);

    // Leer otra vez sin el pulso no vuelve a la API (caché de la pantalla).
    await container.read(gradesForStudentProvider(args).future);
    expect(c.calls['grades'], 1);

    container.read(dataRefreshProvider.notifier).state++;
    await container.read(gradesForStudentProvider(args).future);
    expect(c.calls['grades'], 2);
  });

  test('cada pantalla de datos en vivo escucha el pulso', () async {
    final c = _Counting();
    final container = ProviderContainer(
      overrides: [
        academicRepositoryProvider.overrideWithValue(_Academic(c)),
        attendanceRepositoryProvider.overrideWithValue(_Attendance(c)),
        currentSessionProvider.overrideWithValue(
          const AppSession(
            user: AppUser(
              userId: 1,
              name: 'Prueba',
              email: 'p@example.com',
              role: Role.parent,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final providers = <ProviderListenable<AsyncValue<Object?>>>[
      studentDashboardProvider,
      parentDashboardProvider,
      teacherDashboardProvider,
      attendanceSummaryProvider(2),
      novedadesForStudentProvider(2),
      todayAttendanceProvider(AttendanceKind.entry),
      teacherNovedadesProvider(null),
      adminNovedadesProvider,
    ];
    final subs = [for (final p in providers) container.listen(p, (_, _) {})];
    addTearDown(() {
      for (final s in subs) {
        s.close();
      }
    });

    Future<void> settle() => Future<void>.delayed(Duration.zero);
    await settle();
    final before = Map.of(c.calls);
    expect(
      before.keys,
      containsAll(<String>[
        'studentDashboard',
        'guardianDashboard',
        'teacherDashboard',
        'attendanceSummary',
        'novedadesForStudent',
        'registeredOn',
        'novedades',
      ]),
    );

    container.read(dataRefreshProvider.notifier).state++;
    await settle();

    // Cada pantalla vuelve a pedir lo suyo exactamente una vez.
    for (final name in before.keys) {
      expect(c.calls[name], before[name]! * 2, reason: name);
    }
  });
}
