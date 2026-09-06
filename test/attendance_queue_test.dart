import 'package:eyes_school/core/storage/local_store.dart';
import 'package:eyes_school/data/api/attendance_api.dart';
import 'package:eyes_school/data/local/attendance_queue.dart';
import 'package:eyes_school/domain/entities/attendance_record.dart';
import 'package:eyes_school/domain/failures/app_failure.dart';
import 'package:eyes_school/domain/value_objects/attendance.dart';
import 'package:flutter_test/flutter_test.dart';

/// The offline queue is the part of the app where a bug loses real work, so it
/// is the part that gets tested. The field test the plan asks for is the
/// "30 escaneos" case below: 30 scans offline, network back, 30 records on the
/// server — not 29, not 31.
void main() {
  late _FakeStore store;

  setUp(() => store = _FakeStore());

  AttendanceQueue queueWith(_FakeAttendanceApi api) =>
      AttendanceQueue(api: api, store: store);

  Future<EnqueueOutcome> enqueue(
    AttendanceQueue queue, {
    required int studentId,
    DateTime? date,
    AttendanceKind kind = AttendanceKind.entry,
    AttendanceState state = AttendanceState.present,
  }) {
    return queue.enqueue(
      studentId: studentId,
      studentName: 'Estudiante $studentId',
      date: date ?? DateTime(2026, 9, 6),
      state: state,
      kind: kind,
      registeredBy: 7,
    );
  }

  test('un escaneo se envía una sola vez', () async {
    final api = _FakeAttendanceApi();
    final queue = queueWith(api);

    final outcome = await enqueue(queue, studentId: 1);
    await queue.flush();

    expect(outcome, EnqueueOutcome.queued);
    expect(api.created, hasLength(1));
    expect(api.created.single.studentId, 1);
    expect(queue.pendingCount, 0);
  });

  test('el mismo estudiante, día y tipo no se encola dos veces', () async {
    final api = _FakeAttendanceApi();
    final queue = queueWith(api);

    await enqueue(queue, studentId: 1);
    final second = await enqueue(queue, studentId: 1);
    await queue.flush();

    expect(second, EnqueueOutcome.duplicate);
    expect(api.created, hasLength(1));
  });

  test('entrada y salida del mismo estudiante son registros distintos', () async {
    final api = _FakeAttendanceApi();
    final queue = queueWith(api);

    await enqueue(queue, studentId: 1);
    final exit = await enqueue(queue, studentId: 1, kind: AttendanceKind.exit);
    await queue.flush();

    expect(exit, EnqueueOutcome.queued);
    expect(api.created, hasLength(2));
  });

  test('el mismo estudiante en días distintos sí se registra', () async {
    final api = _FakeAttendanceApi();
    final queue = queueWith(api);

    await enqueue(queue, studentId: 1, date: DateTime(2026, 9, 6));
    final otherDay = await enqueue(queue, studentId: 1, date: DateTime(2026, 9, 7));
    await queue.flush();

    expect(otherDay, EnqueueOutcome.queued);
    expect(api.created, hasLength(2));
  });

  test('30 escaneos sin red producen exactamente 30 registros al recuperarla',
      () async {
    final api = _FakeAttendanceApi(offline: true);
    final queue = queueWith(api);

    for (var i = 1; i <= 30; i++) {
      await enqueue(queue, studentId: i);
    }

    // Sin red: nada llegó al servidor, pero nada se perdió tampoco.
    expect(api.created, isEmpty);
    expect(queue.pendingCount, 30);

    api.offline = false;
    await queue.flush(force: true);

    expect(api.created, hasLength(30));
    expect(api.created.map((e) => e.studentId).toSet(), hasLength(30));
    expect(queue.pendingCount, 0);
  });

  test('la fecha enviada es la del escaneo, no la del envío', () async {
    final api = _FakeAttendanceApi(offline: true);
    final queue = queueWith(api);

    final friday = DateTime(2026, 9, 4);
    await enqueue(queue, studentId: 1, date: friday);

    api.offline = false;
    await queue.flush(force: true);

    expect(api.created.single.date, friday);
  });

  test('un 409 del servidor cuenta como entregado, no como error', () async {
    final api = _FakeAttendanceApi(failWith: const ConflictFailure());
    final queue = queueWith(api);

    await enqueue(queue, studentId: 1);
    await queue.flush();

    expect(queue.items.single.sync, SyncState.sent);
    expect(queue.pendingCount, 0);
  });

  test('un error de red deja el registro pendiente y reintentable', () async {
    final api = _FakeAttendanceApi(offline: true);
    final queue = queueWith(api);

    await enqueue(queue, studentId: 1);
    // `enqueue` returns as soon as the record is on disk; the send is
    // fire-and-forget, so the test waits for that first pass explicitly.
    await queue.flush();

    expect(queue.items.single.sync, SyncState.pending);
    expect(queue.items.single.attempts, 1);
    expect(queue.pendingCount, 1);

    api.offline = false;
    await queue.retry(queue.items.single.localId);

    expect(api.created, hasLength(1));
    expect(queue.pendingCount, 0);
  });

  test('un 422 no se reintenta: queda como fallido para revisión humana',
      () async {
    final api = _FakeAttendanceApi(
      failWith: const ValidationFailure('Estado inválido.', {'estado': 'inválido'}),
    );
    final queue = queueWith(api);

    await enqueue(queue, studentId: 1);
    await queue.flush();

    expect(queue.items.single.sync, SyncState.failed);
    expect(queue.failed, hasLength(1));
  });

  test('la cola sobrevive a un reinicio del proceso', () async {
    final api = _FakeAttendanceApi(offline: true);
    final original = queueWith(api);
    await enqueue(original, studentId: 1);
    await original.flush();

    // Otra instancia sobre el mismo almacenamiento: lo capturado sigue ahí.
    final restored = queueWith(api);
    await restored.load();

    expect(restored.pendingCount, 1);
    expect(restored.items.single.studentId, 1);

    api.offline = false;
    await restored.flush(force: true);
    expect(api.created, hasLength(1));
  });

  test('descartar quita el registro de la cola', () async {
    final api = _FakeAttendanceApi(offline: true);
    final queue = queueWith(api);

    await enqueue(queue, studentId: 1);
    await queue.discard(queue.items.single.localId);

    expect(queue.items, isEmpty);
    expect(queue.pendingCount, 0);
  });
}

