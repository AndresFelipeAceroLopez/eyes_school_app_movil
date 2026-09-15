import 'package:eyes_school/features/directory/domain/role.dart';
import 'app_user.dart';

/// Everything resolved by the post-login bootstrap (§5.4 of the plan):
/// `/auth/me` first, then the role profile that gives the app the ids every
/// later request needs.
class AppSession {
  const AppSession({
    required this.user,
    this.teacherId,
    this.studentId,
    this.studentCode,
    this.courseId,
    this.parentId,
    this.childId,
    this.childName,
    this.childDocument,
    this.relationship,
    this.currentPeriod,
    this.bootstrapWarning,
  });

  final AppUser user;

  /// Docente: `id_profesor` from `/profesores/me`.
  final int? teacherId;

  /// Estudiante: `/estudiantes/me`.
  final int? studentId;
  final String? studentCode;
  final int? courseId;

  /// Padre: `/padres/me`.
  final int? parentId;

  /// The linked child. Modelled as an "active child" from day one so that
  /// supporting several children later is additive (§11.1): every screen
  /// already queries by [childId], not by "the child".
  final int? childId;
  final String? childName;
  final String? childDocument;
  final String? relationship;

  /// `periodo_actual` as reported by the student/parent dashboard. There is no
  /// `/periodos` endpoint (backend gap #4).
  final int? currentPeriod;

  /// Set when the role profile could not be resolved (for example a teacher
  /// account with no `ProfesorOut` row). The shell still opens, but the
  /// screens that need the id show it instead of failing silently.
  final String? bootstrapWarning;

  Role get role => user.role;

  /// The student every query in this session is about: the student themself,
  /// or the guardian's child.
  int? get subjectStudentId => switch (role) {
        Role.student => studentId,
        Role.parent => childId,
        _ => null,
      };

  AppSession copyWith({
    AppUser? user,
    int? currentPeriod,
    String? childName,
  }) {
    return AppSession(
      user: user ?? this.user,
      teacherId: teacherId,
      studentId: studentId,
      studentCode: studentCode,
      courseId: courseId,
      parentId: parentId,
      childId: childId,
      childName: childName ?? this.childName,
      childDocument: childDocument,
      relationship: relationship,
      currentPeriod: currentPeriod ?? this.currentPeriod,
      bootstrapWarning: bootstrapWarning,
    );
  }
}
