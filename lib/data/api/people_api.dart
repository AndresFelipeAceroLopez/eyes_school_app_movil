import '../../core/network/api_config.dart';
import '../../core/utils/json_x.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/failures/app_failure.dart';
import '../dto/attendance_dto.dart';
import '../dto/people_dto.dart';
import 'api_client.dart';

/// `/usuarios`, `/estudiantes`, `/profesores`, `/padres`, `/administradores`.
class PeopleApi {
  const PeopleApi(this._client);

  final ApiClient _client;

  // ── Usuarios ────────────────────────────────────────────────────────────

  Future<List<UsuarioDto>> users({
    int skip = 0,
    int limit = ApiConfig.pageSize,
    int? roleId,
    bool? active,
    String? search,
  }) {
    return _client.getList('/usuarios', UsuarioDto.fromJson, query: {
      'skip': skip,
      'limit': limit,
      'id_rol': roleId,
      'estado': active,
      'search': (search != null && search.trim().isNotEmpty) ? search.trim() : null,
    });
  }

  Future<UsuarioDto> user(int userId) async =>
      UsuarioDto.fromJson(await _client.getObject('/usuarios/$userId'));

  /// Only ever called for the signed-in user's own profile. The document
  /// fields are deliberately absent: they are locked, as in the web panel.
  Future<UsuarioDto> updateUser(
    int userId, {
    String? address,
    String? email,
    String? phone,
    String? password,
  }) async {
    final body = <String, dynamic>{
      'direccion': ?address,
      'correo': ?email,
      'telefono': ?phone,
      'password': ?password,
    };
    return UsuarioDto.fromJson(await _client.put('/usuarios/$userId', body: body));
  }

  // ── Estudiantes ─────────────────────────────────────────────────────────

  Future<EstudianteDto> studentMe() async =>
      EstudianteDto.fromJson(await _client.getObject('/estudiantes/me'));

  Future<List<EstudianteDto>> students({
    int skip = 0,
    int limit = ApiConfig.pageSize,
    int? courseId,
    String? status,
  }) {
    return _client.getList('/estudiantes', EstudianteDto.fromJson, query: {
      'skip': skip,
      'limit': limit,
      'id_curso': courseId,
      'estado': status,
    });
  }

  Future<EstudianteDto> student(int studentId) async =>
      EstudianteDto.fromJson(await _client.getObject('/estudiantes/$studentId'));

  /// Raw rows: the repository joins them against the subject catalog.
  Future<List<Json>> gradesOfStudent(int studentId, {int? period, int? subjectId}) {
    return _client.getList('/estudiantes/$studentId/notas', (json) => json, query: {
      'id_periodo': period,
      'id_materia': subjectId,
    });
  }

  Future<List<AttendanceRecord>> attendanceOfStudent(
    int studentId, {
    int skip = 0,
    int limit = ApiConfig.pageSize,
  }) {
    return _client.getList(
      '/estudiantes/$studentId/asistencia',
      AttendanceMapper.fromJson,
      query: {'skip': skip, 'limit': limit},
    );
  }

  Future<List<Json>> novedadesOfStudent(int studentId) =>
      _client.getList('/estudiantes/$studentId/novedades', (json) => json);

  // ── Profesores ──────────────────────────────────────────────────────────

  /// `GET /profesores/me` is the one endpoint the plan asks the backend to
  /// add and it is **not deployed yet**: with a valid token the API matches
  /// `/{id_profesor}` and answers 422. Until it ships, the teacher bootstrap
  /// falls back to paging `/profesores` and matching `id_usuario`; the moment
  /// it does, the fast path takes over on its own.
  Future<ProfesorDto?> teacherMe(int userId) async {
    try {
      return ProfesorDto.fromJson(await _client.getObject('/profesores/me'));
    } on NotFoundFailure {
      return _findTeacherByUser(userId);
    } on ValidationFailure {
      return _findTeacherByUser(userId);
    } on UnexpectedFailure {
      return _findTeacherByUser(userId);
    }
  }

  Future<ProfesorDto?> _findTeacherByUser(int userId) async {
    for (var skip = 0; skip < 2000; skip += ApiConfig.catalogPageSize) {
      final page = await teachers(skip: skip, limit: ApiConfig.catalogPageSize);
      for (final teacher in page) {
        if (teacher.idUsuario == userId) return teacher;
      }
      if (page.length < ApiConfig.catalogPageSize) break;
    }
    return null;
  }

  Future<List<ProfesorDto>> teachers({
    int skip = 0,
    int limit = ApiConfig.pageSize,
    String? status,
  }) {
    return _client.getList('/profesores', ProfesorDto.fromJson, query: {
      'skip': skip,
      'limit': limit,
      'estado': status,
    });
  }

  Future<ProfesorDto> teacher(int teacherId) async =>
      ProfesorDto.fromJson(await _client.getObject('/profesores/$teacherId'));

  Future<List<EspecializacionDto>> specialitiesOfTeacher(int teacherId) => _client
      .getList('/profesores/$teacherId/especializaciones', EspecializacionDto.fromJson);

  // ── Padres ──────────────────────────────────────────────────────────────

  Future<PadreDto> guardianMe() async =>
      PadreDto.fromJson(await _client.getObject('/padres/me'));

  Future<List<PadreDto>> guardians({int skip = 0, int limit = ApiConfig.pageSize}) =>
      _client.getList('/padres', PadreDto.fromJson,
          query: {'skip': skip, 'limit': limit});

  // ── Administradores ─────────────────────────────────────────────────────

  /// There is no `/administradores/me`; the admin profile card resolves its
  /// `cargo` by scanning the (short) list for the signed-in user.
  Future<AdministradorDto?> adminOfUser(int userId) async {
    for (var skip = 0; skip < 500; skip += ApiConfig.catalogPageSize) {
      final page = await _client.getList(
        '/administradores',
        AdministradorDto.fromJson,
        query: {'skip': skip, 'limit': ApiConfig.catalogPageSize},
      );
      for (final admin in page) {
        if (admin.idUsuario == userId) return admin;
      }
      if (page.length < ApiConfig.catalogPageSize) break;
    }
    return null;
  }
}
