import '../entities/app_user.dart';
import '../entities/attendance_record.dart';
import '../entities/attendance_summary.dart';
import '../entities/catalog.dart';
import '../entities/class_session.dart';
import '../entities/dashboard.dart';
import '../entities/grade.dart';
import '../entities/guardian.dart';
import '../entities/novedad.dart';
import '../entities/roster_student.dart';
import '../entities/session.dart';
import '../entities/subject.dart';
import '../entities/teacher_class.dart';
import '../value_objects/attendance.dart';
import '../value_objects/severity.dart';

/// The contracts the application layer depends on.
///
/// They live in the domain and are implemented in `data`, so the direction of
/// dependency points inward: nothing here knows about Dio, JSON or a database.
/// Every method may throw an `AppFailure`.

// ── Sesión ────────────────────────────────────────────────────────────────

abstract interface class AuthRepository {
  /// True when there are stored tokens worth trying on a cold start.
  Future<bool> hasStoredSession();

  /// Signs in and resolves the role profile in one step.
  Future<AppSession> signIn({required String email, required String password});

  /// Rebuilds the session from the stored tokens.
  Future<AppSession> restoreSession();

  Future<void> signOut();

  Future<void> register(RegistrationRequest request);

  /// Neutral by design: it never reveals whether the address exists.
  Future<void> requestPasswordReset(String email);

  Future<void> resetPassword({required String token, required String newPassword});

  /// Completes a user with the fields `/auth/me` does not carry.
  Future<AppUser> loadFullProfile(AppUser user);

  Future<void> updateProfile({
    required int userId,
    String? phone,
    String? address,
    String? email,
  });

  Future<void> changePassword({required int userId, required String password});

  Future<void> uploadAvatar(String filePath);

  Future<List<RoleOption>> availableRoles();
}

/// The sign-up payload: one request creates the user and its role profile.
class RegistrationRequest {
  const RegistrationRequest({
    required this.documentType,
    required this.documentNumber,
    required this.firstName,
    required this.lastName,
    required this.roleId,
    this.middleName,
    this.secondLastName,
    this.gender,
    this.address,
    this.email,
    this.password,
    this.phone,
    this.position,
    this.courseId,
    this.linkedStudentId,
    this.relationship,
    this.title,
    this.studyLevel,
  });

  final String documentType;
  final String documentNumber;
  final String firstName;
  final String lastName;
  final int roleId;
  final String? middleName;
  final String? secondLastName;
  final String? gender;
  final String? address;
  final String? email;
  final String? password;
  final String? phone;
  final String? position;
  final int? courseId;
  final int? linkedStudentId;
  final String? relationship;
  final String? title;
  final String? studyLevel;
}

class RoleOption {
  const RoleOption({required this.id, required this.name});

  final int id;
  final String name;
}

// ── Catálogos ─────────────────────────────────────────────────────────────

abstract interface class CatalogRepository {
  /// Courses, subjects and news types. Cached for the session.
  Future<Catalogs> load({bool force = false});

  void invalidate();
}

// ── Académico ─────────────────────────────────────────────────────────────

abstract interface class AcademicRepository {
  Future<TeacherDashboard> teacherDashboard();
  Future<StudentDashboard> studentDashboard();
  Future<GuardianDashboard> guardianDashboard();

  /// Weekly grid of a course.
  Future<List<ClassSession>> courseSchedule(int courseId);

  /// The teacher's own grid: the union of the courses they are assigned to.
  Future<List<ClassSession>> teacherSchedule(int teacherId);

  /// Active assignments — the unit that scopes everything a teacher may write.
  Future<List<TeacherClass>> teacherClasses(int teacherId);
  Future<TeacherClass?> teacherClass(int assignmentId);

  Future<List<RosterStudent>> roster(int courseId);

  Future<List<Grade>> gradesForStudent(int studentId, {int? period, int? subjectId});
  Future<List<Grade>> gradeSheet({required int subjectId, required int period});

  /// Creates the grade, or updates it when [gradeId] is known.
  Future<void> saveGrade({
    required int studentId,
    required int subjectId,
    required int period,
    required double score,
    required int registeredBy,
    int? gradeId,
    String? observation,
  });

  Future<void> deleteGrade(int gradeId);

