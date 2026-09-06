/// A subject as shown in the admin catalog: `MateriaOut` enriched with the
/// courses it is taught in and how many students that reaches, both derived
/// from `/asignaciones` and `/cursos/{id}/estudiantes`.
class Subject {
  const Subject({
    required this.name,
    required this.teacherName,
    required this.groups,
    required this.studentCount,
    this.subjectId,
    this.code,
  });

  final String name;
  final String teacherName;

  /// Comma-separated course names, e.g. `"10-A, 10-B"`.
  final String groups;
  final int studentCount;
  final int? subjectId;
  final String? code;
}
