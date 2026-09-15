import 'package:eyes_school/core/utils/json_x.dart';
import 'package:eyes_school/features/dashboard/domain/dashboard.dart';

/// The `/dashboard/{rol}` endpoints have no schema in the OpenAPI contract,
/// so every field is read defensively.
abstract final class DashboardMapper {
  static TeacherDashboard teacher(Json json) => TeacherDashboard(
        assignedCourses: asInt(json['total_cursos_asignados']),
        totalStudents: asInt(json['total_estudiantes']),
        gradesToday: asInt(json['notas_registradas_hoy']),
        attendanceToday: asInt(json['asistencias_registradas_hoy']),
      );

  static StudentDashboard student(Json json) => StudentDashboard(
        pendingNovedades: asInt(json['novedades_pendientes']),
        average: asDoubleOrNull(json['promedio_general']),
        attendancePercent: asDoubleOrNull(json['porcentaje_asistencia']),
        currentPeriod: asIntOrNull(json['periodo_actual']),
      );

  static GuardianDashboard guardian(Json json) => GuardianDashboard(
        pendingNovedades: asInt(json['novedades_pendientes']),
        studentId: asIntOrNull(json['id_estudiante']),
        studentName: asStringOrNull(json['nombre_estudiante']),
        average: asDoubleOrNull(json['promedio_general']),
        attendancePercent: asDoubleOrNull(json['porcentaje_asistencia']),
        currentPeriod: asIntOrNull(json['periodo_actual']),
      );
}
