import '../value_objects/attendance.dart';

/// One attendance entry as stored by the server.
class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.date,
    required this.state,
    required this.registeredBy,
    this.kind,
    this.observation,
    this.qrCode,
    this.registeredAt,
  });

  final int id;
  final int studentId;
  final DateTime date;
  final AttendanceState state;
  final int registeredBy;
  final AttendanceKind? kind;
  final String? observation;
  final String? qrCode;
  final DateTime? registeredAt;
}

/// One attendance entry captured on the device and not yet acknowledged.
///
/// Written to disk before the network is touched, so the UI never waits on the
/// server and a kill mid-shift loses nothing.
class PendingAttendance {
  const PendingAttendance({
    required this.localId,
    required this.studentId,
    required this.studentName,
    required this.date,
    required this.state,
    required this.kind,
    required this.registeredBy,
    required this.createdAt,
    this.qrCode,
    this.observation,
    this.attempts = 0,
    this.lastError,
    this.sync = SyncState.pending,
    this.remoteId,
    this.nextAttemptAt,
  });

  final int localId;
  final int studentId;

  /// Denormalized so the pending list reads correctly with no network.
  final String studentName;

  /// The date of the **scan**, never of the upload: a Friday scan that syncs
  /// on Monday is still a Friday record.
  final DateTime date;
  final AttendanceState state;
  final AttendanceKind kind;
  final int registeredBy;
  final DateTime createdAt;

  /// The raw scanned text, kept as evidence of what the device read.
  final String? qrCode;
  final String? observation;
  final int attempts;
  final String? lastError;
  final SyncState sync;
  final int? remoteId;
  final DateTime? nextAttemptAt;

  bool get isSettled => sync == SyncState.sent || sync == SyncState.duplicate;
  bool get isWaiting => sync == SyncState.pending || sync == SyncState.sending;

  /// The natural key used to deduplicate. The API has no idempotency key, so
  /// the client refuses to send the same student twice for the same day and
  /// kind.
  String get dedupeKey =>
      '$studentId|${date.year}-${date.month}-${date.day}|${kind.wire}';

  PendingAttendance copyWith({
    SyncState? sync,
    int? attempts,
    String? lastError,
    bool clearError = false,
    int? remoteId,
    DateTime? nextAttemptAt,
    bool clearNextAttempt = false,
    AttendanceState? state,
    AttendanceKind? kind,
    String? observation,
  }) {
    return PendingAttendance(
      localId: localId,
      studentId: studentId,
      studentName: studentName,
      date: date,
      state: state ?? this.state,
      kind: kind ?? this.kind,
      registeredBy: registeredBy,
      createdAt: createdAt,
      qrCode: qrCode,
      observation: observation ?? this.observation,
      attempts: attempts ?? this.attempts,
      lastError: clearError ? null : (lastError ?? this.lastError),
      sync: sync ?? this.sync,
      remoteId: remoteId ?? this.remoteId,
      nextAttemptAt: clearNextAttempt ? null : (nextAttemptAt ?? this.nextAttemptAt),
    );
  }
}

/// A student as the QR catalog knows them: the minimum needed to turn a
/// scanned code into a record.
class StudentIdentity {
  const StudentIdentity({
    required this.studentId,
    required this.userId,
    required this.code,
    required this.status,
    this.courseId,
    this.firstName,
    this.lastName,
  });

  final int studentId;
  final int userId;

  /// `codigo_estudiante` — exactly what the QR encodes.
  final String code;
  final String status;
  final int? courseId;
  final String? firstName;
  final String? lastName;

  bool get active => status.toLowerCase() == 'activo';

  String get fullName => [firstName, lastName]
      .where((p) => p != null && p.trim().isNotEmpty)
      .map((p) => p!.trim())
      .join(' ');

  /// What to show when the API did not send the names.
  String get displayName => fullName.isEmpty ? code : fullName;
}
