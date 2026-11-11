import 'package:eyes_school/core/network/api_config.dart';
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
import 'package:eyes_school/core/errors/app_failure.dart';
import 'package:eyes_school/core/domain/repositories.dart';
import 'package:eyes_school/features/novedades/domain/severity.dart';
import 'package:eyes_school/features/academic/data/academic_api.dart';
import 'package:eyes_school/features/dashboard/data/dashboard_api.dart';
import 'package:eyes_school/features/novedades/data/novedades_api.dart';
import 'package:eyes_school/features/directory/data/people_api.dart';
import 'package:eyes_school/features/academic/data/academic_dto.dart';
import 'package:eyes_school/features/novedades/data/novedad_dto.dart';

/// Reads and writes everything academic, translating wire shapes into domain
/// entities. All the joins the API leaves to the client happen here, against
/// the cached catalogs.
class AcademicRepositoryImpl implements AcademicRepository {
  AcademicRepositoryImpl({
    required this._academic,
    required this._novedades,
    required this._people,
    required this._dashboard,
    required this._catalogs,
  });

  final AcademicApi _academic;
  final NovedadesApi _novedades;
  final PeopleApi _people;
  final DashboardApi _dashboard;
  final CatalogRepository _catalogs;

  // ── Dashboards ──────────────────────────────────────────────────────────

  @override
  Future<TeacherDashboard> teacherDashboard() => _dashboard.teacher();

  @override
  Future<StudentDashboard> studentDashboard() async {
    final d = await _dashboard.student();
    int? studentId;
    try {
      studentId = (await _people.studentMe()).idEstudiante;
    } on AppFailure {
      studentId = null;
    }
    return StudentDashboard(
      pendingNovedades: d.pendingNovedades,
      average: d.average,
      attendancePercent: await _attendancePercent(
        studentId,
        d.attendancePercent,
      ),
      currentPeriod: d.currentPeriod,
    );
  }

  @override
  Future<GuardianDashboard> guardianDashboard({int? studentId}) async {
    final d = await _dashboard.guardian(studentId: studentId);
    return GuardianDashboard(
      pendingNovedades: d.pendingNovedades,
      studentId: d.studentId ?? studentId,
      studentName: d.studentName,
      average: d.average,
      attendancePercent: await _attendancePercent(
        d.studentId ?? studentId,
        d.attendancePercent,
      ),
      currentPeriod: d.currentPeriod,
    );
  }

  /// The home card and the attendance screen show the same figure (N-20):
  /// the one computed from the records, as the attendance screen does. The
  /// API's own figure has been seen above 100 % (N-04), so it is only a
  /// fallback, and never shown above 100.
  Future<double?> _attendancePercent(int? studentId, double? apiValue) async {
    if (studentId != null) {
      try {
        final summary = await attendanceSummary(studentId);
        if (summary.total > 0) return summary.percent;
      } on AppFailure {
        // Fall back to the API figure below.
      }
    }
    if (apiValue == null) return null;
    return apiValue.clamp(0, 100).toDouble();
  }

  // ── Horarios ────────────────────────────────────────────────────────────

  @override
  Future<List<ClassSession>> courseSchedule(int courseId) async {
    final catalogs = await _catalogs.load();
    final blocks = await _academic.scheduleOfCourse(courseId);
    return _toSessions(blocks, catalogs, secondaryLine: (block) => block.room);
  }

  @override
  Future<List<ClassSession>> teacherSchedule(int teacherId) async {
    final catalogs = await _catalogs.load();
    final assignments = await _academic.assignments(
      teacherId: teacherId,
      active: true,
    );
    if (assignments.isEmpty) return const [];

    final subjectsByCourse = <int, Set<int>>{};
    for (final assignment in assignments) {
      subjectsByCourse
          .putIfAbsent(assignment.courseId, () => {})
          .add(assignment.subjectId);
    }

    final sessions = <ClassSession>[];
    for (final entry in subjectsByCourse.entries) {
      final blocks = await _academic.scheduleOfCourse(entry.key);
      // A course's grid contains every subject; the teacher only owns theirs.
      final mine = blocks
          .where((b) => entry.value.contains(b.subjectId))
          .toList();
      sessions.addAll(
        _toSessions(
          mine,
          catalogs,
          secondaryLine: (block) =>
              '${catalogs.courseName(block.courseId)} · ${block.room}',
        ),
      );
    }
    _sortByDayAndTime(sessions);
    return sessions;
  }

