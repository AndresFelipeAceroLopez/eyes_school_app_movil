import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/storage/local_store.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/value_objects/attendance.dart';
import '../api/attendance_api.dart';
import '../dto/attendance_dto.dart';

/// Result of enqueuing one scan, so the scanner can give immediate feedback.
enum EnqueueOutcome { queued, duplicate }

/// The offline write-behind queue for attendance.
///
/// Rules it enforces:
/// 1. Every scan is written to disk first and only then sent. The UI never
///    waits for the server.
/// 2. Retries use exponential backoff and stop at [maxAttempts]; what is left
///    surfaces on the "pendientes" screen instead of disappearing.
/// 3. Deduplication is by `(id_estudiante, fecha, tipo)` because the API has
///    no idempotency key. A 409/duplicate answer counts as delivered.
/// 4. The date sent is the date of the scan, never of the upload.
class AttendanceQueue extends ChangeNotifier {
  AttendanceQueue({required this._api, required this._store});

  static const _key = 'attendance_queue';
  static const maxAttempts = 5;
  static const _backoff = [
    Duration(seconds: 2),
    Duration(seconds: 8),
    Duration(seconds: 30),
    Duration(minutes: 2),
    Duration(minutes: 10),
  ];

  final AttendanceApi _api;
  final LocalStore _store;

  final List<PendingAttendance> _items = [];
  bool _loaded = false;
  bool _flushing = false;
  Future<void>? _inFlight;
  int _nextLocalId = 1;

  List<PendingAttendance> get items => List.unmodifiable(_items);

  /// Everything still owed to the server: what the tab badge counts.
  List<PendingAttendance> get outstanding =>
      _items.where((i) => !i.isSettled).toList(growable: false);

  List<PendingAttendance> get failed =>
      _items.where((i) => i.sync == SyncState.failed).toList(growable: false);

  int get pendingCount => outstanding.length;

