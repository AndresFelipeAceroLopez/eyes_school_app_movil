/// The per-role summaries the API exposes under `/dashboard`.
///
/// There is deliberately no admin dashboard: the API has none, and the mobile
/// admin is a hallway tool rather than a control panel.
library;

class TeacherDashboard {
  const TeacherDashboard({
    required this.assignedCourses,
    required this.totalStudents,
    required this.gradesToday,
    required this.attendanceToday,
  });

  static const empty = TeacherDashboard(
    assignedCourses: 0,
    totalStudents: 0,
    gradesToday: 0,
    attendanceToday: 0,
  );

  final int assignedCourses;
  final int totalStudents;
  final int gradesToday;
  final int attendanceToday;
}

class StudentDashboard {
  const StudentDashboard({
    required this.pendingNovedades,
    this.average,
    this.attendancePercent,
    this.currentPeriod,
  });

  final int pendingNovedades;
  final double? average;
  final double? attendancePercent;

  /// The only place the API reports the running academic period: there is no
  /// `/periodos` catalog.
  final int? currentPeriod;
}

class GuardianDashboard {
  const GuardianDashboard({
    required this.pendingNovedades,
    this.studentId,
    this.studentName,
    this.average,
    this.attendancePercent,
    this.currentPeriod,
  });

  final int pendingNovedades;
  final int? studentId;
  final String? studentName;
  final double? average;
  final double? attendancePercent;
  final int? currentPeriod;
}

/// A generated report. Read-only on mobile: generating one is a desktop flow.
class Report {
  const Report({
    required this.id,
    required this.type,
    required this.status,
    this.title,
    this.description,
    this.generatedAt,
    this.hasFile = false,
  });

  final int id;
  final String type;

  /// Pendiente · Generando · Procesando · Completado · Error.
  final String status;
  final String? title;
  final String? description;
  final DateTime? generatedAt;
  final bool hasFile;

  bool get isReady => status.toLowerCase() == 'completado';
  bool get isFailed => status.toLowerCase() == 'error';
}
