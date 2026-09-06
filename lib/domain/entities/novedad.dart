import '../value_objects/severity.dart';

/// A disciplinary or academic note about a student.
class Novedad {
  const Novedad({
    required this.studentName,
    required this.title,
    required this.severity,
    this.novedadId,
    this.studentId,
    this.typeId,
    this.description,
    this.action,
    this.date,
    this.status = NovedadStatus.pending,
  });

  final String studentName;

  /// The type's name, e.g. `"Llegada tarde"`.
  final String title;
  final NovedadSeverity severity;

  final int? novedadId;
  final int? studentId;
  final int? typeId;
  final String? description;
  final String? action;
  final DateTime? date;
  final NovedadStatus status;

  bool get resolved => status == NovedadStatus.done;

  Novedad withStudentName(String name) => Novedad(
        studentName: name,
        title: title,
        severity: severity,
        novedadId: novedadId,
        studentId: studentId,
        typeId: typeId,
        description: description,
        action: action,
        date: date,
        status: status,
      );
}

/// An entry of the `/tipos-novedad` catalog. The severity of a novedad is a
/// property of its type: the institution configures it, a teacher does not
/// choose it per case.
class NovedadType {
  const NovedadType({
    required this.id,
    required this.name,
    required this.severity,
    required this.requiresAction,
    required this.active,
    this.description,
  });

  final int id;
  final String name;
  final NovedadSeverity severity;
  final bool requiresAction;
  final bool active;
  final String? description;
}
