import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_log.dart';
import '../models/attendance_summary.dart';
import '../models/class_session.dart';
import '../models/grade.dart';
import '../models/novedad.dart';
import '../models/roster_student.dart';
import '../models/subject.dart';
import '../models/user.dart';
import 'repository_providers.dart';

final teacherClassesProvider = FutureProvider<List<ClassSession>>(
  (ref) => ref.watch(academicRepositoryProvider).getTeacherClassesToday(),
);

final teacherPendingNovedadesProvider = FutureProvider<List<Novedad>>(
  (ref) => ref.watch(academicRepositoryProvider).getTeacherPendingNovedades(),
);

final studentNextClassProvider = FutureProvider<ClassSession>(
  (ref) => ref.watch(academicRepositoryProvider).getStudentNextClass(),
);

final gradesForStudentProvider =
    FutureProvider.family<List<Grade>, String>(
  (ref, studentId) => ref.watch(academicRepositoryProvider).getGradesForStudent(studentId),
);

final attendanceForStudentProvider =
    FutureProvider.family<AttendanceSummary?, String>(
  (ref, studentId) =>
      ref.watch(academicRepositoryProvider).getAttendanceForStudent(studentId),
);

final novedadesForStudentProvider =
    FutureProvider.family<List<Novedad>, String>(
  (ref, studentId) =>
      ref.watch(academicRepositoryProvider).getNovedadesForStudent(studentId),
);

final parentRecentActivityProvider = FutureProvider<List<ActivityLog>>(
  (ref) => ref.watch(academicRepositoryProvider).getParentRecentActivity(),
);

final childrenOfProvider = FutureProvider.family<List<AppUser>, AppUser>(
  (ref, parent) => ref.watch(userRepositoryProvider).getChildrenOf(parent),
);

final adminAttendanceTodayProvider = FutureProvider<AttendanceSummary>(
  (ref) => ref.watch(academicRepositoryProvider).getAdminAttendanceToday(),
);

final adminRecentActivityProvider = FutureProvider<List<ActivityLog>>(
  (ref) => ref.watch(academicRepositoryProvider).getAdminRecentActivity(),
);

final allUsersProvider = FutureProvider<List<AppUser>>(
  (ref) => ref.watch(userRepositoryProvider).getAllUsers(),
);

final userByIdProvider = FutureProvider.family<AppUser?, String>(
  (ref, id) => ref.watch(userRepositoryProvider).getUserById(id),
);

final teacherWeeklyScheduleProvider = FutureProvider<List<ClassSession>>(
  (ref) => ref.watch(academicRepositoryProvider).getTeacherWeeklySchedule(),
);

final studentWeeklyScheduleProvider = FutureProvider.family<List<ClassSession>, String>(
  (ref, studentId) =>
      ref.watch(academicRepositoryProvider).getStudentWeeklySchedule(studentId),
);

final rosterForGroupProvider = FutureProvider.family<List<RosterStudent>, String>(
  (ref, group) => ref.watch(academicRepositoryProvider).getRosterForGroup(group),
);

final subjectsProvider = FutureProvider<List<Subject>>(
  (ref) => ref.watch(academicRepositoryProvider).getSubjects(),
);

final adminNovedadesProvider = FutureProvider<List<Novedad>>(
  (ref) => ref.watch(academicRepositoryProvider).getAdminNovedades(),
);
