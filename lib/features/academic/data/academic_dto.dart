import 'package:eyes_school/core/utils/json_x.dart';
import 'package:eyes_school/features/directory/domain/catalog.dart';
import 'package:eyes_school/features/academic/domain/grade.dart';
import 'package:eyes_school/features/academic/domain/class_time.dart';
import 'package:eyes_school/features/novedades/domain/severity.dart';

/// `CursoOut` → [Course].
abstract final class CourseMapper {
  static Course fromJson(Json json) => Course(
        id: asInt(json['id_curso']),
        name: asString(json['nombre_curso']),
        grade: asString(json['grado']),
        // The API stores "mañana" | "manana" | "tarde" | "unica" | "1".."4".
        shift: SchoolShift.parse(asStringOrNull(json['jornada'])),
        year: asInt(json['ano']),
        active: asBool(json['activo'], fallback: true),
        area: asStringOrNull(json['area']),
      );
}

/// `MateriaOut` → [CourseSubject].
abstract final class SubjectMapper {
  static CourseSubject fromJson(Json json) => CourseSubject(
        id: asInt(json['id_materia']),
        name: asString(json['nombre_materia']),
        code: asString(json['codigo_materia']),
        active: asBool(json['activa'], fallback: true),
      );
}

/// `AsignacionOut` — the profesor ↔ curso ↔ materia triple that scopes
/// everything a teacher is allowed to register.
class AssignmentDto {
  const AssignmentDto({
    required this.id,
    required this.teacherId,
    required this.courseId,
    required this.subjectId,
    required this.active,
  });

  factory AssignmentDto.fromJson(Json json) => AssignmentDto(
        id: asInt(json['id_asignacion']),
        teacherId: asInt(json['id_profesor']),
        courseId: asInt(json['id_curso']),
        subjectId: asInt(json['id_materia']),
        active: asBool(json['activo'], fallback: true),
      );

  final int id;
  final int teacherId;
  final int courseId;
  final int subjectId;
  final bool active;
}

/// `HorarioOut`. Carries only ids: the subject and course names come from the
/// cached catalogs.
class ScheduleBlockDto {
  const ScheduleBlockDto({
    required this.id,
    required this.courseId,
    required this.subjectId,
    required this.day,
    required this.room,
    required this.active,
    this.start,
    this.end,
  });

  factory ScheduleBlockDto.fromJson(Json json) => ScheduleBlockDto(
        id: asInt(json['id_horario']),
        courseId: asInt(json['id_curso']),
        subjectId: asInt(json['id_materia']),
        day: asString(json['dia']),
        room: asString(json['salon']),
        active: asBool(json['activo'], fallback: true),
        // `format: time` — "07:00:00" is not an ISO datetime.
        start: ClassTime.tryParse(asStringOrNull(json['hora_inicio'])),
        end: ClassTime.tryParse(asStringOrNull(json['hora_fin'])),
      );

  final int id;
  final int courseId;
  final int subjectId;

  /// `"Lunes".."Viernes"`, written without an accent on `Miercoles`.
  final String day;
  final String room;
  final bool active;
  final ClassTime? start;
  final ClassTime? end;
}

/// `NotaOut` → [Grade], once the subject name is known.
abstract final class GradeMapper {
  static Grade fromJson(Json json, String Function(int subjectId) subjectName) {
    final subjectId = asInt(json['id_materia']);
    final period = asInt(json['id_periodo']);
    return Grade(
      subject: subjectName(subjectId),
      // `number` in the contract: it arrives as int or double.
      score: asDouble(json['nota']),
      period: AcademicPeriods.labelOf(period),
      gradeId: asInt(json['id_nota']),
      studentId: asInt(json['id_estudiante']),
      subjectId: subjectId,
      periodId: period,
      observation: asStringOrNull(json['observacion']),
    );
  }

  /// `NotaCreate`.
  static Json createPayload({
    required int studentId,
    required int subjectId,
    required int period,
    required double score,
    required int registeredBy,
    String? observation,
  }) {
    return <String, dynamic>{
      'id_estudiante': studentId,
      'id_materia': subjectId,
      'id_periodo': period,
      'nota': score,
      'registrado_por': registeredBy,
      'observacion': ?observation,
    };
  }
}
