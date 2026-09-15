import 'package:eyes_school/features/directory/domain/guardian.dart';
import 'package:eyes_school/features/directory/domain/role.dart';

enum AccountStatus { active, inactive }

/// A person as the UI needs them, assembled from `MeResponse` / `UsuarioOut`
/// plus the role profile (`EstudianteOut`, `ProfesorOut`, `PadreOut`).
/// The presentation layer never sees a DTO.
class AppUser {
  const AppUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.status = AccountStatus.active,
    this.photoUrl,
    this.subject,
    this.institution,
    this.grade,
    this.jornada,
    this.code,
    this.document,
    this.phone,
    this.address,
    this.average,
    this.attendancePercent,
    this.guardians = const [],
    this.studentId,
    this.teacherId,
    this.courseId,
  });

  /// `id_usuario`. Kept as an int because every API path is typed.
  final int userId;
  final String name;
  final String email;
  final Role role;
  final AccountStatus status;
  final String? photoUrl;

  // Teacher / Admin
  final String? subject;
  final String? institution;

  // Student
  final String? grade;
  final String? jornada;

  /// `codigo_estudiante` for students, `codigo_profesor` for teachers. This is
  /// exactly what the QR encodes.
  final String? code;
  final String? document;
  final String? phone;
  final String? address;
  final double? average;
  final double? attendancePercent;
  final List<Guardian> guardians;

  /// Role profile ids, present only for the matching role.
  final int? studentId;
  final int? teacherId;
  final int? courseId;

  /// String form used by the router's path params.
  String get id => userId.toString();

  String get firstName => name.trim().isEmpty ? '' : name.trim().split(' ').first;

  bool get isActive => status == AccountStatus.active;

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? photoUrl,
    String? document,
    String? grade,
    String? jornada,
    String? code,
    String? subject,
    String? institution,
    double? average,
    double? attendancePercent,
    List<Guardian>? guardians,
    int? studentId,
    int? teacherId,
    int? courseId,
  }) {
    return AppUser(
      userId: userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role,
      status: status,
      photoUrl: photoUrl ?? this.photoUrl,
      subject: subject ?? this.subject,
      institution: institution ?? this.institution,
      grade: grade ?? this.grade,
      jornada: jornada ?? this.jornada,
      code: code ?? this.code,
      document: document ?? this.document,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      average: average ?? this.average,
      attendancePercent: attendancePercent ?? this.attendancePercent,
      guardians: guardians ?? this.guardians,
      studentId: studentId ?? this.studentId,
      teacherId: teacherId ?? this.teacherId,
      courseId: courseId ?? this.courseId,
    );
  }
}
