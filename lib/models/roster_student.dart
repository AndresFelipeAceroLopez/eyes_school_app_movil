enum AttendanceMark { present, absent, late }

class RosterStudent {
  const RosterStudent({required this.id, required this.name});

  final String id;
  final String name;
}
