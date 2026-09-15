import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

import 'package:eyes_school/features/attendance/data/attendance_queue.dart';

/// Drives [AttendanceQueue] on the four triggers the plan calls for: when a
/// record is enqueued (the queue does that itself), when connectivity comes
/// back, when the app returns to the foreground, and on a 60-second tick while
/// anything is still owed to the server.
class SyncWorker with WidgetsBindingObserver {
  SyncWorker(this._queue);

  static const _tick = Duration(seconds: 60);

  final AttendanceQueue _queue;

  StreamSubscription<List<ConnectivityResult>>? _connectivity;
  Timer? _timer;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    WidgetsBinding.instance.addObserver(this);
    await _queue.load();

    _connectivity = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) unawaited(_queue.flush());
    });

    _timer = Timer.periodic(_tick, (_) {
      if (_queue.pendingCount > 0) unawaited(_queue.flush());
    });

    unawaited(_queue.flush());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _queue.pendingCount > 0) {
      unawaited(_queue.flush());
    }
  }

  void dispose() {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    _connectivity?.cancel();
    _timer?.cancel();
  }
}

/// Emits `true` while the device has a usable connection. Feeds the offline
/// banner on the scanner.
Stream<bool> connectivityStream() async* {
  final connectivity = Connectivity();
  yield (await connectivity.checkConnectivity()).any((r) => r != ConnectivityResult.none);
  yield* connectivity.onConnectivityChanged
      .map((results) => results.any((r) => r != ConnectivityResult.none));
}