  List<ClassSession> _toSessions(
    List<ScheduleBlockDto> blocks,
    Catalogs catalogs, {
    required String Function(ScheduleBlockDto block) secondaryLine,
  }) {
    final sessions = blocks
        .where((b) => b.active)
        .map(
          (b) => ClassSession(
            subject: catalogs.subjectName(b.subjectId),
            group: secondaryLine(b),
            room: b.room,
            status: ClassSession.statusFor(b.start, b.end),
            day: Weekdays.normalize(b.day),
            courseId: b.courseId,
            subjectId: b.subjectId,
            start: b.start,
            end: b.end,
          ),
        )
        .toList();
    _sortByDayAndTime(sessions);
    return sessions;
  }

  void _sortByDayAndTime(List<ClassSession> sessions) {
    sessions.sort((a, b) {
      final byDay = Weekdays.orderOf(a.day).compareTo(Weekdays.orderOf(b.day));
      if (byDay != 0) return byDay;
      return a.time.compareTo(b.time);
    });
  }

  // ── Clases del docente ──────────────────────────────────────────────────

  @override
  Future<List<TeacherClass>> teacherClasses(int teacherId) async {
    final catalogs = await _catalogs.load();
    final assignments = await _academic.assignments(
      teacherId: teacherId,
      active: true,
    );
    final classes = assignments
        .map((a) => _toTeacherClass(a, catalogs))
        .toList();
    classes.sort((a, b) {
      final byCourse = a.courseName.compareTo(b.courseName);
      return byCourse != 0 ? byCourse : a.subjectName.compareTo(b.subjectName);
    });
    return classes;
  }

  @override
  Future<TeacherClass?> teacherClass(int assignmentId) async {
    final catalogs = await _catalogs.load();
    try {
      return _toTeacherClass(
        await _academic.assignment(assignmentId),
        catalogs,
      );
    } on NotFoundFailure {
      return null;
    }
  }

  TeacherClass _toTeacherClass(AssignmentDto assignment, Catalogs catalogs) {
    return TeacherClass(
      assignmentId: assignment.id,
      courseId: assignment.courseId,
      subjectId: assignment.subjectId,
      courseName: catalogs.courseName(assignment.courseId),
      subjectName: catalogs.subjectName(assignment.subjectId),
      active: assignment.active,
      shift: catalogs.courses[assignment.courseId]?.shiftLabel,
    );
  }

  // ── Listas de clase ─────────────────────────────────────────────────────

  @override
  Future<List<RosterStudent>> roster(int courseId) async {
    final students = await _academic.studentsOfCourse(courseId);
    final roster = students
        .where((s) => s.activo)
        .map(
          (s) => RosterStudent(
            id: s.idEstudiante,
            name: s.nombreCompleto.isEmpty
                ? s.codigoEstudiante
                : s.nombreCompleto,
            code: s.codigoEstudiante,
            courseId: s.idCursoActual,
          ),
        )
        .toList();
    roster.sort((a, b) => a.name.compareTo(b.name));
    return roster;
  }

  // ── Notas ───────────────────────────────────────────────────────────────

  @override
  Future<List<Grade>> gradesForStudent(
    int studentId, {
    int? period,
    int? subjectId,
  }) async {
    final catalogs = await _catalogs.load();
    final rows = await _people.gradesOfStudent(
      studentId,
      period: period,
      subjectId: subjectId,
    );
    final grades = rows
        .map((json) => GradeMapper.fromJson(json, catalogs.subjectName))
        .toList();
    grades.sort((a, b) => a.subject.compareTo(b.subject));
    return grades;
  }

