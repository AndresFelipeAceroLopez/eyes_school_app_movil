import '../../core/network/api_config.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/guardian.dart';
import '../../domain/entities/role.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/repositories/repositories.dart';
import '../api/academic_api.dart';
import '../api/people_api.dart';
import '../dto/people_dto.dart';
import '../local/student_catalog.dart';

/// The admin directory and the shared "person card" screens.
///
/// The mobile admin is a hallway tool: this repository only reads. Creating,
/// editing and deactivating users stays in the web panel.
class DirectoryRepositoryImpl implements DirectoryRepository {
  DirectoryRepositoryImpl({
    required this._people,
    required this._academic,
    required this._catalogs,
    required this._students,
  });

  final PeopleApi _people;
  final AcademicApi _academic;
  final CatalogRepository _catalogs;
  final StudentCatalog _students;

  AppUser _toAppUser(UsuarioDto dto) {
    return AppUser(
      userId: dto.idUsuario,
      name: dto.nombreCompleto,
      email: dto.correo ?? '',
      role: roleFromApiId(dto.idRol),
      status: dto.estado ? AccountStatus.active : AccountStatus.inactive,
      photoUrl: dto.fotoPerfil,
      document: '${dto.tipoDocumento} ${dto.numeroDocumento}',
      phone: dto.telefono,
      address: dto.direccion,
    );
  }

  @override
  Future<AppUser?> userById(int userId) async {
    try {
      return _toAppUser(await _people.user(userId));
    } on NotFoundFailure {
      return null;
    }
  }

  /// Full student card: identity, course, code and guardians. Assembled from
  /// four endpoints because no single one carries all of it.
  @override
  Future<AppUser?> studentProfile(int studentId) async {
    final EstudianteDto student;
    try {
      student = await _people.student(studentId);
    } on NotFoundFailure {
      return null;
    }

    final catalogs = await _catalogs.load();
    final course =
        student.idCursoActual == null ? null : catalogs.courses[student.idCursoActual];

    UsuarioDto? user;
    try {
      user = await _people.user(student.idUsuario);
    } on AppFailure {
      user = null;
    }

    return AppUser(
      userId: student.idUsuario,
      name: (user?.nombreCompleto.isNotEmpty ?? false)
          ? user!.nombreCompleto
          : student.nombreCompleto,
      email: user?.correo ?? '',
      role: Role.student,
      status: student.activo ? AccountStatus.active : AccountStatus.inactive,
      photoUrl: user?.fotoPerfil,
      grade: course?.name,
      jornada: course?.shiftLabel,
      code: student.codigoEstudiante,
      document:
          user == null ? null : '${user.tipoDocumento} ${user.numeroDocumento}',
      phone: user?.telefono,
      address: user?.direccion,
      guardians: await guardiansOf(studentId),
      studentId: student.idEstudiante,
      courseId: student.idCursoActual,
    );
  }

  /// `/padres` has no `id_estudiante` filter, so the link is resolved by
  /// paging the (small) guardian list once.
  @override
  Future<List<Guardian>> guardiansOf(int studentId) async {
    try {
      final result = <Guardian>[];
      for (var skip = 0; skip < 2000; skip += ApiConfig.catalogPageSize) {
        final page =
            await _people.guardians(skip: skip, limit: ApiConfig.catalogPageSize);
        for (final link in page) {
          if (link.idEstudiante != studentId) continue;
          UsuarioDto? user;
          try {
            user = await _people.user(link.idUsuario);
          } on AppFailure {
            user = null;
          }
          result.add(Guardian(
            name: user?.nombreCompleto ?? 'Acudiente ${link.idPadre}',
            relation: link.parentesco,
            phone: user?.telefono ?? '—',
          ));
        }
        if (page.length < ApiConfig.catalogPageSize) break;
      }
      return result;
    } on AppFailure {
      return const [];
    }
  }

