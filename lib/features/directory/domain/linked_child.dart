/// A student linked to the signed-in guardian (`/padres/me/hijos`, APP-03).
/// A guardian can have several; the session keeps one of them active.
class LinkedChild {
  const LinkedChild({
    required this.id,
    required this.name,
    this.document,
    this.relationship,
    this.courseId,
  });

  final int id;

  /// `nombre_estudiante`, resolved by the API. It is the name the guardian is
  /// allowed to see: `/usuarios/{id}` answers 403 to a guardian (N-05).
  final String name;
  final String? document;
  final String? relationship;
  final int? courseId;
}
