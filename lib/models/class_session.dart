enum ClassStatus { upcoming, inCourse, done }

class ClassSession {
  const ClassSession({
    required this.time,
    required this.subject,
    required this.group,
    required this.room,
    required this.status,
    this.day,
  });

  final String time;
  final String subject;
  final String group;
  final String room;
  final ClassStatus status;

  /// Day of the week label (e.g. "Lunes"), used by weekly schedule views.
  final String? day;
}