  /// Full teacher card, with specializations and the courses they teach.
  @override
  Future<AppUser?> teacherProfile(int teacherId) async {
    final ProfesorDto teacher;
    try {
      teacher = await _people.teacher(teacherId);
    } on NotFoundFailure {
      return null;
    }

    UsuarioDto? user;
    try {
      user = await _people.user(teacher.idUsuario);
    } on AppFailure {
      user = null;
    }

    List<EspecializacionDto> specialities;
    try {
      specialities = await _people.specialitiesOfTeacher(teacherId);
    } on AppFailure {
      specialities = const [];
    }

    return AppUser(
      userId: teacher.idUsuario,
      name: (user?.nombreCompleto.isNotEmpty ?? false)
          ? user!.nombreCompleto
          : teacher.nombreCompleto,
      email: user?.correo ?? '',
      role: Role.teacher,
      status: teacher.estado.toLowerCase() == 'activo'
          ? AccountStatus.active
          : AccountStatus.inactive,
      photoUrl: user?.fotoPerfil,
      code: teacher.codigoProfesor,
      subject: specialities.isEmpty
          ? teacher.titulo
          : specialities.map((e) => e.nombre).join(' · '),
      institution: teacher.nivelEstudios,
      document:
          user == null ? null : '${user.tipoDocumento} ${user.numeroDocumento}',
      phone: user?.telefono,
      address: user?.direccion,
      teacherId: teacher.idProfesor,
    );
  }

  @override
  Future<List<String>> coursesOfTeacher(int teacherId) async {
    final catalogs = await _catalogs.load();
    final assignments = await _academic.assignments(teacherId: teacherId, active: true);
    final names = assignments
        .map((a) =>
            '${catalogs.subjectName(a.subjectId)} · ${catalogs.courseName(a.courseId)}')
        .toSet()
        .toList();
    names.sort();
    return names;
  }

  /// Directory tab for students: served from the local catalog so it works
  /// with no signal and filters by code as well as by name.
  @override
  Future<List<AppUser>> searchStudents(String query, {int? courseId}) async {
    await _students.ensureReady();
    final catalogs = await _catalogs.load();
    return _students.search(query, courseId: courseId).map((s) {
      final course = s.courseId == null ? null : catalogs.courses[s.courseId];
      return AppUser(
        userId: s.userId,
        name: s.displayName,
        email: '',
        role: Role.student,
        status: s.active ? AccountStatus.active : AccountStatus.inactive,
        grade: course?.name,
        jornada: course?.shiftLabel,
        code: s.code,
        studentId: s.studentId,
        courseId: s.courseId,
      );
    }).toList();
  }

  @override
  Future<List<AppUser>> teachers({
    int skip = 0,
    int limit = ApiConfig.pageSize,
  }) async {
    final rows = await _people.teachers(skip: skip, limit: limit);
    final result = rows
        .map((t) => AppUser(
              userId: t.idUsuario,
              name: t.nombreCompleto.isEmpty ? t.codigoProfesor : t.nombreCompleto,
              email: '',
              role: Role.teacher,
              status: t.estado.toLowerCase() == 'activo'
                  ? AccountStatus.active
                  : AccountStatus.inactive,
              code: t.codigoProfesor,
              subject: t.titulo,
              teacherId: t.idProfesor,
            ))
        .toList();
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  /// Guardians tab of the directory: the acudiente ↔ estudiante link.
  @override
  Future<List<AppUser>> guardians({
    int skip = 0,
    int limit = ApiConfig.pageSize,
  }) async {
    final rows = await _people.guardians(skip: skip, limit: limit);
    final result = <AppUser>[];
    for (final link in rows) {
      UsuarioDto? user;
      try {
        user = await _people.user(link.idUsuario);
      } on AppFailure {
        user = null;
      }
      result.add(AppUser(
        userId: link.idUsuario,
        name: user?.nombreCompleto ?? 'Acudiente ${link.idPadre}',
        email: user?.correo ?? '',
        role: Role.parent,
        status: (user?.estado ?? true) ? AccountStatus.active : AccountStatus.inactive,
        phone: user?.telefono,
        subject: link.nombreEstudiante == null
            ? link.parentesco
            : '${link.parentesco} de ${link.nombreEstudiante}',
        studentId: link.idEstudiante,
      ));
    }
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }
}