/// In-memory [LocalStore]: the queue's persistence is exercised for real,
/// only the disk is swapped out.
class _FakeStore implements LocalStore {
  final Map<String, Object?> _data = {};

  @override
  Future<T?> read<T extends Object>(String name) async => _data[name] as T?;

  @override
  Future<List<Map<String, Object?>>> readList(String name) async {
    final raw = _data[name];
    if (raw is! List) return [];
    return raw.cast<Map<String, Object?>>();
  }

  @override
  Future<void> write(String name, Object value) async => _data[name] = value;

  @override
  Future<void> delete(String name) async => _data.remove(name);
}

class _FakeAttendanceApi implements AttendanceApi {
  _FakeAttendanceApi({this.offline = false, this.failWith});

  bool offline;
  final AppFailure? failWith;
  final List<AttendanceRecord> created = [];

  var _nextId = 1;

  @override
  Future<AttendanceRecord> create({
    required int studentId,
    required DateTime date,
    required AttendanceState state,
    required int registeredBy,
    AttendanceKind? kind,
    String? observation,
  }) async {
    if (offline) throw const NetworkFailure();
    if (failWith != null) throw failWith!;
    final record = AttendanceRecord(
      id: _nextId++,
      studentId: studentId,
      date: date,
      state: state,
      registeredBy: registeredBy,
      kind: kind,
      observation: observation,
    );
    created.add(record);
    return record;
  }

  @override
  Future<List<AttendanceRecord>> list({
    int? studentId,
    DateTime? date,
    AttendanceKind? kind,
    int skip = 0,
    int limit = 20,
  }) async =>
      const [];

  @override
  Future<AttendanceRecord> byId(int attendanceId) => throw UnimplementedError();

  @override
  Future<AttendanceRecord> update(
    int attendanceId, {
    AttendanceState? state,
    String? observation,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> delete(int attendanceId) => throw UnimplementedError();
}
