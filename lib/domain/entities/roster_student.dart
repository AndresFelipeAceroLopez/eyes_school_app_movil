/// One row of a class list.
class RosterStudent {
  const RosterStudent({
    required this.id,
    required this.name,
    this.code,
    this.courseId,
  });

  /// `id_estudiante`.
  final int id;
  final String name;

  /// `codigo_estudiante` — what the QR encodes.
  final String? code;
  final int? courseId;
}
