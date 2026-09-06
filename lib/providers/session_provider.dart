import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/app_user.dart';
import '../domain/entities/session.dart';
import '../domain/repositories/repositories.dart';
import 'repository_providers.dart';

/// The auth session.
///
/// `loading` while the stored tokens are being validated on start-up,
/// `data(null)` when signed out, `data(session)` when signed in. The router
/// listens to it and is the only thing that navigates.
class SessionNotifier extends StateNotifier<AsyncValue<AppSession?>> {
  SessionNotifier(this._ref) : super(const AsyncValue.loading()) {
    // The Dio interceptor calls this when a refresh token is rejected.
    _ref.read(sessionExpiryProvider).onExpired = _onTokenRejected;
    _restore();
  }

  final Ref _ref;

  AuthRepository get _auth => _ref.read(authRepositoryProvider);

  /// Cold start. The use case owns the rule that an unusable stored session
  /// means "signed out", not "error".
  Future<void> _restore() async {
    final session = await _ref.read(restoreSessionProvider).call();
    state = AsyncValue.data(session);
    if (session != null) await _startBackgroundSync();
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final session =
          await _ref.read(signInProvider).call(email: email, password: password);
      state = AsyncValue.data(session);
      await _startBackgroundSync();
    } catch (error, stackTrace) {
      // Back to "signed out" rather than to an error state, so the login form
      // stays on screen and can show the message itself.
      state = const AsyncValue.data(null);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// Starts the offline queue's worker. A failure here — a plugin missing on
  /// this platform, say — must never cost the user the session they just
  /// opened, so it is deliberately swallowed.
  Future<void> _startBackgroundSync() async {
    try {
      await _ref.read(syncWorkerProvider).start();
    } catch (_) {
      // Background sync is best-effort; the queue still works on demand.
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _ref.read(attendanceQueueProvider).clear();
    await _ref.read(studentCatalogProvider).clear();
    _ref.read(syncWorkerProvider).dispose();
    state = const AsyncValue.data(null);
  }

  /// The refresh token was rejected mid-session: drop to the login screen
  /// without touching the queue, which may still hold unsent work.
  Future<void> _onTokenRejected() async {
    if (state.valueOrNull == null) return;
    await _auth.signOut();
    state = const AsyncValue.data(null);
  }

  /// Replaces the signed-in user after a profile edit, keeping the role
  /// bootstrap (ids, linked child) untouched.
  void updateUser(AppUser user) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(user: user));
  }

  /// Re-runs the bootstrap, e.g. after pull-to-refresh on the profile.
  Future<void> refresh() async {
    if (state.valueOrNull == null) return;
    try {
      state = AsyncValue.data(await _auth.restoreSession());
    } catch (_) {
      // Keep the current session: a failed refresh is not a sign-out.
    }
  }
}

final sessionProvider =
    StateNotifierProvider<SessionNotifier, AsyncValue<AppSession?>>(
  SessionNotifier.new,
);

/// The signed-in user, or `null`. What most screens actually want.
final currentUserProvider = Provider<AppUser?>(
  (ref) => ref.watch(sessionProvider).valueOrNull?.user,
);

/// The full session, including the role bootstrap ids.
final currentSessionProvider = Provider<AppSession?>(
  (ref) => ref.watch(sessionProvider).valueOrNull,
);

/// The student every query in this session is about: the student themself for
/// a student session, the linked child for a guardian session.
final subjectStudentIdProvider = Provider<int?>(
  (ref) => ref.watch(sessionProvider).valueOrNull?.subjectStudentId,
);

/// The running academic period. There is no `/periodos` endpoint, so this is
/// `periodo_actual` from the dashboard when known, and 1 otherwise.
final currentPeriodProvider = Provider<int>(
  (ref) => ref.watch(sessionProvider).valueOrNull?.currentPeriod ?? 1,
);
