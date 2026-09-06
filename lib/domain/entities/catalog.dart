/// The academic catalogs, as the app understands them.
///
/// `HorarioOut`, `NotaOut` and `NovedadOut` carry only foreign keys, so almost
/// every screen needs these to print a name instead of an id. They change
/// rarely, which is what makes caching them per session correct rather than
/// merely convenient.
library;

import '../value_objects/severity.dart';
import 'novedad.dart';

class Course {
  const Course({
    required this.id,
    required this.name,
    required this.grade,
    required this.shift,
    required this.year,
    required this.active,
    this.area,
  });

  final int id;
  final String name;
  final String grade;

  /// Normalized: the API stores `"mañana"`, `"manana"` or even `"1"`.
  final SchoolShift shift;
  final int year;
  final bool active;
  final String? area;

  String get shiftLabel => shift.label;
}

enum SchoolShift {
  morning('Mañana', {'mañana', 'manana', '1'}),
  afternoon('Tarde', {'tarde', '2'}),
  single('Única', {'unica', 'única', '3'}),
  unknown('—', {});

  const SchoolShift(this.label, this._wireValues);

  final String label;
  final Set<String> _wireValues;

  static SchoolShift parse(String? value) {
    final normalized = (value ?? '').toLowerCase().trim();
    for (final shift in values) {
      if (shift._wireValues.contains(normalized)) return shift;
    }
    return SchoolShift.unknown;
  }

  static List<SchoolShift> get selectable =>
      const [SchoolShift.morning, SchoolShift.afternoon, SchoolShift.single];
}

class CourseSubject {
  const CourseSubject({
    required this.id,
    required this.name,
    required this.code,
    required this.active,
  });

  final int id;
  final String name;
  final String code;
  final bool active;
}

/// Courses, subjects and news types resolved together, so a join never needs
/// a round trip.
class Catalogs {
  const Catalogs({
    required this.courses,
    required this.subjects,
    required this.novedadTypes,
  });

  static const empty = Catalogs(courses: {}, subjects: {}, novedadTypes: {});

  final Map<int, Course> courses;
  final Map<int, CourseSubject> subjects;
  final Map<int, NovedadType> novedadTypes;

  String courseName(int? id) => id == null ? '—' : courses[id]?.name ?? 'Curso $id';

  String subjectName(int? id) => id == null ? '—' : subjects[id]?.name ?? 'Materia $id';

  String novedadTypeName(int? id) =>
      id == null ? 'Novedad' : novedadTypes[id]?.name ?? 'Novedad';

  NovedadSeverity severityOf(int? typeId) =>
      novedadTypes[typeId]?.severity ?? NovedadSeverity.low;

  List<Course> get activeCourses {
    final list = courses.values.where((c) => c.active).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  List<NovedadType> get activeNovedadTypes {
    final list = novedadTypes.values.where((t) => t.active).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }
}
