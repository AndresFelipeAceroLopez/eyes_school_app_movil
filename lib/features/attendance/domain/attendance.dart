/// Attendance vocabulary, owned by the domain.
///
/// The wire spellings live here because they are institutional facts, not
/// transport details: `Suspensión` carries an accent and an initial capital,
/// and getting that wrong is a rejected record, not a cosmetic bug.
library;

enum AttendanceState {
  present('Presente'),
  absent('Ausente'),
  late('Tarde'),
  excused('Excusa'),
  suspended('Suspensión');

  const AttendanceState(this.label);

  /// Also the value the API expects.
  final String label;

  static AttendanceState parse(String? value) {
    final normalized = (value ?? '').toLowerCase().trim();
    for (final state in values) {
      if (state.label.toLowerCase() == normalized || state.name == normalized) {
        return state;
      }
    }
    // The web panel has historically written "Suspension" without the accent.
    if (normalized.startsWith('suspens')) return AttendanceState.suspended;
    return AttendanceState.present;
  }

  /// A late arrival still counts as attending; an excused absence does not
  /// count as a presence but is not a fault either. This is how the web panel
  /// reports the percentage.
  bool get countsAsAttendance =>
      this == AttendanceState.present || this == AttendanceState.late;
}

enum AttendanceKind {
  entry('entrada', 'Entrada'),
  exit('salida', 'Salida'),
  classroom('clase', 'Clase');

  const AttendanceKind(this.wire, this.label);

  final String wire;
  final String label;

  static AttendanceKind parse(String? value) {
    final normalized = (value ?? '').toLowerCase().trim();
    return values.firstWhere(
      (kind) => kind.wire == normalized,
      orElse: () => AttendanceKind.entry,
    );
  }
}

/// How a student is marked during roll call — the subset of [AttendanceState]
/// a teacher picks from a row of chips.
enum AttendanceMark {
  present,
  late,
  absent,
  excused;

  String get label => state.label;

  AttendanceState get state => switch (this) {
        AttendanceMark.present => AttendanceState.present,
        AttendanceMark.late => AttendanceState.late,
        AttendanceMark.absent => AttendanceState.absent,
        AttendanceMark.excused => AttendanceState.excused,
      };
}

/// Whether a record still owes something to the server.
enum SyncState { pending, sending, sent, failed, duplicate }
