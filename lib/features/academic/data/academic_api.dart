import 'package:eyes_school/core/network/api_config.dart';
import 'package:eyes_school/features/directory/domain/catalog.dart';
import 'package:eyes_school/features/academic/data/academic_dto.dart';
import 'package:eyes_school/features/directory/data/people_dto.dart';
import 'package:eyes_school/core/network/api_client.dart';

/// `/cursos`, `/materias`, `/asignaciones`, `/horarios`, `/notas`.
class AcademicApi {
  const AcademicApi(this._client);

  final ApiClient _client;

  Future<List<Course>> courses({
    int skip = 0,
    int limit = ApiConfig.catalogPageSize,
    bool? active,
  }) {
    return _client.getList('/cursos', CourseMapper.fromJson, query: {
      'skip': skip,
      'limit': limit,
      'activo': active,
    });
  }

  Future<Course> course(int courseId) async =>
      CourseMapper.fromJson(await _client.getObject('/cursos/$courseId'));

  /// The class roster: drives bulk attendance and the teacher's roll call.
  Future<List<EstudianteDto>> studentsOfCourse(int courseId) =>
      _client.getList('/cursos/$courseId/estudiantes', EstudianteDto.fromJson);

  Future<List<ScheduleBlockDto>> scheduleOfCourse(int courseId) =>
      _client.getList('/cursos/$courseId/horarios', ScheduleBlockDto.fromJson);

  Future<List<CourseSubject>> subjects() =>
      _client.getList('/materias', SubjectMapper.fromJson);

  Future<List<AssignmentDto>> assignments({
    int? teacherId,
    int? courseId,
    int? subjectId,
    bool? active,
    int skip = 0,
    int limit = ApiConfig.catalogPageSize,
  }) {
    return _client.getList('/asignaciones', AssignmentDto.fromJson, query: {
      'id_profesor': teacherId,
      'id_curso': courseId,
      'id_materia': subjectId,
      'activo': active,
      'skip': skip,
      'limit': limit,
    });
  }

  Future<AssignmentDto> assignment(int assignmentId) async =>
      AssignmentDto.fromJson(await _client.getObject('/asignaciones/$assignmentId'));

  Future<List<Map<String, dynamic>>> rawGrades({
    int? studentId,
    int? subjectId,
    int? period,
    int skip = 0,
    int limit = ApiConfig.catalogPageSize,
  }) {
    return _client.getList('/notas', (json) => json, query: {
      'id_estudiante': studentId,
      'id_materia': subjectId,
      'id_periodo': period,
      'skip': skip,
      'limit': limit,
    });
  }

  Future<void> createGrade(Map<String, dynamic> payload) =>
      _client.post('/notas', body: payload);

  Future<void> updateGrade(int gradeId, {double? score, String? observation}) {
    return _client.put('/notas/$gradeId', body: <String, dynamic>{
      'nota': ?score,
      'observacion': ?observation,
    });
  }

  Future<void> deleteGrade(int gradeId) => _client.delete('/notas/$gradeId');

  /// Authenticated PDF download — needs the bearer header, so it goes through
  /// Dio and lands on disk rather than through a browser link.
  Future<void> downloadReportCard({
    required int studentId,
    required String savePath,
    void Function(int received, int total)? onProgress,
  }) {
    return _client.download(
      '/notas/estudiantes/$studentId/boletin/pdf',
      savePath,
      onProgress: onProgress,
    );
  }
}
