import 'package:eyes_school/domain/entities/attendance_record.dart';
import 'package:eyes_school/domain/entities/class_session.dart';
import 'package:eyes_school/domain/failures/app_failure.dart';
import 'package:eyes_school/domain/repositories/repositories.dart';
import 'package:eyes_school/domain/usecases/usecases.dart';
import 'package:eyes_school/domain/value_objects/attendance.dart';
import 'package:eyes_school/domain/value_objects/class_time.dart';
import 'package:flutter_test/flutter_test.dart';

/// The application rules, tested without a widget, a plugin or a socket —
/// which is the practical payoff of keeping them out of the screens.
void main() {
  group('SaveGradeSheet', () {
    test('rechaza el lote completo si una nota está fuera de 0.0–5.0', () async {
      final academic = _FakeAcademicRepository();
      final useCase = SaveGradeSheet(academic);

      await expectLater(
        useCase.call(
          entries: const [
            GradeEntry(studentId: 1, score: 4.0),
            GradeEntry(studentId: 2, score: 7.5),
          ],
          subjectId: 3,
          period: 2,
          registeredBy: 9,
        ),
        throwsA(isA<ValidationFailure>()),
      );

      // Nada se guardó: media planilla escrita es peor que una rechazada.
      expect(academic.saved, isEmpty);
    });

    test('crea la nota nueva y actualiza la que ya tenía id', () async {
      final academic = _FakeAcademicRepository();
      final useCase = SaveGradeSheet(academic);

      final result = await useCase.call(
        entries: const [
          GradeEntry(studentId: 1, score: 4.0),
          GradeEntry(studentId: 2, score: 3.5, gradeId: 77),
        ],
        subjectId: 3,
        period: 2,
        registeredBy: 9,
      );

      expect(result.saved, 2);
      expect(academic.saved, hasLength(2));
      expect(academic.saved.first.gradeId, isNull);
      expect(academic.saved.last.gradeId, 77);
    });
  });

  group('RegisterScan', () {
    test('un código desconocido no registra nada', () async {
      final attendance = _FakeAttendanceRepository();
      final useCase = RegisterScan(attendance);

      final result = await useCase.resolve('NO-EXISTE');

      expect(result, isA<ScanUnknownCode>());
      expect(attendance.recorded, isEmpty);
    });

    test('un estudiante inactivo se detiene antes de escribir', () async {
      final attendance = _FakeAttendanceRepository(
        students: {'EST002': _identity('EST002', status: 'Retirado')},
      );
      final useCase = RegisterScan(attendance);

      final result = await useCase.resolve('EST002');

      expect(result, isA<ScanInactiveStudent>());
      expect(attendance.recorded, isEmpty);
    });

    test('un escaneo válido llega a la cola con el nombre del estudiante',
        () async {
      final attendance = _FakeAttendanceRepository(
        students: {'EST001': _identity('EST001', first: 'Ana', last: 'Gómez')},
      );
      final useCase = RegisterScan(attendance);

      final result = await useCase.resolve('EST001');
      expect(result, isA<ScanResolved>());

      final queued = await useCase.confirm(
        student: (result as ScanResolved).student,
        state: result.suggested,
        kind: AttendanceKind.entry,
        registeredBy: 7,
        qrCode: 'EST001',
      );

      expect(queued, isTrue);
      expect(attendance.recorded.single, 'Ana Gómez');
    });
  });

  group('TodaysClasses y NextClass', () {
    ClassSession block(String day, int hour) => ClassSession(
          subject: 'Matemáticas',
          group: '10-A',
          room: 'Aula 1',
          status: ClassStatus.upcoming,
          day: day,
          start: ClassTime(hour, 0),
          end: ClassTime(hour + 1, 0),
        );

    test('solo devuelve los bloques del día, con su estado real', () {
      // Un lunes a las 09:30.
      final monday = DateTime(2026, 9, 7, 9, 30);
      final weekly = [block('Lunes', 7), block('Lunes', 9), block('Martes', 7)];

      final today = const TodaysClasses().call(weekly, now: monday);

      expect(today, hasLength(2));
      expect(today.first.status, ClassStatus.done);
      expect(today.last.status, ClassStatus.inCourse);
    });

    test('la próxima clase es la primera que aún no terminó', () {
      final monday = DateTime(2026, 9, 7, 9, 30);
      final today = const TodaysClasses()
          .call([block('Lunes', 7), block('Lunes', 9), block('Lunes', 11)],
              now: monday);

      expect(const NextClass().call(today)?.time, '09:00');
    });

    test('terminada la jornada, se muestra el último bloque en vez de nada', () {
      final evening = DateTime(2026, 9, 7, 20, 0);
      final today = const TodaysClasses()
          .call([block('Lunes', 7), block('Lunes', 9)], now: evening);

      expect(const NextClass().call(today)?.time, '09:00');
    });

    test('sin clases hoy devuelve null, no una excepción', () {
      expect(const NextClass().call(const []), isNull);
    });
  });

  group('RestoreSession', () {
    test('sin tokens guardados no intenta nada', () async {
      final auth = _FakeAuthRepository(hasSession: false);

      expect(await RestoreSession(auth).call(), isNull);
      expect(auth.restoreCalls, 0);
    });

    test('una sesión guardada inservible termina en "sin sesión", no en error',
        () async {
      final auth = _FakeAuthRepository(failRestore: true);

      expect(await RestoreSession(auth).call(), isNull);
      expect(auth.signedOut, isTrue);
    });
  });
}

StudentIdentity _identity(
  String code, {
  String status = 'Activo',
  String? first,
  String? last,
}) {
  return StudentIdentity(
    studentId: 41,
    userId: 88,
    code: code,
    status: status,
    firstName: first,
    lastName: last,
  );
}

class _SavedGrade {
  const _SavedGrade(this.studentId, this.gradeId);

  final int studentId;
  final int? gradeId;
}

class _FakeAcademicRepository implements AcademicRepository {
  final List<_SavedGrade> saved = [];

  @override
  Future<void> saveGrade({
    required int studentId,
    required int subjectId,
    required int period,
    required double score,
    required int registeredBy,
    int? gradeId,
    String? observation,
  }) async {
    saved.add(_SavedGrade(studentId, gradeId));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeAttendanceRepository implements AttendanceRepository {
  _FakeAttendanceRepository({this.students = const {}});

  final Map<String, StudentIdentity> students;
  final List<String> recorded = [];

  @override
  Future<ScanResult> resolve(
    String rawCode,
    {AttendanceKind? kind, DateTime? now}
  ) async {
    final student = students[rawCode.trim()];
    if (student == null) return ScanUnknownCode(rawCode);
    if (!student.active) return ScanInactiveStudent(student);
    return ScanResolved(student, AttendanceState.present);
  }

  @override
  Future<bool> record({
    required int studentId,
    required String studentName,
    required AttendanceState state,
    required AttendanceKind kind,
    required int registeredBy,
    DateTime? date,
    String? qrCode,
    String? observation,
  }) async {
    recorded.add(studentName);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.hasSession = true, this.failRestore = false});

  final bool hasSession;
  final bool failRestore;
  int restoreCalls = 0;
  bool signedOut = false;

  @override
  Future<bool> hasStoredSession() async => hasSession;

  @override
  Future<Never> restoreSession() async {
    restoreCalls++;
    throw const UnauthorizedFailure();
  }

  @override
  Future<void> signOut() async => signedOut = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
