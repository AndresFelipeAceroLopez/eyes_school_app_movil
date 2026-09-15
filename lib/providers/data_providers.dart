import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eyes_school/features/auth/domain/app_user.dart';
import 'package:eyes_school/features/attendance/domain/attendance_record.dart';
import 'package:eyes_school/features/attendance/domain/attendance_summary.dart';
import 'package:eyes_school/features/directory/domain/catalog.dart';
import 'package:eyes_school/features/academic/domain/class_session.dart';
import 'package:eyes_school/features/dashboard/domain/dashboard.dart';
import 'package:eyes_school/features/academic/domain/grade.dart';
import 'package:eyes_school/features/novedades/domain/novedad.dart';
import 'package:eyes_school/features/academic/domain/roster_student.dart';
import 'package:eyes_school/features/academic/domain/subject.dart';
import 'package:eyes_school/features/academic/domain/teacher_class.dart';
import 'package:eyes_school/features/attendance/domain/attendance.dart';
import 'package:eyes_school/features/novedades/domain/severity.dart';
import 'repository_providers.dart';
import 'session_provider.dart';

/// Read models for the presentation layer.
///
/// Every one of these returns a **domain entity**: no screen ever sees a DTO,
/// a status code or a JSON map.

// ── Catálogos ─────────────────────────────────────────────────────────────

final coursesProvider = FutureProvider<List<Course>>(
  (ref) => ref.watch(academicRepositoryProvider).courses(onlyActive: true),
);

final novedadTypesProvider = FutureProvider<List<NovedadType>>(
  (ref) => ref.watch(academicRepositoryProvider).novedadTypes(),
);

final subjectsProvider = FutureProvider<List<Subject>>(
  (ref) => ref.watch(academicRepositoryProvider).subjects(),
);

// ── Docente ───────────────────────────────────────────────────────────────

final teacherDashboardProvider = FutureProvider<TeacherDashboard>(
  (ref) => ref.watch(academicRepositoryProvider).teacherDashboard(),
);

final teacherClassesProvider = FutureProvider<List<TeacherClass>>((ref) async {
  final teacherId = ref.watch(currentSessionProvider)?.teacherId;
  if (teacherId == null) return const [];
  return ref.watch(academicRepositoryProvider).teacherClasses(teacherId);
});

final teacherWeeklyScheduleProvider = FutureProvider<List<ClassSession>>((ref) async {
  final teacherId = ref.watch(currentSessionProvider)?.teacherId;
  if (teacherId == null) return const [];
  return ref.watch(academicRepositoryProvider).teacherSchedule(teacherId);
});

/// Today's blocks, derived from the weekly grid so the API is hit once.
final teacherTodayClassesProvider = FutureProvider<List<ClassSession>>((ref) async {
  final weekly = await ref.watch(teacherWeeklyScheduleProvider.future);
  return todaysClasses(weekly);
});

final teacherNovedadesProvider =
    FutureProvider.family<List<Novedad>, NovedadStatus?>((ref, status) async {
  final novedades =
      await ref.watch(academicRepositoryProvider).novedades(status: status, limit: 50);
  return _withStudentNames(ref, novedades);
});

/// Class list of a course, for roll call and bulk registration.
final rosterProvider = FutureProvider.family<List<RosterStudent>, int>(
  (ref, courseId) => ref.watch(academicRepositoryProvider).roster(courseId),
);

/// Grade sheet: one subject, one period.
final gradeSheetProvider =
    FutureProvider.family<List<Grade>, ({int subjectId, int period})>(
  (ref, args) => ref
      .watch(academicRepositoryProvider)
      .gradeSheet(subjectId: args.subjectId, period: args.period),
);

final teacherClassProvider = FutureProvider.family<TeacherClass?, int>(
  (ref, assignmentId) =>
      ref.watch(academicRepositoryProvider).teacherClass(assignmentId),
);

// ── Estudiante y acudiente ────────────────────────────────────────────────

final studentDashboardProvider = FutureProvider<StudentDashboard>(
  (ref) => ref.watch(academicRepositoryProvider).studentDashboard(),
);

final parentDashboardProvider = FutureProvider<GuardianDashboard>(
  (ref) => ref.watch(academicRepositoryProvider).guardianDashboard(),
);

