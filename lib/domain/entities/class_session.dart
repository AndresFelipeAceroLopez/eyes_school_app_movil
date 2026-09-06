import '../value_objects/class_time.dart';

enum ClassStatus { upcoming, inCourse, done }

/// One block of the weekly grid: a subject, in a course, at a time, in a room.
class ClassSession {
  const ClassSession({
    required this.subject,
    required this.group,
    required this.room,
    required this.status,
    this.day,
    this.courseId,
    this.subjectId,
    this.assignmentId,
    this.start,
    this.end,
  });

  final String subject;

  /// Secondary line: the course for a teacher, the room for a student.
  final String group;
  final String room;
  final ClassStatus status;

  /// Day label, e.g. `"Lunes"`. The API writes `Miercoles` without an accent;
  /// [Weekdays.normalize] is what reconciles the two.
  final String? day;

  final int? courseId;
  final int? subjectId;
  final int? assignmentId;
  final ClassTime? start;
  final ClassTime? end;

  /// `"07:00"`, ready for the row.
  String get time => start?.formatted ?? '--:--';

  /// Resolves the block against the wall clock. Only meaningful for today.
  static ClassStatus statusFor(ClassTime? start, ClassTime? end, {DateTime? now}) {
    if (start == null) return ClassStatus.upcoming;
    final minutes = ClassTime.fromDateTime(now ?? DateTime.now()).minutesOfDay;
    final from = start.minutesOfDay;
    // A block with no end time is assumed to last an hour.
    final to = (end ?? start.plusMinutes(60)).minutesOfDay;
    if (minutes < from) return ClassStatus.upcoming;
    if (minutes < to) return ClassStatus.inCourse;
    return ClassStatus.done;
  }

  ClassSession resolvedAt(DateTime now) => ClassSession(
        subject: subject,
        group: group,
        room: room,
        status: statusFor(start, end, now: now),
        day: day,
        courseId: courseId,
        subjectId: subjectId,
        assignmentId: assignmentId,
        start: start,
        end: end,
      );

  /// Minutes from now until the block starts; negative once it has begun.
  int minutesUntilStart({DateTime? now}) {
    final start = this.start;
    if (start == null) return 0;
    return start.minutesOfDay -
        ClassTime.fromDateTime(now ?? DateTime.now()).minutesOfDay;
  }
}

/// The school week, and the reconciliation of how the API spells it.
abstract final class Weekdays {
  static const List<String> school = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
  ];

  static const List<String> _all = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  /// `Miercoles` (as the API writes it) and `miércoles` both become `Miércoles`.
  static String normalize(String day) {
    final plain = day
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
    return switch (plain) {
      'lunes' => 'Lunes',
      'martes' => 'Martes',
      'miercoles' => 'Miércoles',
      'jueves' => 'Jueves',
      'viernes' => 'Viernes',
      'sabado' => 'Sábado',
      'domingo' => 'Domingo',
      _ => day,
    };
  }

  static String labelFor(DateTime date) => _all[(date.weekday - 1).clamp(0, 6)];

  /// Sort key; anything unrecognised goes last.
  static int orderOf(String? day) {
    final index = school.indexOf(day ?? '');
    return index == -1 ? 99 : index;
  }
}
