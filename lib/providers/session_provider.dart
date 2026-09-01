import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repositories/auth_repository.dart';
import '../models/user.dart';
import 'repository_providers.dart';

const _prefsUserIdKey = 'eyeschool.session.userId';

/// Holds the current auth session. `AsyncValue.loading()` while the persisted
/// session is being restored on app start, `AsyncValue.data(null)` when
/// logged out, `AsyncValue.data(user)` when logged in.
class SessionNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  SessionNotifier(this._authRepository) : super(const AsyncValue.loading()) {
    _restore();
  }

  final AuthRepository _authRepository;

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_prefsUserIdKey);
      if (userId == null) {
        state = const AsyncValue.data(null);
        return;
      }
      final user = await _authRepository.findById(userId);
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.login(email: email, password: password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsUserIdKey, user.id);
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsUserIdKey);
    state = const AsyncValue.data(null);
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, AsyncValue<AppUser?>>(
  (ref) => SessionNotifier(ref.watch(authRepositoryProvider)),
);