  Future<void> downloadReportCard({
    required int studentId,
    required String savePath,
    void Function(int received, int total)? onProgress,
  });

  /// Paged history: the API gives no totals, so `page.length == limit` is the
  /// only "there is more" signal there is.
  Future<List<AttendanceRecord>> attendanceHistory(
    int studentId, {
    int skip,
    int limit,
  });

  Future<AttendanceSummary> attendanceSummary(int studentId, {int sample});

  Future<List<Novedad>> novedades({
    int? studentId,
    NovedadStatus? status,
    int skip,
    int limit,
  });

  Future<List<Novedad>> novedadesForStudent(int studentId);

  Future<void> createNovedad({
    required int studentId,
    required int typeId,
    required DateTime date,
    required String description,
    required int registeredBy,
    String? action,
  });

  Future<void> resolveNovedad(int novedadId, {String? action});

  Future<void> reopenNovedad(int novedadId);

  Future<List<Subject>> subjects();
  Future<List<Course>> courses({bool onlyActive});
  Future<List<NovedadType>> novedadTypes();
}

// ── Asistencia (escritura) ────────────────────────────────────────────────

abstract interface class AttendanceRepository {
  /// Loads the local student catalog that resolves scanned codes.
  Future<void> warmUp({bool force});

  /// Resolves a scanned QR. The code is plain text: the `codigo_estudiante`.
  Future<ScanResult> resolve(String rawCode, {AttendanceKind? kind, DateTime? now});

  /// `Tarde` after the entry cutoff, `Presente` otherwise.
  AttendanceState suggestedState({AttendanceKind? kind, DateTime? now});

  /// Records one event. `false` means the queue already had this student for
  /// the same day and kind.
  Future<bool> record({
    required int studentId,
    required String studentName,
    required AttendanceState state,
    required AttendanceKind kind,
    required int registeredBy,
    DateTime? date,
    String? qrCode,
    String? observation,
  });

  /// A whole course at once. Everything is queued first, so the user's work is
  /// safe the moment they tap send.
  Future<BulkAttendanceResult> recordBulk({
    required Map<int, AttendanceMark> marks,
    required Map<int, String> names,
    required AttendanceKind kind,
    required int registeredBy,
    required DateTime date,
    Map<int, String>? observations,
    void Function(int done, int total)? onProgress,
  });

  Future<List<AttendanceRecord>> registeredOn(DateTime date, {AttendanceKind? kind});

  Future<void> correct(int attendanceId, {AttendanceState? state, String? observation});

  Future<void> undo(int attendanceId);

  /// Local lookup of a student the catalog already knows.
  StudentIdentity? studentById(int studentId);
  List<StudentIdentity> searchStudents(String query, {int? courseId, int limit});
  int get cachedStudentCount;
  DateTime? get catalogRefreshedAt;
}

sealed class ScanResult {
  const ScanResult();
}

class ScanResolved extends ScanResult {
  const ScanResolved(this.student, this.suggested);

  final StudentIdentity student;
  final AttendanceState suggested;
}

class ScanUnknownCode extends ScanResult {
  const ScanUnknownCode(this.code);

  final String code;
}

class ScanInactiveStudent extends ScanResult {
  const ScanInactiveStudent(this.student);

  final StudentIdentity student;
}

class BulkAttendanceResult {
  const BulkAttendanceResult({required this.queued, required this.duplicates});

  final int queued;
  final int duplicates;

  int get total => queued + duplicates;
}

// ── Directorio ────────────────────────────────────────────────────────────

abstract interface class DirectoryRepository {
  Future<List<AppUser>> searchStudents(String query, {int? courseId});
  Future<List<AppUser>> teachers({int skip, int limit});
  Future<List<AppUser>> guardians({int skip, int limit});

  Future<AppUser?> userById(int userId);
  Future<AppUser?> studentProfile(int studentId);
  Future<AppUser?> teacherProfile(int teacherId);

  Future<List<Guardian>> guardiansOf(int studentId);
  Future<List<String>> coursesOfTeacher(int teacherId);
}

// ── Reportes ──────────────────────────────────────────────────────────────

abstract interface class ReportRepository {
  Future<List<Report>> reports({int skip, int limit});

  Future<void> downloadReport({
    required int reportId,
    required String savePath,
    void Function(int received, int total)? onProgress,
  });
}
