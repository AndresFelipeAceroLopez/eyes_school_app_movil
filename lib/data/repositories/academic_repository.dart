import '../../models/activity_log.dart';
import '../../models/attendance_summary.dart';
import '../../models/class_session.dart';
import '../../models/grade.dart';
import '../../models/novedad.dart';
import '../../models/roster_student.dart';
import '../../models/subject.dart';
import '../mock/mock_seed.dart';

abstract class AcademicRepository {
  Future<List<ClassSession>> getTeacherClassesToday();
  Future<ClassSession> getStudentNextClass();
  Future<List<Grade>> getGradesForStudent(String studentId);
  Future<AttendanceSummary?> getAttendanceForStudent(String studentId);
  Future<List<Novedad>> getNovedadesForStudent(String studentId);
  Future<List<Novedad>> getTeacherPendingNovedades();
  Future<List<ActivityLog>> getParentRecentActivity();
  Future<AttendanceSummary> getAdminAttendanceToday();
  Future<List<ActivityLog>> getAdminRecentActivity();
  Future<List<ClassSession>> getTeacherWeeklySchedule();
  Future<List<ClassSession>> getStudentWeeklySchedule(String studentId);
  Future<List<RosterStudent>> getRosterForGroup(String group);
  Future<List<Subject>> getSubjects();
  Future<List<Novedad>> getAdminNovedades();
}

class MockAcademicRepository implements AcademicRepository {
  @override
  Future<List<ClassSession>> getTeacherClassesToday() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockSeed.teacherClasses;
  }

  @override
  Future<ClassSession> getStudentNextClass() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return MockSeed.studentNextClass;
  }

  @override
  Future<List<Grade>> getGradesForStudent(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return MockSeed.gradesByStudentId[studentId] ?? const [];
  }

  @override
  Future<AttendanceSummary?> getAttendanceForStudent(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return MockSeed.attendanceByStudentId[studentId];
  }

  @override
  Future<List<Novedad>> getNovedadesForStudent(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return MockSeed.novedadesByStudentId[studentId] ?? const [];
  }

  @override
  Future<List<Novedad>> getTeacherPendingNovedades() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return MockSeed.teacherPendingNovedades;
  }

  @override
  Future<List<ActivityLog>> getParentRecentActivity() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return MockSeed.parentRecentActivity;
  }

  @override
  Future<AttendanceSummary> getAdminAttendanceToday() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return MockSeed.adminAttendanceToday;
  }

  @override
  Future<List<ActivityLog>> getAdminRecentActivity() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return MockSeed.adminActivity;
  }

  @override
  Future<List<ClassSession>> getTeacherWeeklySchedule() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockSeed.teacherWeeklySchedule;
  }

  @override
  Future<List<ClassSession>> getStudentWeeklySchedule(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return MockSeed.weeklyScheduleByStudentId[studentId] ?? const [];
  }

  @override
  Future<List<RosterStudent>> getRosterForGroup(String group) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return MockSeed.rosterByGroup[group] ?? const [];
  }

  @override
  Future<List<Subject>> getSubjects() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return MockSeed.subjects;
  }

  @override
  Future<List<Novedad>> getAdminNovedades() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return MockSeed.adminNovedades;
  }
}