  @override
  Future<List<Grade>> gradeSheet({
    required int subjectId,
    required int period,
  }) async {
    final catalogs = await _catalogs.load();
    final rows = await _academic.rawGrades(
      subjectId: subjectId,
      period: period,
    );
    return rows
        .map((json) => GradeMapper.fromJson(json, catalogs.subjectName))
        .toList();
  }

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
    if (gradeId != null) {
      await _academic.updateGrade(
        gradeId,
        score: score,
        observation: observation,
      );
      return;
    }
    await _academic.createGrade(
      GradeMapper.createPayload(
        studentId: studentId,
        subjectId: subjectId,
        period: period,
        score: score,
        registeredBy: registeredBy,
        observation: observation,
      ),
    );
  }

  @override
  Future<void> deleteGrade(int gradeId) => _academic.deleteGrade(gradeId);

  @override
  Future<void> downloadReportCard({
    required int studentId,
    required String savePath,
    void Function(int received, int total)? onProgress,
  }) {
    return _academic.downloadReportCard(
      studentId: studentId,
      savePath: savePath,
      onProgress: onProgress,
    );
  }

  // ── Asistencia (lectura) ────────────────────────────────────────────────

  @override
  Future<List<AttendanceRecord>> attendanceHistory(
    int studentId, {
    int skip = 0,
    int limit = ApiConfig.pageSize,
  }) {
    return _people.attendanceOfStudent(studentId, skip: skip, limit: limit);
  }

  @override
  Future<AttendanceSummary> attendanceSummary(
    int studentId, {
    int sample = 100,
  }) async {
    final rows = await _people.attendanceOfStudent(studentId, limit: sample);
    return AttendanceSummary.of(rows);
  }

  // ── Novedades ───────────────────────────────────────────────────────────

  @override
  Future<List<Novedad>> novedades({
    int? studentId,
    NovedadStatus? status,
    int skip = 0,
    int limit = ApiConfig.pageSize,
  }) async {
    final catalogs = await _catalogs.load();
    final rows = await _novedades.rawList(
      studentId: studentId,
      status: status,
      skip: skip,
      limit: limit,
    );
    return _newestFirst(rows.map((json) => _toNovedad(json, catalogs)));
  }

  @override
  Future<List<Novedad>> novedadesForStudent(int studentId) async {
    final catalogs = await _catalogs.load();
    final rows = await _people.novedadesOfStudent(studentId);
    return _newestFirst(rows.map((json) => _toNovedad(json, catalogs)));
  }

  /// Most recent first (N-21, CP-SIS-084). The API has no ordering parameter,
  /// so each page is ordered as it arrives.
  static List<Novedad> _newestFirst(Iterable<Novedad> items) {
    final list = items.toList();
    list.sort((a, b) {
      final da = a.date, db = b.date;
      if (da == null && db == null) {
        return (b.novedadId ?? 0).compareTo(a.novedadId ?? 0);
      }
      if (da == null) return 1;
      if (db == null) return -1;
      final byDate = db.compareTo(da);
      return byDate != 0
          ? byDate
          : (b.novedadId ?? 0).compareTo(a.novedadId ?? 0);
    });
    return list;
  }

  Novedad _toNovedad(Map<String, dynamic> json, Catalogs catalogs) {
    return NovedadMapper.fromJson(
      json,
      typeName: catalogs.novedadTypeName,
      severityOf: catalogs.severityOf,
    );
  }

  @override
  Future<void> createNovedad({
    required int studentId,
    required int typeId,
    required DateTime date,
    required String description,
    required int registeredBy,
    String? action,
  }) {
    return _novedades.create(
      NovedadMapper.createPayload(
        studentId: studentId,
        typeId: typeId,
        date: date,
        description: description,
        registeredBy: registeredBy,
        action: action,
      ),
    );
  }

  @override
  Future<void> resolveNovedad(int novedadId, {String? action}) {
    return _novedades.update(
      novedadId,
      status: NovedadStatus.done,
      action: action,
      resolvedOn: DateTime.now(),
    );
  }

  @override
  Future<void> reopenNovedad(int novedadId) =>
      _novedades.update(novedadId, status: NovedadStatus.pending);

  // ── Catálogos enriquecidos ──────────────────────────────────────────────

  @override
  Future<List<Subject>> subjects() async {
    final catalogs = await _catalogs.load();
    final assignments = await _academic.assignments(active: true);

    final coursesBySubject = <int, Set<int>>{};
    for (final assignment in assignments) {
      coursesBySubject
          .putIfAbsent(assignment.subjectId, () => {})
          .add(assignment.courseId);
    }

    final subjects = catalogs.subjects.values.where((m) => m.active).map((m) {
      final courses = coursesBySubject[m.id] ?? const <int>{};
      final names = courses.map(catalogs.courseName).toList()..sort();
      return Subject(
        name: m.name,
        teacherName: m.code,
        groups: names.isEmpty ? 'Sin cursos asignados' : names.join(', '),
        studentCount: courses.length,
        subjectId: m.id,
        code: m.code,
      );
    }).toList();
    subjects.sort((a, b) => a.name.compareTo(b.name));
    return subjects;
  }

  @override
  Future<List<Course>> courses({bool onlyActive = true}) async {
    final catalogs = await _catalogs.load();
    return onlyActive
        ? catalogs.activeCourses
        : catalogs.courses.values.toList();
  }

  @override
  Future<List<NovedadType>> novedadTypes() async =>
      (await _catalogs.load()).activeNovedadTypes;

  /// Today's blocks out of a weekly grid, with the live status resolved.
  static List<ClassSession> todayFrom(
    List<ClassSession> weekly, {
    DateTime? now,
  }) {
    final moment = now ?? DateTime.now();
    final today = Weekdays.labelFor(moment);
    return weekly
        .where((s) => s.day == today)
        .map((s) => s.resolvedAt(moment))
        .toList();
  }
}
