import 'package:eyes_school/features/directory/domain/linked_child.dart';
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
    this.children = const [],
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

  /// Padre: every linked student (`/padres/me/hijos`, APP-03). The `child*`
  /// fields above describe the active one, which is the first by default.
  final List<LinkedChild> children;

  bool get hasSeveralChildren => children.length > 1;

  /// The active child as a [LinkedChild], when the guardian has any.
  LinkedChild? get activeChild {
    for (final c in children) {
      if (c.id == childId) return c;
    }
    return null;
  }

  /// Same session with another linked child active. Every parent screen reads
  /// [childId], so they all follow the switch.
  AppSession withActiveChild(int id) {
    LinkedChild? child;
    for (final c in children) {
      if (c.id == id) child = c;
    }
    if (child == null) return this;
    return AppSession(
      user: user,
      teacherId: teacherId,
      studentId: studentId,
      studentCode: studentCode,
      courseId: child.courseId,
      parentId: parentId,
      childId: child.id,
      childName: child.name,
      childDocument: child.document,
      relationship: child.relationship,
      currentPeriod: currentPeriod,
      bootstrapWarning: bootstrapWarning,
      children: children,
    );
  }

  Role get role => user.role;

  /// The student every query in this session is about: the student themself,
  /// or the guardian's child.
  int? get subjectStudentId => switch (role) {
    Role.student => studentId,
    Role.parent => childId,
    _ => null,
  };

  AppSession copyWith({AppUser? user, int? currentPeriod, String? childName}) {
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
      children: children,
    );
  }
}