/// Grades of a student for a period. `period: null` means "every period".
final gradesForStudentProvider =
    FutureProvider.family<List<Grade>, ({int studentId, int? period})>(
  (ref, args) => ref
      .watch(academicRepositoryProvider)
      .gradesForStudent(args.studentId, period: args.period),
);

final attendanceSummaryProvider = FutureProvider.family<AttendanceSummary, int>(
  (ref, studentId) =>
      ref.watch(academicRepositoryProvider).attendanceSummary(studentId),
);

final novedadesForStudentProvider = FutureProvider.family<List<Novedad>, int>(
  (ref, studentId) =>
      ref.watch(academicRepositoryProvider).novedadesForStudent(studentId),
);

final studentWeeklyScheduleProvider = FutureProvider.family<List<ClassSession>, int>(
  (ref, courseId) => ref.watch(academicRepositoryProvider).courseSchedule(courseId),
);

/// The next block of today, for the student home card.
final studentNextClassProvider = FutureProvider<ClassSession?>((ref) async {
  final courseId = ref.watch(currentSessionProvider)?.courseId;
  if (courseId == null) return null;
  final weekly = await ref.watch(academicRepositoryProvider).courseSchedule(courseId);
  return nextClass(todaysClasses(weekly));
});

// ── Admin ─────────────────────────────────────────────────────────────────

enum DirectoryTab { students, teachers, guardians }

/// Directory search. An empty query lists the first page of the tab.
final directorySearchProvider =
    FutureProvider.family<List<AppUser>, ({String query, DirectoryTab tab})>(
  (ref, args) async {
    final repo = ref.watch(directoryRepositoryProvider);
    return switch (args.tab) {
      DirectoryTab.students => repo.searchStudents(args.query),
      DirectoryTab.teachers => _filterByName(await repo.teachers(limit: 100), args.query),
      DirectoryTab.guardians => _filterByName(await repo.guardians(limit: 50), args.query),
    };
  },
);

List<AppUser> _filterByName(List<AppUser> users, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return users;
  return users
      .where((u) =>
          u.name.toLowerCase().contains(needle) ||
          (u.code ?? '').toLowerCase().contains(needle))
      .toList();
}

final studentProfileProvider = FutureProvider.family<AppUser?, int>(
  (ref, studentId) => ref.watch(directoryRepositoryProvider).studentProfile(studentId),
);

final teacherProfileProvider = FutureProvider.family<AppUser?, int>(
  (ref, teacherId) => ref.watch(directoryRepositoryProvider).teacherProfile(teacherId),
);

final teacherCoursesProvider = FutureProvider.family<List<String>, int>(
  (ref, teacherId) => ref.watch(directoryRepositoryProvider).coursesOfTeacher(teacherId),
);

final userByIdProvider = FutureProvider.family<AppUser?, int>(
  (ref, userId) => ref.watch(directoryRepositoryProvider).userById(userId),
);

/// Everything registered today, for the scanner's counter and day list.
final todayAttendanceProvider =
    FutureProvider.family<List<AttendanceRecord>, AttendanceKind?>(
  (ref, kind) =>
      ref.watch(attendanceRepositoryProvider).registeredOn(DateTime.now(), kind: kind),
);

/// All novedades, newest first — the admin news tab.
final adminNovedadesProvider = FutureProvider<List<Novedad>>((ref) async {
  final novedades = await ref.watch(academicRepositoryProvider).novedades(limit: 50);
  return _withStudentNames(ref, novedades);
});

/// Generated reports, newest first. Read-only.
final reportesProvider = FutureProvider<List<Report>>(
  (ref) => ref.watch(reportRepositoryProvider).reports(limit: 50),
);

// ── Apoyo ─────────────────────────────────────────────────────────────────

/// `NovedadOut` has no student name. The local catalog resolves the ids
/// without an extra request per row.
Future<List<Novedad>> _withStudentNames(Ref ref, List<Novedad> novedades) {
  return ref.read(nameNovedadesProvider).call<Novedad>(
        novedades,
        studentIdOf: (novedad) => novedad.studentId,
        withName: (novedad, name) => novedad.withStudentName(name),
      );
}