  bool get isFlushing => _flushing;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final rows = await _store.readList(_key);
    for (final row in rows) {
      final item = PendingAttendanceMapper.fromJson(row.cast<String, dynamic>());
      _items.add(item);
      if (item.localId >= _nextLocalId) _nextLocalId = item.localId + 1;
    }
    // A record left as "sending" by a kill is unknown, not lost: retry it.
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].sync == SyncState.sending) {
        _items[i] = _items[i].copyWith(sync: SyncState.pending);
      }
    }
    notifyListeners();
  }

  /// Records one scan. Returns [EnqueueOutcome.duplicate] when this student
  /// already has a record for the same day and kind.
  Future<EnqueueOutcome> enqueue({
    required int studentId,
    required String studentName,
    required DateTime date,
    required AttendanceState state,
    required AttendanceKind kind,
    required int registeredBy,
    String? qrCode,
    String? observation,
  }) async {
    await load();

    final candidate = PendingAttendance(
      localId: _nextLocalId++,
      studentId: studentId,
      studentName: studentName,
      date: date,
      state: state,
      kind: kind,
      registeredBy: registeredBy,
      createdAt: DateTime.now(),
      qrCode: qrCode,
      observation: observation,
    );

    final clash = _items.any(
      (i) => i.dedupeKey == candidate.dedupeKey && i.sync != SyncState.duplicate,
    );
    if (clash) return EnqueueOutcome.duplicate;

    _items.add(candidate);
    await _persist();
    notifyListeners();
    unawaited(flush());
    return EnqueueOutcome.queued;
  }

  /// Sends everything that is due.
  ///
  /// Safe to call from anywhere and from several places at once: passes are
  /// serialized rather than dropped, so awaiting the returned future really
  /// does mean "the queue has been given a chance to drain". Dropping a
  /// concurrent call instead would make `await flush()` a lie.
  Future<void> flush({bool force = false}) {
    final previous = _inFlight ?? Future<void>.value();
    final next = previous.then((_) => _runFlush(force: force));
    _inFlight = next;
    return next.whenComplete(() {
      if (identical(_inFlight, next)) _inFlight = null;
    });
  }

  Future<void> _runFlush({required bool force}) async {
    await load();

    final now = DateTime.now();
    final due = _items.where((i) {
      if (i.isSettled) return false;
      // A record that exhausted its retries only moves again on an explicit
      // "reintentar", never on a background tick.
      if (i.sync == SyncState.failed && !force) return false;
      final next = i.nextAttemptAt;
      return force || next == null || !next.isAfter(now);
    }).toList();

    if (due.isEmpty) return;

    _flushing = true;
    notifyListeners();
    try {
      for (final item in due) {
        await _send(item);
      }
      await _persist();
    } finally {
      _flushing = false;
      notifyListeners();
    }
  }

  Future<void> _send(PendingAttendance item) async {
    _replace(item.copyWith(sync: SyncState.sending));
    try {
      final created = await _api.create(
        studentId: item.studentId,
        date: item.date,
        state: item.state,
        registeredBy: item.registeredBy,
        kind: item.kind,
        observation: item.observation,
      );
      _replace(item.copyWith(
        sync: SyncState.sent,
        remoteId: created.id,
        clearError: true,
        clearNextAttempt: true,
      ));
    } on ConflictFailure catch (e) {
      // The server already has it. That is success, not failure.
      _replace(item.copyWith(sync: SyncState.sent, lastError: e.message));
    } on ValidationFailure catch (e) {
      // Some deployments answer a repeated record with a 422 rather than a
      // 409; that still means the server has it. Anything else is a payload
      // problem that will never succeed on retry, so a human has to see it.
      final alreadyThere = _duplicateHint(e.message);
      _replace(item.copyWith(
        sync: alreadyThere ? SyncState.sent : SyncState.failed,
        attempts: item.attempts + 1,
        lastError: alreadyThere ? 'Ya estaba registrado en el servidor.' : e.message,
      ));
    } on AppFailure catch (e) {
      final attempts = item.attempts + 1;
      final exhausted = attempts >= maxAttempts;
      _replace(item.copyWith(
        sync: exhausted ? SyncState.failed : SyncState.pending,
        attempts: attempts,
        lastError: e.message,
        nextAttemptAt: exhausted
            ? null
            : DateTime.now().add(_backoff[(attempts - 1).clamp(0, _backoff.length - 1)]),
      ));
    }
  }

  bool _duplicateHint(String message) {
    final m = message.toLowerCase();
    return m.contains('duplic') || m.contains('ya existe') || m.contains('already');
  }

  PendingAttendance? _byId(int localId) {
    for (final item in _items) {
      if (item.localId == localId) return item;
    }
    return null;
  }

  void _replace(PendingAttendance updated) {
    final index = _items.indexWhere((i) => i.localId == updated.localId);
    if (index == -1) return;
    _items[index] = updated;
    notifyListeners();
  }

  /// Puts a failed record back in line, resetting its attempt counter.
  Future<void> retry(int localId) async {
    final item = _byId(localId);
    if (item == null) return;
    _replace(item.copyWith(
      sync: SyncState.pending,
      attempts: 0,
      clearError: true,
      clearNextAttempt: true,
    ));
    await _persist();
    await flush(force: true);
  }

  Future<void> retryAll() async {
    for (final item in failed) {
      _replace(item.copyWith(
        sync: SyncState.pending,
        attempts: 0,
        clearError: true,
        clearNextAttempt: true,
      ));
    }
    await _persist();
    await flush(force: true);
  }

  /// Corrects a queued record before it reaches the server.
  Future<void> edit(
    int localId, {
    AttendanceState? state,
    AttendanceKind? kind,
    String? observation,
  }) async {
    final item = _byId(localId);
    if (item == null || item.isSettled) return;
    _replace(item.copyWith(
      state: state,
      kind: kind,
      observation: observation,
      sync: SyncState.pending,
      attempts: 0,
      clearError: true,
      clearNextAttempt: true,
    ));
    await _persist();
  }

  Future<void> discard(int localId) async {
    _items.removeWhere((i) => i.localId == localId);
    await _persist();
    notifyListeners();
  }

  /// Drops records already acknowledged by the server, keeping the file small.
  Future<void> pruneSettled() async {
    final before = _items.length;
    _items.removeWhere((i) => i.sync == SyncState.sent);
    if (_items.length != before) {
      await _persist();
      notifyListeners();
    }
  }

  /// Called on logout: a queue belongs to the admin who captured it.
  Future<void> clear() async {
    _items.clear();
    _loaded = false;
    _inFlight = null;
    _nextLocalId = 1;
    await _store.delete(_key);
    notifyListeners();
  }

  Future<void> _persist() =>
      _store.write(_key, _items.map(PendingAttendanceMapper.toJson).toList());
}
