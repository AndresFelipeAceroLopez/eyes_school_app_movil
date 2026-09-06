import '../../core/constants/app_constants.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/value_objects/attendance.dart';
import '../../domain/value_objects/class_time.dart';
import '../api/attendance_api.dart';
import '../local/attendance_queue.dart';
import '../local/student_catalog.dart';

/// The write side of attendance: scanning, bulk registration and roll call.
///
/// Every write goes through [AttendanceQueue] so nothing is lost without
/// signal and nothing is sent twice.
class AttendanceRepositoryImpl implements AttendanceRepository {
  AttendanceRepositoryImpl({
    required this._api,
    required this._catalog,
    required this._queue,
  });

  final AttendanceApi _api;
  final StudentCatalog _catalog;
  final AttendanceQueue _queue;

  @override
  Future<void> warmUp({bool force = false}) => _catalog.ensureReady(force: force);

  /// Resolves a scanned QR. The code is plain text: it is the
  /// `codigo_estudiante`, exactly as the web panel encodes it.
  ///
  /// A miss triggers one catalog refresh before giving up, so a student
  /// enrolled this morning still scans this afternoon.
  @override
  Future<ScanResult> resolve(
    String rawCode, {
    AttendanceKind? kind,
    DateTime? now,
  }) async {
    final code = rawCode.trim();
    await _catalog.ensureReady();

    var student = _catalog.byCode(code);
    if (student == null) {
      try {
        await _catalog.ensureReady(force: true);
      } catch (_) {
        // Offline: the on-disk catalog is all there is, and it did not match.
      }
      student = _catalog.byCode(code);
    }
    if (student == null) return ScanUnknownCode(code);
    if (!student.active) return ScanInactiveStudent(student);

    return ScanResolved(student, suggestedState(kind: kind, now: now));
  }

  /// A late arrival is only late on the way *in*.
  @override
  AttendanceState suggestedState({AttendanceKind? kind, DateTime? now}) {
    if (kind != null && kind != AttendanceKind.entry) return AttendanceState.present;
    final minutes = ClassTime.fromDateTime(now ?? DateTime.now()).minutesOfDay;
    return minutes > AppConstants.entryCutoff.minutesOfDay
        ? AttendanceState.late
        : AttendanceState.present;
  }

  @override
  Future<bool> record({
    required int studentId,
    required String studentName,
    required AttendanceState state,
    required AttendanceKind kind,
    required int registeredBy,
    DateTime? date,
    String? qrCode,
    String? observation,
  }) async {
    final outcome = await _queue.enqueue(
      studentId: studentId,
      studentName: studentName,
      date: date ?? DateTime.now(),
      state: state,
      kind: kind,
      registeredBy: registeredBy,
      qrCode: qrCode,
      observation: observation,
    );
    return outcome == EnqueueOutcome.queued;
  }

  /// Bulk registration for a whole course. Everything is queued first — the
  /// user's work is safe the moment they tap send — and the queue drains it,
  /// since the API has no batch endpoint.
  @override
  Future<BulkAttendanceResult> recordBulk({
    required Map<int, AttendanceMark> marks,
    required Map<int, String> names,
    required AttendanceKind kind,
    required int registeredBy,
    required DateTime date,
    Map<int, String>? observations,
    void Function(int done, int total)? onProgress,
  }) async {
    var queued = 0;
    var duplicates = 0;
    final total = marks.length;
    var index = 0;

    for (final entry in marks.entries) {
      final outcome = await _queue.enqueue(
        studentId: entry.key,
        studentName: names[entry.key] ?? 'Estudiante ${entry.key}',
        date: date,
        state: entry.value.state,
        kind: kind,
        registeredBy: registeredBy,
        observation: observations?[entry.key],
      );
      outcome == EnqueueOutcome.queued ? queued++ : duplicates++;
      onProgress?.call(++index, total);
    }

    await _queue.flush();
    return BulkAttendanceResult(queued: queued, duplicates: duplicates);
  }

  /// Records already stored on the server for a date. Course and shift are
  /// filtered by the caller because the endpoint accepts neither.
  @override
  Future<List<AttendanceRecord>> registeredOn(DateTime date, {AttendanceKind? kind}) {
    return _api.list(date: date, kind: kind, limit: 500);
  }

  @override
  Future<void> correct(
    int attendanceId, {
    AttendanceState? state,
    String? observation,
  }) {
    return _api.update(attendanceId, state: state, observation: observation);
  }

  @override
  Future<void> undo(int attendanceId) => _api.delete(attendanceId);

  @override
  StudentIdentity? studentById(int studentId) => _catalog.byId(studentId);

  @override
  List<StudentIdentity> searchStudents(String query, {int? courseId, int limit = 30}) =>
      _catalog.search(query, courseId: courseId, limit: limit);

  @override
  int get cachedStudentCount => _catalog.size;

  @override
  DateTime? get catalogRefreshedAt => _catalog.refreshedAt;

  /// The queue is exposed so the pending screen and the badge can listen to it
  /// directly; it is a `ChangeNotifier`, not a data source the UI writes to.
  AttendanceQueue get queue => _queue;
}
