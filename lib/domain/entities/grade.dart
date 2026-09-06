import '../value_objects/severity.dart';

/// A grade a teacher registered for a student, in a subject, in a period.
///
/// The domain owns the 0.0–5.0 scale; how a score is coloured is a
/// presentation concern and lives there.
class Grade {
  const Grade({
    required this.subject,
    required this.score,
    required this.period,
    this.gradeId,
    this.studentId,
    this.subjectId,
    this.periodId,
    this.observation,
  });

  final String subject;
  final double score;

  /// Display label, e.g. `"Periodo 2"`.
  final String period;

  final int? gradeId;
  final int? studentId;
  final int? subjectId;
  final int? periodId;
  final String? observation;

  String get qualitative => GradeScale.qualitativeOf(score);

  /// 0..1, for progress bars.
  double get progress => GradeScale.progressOf(score);

  bool get passing => score >= GradeScale.passing;

  /// Averages several grades of the same subject into the single line a
  /// student thinks of as "mi nota de Matemáticas".
  static List<Grade> averageBySubject(List<Grade> grades) {
    final bySubject = <String, List<Grade>>{};
    for (final grade in grades) {
      bySubject.putIfAbsent(grade.subject, () => []).add(grade);
    }
    final result = bySubject.entries.map((entry) {
      final rows = entry.value;
      if (rows.length == 1) return rows.first;
      final average = rows.fold<double>(0, (sum, g) => sum + g.score) / rows.length;
      return Grade(
        subject: entry.key,
        score: average,
        period: rows.first.period,
        studentId: rows.first.studentId,
        subjectId: rows.first.subjectId,
        periodId: rows.first.periodId,
      );
    }).toList();
    result.sort((a, b) => a.subject.compareTo(b.subject));
    return result;
  }

  static double overallAverage(List<Grade> grades) {
    if (grades.isEmpty) return 0;
    final rows = averageBySubject(grades);
    return rows.fold<double>(0, (sum, g) => sum + g.score) / rows.length;
  }
}
