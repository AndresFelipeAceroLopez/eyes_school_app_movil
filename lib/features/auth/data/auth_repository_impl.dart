import 'package:eyes_school/core/storage/token_storage.dart';
import 'package:eyes_school/features/auth/domain/app_user.dart';
import 'package:eyes_school/features/directory/domain/role.dart';
import 'package:eyes_school/features/auth/domain/session.dart';
import 'package:eyes_school/core/errors/app_failure.dart';
import 'package:eyes_school/core/domain/repositories.dart';
import 'package:eyes_school/features/auth/data/auth_api.dart';
import 'package:eyes_school/features/dashboard/data/dashboard_api.dart';
import 'package:eyes_school/features/directory/data/people_api.dart';
import 'package:eyes_school/features/auth/data/auth_dto.dart';
import 'package:eyes_school/features/directory/data/people_dto.dart';

/// Sign-in, sign-up, password recovery and the per-role bootstrap that turns a
/// `MeResponse` into a fully addressed [AppSession].
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this._auth,
    required this._people,
    required this._dashboard,
    required this._catalogs,
    required this._tokens,
  });

  final AuthApi _auth;
  final PeopleApi _people;
  final DashboardApi _dashboard;
  final CatalogRepository _catalogs;
  final TokenStorage _tokens;

  @override
  Future<bool> hasStoredSession() => _tokens.hasSession();

  /// The tokens land in the Keystore before any authenticated call is made.
  @override
  Future<AppSession> signIn({required String email, required String password}) async {
    final pair = await _auth.login(correo: email.trim(), password: password);
    await _tokens.save(accessToken: pair.accessToken, refreshToken: pair.refreshToken);
    return restoreSession();
  }

  /// Called on every cold start: the interceptor refreshes silently if the
  /// access token has expired.
  @override
  Future<AppSession> restoreSession() async {
    final me = await _auth.me();
    final role = roleFromApiId(me.idRol);

    // Warm the catalogs before the first screen paints, so schedules and
    // grades can print names instead of ids.
    await _catalogs.load();

    return switch (role) {
      Role.teacher => _bootstrapTeacher(me),
      Role.student => _bootstrapStudent(me),
      Role.parent => _bootstrapGuardian(me),
      Role.admin => _bootstrapAdmin(me),
    };
  }

  AppUser _userFrom(MeDto me, Role role) {
    return AppUser(
      userId: me.idUsuario,
      name: '${me.primerNombre} ${me.primerApellido}'.trim(),
      email: me.correo ?? '',
      role: role,
      status: me.estado ? AccountStatus.active : AccountStatus.inactive,
    );
  }

  Future<AppSession> _bootstrapTeacher(MeDto me) async {
    final user = _userFrom(me, Role.teacher);
    ProfesorDto? teacher;
    String? warning;
    try {
      teacher = await _people.teacherMe(me.idUsuario);
    } on AppFailure catch (e) {
      warning = e.message;
    }
    if (teacher == null) {
      return AppSession(
        user: user,
        bootstrapWarning: warning ??
            'Tu cuenta no tiene un perfil de docente asociado. '
                'Pide a un administrador que lo cree.',
      );
    }
    return AppSession(
      user: user.copyWith(
        code: teacher.codigoProfesor,
        subject: teacher.titulo,
        teacherId: teacher.idProfesor,
      ),
      teacherId: teacher.idProfesor,
    );
  }

  Future<AppSession> _bootstrapStudent(MeDto me) async {
    final user = _userFrom(me, Role.student);
    EstudianteDto? student;
    String? warning;
    try {
      student = await _people.studentMe();
    } on AppFailure catch (e) {
      warning = e.message;
    }
    if (student == null) {
      return AppSession(
        user: user,
        bootstrapWarning:
            warning ?? 'Tu cuenta no tiene un perfil de estudiante asociado.',
      );
    }

    final catalogs = await _catalogs.load();
    final course =
        student.idCursoActual == null ? null : catalogs.courses[student.idCursoActual];

    // The dashboard is the only place that reports the running period.
    int? period;
    double? average;
    double? attendance;
    try {
      final summary = await _dashboard.student();
      period = summary.currentPeriod;
      average = summary.average;
      attendance = summary.attendancePercent;
    } on AppFailure {
      // Not fatal: the home screen shows its own error state.
    }

    return AppSession(
      user: user.copyWith(
        code: student.codigoEstudiante,
        grade: course?.name,
        jornada: course?.shiftLabel,
        studentId: student.idEstudiante,
        courseId: student.idCursoActual,
        average: average,
        attendancePercent: attendance,
      ),
      studentId: student.idEstudiante,
      studentCode: student.codigoEstudiante,
      courseId: student.idCursoActual,
      currentPeriod: period,
    );
  }

  Future<AppSession> _bootstrapGuardian(MeDto me) async {
    final user = _userFrom(me, Role.parent);
    PadreDto? link;
    String? warning;
    try {
      link = await _people.guardianMe();
    } on AppFailure catch (e) {
      warning = e.message;
    }
    if (link == null) {
      return AppSession(
        user: user,
        bootstrapWarning:
            warning ?? 'Tu cuenta de acudiente aún no está vinculada a un estudiante.',
      );
    }

    int? period;
    try {
      period = (await _dashboard.guardian()).currentPeriod;
    } on AppFailure {
      period = null;
    }

    // The child's course drives the schedule tab.
    int? courseId;
    try {
      courseId = (await _people.student(link.idEstudiante)).idCursoActual;
    } on AppFailure {
      courseId = null;
    }

    return AppSession(
      user: user,
      parentId: link.idPadre,
      childId: link.idEstudiante,
      childName: link.nombreEstudiante,
      childDocument: link.documentoEstudiante,
      relationship: link.parentesco,
      courseId: courseId,
      currentPeriod: period,
    );
  }

  Future<AppSession> _bootstrapAdmin(MeDto me) async {
    final user = _userFrom(me, Role.admin);
    AdministradorDto? admin;
    try {
      admin = await _people.adminOfUser(me.idUsuario);
    } on AppFailure {
      admin = null;
    }
    return AppSession(
      user: user.copyWith(subject: admin?.cargo, institution: admin?.nivelAcceso),
    );
  }

  /// Completes the signed-in user with the `UsuarioOut` fields (phone,
  /// address, document) that `/auth/me` does not carry.
  @override
  Future<AppUser> loadFullProfile(AppUser user) async {
    final dto = await _people.user(user.userId);
    return user.copyWith(
      name: dto.nombreCompleto,
      email: dto.correo ?? user.email,
      photoUrl: dto.fotoPerfil,
      phone: dto.telefono,
      address: dto.direccion,
      document: '${dto.tipoDocumento} ${dto.numeroDocumento}',
    );
  }

  @override
  Future<void> updateProfile({
    required int userId,
    String? phone,
    String? address,
    String? email,
  }) {
    return _people.updateUser(userId, phone: phone, address: address, email: email);
  }

  @override
  Future<void> changePassword({required int userId, required String password}) =>
      _people.updateUser(userId, password: password);

  @override
  Future<void> uploadAvatar(String filePath) => _auth.uploadAvatar(filePath);

  @override
  Future<List<RoleOption>> availableRoles() async {
    final roles = await _auth.roles();
    return roles.map((r) => RoleOption(id: r.idRol, name: r.nombreRol)).toList();
  }

  @override
  Future<void> register(RegistrationRequest request) =>
      _auth.register(RegisterPayload.from(request));

  /// Neutral by design: the API never reveals whether the address exists.
  @override
  Future<void> requestPasswordReset(String email) => _auth.forgotPassword(email.trim());

  @override
  Future<void> resetPassword({required String token, required String newPassword}) =>
      _auth.resetPassword(token: token, newPassword: newPassword);

  /// Clears local state whatever the server answers — a failed sign-out must
  /// never leave the user stuck in a session they asked to end.
  @override
  Future<void> signOut() async {
    final refresh = await _tokens.readRefreshToken();
    if (refresh != null) {
      try {
        await _auth.logout(refresh);
      } on AppFailure {
        // Ignored on purpose.
      }
    }
    await _tokens.clear();
    _catalogs.invalidate();
  }
}
