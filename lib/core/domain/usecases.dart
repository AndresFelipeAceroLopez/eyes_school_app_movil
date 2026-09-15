import 'package:eyes_school/features/attendance/domain/attendance_record.dart';
import 'package:eyes_school/features/academic/domain/class_session.dart';
import 'package:eyes_school/features/auth/domain/session.dart';
import 'package:eyes_school/core/errors/app_failure.dart';
import 'package:eyes_school/core/domain/repositories.dart';
import 'package:eyes_school/features/attendance/domain/attendance.dart';
import 'package:eyes_school/features/novedades/domain/severity.dart';

/// Application business rules.
///
/// Only the operations that carry a *decision* live here. A use case per CRUD
/// call would be ceremony: `getCursos()` decides nothing, and wrapping it adds
/// a file without adding a rule. What follows are the rules that would
/// otherwise be scattered across widgets, where they cannot be tested.

/// Signing in, and the invariant that a background concern must never cost
/// the user their session.
class SignIn {
  const SignIn(this._auth);

  final AuthRepository _auth;

  Future<AppSession> call({required String email, required String password}) {
    if (email.trim().isEmpty) {
      throw const ValidationFailure('Ingresa tu correo.', {'correo': 'Requerido'});
    }
    if (password.isEmpty) {
      throw const ValidationFailure('Ingresa tu contraseña.', {'password': 'Requerido'});
    }
    return _auth.signIn(email: email, password: password);
  }
}

/// Cold start: a stored session is restored, and anything unrecoverable ends
/// as "signed out" rather than as an error the user cannot act on.
class RestoreSession {
  const RestoreSession(this._auth);

  final AuthRepository _auth;

  Future<AppSession?> call() async {
    if (!await _auth.hasStoredSession()) return null;
    try {
      return await _auth.restoreSession();
    } on AppFailure {
      // A bad or expired stored session is not an app error: it is a login.
      await _auth.signOut();
      return null;
    }
  }
}

/// Turning a scanned QR into an attendance record.
///
/// The whole rule lives here: resolve the code locally (the API cannot look up
/// by code), refuse an inactive student, suggest `Tarde` past the cutoff, and
/// hand the write to the queue so it survives with no signal.
class RegisterScan {
  const RegisterScan(this._attendance);

  final AttendanceRepository _attendance;

  Future<ScanResult> resolve(String rawCode, {AttendanceKind? kind}) =>
      _attendance.resolve(rawCode, kind: kind);

  Future<bool> confirm({
    required StudentIdentity student,
    required AttendanceState state,
    required AttendanceKind kind,
    required int registeredBy,
    String? qrCode,
    String? observation,
  }) {
    return _attendance.record(
      studentId: student.studentId,
      studentName: student.displayName,
      state: state,
      kind: kind,
      registeredBy: registeredBy,
      qrCode: qrCode,
      observation: observation,
    );
  }
}

/// Roll call and bulk registration: one course, one date, one kind.
class RegisterCourseAttendance {
  const RegisterCourseAttendance(this._attendance);

  final AttendanceRepository _attendance;

  Future<BulkAttendanceResult> call({
    required Map<int, AttendanceMark> marks,
    required Map<int, String> names,
    required AttendanceKind kind,
    required int registeredBy,
    required DateTime date,
    Map<int, String>? observations,
    void Function(int done, int total)? onProgress,
  }) {
    if (marks.isEmpty) {
      return Future.value(const BulkAttendanceResult(queued: 0, duplicates: 0));
    }
    return _attendance.recordBulk(
      marks: marks,
      names: names,
      kind: kind,
      registeredBy: registeredBy,
      date: date,
      observations: observations,
      onProgress: onProgress,
    );
  }
}

/// Saving a grade sheet.
///
/// Two rules the UI must not own: a score outside 0.0–5.0 is rejected before
/// anything is written, and a row that already has an id is an update, not a
/// second grade.
class SaveGradeSheet {
  const SaveGradeSheet(this._academic);

  final AcademicRepository _academic;

  Future<GradeSheetResult> call({
    required List<GradeEntry> entries,
    required int subjectId,
    required int period,
    required int registeredBy,
  }) async {
    final invalid = entries.where((e) => !GradeScale.isValid(e.score)).toList();
    if (invalid.isNotEmpty) {
      throw ValidationFailure(
        'Las notas deben estar entre 0.0 y ${GradeScale.max.toStringAsFixed(1)}.',
        {for (final e in invalid) '${e.studentId}': 'Fuera de la escala'},
      );
    }

    var saved = 0;
    for (final entry in entries) {
      await _academic.saveGrade(
        studentId: entry.studentId,
        subjectId: subjectId,
        period: period,
        score: entry.score,
        registeredBy: registeredBy,
        gradeId: entry.gradeId,
      );
      saved++;
    }
    return GradeSheetResult(saved: saved);
  }
}

class GradeEntry {
  const GradeEntry({required this.studentId, required this.score, this.gradeId});

  final int studentId;
  final double score;

  /// Present when the student already has a grade for this subject and period.
  final int? gradeId;
}

class GradeSheetResult {
  const GradeSheetResult({required this.saved});

  final int saved;
}

/// Today's blocks out of a weekly grid, with the live status resolved.
class TodaysClasses {
  const TodaysClasses();

  List<ClassSession> call(List<ClassSession> weekly, {DateTime? now}) {
    final moment = now ?? DateTime.now();
    final today = Weekdays.labelFor(moment);
    return weekly.where((s) => s.day == today).map((s) => s.resolvedAt(moment)).toList();
  }
}

/// The next block a student has today: the first one not yet finished, or the
/// last of the day once they all are.
class NextClass {
  const NextClass();

  ClassSession? call(List<ClassSession> today) {
    for (final session in today) {
      if (session.status != ClassStatus.done) return session;
    }
    return today.isEmpty ? null : today.last;
  }
}

/// Attaching student names to news rows.
///
/// `NovedadOut` carries only an id, and the list would otherwise read
/// "Estudiante 41". The local catalog resolves them without one request per
/// row — and degrades to the id when it cannot.
class NameNovedades {
  const NameNovedades(this._attendance);

  final AttendanceRepository _attendance;

  Future<List<T>> call<T>(
    List<T> novedades, {
    required int? Function(T novedad) studentIdOf,
    required T Function(T novedad, String name) withName,
  }) async {
    if (novedades.isEmpty) return novedades;
    try {
      await _attendance.warmUp(force: false);
    } on AppFailure {
      return novedades;
    }
    return novedades.map((novedad) {
      final id = studentIdOf(novedad);
      final student = id == null ? null : _attendance.studentById(id);
      return student == null ? novedad : withName(novedad, student.displayName);
    }).toList();
  }
}
